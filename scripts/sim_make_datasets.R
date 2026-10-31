#!/usr/bin/env Rscript
## Make the simulated datasets (burst trees, hard rate models, early bursts).
##
## One true chronogram per replicate. Every rate model and calibration set of
## a replicate uses that same tree (paired design), so differences between
## rate models are not differences between trees.
##
## Output, per replicate r, rate model m and calibration set c:
##   <outdir>/rep<r>/true_chronogram.tre
##   <outdir>/rep<r>/bursts.csv                 burst clades of the true tree
##   <outdir>/rep<r>/cal_<c>.csv                calibrations from the true tree
##   <outdir>/rep<r>/<m>/phylogram.tre          rate x time, then Poisson noise
##   <outdir>/rep<r>/<m>/branch_rates.csv       true rate on each branch
## plus <outdir>/datasets.csv with one row per dating run (rep x model x cal).
##
## Usage:
##   Rscript sim_make_datasets.R --outdir=DIR [--n-reps=10] [--seed=20261029]
##     [--rate-models=acln,ucln,discrete,punct] [--cal-sets=sparse6,fossil10,dense19]
##     [--root-age=100] [--height=0.25] [--n-sites=1000]
##     [--lambda0=0.045] [--mu0=0.025] [--burst-lambda=2] [--burst-dur=1.5]
##     [--burst-window=0.4,0.85] [--n-bursts=3] [--iqtree-bin=iqtree3]
## Rate models: acln, ucln, discrete, punct (main set); acln_s025..acln_s150,
## ucln_s025..ucln_s150 (sigma 0.25-1.5), localclock; seqhomo050/100 and
## seqhet050/100 (sequence simulation with AliSim, needs IQ-TREE 2+);
## codex_ac_h100/150, codex_disc_h100/150 (Codex autocorrelated and discrete
## clocks at heterotachy 1.0 and 1.5).

suppressPackageStartupMessages(library(ape))

args <- commandArgs(trailingOnly = TRUE)
kv <- list()
for (a in args) {
  if (!grepl('^--', a)) next
  parts <- strsplit(sub('^--', '', a), '=', fixed = TRUE)[[1]]
  kv[[parts[1]]] <- if (length(parts) > 1) paste(parts[-1], collapse = '=') else 'TRUE'
}
arg <- function(key, default) if (key %in% names(kv)) kv[[key]] else default
if (!('outdir' %in% names(kv))) stop('Missing --outdir')
outdir <- kv[['outdir']]
n_reps <- as.integer(arg('n-reps', 10))
seed <- as.integer(arg('seed', 20261029))
rate_models <- strsplit(arg('rate-models', 'acln,ucln,discrete,punct'), ',')[[1]]
cal_sets <- strsplit(arg('cal-sets', 'sparse6,fossil10,dense19'), ',')[[1]]
root_age <- as.numeric(arg('root-age', 100))
height <- as.numeric(arg('height', 0.25))
n_sites <- as.integer(arg('n-sites', 1000))
burst_args <- list(lambda0 = as.numeric(arg('lambda0', 0.045)), mu0 = as.numeric(arg('mu0', 0.025)),
                   burst_lambda = as.numeric(arg('burst-lambda', 2)), burst_dur = as.numeric(arg('burst-dur', 1.5)),
                   burst_window = as.numeric(strsplit(arg('burst-window', '0.4,0.85'), ',')[[1]]),
                   n_bursts = as.integer(arg('n-bursts', 3)))
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

## ── True chronogram: birth-death with clade bursts ─────────────────────────
## Background speciation lambda0 and extinction mu0. At each burst time one
## living lineage, and every lineage born from it inside the burst window,
## speciates at burst_lambda for burst_dur Myr, then returns to lambda0.
## Defaults: lambda0 0.045, mu0 0.025, three bursts of 2 per Myr (about 40
## times background) for 1.5 Myr, at 40-85% of the time from root to present.
## The run is kept only if the extant tree has ntip_range tips and every
## burst clade has at least min_burst_tips extant tips (so that each burst clade
## has 8+ tips).
sim_burst_once <- function(T, lambda0, mu0, burst_times, burst_lambda, burst_dur, max_alive = 1500L) {
  maxE <- 40000L
  e_par <- integer(maxE); e_child <- integer(maxE)
  e_start <- numeric(maxE); e_end <- numeric(maxE)
  e_burst <- integer(maxE); e_extinct <- logical(maxE)
  n_e <- 0L; next_node <- 2L  # node 1 is the root
  add_edge <- function(parent, t, burst) {
    n_e <<- n_e + 1L
    e_par[n_e] <<- parent; e_start[n_e] <<- t; e_burst[n_e] <<- burst
    n_e
  }
  alive <- c(add_edge(1L, 0, 0L), add_edge(1L, 0, 0L))
  until <- c(0, 0)
  t <- 0; b_next <- 1L; burst_times <- sort(burst_times)
  repeat {
    lam <- ifelse(until > t, burst_lambda, lambda0)
    rate_i <- lam + mu0
    dt <- stats::rexp(1, sum(rate_i))
    sched <- c(if (b_next <= length(burst_times)) burst_times[b_next], until[until > t], T)
    t_sched <- min(sched)
    if (t + dt >= t_sched) {
      t <- t_sched
      if (t >= T) break
      if (b_next <= length(burst_times) && abs(t - burst_times[b_next]) < 1e-12) {
        i <- sample.int(length(alive), 1L)
        until[i] <- t + burst_dur
        e_burst[alive[i]] <- b_next
        b_next <- b_next + 1L
      }
      next
    }
    t <- t + dt
    i <- sample.int(length(alive), 1L, prob = rate_i)
    e <- alive[i]
    e_end[e] <- t
    if (stats::runif(1) < lam[i] / rate_i[i]) {
      nd <- next_node; next_node <- next_node + 1L
      e_child[e] <- nd
      c1 <- add_edge(nd, t, e_burst[e]); c2 <- add_edge(nd, t, e_burst[e])
      alive <- c(alive[-i], c1, c2)
      until <- c(until[-i], until[i], until[i])
    } else {
      e_extinct[e] <- TRUE
      alive <- alive[-i]; until <- until[-i]
    }
    if (!length(alive) || length(alive) > max_alive || n_e > maxE - 10L) return(NULL)
  }
  e_end[alive] <- T
  ## Number tips 1..n, internal nodes n+1.. (root = n+1)
  tip_edges <- which(e_child[seq_len(n_e)] == 0L)
  n_tip <- length(tip_edges)
  int_ids <- sort(unique(e_par[seq_len(n_e)]))
  map_int <- stats::setNames(n_tip + seq_along(int_ids), int_ids)
  child <- integer(n_e)
  child[tip_edges] <- seq_len(n_tip)
  int_edges <- setdiff(seq_len(n_e), tip_edges)
  child[int_edges] <- map_int[as.character(e_child[int_edges])]
  phy <- list(edge = cbind(unname(map_int[as.character(e_par[seq_len(n_e)])]), child),
              edge.length = e_end[seq_len(n_e)] - e_start[seq_len(n_e)],
              tip.label = paste0('x', seq_len(n_tip)), Nnode = length(int_ids))
  class(phy) <- 'phylo'
  extant <- !e_extinct[tip_edges]
  list(phy = phy, extant_labels = phy$tip.label[extant], tip_burst = e_burst[tip_edges])
}

sim_burst_tree <- function(root_age, ntip_range = c(90L, 120L), n_bursts = 3L,
                           lambda0 = 0.045, mu0 = 0.025, burst_lambda = 2, burst_dur = 1.5,
                           burst_window = c(0.4, 0.85), min_burst_tips = 8L, max_tries = 20000L) {
  T <- 100
  for (k in seq_len(max_tries)) {
    bt <- sort(stats::runif(n_bursts, burst_window[1] * T, burst_window[2] * T))
    s <- sim_burst_once(T, lambda0, mu0, bt, burst_lambda, burst_dur)
    if (is.null(s)) next
    n_ext <- length(s$extant_labels)
    if (n_ext < ntip_range[1] || n_ext > ntip_range[2]) next
    burst_of <- stats::setNames(s$tip_burst, s$phy$tip.label)[s$extant_labels]
    sizes <- tabulate(burst_of[burst_of > 0], nbins = n_bursts)
    if (any(sizes < min_burst_tips)) next
    tr <- ape::keep.tip(s$phy, s$extant_labels)
    ## Both root lineages must survive, so the crown age is the full run time.
    d <- ape::node.depth.edgelength(tr)
    if (abs(max(d[seq_len(ape::Ntip(tr))]) - T) > 1e-6 || ape::is.binary(tr) == FALSE) next
    ## Rescale to root_age, rename tips sp001.., keep burst membership
    tr$edge.length <- tr$edge.length * (root_age / T)
    old <- tr$tip.label
    tr$tip.label <- sprintf('sp%03d', seq_along(old))
    tr <- ape::ladderize(tr)
    tr <- ape::read.tree(text = ape::write.tree(tr))
    lab_map <- stats::setNames(sprintf('sp%03d', seq_along(old)), old)
    bursts <- data.frame(tip = unname(lab_map[names(burst_of)]), burst = unname(burst_of), stringsAsFactors = FALSE)
    bursts$burst_time_ma <- ifelse(bursts$burst > 0, root_age * (1 - bt[pmax(bursts$burst, 1)] / T), NA_real_)
    attr(tr, 'tries') <- k
    return(list(tree = tr, bursts = bursts))
  }
  stop('No tree met the conditions after ', max_tries, ' tries')
}

## ── Rate models ────────────────────────────────────────────────────────────
## Each returns substitutions per site per Myr on each edge (mean about 1;
## the scale is set later), or, for punct, the expected branch length.
node_ages <- function(tr) {
  d <- ape::node.depth.edgelength(tr)
  max(d[seq_len(ape::Ntip(tr))]) - d
}

rates_acln <- function(tr, nu = 0.005, ...) {
  ## Autocorrelated lognormal (Kishino et al. 2001): log rate at the child
  ## node = log rate at the parent + N(-nu t / 2, nu t). Branch rate = mean of
  ## the two end-node rates. nu * root age = 0.5, so tip log rates have sd ~0.7.
  tr <- ape::reorder.phylo(tr, 'cladewise')
  n_nodes <- ape::Ntip(tr) + tr$Nnode
  lr <- rep(NA_real_, n_nodes); lr[ape::Ntip(tr) + 1L] <- 0
  for (i in seq_len(nrow(tr$edge))) {
    p <- tr$edge[i, 1]; ch <- tr$edge[i, 2]; t <- tr$edge.length[i]
    lr[ch] <- lr[p] + stats::rnorm(1, -nu * t / 2, sqrt(nu * t))
  }
  r <- exp(lr)
  list(tree = tr, rate = (r[tr$edge[, 1]] + r[tr$edge[, 2]]) / 2, spike = 0)
}

rates_ucln <- function(tr, sdlog = 0.5, ...) {
  ## Uncorrelated lognormal: iid rate per branch, mean 1.
  list(tree = tr, rate = exp(stats::rnorm(nrow(tr$edge), -sdlog^2 / 2, sdlog)), spike = 0)
}

rates_discrete <- function(tr, cats = c(0.4, 1, 2.5), ...) {
  ## Discrete categories: each branch takes one of three rates, iid, equal
  ## probability (the model behind chronos 'discrete' and MD-Cat).
  list(tree = tr, rate = sample(cats / mean(cats), nrow(tr$edge), replace = TRUE), spike = 0)
}

rates_punct <- function(tr, spike_myr = 2.5, sdlog = 0.2, ...) {
  ## Punctuated: a near-clock background rate plus a fixed substitution spike
  ## at the start of every branch (each speciation). The spike equals
  ## spike_myr Myr of background change, about 20-30% of root-to-tip
  ## change here (Pagel et al. 2006 report values in this range).
  list(tree = tr, rate = exp(stats::rnorm(nrow(tr$edge), -sdlog^2 / 2, sdlog)), spike = spike_myr)
}

## Heterotachy gradient: the same two laws at set sigma, the sd of log rate.
## For acln, nu = sigma^2 / root age, so tip log rates have sd sigma.
rates_acln_sigma <- function(sigma) function(tr, ...) rates_acln(tr, nu = sigma^2 / max(node_ages(tr)))
rates_ucln_sigma <- function(sigma) function(tr, ...) rates_ucln(tr, sdlog = sigma)

## Codex benchmark definitions (chronosPL/simulations/benchmark_abc,
## simulate_rates_by_clock), so heterotachy h lines up with its levels:
## autocorrelated = log rate of each edge = log rate of its parent edge +
## N(0, h), per edge, not scaled by duration; discrete = rates exp(-2h),
## 1, exp(2h) with probabilities 0.25, 0.5, 0.25. Codex 'independent' at h is
## ucln at sigma = h (only the mean differs, and the scale is set later).
rates_codex_autocorrelated <- function(h) function(tr, ...) {
  tr <- ape::reorder.phylo(tr, 'cladewise')
  n <- ape::Ntip(tr)
  node_rate <- rep(NA_real_, n + tr$Nnode); node_rate[n + 1L] <- 1
  rate <- numeric(nrow(tr$edge))
  for (i in seq_len(nrow(tr$edge))) {
    rate[i] <- node_rate[tr$edge[i, 1]] * exp(stats::rnorm(1, 0, h))
    node_rate[tr$edge[i, 2]] <- rate[i]
  }
  list(tree = tr, rate = rate, spike = 0)
}
rates_codex_discrete <- function(h) function(tr, ...) {
  list(tree = tr, spike = 0,
       rate = sample(exp(c(-1, 0, 1) * 2 * h), nrow(tr$edge), replace = TRUE, prob = c(0.25, 0.5, 0.25)))
}

rates_localclock <- function(tr, bursts, n_shifts = 4L, fold = c(5, 10), sdlog = 0.2) {
  ## Local clocks: a near-clock background (lognormal noise, sdlog 0.2) with
  ## n_shifts clades whose rate is multiplied or divided by 5-10x, the shift
  ## starting on the clade's stem branch. One shift is inside a radiation
  ## (the crown of a burst clade or a clade of 4+ tips within it); the others
  ## are clades of 4 tips to a third of the tree. Nested shifts multiply.
  n <- ape::Ntip(tr)
  rate <- exp(stats::rnorm(nrow(tr$edge), -sdlog^2 / 2, sdlog))
  pp <- ape::prop.part(tr)
  sizes <- lengths(pp)
  nodes <- n + seq_along(pp)
  ok <- sizes >= 4L & sizes <= n / 3
  ok[1] <- FALSE
  k <- sample(sort(unique(bursts$burst[bursts$burst > 0])), 1L)
  crown <- ape::getMRCA(tr, bursts$tip[bursts$burst == k])
  crown_tips <- ape::extract.clade(tr, crown)$tip.label
  inside <- nodes[sizes >= 4L & vapply(pp, function(p) all(tr$tip.label[p] %in% crown_tips), logical(1))]
  first <- inside[sample.int(length(inside), 1L)]
  pool <- setdiff(nodes[ok], first)
  shifts <- c(first, pool[sample.int(length(pool), n_shifts - 1L)])
  factor <- exp(sample(c(-1, 1), n_shifts, replace = TRUE) * stats::runif(n_shifts, log(fold[1]), log(fold[2])))
  for (j in seq_along(shifts)) {
    below <- c(shifts[j], phangorn::Descendants(tr, shifts[j], type = 'all'))
    idx <- which(tr$edge[, 2] %in% below)
    rate[idx] <- rate[idx] * factor[j]
  }
  list(tree = tr, rate = rate, spike = 0,
       shifts = data.frame(node = shifts, n_tips = sizes[shifts - n], factor = factor,
                           inside_burst = c(TRUE, rep(FALSE, n_shifts - 1L))))
}

## Sequence-level heterotachy. n_part blocks of sites, each with its own
## UCLN(sigma) branch rates on the true tree (n_part = 1: homotachous
## control). Each block is simulated with AliSim under one GTR+G model, the
## blocks are joined, and branch lengths are inferred with IQ-TREE under a
## single GTR+G4 on the true (unrooted) topology. The tree is rooted on the
## true root edge, split in half.
read_fasta <- function(path) {
  x <- readLines(path)
  hdr <- grep('^>', x)
  ends <- c(hdr[-1] - 1L, length(x))
  stats::setNames(vapply(seq_along(hdr), function(i) paste(x[(hdr[i] + 1L):ends[i]], collapse = ''), character(1)),
                  trimws(sub('^>', '', x[hdr])))
}

make_seq_phylogram <- function(tr, sigma, n_part, height, n_sites, iqtree, wd, seed) {
  dir.create(wd, showWarnings = FALSE, recursive = TRUE)
  model <- 'GTR{1.2,4.0,0.9,1.1,4.5}+F{0.3,0.2,0.25,0.25}+G4{0.5}'
  len <- rep(n_sites %/% n_part, n_part)
  exp_bl <- matrix(NA_real_, nrow(tr$edge), n_part)
  seqs <- list()
  for (p in seq_len(n_part)) {
    rm <- rates_ucln(tr, sdlog = sigma)
    ph <- tr
    ph$edge.length <- rm$rate * tr$edge.length
    d <- ape::node.depth.edgelength(ph)
    ph$edge.length <- ph$edge.length * height / mean(d[seq_len(ape::Ntip(ph))])
    exp_bl[, p] <- ph$edge.length
    f_tree <- file.path(wd, sprintf('part%d.nwk', p))
    ape::write.tree(ph, f_tree)
    pre <- file.path(wd, sprintf('part%d', p))
    rc <- system2(iqtree, c('--alisim', shQuote(pre), '-t', shQuote(f_tree), '-m', shQuote(model), '--length', len[p],
                            '--seed', seed + p, '-af', 'fasta', '-nt', '1'),
                  stdout = paste0(pre, '_alisim.log'), stderr = paste0(pre, '_alisim.log'))
    if (rc != 0) stop('AliSim failed: ', pre)
    seqs[[p]] <- read_fasta(paste0(pre, '.fa'))
  }
  labs <- tr$tip.label
  joined <- vapply(labs, function(l) paste(vapply(seqs, function(s) s[[l]], character(1)), collapse = ''), character(1))
  aln <- file.path(wd, 'alignment.fa')
  writeLines(paste0('>', labs, '
', joined), aln)
  topo <- file.path(wd, 'topology_unrooted.nwk')
  ## Topology only: Myr branch lengths as starting values leave IQ-TREE stuck
  ## on saturated branches
  topo_tr <- ape::unroot(tr)
  topo_tr$edge.length <- NULL
  ape::write.tree(topo_tr, topo)
  pre_inf <- file.path(wd, 'iqtree')
  rc <- system2(iqtree, c('-s', shQuote(aln), '-te', shQuote(topo), '-m', 'GTR+G4', '-pre', shQuote(pre_inf),
                          '--seed', seed, '-nt', '1', '-keep-ident', '-redo', '-quiet'), stdout = FALSE, stderr = FALSE)
  if (rc != 0) stop('IQ-TREE failed: ', pre_inf)
  inf <- ape::read.tree(paste0(pre_inf, '.treefile'))
  ## Outgroup = the smaller side of the true root (ape::root misplaces the
  ## root when the outgroup holds the tree's current basal node)
  kids <- tr$edge[tr$edge[, 1] == ape::Ntip(tr) + 1L, 2]
  side <- lapply(kids, function(k) if (k <= ape::Ntip(tr)) tr$tip.label[k] else ape::extract.clade(tr, k)$tip.label)
  og <- side[[which.min(lengths(side))]]
  rr <- ape::root(inf, outgroup = og, resolve.root = TRUE)
  rk <- which(rr$edge[, 1] == ape::Ntip(rr) + 1L)
  rr$edge.length[rk] <- sum(rr$edge.length[rk]) / 2
  rr$edge.length <- pmax(rr$edge.length, 1e-6)
  rr <- ape::read.tree(text = ape::write.tree(rr))
  ## Map inferred lengths back to the true tree's edges by descendant tips
  sig <- function(t) {
    pp <- ape::prop.part(t); labs <- attr(pp, 'labels')
    s_int <- vapply(pp, function(x) paste(sort(labs[x]), collapse = '|'), character(1))
    ch <- t$edge[, 2]
    ifelse(ch <= ape::Ntip(t), t$tip.label[pmin(ch, ape::Ntip(t))], s_int[pmax(ch - ape::Ntip(t), 1L)])
  }
  if (!isTRUE(ape::all.equal.phylo(rr, tr, use.edge.length = FALSE))) stop('Inferred topology differs from the true tree')
  obs <- stats::setNames(rr$edge.length, sig(rr))[sig(tr)]
  expected <- tr
  expected$edge.length <- rowMeans(exp_bl)
  list(expected = expected, phylogram = rr,
       rates = data.frame(parent = tr$edge[, 1], child = tr$edge[, 2], time_myr = tr$edge.length,
                          rate = expected$edge.length / tr$edge.length, expected_bl = expected$edge.length,
                          observed_bl = unname(obs), exp_bl_part = exp_bl))
}

make_phylogram <- function(tr, rm, height, n_sites) {
  tr <- rm$tree
  bl <- rm$rate * tr$edge.length + rm$spike
  ph <- tr; ph$edge.length <- bl
  d <- ape::node.depth.edgelength(ph)
  scale <- height / mean(d[seq_len(ape::Ntip(ph))])
  ph$edge.length <- bl * scale
  ## Poisson noise at n_sites (the pipeline bootstrap scheme); 1e-6 floor as
  ## in RAxML/IQ-TREE output.
  noisy <- ph
  noisy$edge.length <- pmax(stats::rpois(length(bl), ph$edge.length * n_sites) / n_sites, 1e-6)
  list(expected = ph, phylogram = noisy,
       rates = data.frame(parent = tr$edge[, 1], child = tr$edge[, 2], time_myr = tr$edge.length,
                          rate = ph$edge.length / tr$edge.length, expected_bl = ph$edge.length,
                          observed_bl = noisy$edge.length, spike_part = rm$spike * scale))
}

## ── Calibrations from the true tree ────────────────────────────────────────
cal_pair <- function(tr, nd) {
  ## Two tips whose MRCA is nd: the first tip under each child.
  kids <- tr$edge[tr$edge[, 1] == nd, 2]
  first_tip <- function(x) {
    while (x > ape::Ntip(tr)) x <- tr$edge[tr$edge[, 1] == x, 2][1]
    tr$tip.label[x]
  }
  c(first_tip(kids[1]), first_tip(kids[2]))
}

pick_by_age_bins <- function(ages, nodes, k, lo, hi, exclude = integer(0)) {
  ## One random node from each of k equal-width age bins in [lo, hi];
  ## empty bins are filled at random from the remaining eligible nodes.
  pool <- setdiff(nodes[ages[nodes] >= lo & ages[nodes] <= hi], exclude)
  breaks <- seq(lo, hi, length.out = k + 1L)
  out <- integer(0)
  for (b in seq_len(k)) {
    inbin <- setdiff(pool[ages[pool] >= breaks[b] & ages[pool] < breaks[b + 1L]], out)
    if (length(inbin)) out <- c(out, inbin[sample.int(length(inbin), 1L)])
  }
  while (length(out) < k && length(setdiff(pool, out))) {
    rest <- setdiff(pool, out)
    out <- c(out, rest[sample.int(length(rest), 1L)])
  }
  out
}

cal_rows <- function(tr, nodes, age_min, age_max, source) {
  ages <- node_ages(tr)
  pr <- t(vapply(nodes, function(nd) cal_pair(tr, nd), character(2)))
  data.frame(taxonA = pr[, 1], taxonB = pr[, 2], age_min = age_min, age_max = age_max,
             calibration_source = source, pair_id = seq_along(nodes), true_age = ages[nodes],
             node = nodes, stringsAsFactors = FALSE)
}

make_calibrations <- function(tr) {
  ages <- node_ages(tr)
  n <- ape::Ntip(tr); root <- n + 1L
  T <- ages[root]
  int_nodes <- setdiff((n + 1L):(n + tr$Nnode), root)
  ## sparse6: the root plus 5 nodes spread over 5%-95% of root age; point ages
  sp <- pick_by_age_bins(ages, int_nodes, 5L, 0.05 * T, 0.95 * T)
  sparse_nodes <- c(root, sp)
  ## dense19: the sparse nodes plus 13 more; point ages
  dn <- pick_by_age_bins(ages, int_nodes, 13L, 0.05 * T, 0.95 * T, exclude = sp)
  dense_nodes <- c(sparse_nodes, dn)
  ## fossil10: the root as an interval, two more intervals and seven minimum
  ## ages. Minima are younger than the true age (fossils are), maxima older.
  ## The order is shuffled so the two interval nodes have random depths.
  fo <- pick_by_age_bins(ages, int_nodes, 9L, 0.05 * T, 0.95 * T)
  fo <- fo[sample.int(length(fo))]
  a_fo <- ages[fo]
  fo_min <- c(T * stats::runif(1, 0.85, 0.97),
              a_fo[1:2] * stats::runif(2, 0.70, 0.95),
              a_fo[3:9] * stats::runif(7, 0.60, 0.98))
  fo_max <- c(T * stats::runif(1, 1.15, 1.50), a_fo[1:2] * stats::runif(2, 1.10, 1.40), rep(NA_real_, 7))
  list(
    sparse6 = cal_rows(tr, sparse_nodes, ages[sparse_nodes], ages[sparse_nodes], 'sim_point'),
    dense19 = cal_rows(tr, dense_nodes, ages[dense_nodes], ages[dense_nodes], 'sim_point'),
    fossil10 = cal_rows(tr, c(root, fo), fo_min, fo_max, 'sim_fossil')
  )
}

## ── Main ───────────────────────────────────────────────────────────────────
## The position of a model in this list sets its random seed, so new models
## go at the end and the first four keep their phylograms.
rate_fun <- list(acln = rates_acln, ucln = rates_ucln, discrete = rates_discrete, punct = rates_punct,
                 acln_s025 = rates_acln_sigma(0.25), acln_s050 = rates_acln_sigma(0.5),
                 acln_s100 = rates_acln_sigma(1.0), acln_s150 = rates_acln_sigma(1.5),
                 ucln_s025 = rates_ucln_sigma(0.25), ucln_s100 = rates_ucln_sigma(1.0),
                 ucln_s150 = rates_ucln_sigma(1.5), localclock = rates_localclock,
                 seqhomo050 = c(0.5, 1), seqhomo100 = c(1.0, 1), seqhet050 = c(0.5, 2), seqhet100 = c(1.0, 2),
                 codex_ac_h100 = rates_codex_autocorrelated(1.0), codex_ac_h150 = rates_codex_autocorrelated(1.5),
                 codex_disc_h100 = rates_codex_discrete(1.0), codex_disc_h150 = rates_codex_discrete(1.5))
iqtree_bin <- arg('iqtree-bin', Sys.which('iqtree3'))
rows <- list()
for (r in seq_len(n_reps)) {
  set.seed(seed + r)
  rep_dir <- file.path(outdir, sprintf('rep%02d', r))
  dir.create(rep_dir, showWarnings = FALSE)
  sim <- do.call(sim_burst_tree, c(list(root_age = root_age), burst_args))
  tr <- sim$tree
  ape::write.tree(tr, file.path(rep_dir, 'true_chronogram.tre'))
  write.csv(sim$bursts, file.path(rep_dir, 'bursts.csv'), row.names = FALSE)
  cals <- make_calibrations(tr)
  for (cs in cal_sets) {
    out <- cals[[cs]]
    write.csv(out[, c('taxonA', 'taxonB', 'age_min', 'age_max', 'calibration_source', 'pair_id')],
              file.path(rep_dir, paste0('cal_', cs, '.csv')), row.names = FALSE, na = '')
    write.csv(out, file.path(rep_dir, paste0('cal_', cs, '_truth.csv')), row.names = FALSE, na = '')
  }
  for (m in rate_models) {
    set.seed(seed * 7L + r * 101L + match(m, names(rate_fun)))
    m_dir <- file.path(rep_dir, m)
    dir.create(m_dir, showWarnings = FALSE)
    if (startsWith(m, 'seq')) {
      spec <- rate_fun[[m]]
      ph <- make_seq_phylogram(tr, sigma = spec[1], n_part = spec[2], height = height, n_sites = n_sites,
                               iqtree = iqtree_bin, wd = file.path(m_dir, 'seqsim'),
                               seed = seed * 7L + r * 101L + match(m, names(rate_fun)))
    } else {
      rm <- rate_fun[[m]](tr, bursts = sim$bursts)
      ph <- make_phylogram(tr, rm, height, n_sites)
      if (!is.null(rm$shifts)) write.csv(rm$shifts, file.path(m_dir, 'rate_shifts.csv'), row.names = FALSE)
    }
    ape::write.tree(ph$phylogram, file.path(m_dir, 'phylogram.tre'))
    ape::write.tree(ph$expected, file.path(m_dir, 'phylogram_expected.tre'))
    write.csv(ph$rates, file.path(m_dir, 'branch_rates.csv'), row.names = FALSE)
    for (cs in cal_sets) {
      rows[[length(rows) + 1L]] <- data.frame(
        dataset = sprintf('rep%02d_%s_%s', r, m, cs), rep = r, rate_model = m, cal_set = cs,
        true_tree = normalizePath(file.path(rep_dir, 'true_chronogram.tre')),
        phylogram = normalizePath(file.path(m_dir, 'phylogram.tre')),
        calibrations = normalizePath(file.path(rep_dir, paste0('cal_', cs, '.csv'))),
        bursts = normalizePath(file.path(rep_dir, 'bursts.csv')),
        n_tips = ape::Ntip(tr), zero_bl_frac = mean(ph$phylogram$edge.length <= 1e-6),
        stringsAsFactors = FALSE)
    }
  }
  message(sprintf('rep %02d: %d tips, burst clade sizes %s, %d tries', r, ape::Ntip(tr),
                  paste(table(sim$bursts$burst[sim$bursts$burst > 0]), collapse = '/'), attr(tr, 'tries')))
}
write.csv(do.call(rbind, rows), file.path(outdir, 'datasets.csv'), row.names = FALSE)
message('Wrote ', length(rows), ' dataset rows to ', file.path(outdir, 'datasets.csv'))
