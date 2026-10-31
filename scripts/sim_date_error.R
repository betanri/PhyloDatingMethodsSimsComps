#!/usr/bin/env Rscript
## True node-age error of each dated tree. Nodes are matched by descendant
## tips, and errors are divided by the true
## root age; burst-zone nodes have every tip in one true burst clade (the
## clade under the MRCA of the burst tips).
##   mae_scaled           mean |est - true| / true root, all internal nodes
##   burst_mae_scaled     the same over the burst-zone nodes
##   nonburst_mae_scaled  the same over the other nodes
##   root_rel_err         (est root - true root) / true root
##
## Usage:
##   Rscript sim_date_error.R --true-tree=T.tre --candidates-csv=dating/candidates.csv
##     --dataset=ID --out=date_error.csv [--bursts=bursts.csv]

suppressPackageStartupMessages(library(ape))
args <- commandArgs(trailingOnly = TRUE)
kv <- list()
for (a in args) {
  if (!grepl('^--', a)) next
  parts <- strsplit(sub('^--', '', a), '=', fixed = TRUE)[[1]]
  kv[[parts[1]]] <- if (length(parts) > 1) paste(parts[-1], collapse = '=') else 'TRUE'
}
need <- c('true-tree', 'candidates-csv', 'dataset', 'out')
miss <- need[!need %in% names(kv)]
if (length(miss)) stop('Missing args: ', paste(miss, collapse = ', '))

read_any_tree <- function(path) {
  tr <- try(ape::read.tree(path), silent = TRUE)
  if (inherits(tr, 'multiPhylo') || inherits(tr, 'try-error') || !inherits(tr, 'phylo') ||
      (inherits(tr, 'phylo') && length(tr$edge.length) == 0)) {
    tr <- try(ape::read.nexus(path), silent = TRUE)
    if (inherits(tr, 'multiPhylo')) tr <- tr[[1]]
  }
  if (inherits(tr, 'try-error') || !inherits(tr, 'phylo')) stop('Cannot read tree: ', path)
  tr
}
clade_ages <- function(tr) {
  n <- ape::Ntip(tr)
  d <- ape::node.depth.edgelength(tr)
  age <- max(d[seq_len(n)]) - d
  pp <- ape::prop.part(tr)
  labs <- attr(pp, 'labels')
  sig <- vapply(pp, function(p) paste(sort(labs[p]), collapse = '|'), character(1))
  stats::setNames(age[n + seq_along(pp)], sig)
}

true_tree <- read_any_tree(kv[['true-tree']])
true_age <- clade_ages(true_tree)
root_true <- max(true_age)
in_burst <- rep(FALSE, length(true_age)); names(in_burst) <- names(true_age)
if ('bursts' %in% names(kv) && file.exists(kv[['bursts']])) {
  b <- read.csv(kv[['bursts']], stringsAsFactors = FALSE)
  zones <- lapply(sort(unique(b$burst[b$burst > 0])), function(k)
    ape::extract.clade(true_tree, ape::getMRCA(true_tree, b$tip[b$burst == k]))$tip.label)
  in_burst[] <- vapply(strsplit(names(true_age), '|', fixed = TRUE),
                       function(tp) any(vapply(zones, function(z) all(tp %in% z), logical(1))), logical(1))
}

cand <- read.csv(kv[['candidates-csv']], stringsAsFactors = FALSE)
rows <- list()
for (i in seq_len(nrow(cand))) {
  if (!file.exists(cand$tree_file[i])) next
  est <- clade_ages(read_any_tree(cand$tree_file[i]))
  common <- intersect(names(true_age), names(est))
  t_a <- true_age[common]; e_a <- est[common]
  ok <- is.finite(t_a) & is.finite(e_a) & t_a > 0
  t_a <- t_a[ok]; e_a <- e_a[ok]
  ib <- in_burst[names(t_a)]
  rows[[length(rows) + 1L]] <- data.frame(
    dataset = kv[['dataset']], candidate = cand$candidate[i],
    method = if ('method' %in% names(cand)) cand$method[i] else NA_character_,
    n_nodes_matched = length(t_a), n_nodes_true = length(true_age), n_burst_nodes = sum(ib),
    mae_scaled = mean(abs(e_a - t_a)) / root_true,
    burst_mae_scaled = if (any(ib)) mean(abs(e_a - t_a)[ib]) / root_true else NA_real_,
    nonburst_mae_scaled = if (any(!ib)) mean(abs(e_a - t_a)[!ib]) / root_true else NA_real_,
    root_rel_err = (max(est) - root_true) / root_true,
    stringsAsFactors = FALSE)
}
out <- do.call(rbind, rows)
write.csv(out, kv[['out']], row.names = FALSE)
message('Wrote ', nrow(out), ' dated trees to ', kv[['out']])
