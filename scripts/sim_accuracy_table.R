#!/usr/bin/env Rscript
## True-age error of every dated tree in every set and minima level, with no
## duplicate drop (two methods that give the same tree are
## both scored). Same rules as sim_date_error.R: nodes matched by descendant
## tips, errors divided by the true root age.
##   whole     mean |est - true| / true root, all internal nodes
##   burst     the same over the burst-zone nodes
##   nonburst  the same over the other nodes
##   root_err  (est root - true root) / true root
## Burst zones: sim sets, the clade under the MRCA of each burst's tips
## (bursts.csv); Codex sets, the zone clades of Codex's postfit_zone_metrics
## CSV, nodes below the root only (the rule of codex_burst_truth.R). Codex F,
## C, D and E have no zones.
##
## Trees per dataset, in this order (the first tree of a method is kept):
##   sim main / het      runs/<dataset>/dating/candidates.csv
##   Codex sets          Codex's candidates.csv, then the MD-Cat runs
##                       (runs_codex*_mdcat/<dataset>/mdcat_run/candidates.csv)
##   minima levels       the refit candidates.csv of the level
##   all                 then work/accuracy_fill/<fill key>/<dataset>/trees.csv
##                       and trees_repair.csv (fits added by sim_accuracy_fill.py
##                       and its --repair pass); Codex C, D and E
##                       take these first (one pipeline run for all 7 methods)
##
## Writes to --outdir:
##   date_errors_main.csv, date_errors_early.csv, date_errors_poor_fossils.csv, date_errors_side.csv
##     one row per set x dataset x tree, columns of early_burst/date_errors.csv
##     first (set, dataset, rep, rate_model, cal_set, candidate, method, whole,
##     burst, root_err, whole_extra, burst_extra), then family, level, source,
##     nonburst, n_nodes_matched, n_nodes_true, n_burst_nodes, tree_file
##   method_counts.csv / .md   set x method: datasets scored / total
##   missing.csv               set, dataset, method with no scored tree
##
## Usage: Rscript sim_accuracy_table.R [--outdir=results/accuracy] [--jobs=4]
##   [--codex-dir=.../benchmark_abc]

suppressPackageStartupMessages(library(ape))
args <- commandArgs(trailingOnly = TRUE)
kv <- list()
for (a in args) {
  if (!grepl('^--', a)) next
  parts <- strsplit(sub('^--', '', a), '=', fixed = TRUE)[[1]]
  kv[[parts[1]]] <- if (length(parts) > 1) paste(parts[-1], collapse = '=') else 'TRUE'
}
`%||%` <- function(a, b) if (is.null(a)) b else a
outdir <- kv[['outdir']] %||% 'results/accuracy'
jobs <- as.integer(kv[['jobs']] %||% 4)
codex_dir <- kv[['codex-dir']] %||% '/Users/ricardobetancur/Desktop/Proxy_Misplaced/chronosPL/simulations/benchmark_abc'
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
P <- 'work/poor_minima'
METHODS <- c('RelTime', 'MD-Cat', 'treePL', 'chronos_clock', 'chronos_discrete', 'chronos_correlated', 'chronos_relaxed')

method_of <- function(cand) {
  m <- sub('^(chronos_[a-z]+).*', '\\1', cand)
  m[grepl('^treePL', cand)] <- 'treePL'
  m[grepl('^RelTime', cand)] <- 'RelTime'
  m[grepl('^MDCat', cand)] <- 'MD-Cat'
  m[!m %in% METHODS] <- NA_character_
  m
}
read_csv <- function(f) if (file.exists(f)) read.csv(f, stringsAsFactors = FALSE) else NULL
read_any_tree <- function(path) {
  tr <- try(ape::read.tree(path), silent = TRUE)
  if (inherits(tr, 'multiPhylo') || inherits(tr, 'try-error') || !inherits(tr, 'phylo') ||
      (inherits(tr, 'phylo') && length(tr$edge.length) == 0)) {
    tr <- try(ape::read.nexus(path), silent = TRUE)
    if (inherits(tr, 'multiPhylo')) tr <- tr[[1]]
  }
  if (inherits(tr, 'try-error') || !inherits(tr, 'phylo')) NULL else tr
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

## ---- Sets ----
## Each set: label, family (output table), level, datasets table, tree
## sources (functions of a dataset row) and the fill key.
codex_trees <- function(mdcat_runs) function(r) {
  x <- read_csv(r$candidates_csv); if (!is.null(x)) x$source <- 'codex'
  m <- read_csv(file.path(mdcat_runs, r$dataset, 'mdcat_run', 'candidates.csv'))
  if (!is.null(m)) { m <- m[grepl('^MDCat', m$candidate), , drop = FALSE]; m$source <- if (nrow(m)) 'mdcat_run' else character(0) }
  rbind(x[, c('candidate', 'tree_file', 'source')], if (!is.null(m) && nrow(m)) m[, c('candidate', 'tree_file', 'source')])
}
dating_trees <- function(runs) function(r) {
  x <- read_csv(file.path(runs, r$dataset, 'dating', 'candidates.csv'))
  if (is.null(x)) return(NULL)
  x$source <- 'dating'; x[, c('candidate', 'tree_file', 'source')]
}
refit_trees <- function(r) {
  x <- read_csv(file.path(dirname(r$calibrations), 'candidates.csv'))
  if (is.null(x) || !nrow(x)) return(NULL)
  x$source <- 'refit'; x[, c('candidate', 'tree_file', 'source')]
}
sets <- list()
add_set <- function(label, family, level, d, trees, fill, fill_first = FALSE) {
  if (is.null(d) || !nrow(d)) return(invisible())
  sets[[length(sets) + 1L]] <<- list(label = label, family = family, level = level, d = d, trees = trees, fill = fill,
                                     fill_first = fill_first)
}
main <- read_csv('work/datasets/datasets.csv'); main <- main[main$cal_set %in% c('sparse6', 'fossil10'), ]
add_set('sim main', 'main', 'original', main, dating_trees('work/runs'), 'main')
add_set('sim het', 'main', 'original', read_csv('work/datasets_het/datasets.csv'), dating_trees('work/runs_het'), 'het')
early <- read_csv('work/datasets_early/datasets.csv'); early <- early[early$cal_set %in% c('sparse6', 'fossil10'), ]
add_set('sim early burst', 'early', 'original', early, dating_trees('work/runs_early'), 'early')
cx <- read_csv('work/codex/datasets.csv')
for (f in c('F', 'G', 'H')) add_set(paste('Codex', f), 'main', 'original', cx[cx$source == paste('Codex', f), ],
                                    codex_trees('work/runs_codex_mdcat'), 'codex_orig')
add_set('Codex G/H + MD-Cat', 'main', 'original', read_csv('work/codex/datasets_mdcat_labeled.csv'),
        codex_trees('work/runs_codex_mdcat'), 'codex_orig')
## Codex C, D and E: all 7 methods from one pipeline run (sim_accuracy_fill.py
## kind full); Codex's own 2-3 trees only where the pipeline gave none
cde <- read_csv('work/codex_cde/datasets.csv')
for (f in c('C', 'D', 'E')) add_set(paste('Codex', f), 'side', 'original', cde[substr(cde$dataset, 1, 1) == f, ],
                                    codex_trees('work/runs_codex_cde_mdcat'), 'cde', fill_first = TRUE)
add_set('Codex D + MD-Cat', 'side', 'original', read_csv('work/codex_cde/datasets_mdcat_D.csv'),
        codex_trees('work/runs_codex_cde_mdcat'), 'cde', fill_first = TRUE)
lv <- c(orig = 'refit', clip1 = 'min clipped at 1.0', u30_60 = 'min 0.3-0.6', f60 = 'min 0.60', f45 = 'min 0.45', f30 = 'min 0.30')
for (k in names(lv)) {
  d <- read_csv(file.path(P, paste0(k, '_codex'), 'datasets.csv'))
  if (!is.null(d)) for (f in c('F', 'G', 'H'))
    add_set(paste('Codex', f, lv[[k]]), 'poor_fossils', lv[[k]], d[substr(d$dataset, 1, 1) == f, ], refit_trees, paste0('codex_', k))
  d <- read_csv(file.path(P, paste0(k, '_main'), 'datasets.csv'))
  if (!is.null(d)) add_set(paste('sim main', lv[[k]]), 'poor_fossils', lv[[k]], d, refit_trees, paste0('main_', k))
}

## ---- Codex zone clades (G and H; by benchmark, condition and replicate) ----
zone_tab <- list()
for (b in unique(unlist(lapply(sets, function(s) s$d$benchmark)))) {
  if (is.na(b)) next
  f <- file.path(codex_dir, paste0('benchmark_', b), paste0('postfit_zone_metrics_benchmark_', b, '.csv'))
  if (!file.exists(f)) next
  z <- read.csv(f, stringsAsFactors = FALSE)
  zone_tab[[b]] <- unique(data.frame(condition = z$condition, rep = as.integer(z$replicate), node = as.integer(z$node),
                                     n_tips = as.integer(z$n_tips), stringsAsFactors = FALSE))
}
zones_of <- function(r, tt) {
  if (!is.null(r$bursts) && !is.na(r$bursts) && file.exists(r$bursts)) {
    b <- read.csv(r$bursts, stringsAsFactors = FALSE)
    return(list(tips = lapply(sort(unique(b$burst[b$burst > 0])), function(k)
      ape::extract.clade(tt, ape::getMRCA(tt, b$tip[b$burst == k]))$tip.label), source = 'bursts.csv'))
  }
  if (!is.null(r$benchmark) && !is.na(r$benchmark) && !is.null(zone_tab[[r$benchmark]])) {
    z <- zone_tab[[r$benchmark]]
    z <- z[z$condition == r$condition & z$rep == as.integer(r$rep), ]
    if (!nrow(z)) return(list(tips = list(), source = 'none'))
    tips <- lapply(z$node, function(nd) ape::extract.clade(tt, nd)$tip.label)
    if (!all(lengths(tips) == z$n_tips)) return(list(tips = list(), source = 'zone tip counts do not match'))
    return(list(tips = tips, source = 'codex zones'))
  }
  list(tips = list(), source = 'none')
}

## ---- Score one dataset of one set ----
score_dataset <- function(s, i) {
  r <- as.list(s$d[i, , drop = FALSE])
  tr <- s$trees(r)
  fill <- do.call(rbind, lapply(c('trees.csv', 'trees_repair.csv'), function(f) {
    x <- read_csv(file.path('work/accuracy_fill', s$fill, r$dataset, f))
    if (!is.null(x) && nrow(x)) x[, c('candidate', 'tree_file', 'source')]
  }))
  ## Did the set's own run give a chronos discrete tree (for C, D and E the
  ## pipeline run of the fill, else the source run)?
  own <- if (isTRUE(s$fill_first)) read_csv(file.path('work/accuracy_fill', s$fill, r$dataset, 'trees.csv')) else tr
  had_discrete <- !is.null(own) && any(method_of(own$candidate) %in% 'chronos_discrete' & file.exists(own$tree_file))
  if (!is.null(fill) && nrow(fill)) {
    tr <- if (isTRUE(s$fill_first)) rbind(fill, tr) else rbind(tr, fill)
  }
  ## A chronos discrete refit (a k x lambda fit had stopped with ape's underflow
  ## error) takes the place of the original discrete tree; at a minima level,
  ## the refit of the new k x lambda at that level
  dr <- read_csv(file.path('work/accuracy_fill', s$fill, r$dataset,
                           if (s$level == 'original') 'trees_discrete_refit.csv' else 'trees_discrete_refit_level.csv'))
  if (!is.null(dr) && nrow(dr)) {
    if (!had_discrete) dr$source <- 'discrete_refit_from_none'
    tr <- rbind(dr[, c('candidate', 'tree_file', 'source')], tr)
  }
  if (is.null(tr) || !nrow(tr)) return(NULL)
  tr$method <- method_of(tr$candidate)
  tr <- tr[!is.na(tr$method) & file.exists(tr$tree_file), , drop = FALSE]
  tr <- tr[!duplicated(tr$method), , drop = FALSE]
  if (!nrow(tr)) return(NULL)
  tt <- read_any_tree(r$true_tree)
  ta <- clade_ages(tt); root <- max(ta)
  zt <- zones_of(r, tt)
  in_b <- vapply(strsplit(names(ta), '|', fixed = TRUE), function(tp)
    length(zt$tips) > 0 && any(vapply(zt$tips, function(z) all(tp %in% z), logical(1))), logical(1))
  in_b[ta >= root * (1 - 1e-9)] <- FALSE
  names(in_b) <- names(ta)
  rows <- lapply(seq_len(nrow(tr)), function(j) {
    et <- read_any_tree(tr$tree_file[j])
    if (is.null(et)) return(NULL)
    e <- clade_ages(et)
    k <- intersect(names(ta), names(e))
    k <- k[is.finite(ta[k]) & is.finite(e[k]) & ta[k] > 0]
    err <- abs(e[k] - ta[k]); ib <- in_b[k]
    data.frame(set = s$label, dataset = r$dataset, rep = r$rep, rate_model = r$rate_model %||% NA, cal_set = r$cal_set %||% NA,
               candidate = tr$candidate[j], method = tr$method[j],
               whole = mean(err) / root, burst = if (any(ib)) mean(err[ib]) / root else NA_real_,
               root_err = (max(e) - root) / root, family = s$family, level = s$level, source = tr$source[j],
               nonburst = if (any(!ib)) mean(err[!ib]) / root else NA_real_,
               n_nodes_matched = length(k), n_nodes_true = length(ta), n_burst_nodes = sum(ib), zones = zt$source,
               tree_file = tr$tree_file[j], stringsAsFactors = FALSE)
  })
  do.call(rbind, rows)
}
tasks <- do.call(rbind, lapply(seq_along(sets), function(k) data.frame(k = k, i = seq_len(nrow(sets[[k]]$d)))))
res <- parallel::mclapply(seq_len(nrow(tasks)), function(t) {
  out <- try(score_dataset(sets[[tasks$k[t]]], tasks$i[t]), silent = TRUE)
  if (inherits(out, 'try-error')) { message(sets[[tasks$k[t]]]$label, ' row ', tasks$i[t], ': ', out); NULL } else out
}, mc.cores = jobs)
e <- do.call(rbind, res)

## A tree whose clades do not all match the true tree is not scored
bad <- e$n_nodes_matched < e$n_nodes_true
if (any(bad)) message(sum(bad), ' trees with unmatched nodes (kept, flagged in n_nodes_matched)')
key <- paste(e$set, e$dataset)
for (v in c('whole', 'burst')) {
  best <- ave(e[[v]], key, FUN = function(z) if (all(is.na(z))) NA_real_ else min(z, na.rm = TRUE))
  e[[paste0(v, '_extra')]] <- e[[v]] / best - 1
}
cols <- c('set', 'dataset', 'rep', 'rate_model', 'cal_set', 'candidate', 'method', 'whole', 'burst', 'root_err', 'whole_extra',
          'burst_extra', 'family', 'level', 'source', 'nonburst', 'n_nodes_matched', 'n_nodes_true', 'n_burst_nodes', 'zones', 'tree_file')
e <- e[, cols]
for (f in unique(e$family)) write.csv(e[e$family == f, ], file.path(outdir, paste0('date_errors_', f, '.csv')), row.names = FALSE)

## ---- Count table: set x method, datasets scored / total ----
cnt <- do.call(rbind, lapply(sets, function(s) {
  x <- e[e$set == s$label & is.finite(e$whole), ]
  dr <- x[x$method == 'chronos_discrete' & grepl('^discrete_refit', x$source), ]
  data.frame(set = s$label, family = s$family, n_datasets = nrow(s$d),
             t(vapply(METHODS, function(m) length(unique(x$dataset[x$method == m])), numeric(1))),
             discrete_refit = length(unique(dr$dataset)),
             discrete_refit_new_pick = length(unique(dr$dataset[dr$source == 'discrete_refit_new_pick'])),
             discrete_refit_from_none = length(unique(dr$dataset[dr$source == 'discrete_refit_from_none'])), check.names = FALSE)
}))
write.csv(cnt, file.path(outdir, 'method_counts.csv'), row.names = FALSE)
md <- c('# Datasets with a scored tree / all datasets, by set and method', '',
        'Bold: a gap. Discrete refits: datasets whose chronos discrete tree comes from a refit (a k x lambda fit',
        "had stopped with ape's underflow error). Pick changed: the refit chose another k x lambda than the",
        'original run. From none: the original run had no discrete tree.', '',
        paste0('| Set | n | ', paste(METHODS, collapse = ' | '), ' | Discrete refits | Pick changed | From none |'),
        paste0('|', paste(rep('---', length(METHODS) + 5), collapse = '|'), '|'))
for (j in seq_len(nrow(cnt))) md <- c(md, paste0('| ', cnt$set[j], ' | ', cnt$n_datasets[j], ' | ',
  paste(vapply(METHODS, function(m) if (cnt[[m]][j] == cnt$n_datasets[j]) as.character(cnt[[m]][j]) else paste0('**', cnt[[m]][j], '**'),
               character(1)), collapse = ' | '), ' | ',
  paste(vapply(c('discrete_refit', 'discrete_refit_new_pick', 'discrete_refit_from_none'), function(v)
    if (cnt[[v]][j]) as.character(cnt[[v]][j]) else '', character(1)), collapse = ' | '), ' |'))
writeLines(md, file.path(outdir, 'method_counts.md'))
miss <- do.call(rbind, lapply(sets, function(s) {
  x <- e[e$set == s$label & is.finite(e$whole), ]
  g <- expand.grid(dataset = s$d$dataset, method = METHODS, stringsAsFactors = FALSE)
  g <- g[!paste(g$dataset, g$method) %in% paste(x$dataset, x$method), ]
  if (nrow(g)) data.frame(set = s$label, family = s$family, fill_key = s$fill, g, stringsAsFactors = FALSE)
}))
write.csv(miss, file.path(outdir, 'missing.csv'), row.names = FALSE)
message('Scored ', nrow(e), ' trees in ', length(unique(key)), ' set x datasets; ', if (is.null(miss)) 0 else nrow(miss), ' set x dataset x method gaps')
