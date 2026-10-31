#!/usr/bin/env Rscript
## Dating accuracy of the early-burst set against the burst trees (late bursts).
## Only true-age errors (sim_date_error.R).
##
## Extra error of a tree = its error / the lowest error in its dataset - 1
## (0 = the most accurate tree). "Most accurate" shares split ties (errors
## equal to 6 significant digits; chronos correlated and relaxed at lambda
## 0.01 are often the same tree).
##
## Usage:
##   Rscript sim_early_burst_report.R
##     --sets=early:work/datasets_early/datasets.csv:work/runs_early,late:work/datasets/datasets.csv:work/date_error_main
##     --outdir=results/early_burst
## An error file is <dir>/<dataset>/date_error.csv or <dir>/<dataset>.csv.

args <- commandArgs(trailingOnly = TRUE)
kv <- list()
for (a in args) {
  if (!grepl('^--', a)) next
  parts <- strsplit(sub('^--', '', a), '=', fixed = TRUE)[[1]]
  kv[[parts[1]]] <- if (length(parts) > 1) paste(parts[-1], collapse = '=') else 'TRUE'
}
outdir <- kv[['outdir']]
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

method_of <- function(cand) {
  m <- sub('^(chronos_[a-z]+).*', '\\1', cand)
  m[grepl('^treePL', cand)] <- 'treePL'
  m[grepl('^RelTime', cand)] <- 'RelTime'
  m[grepl('^MDCat', cand)] <- 'MD-Cat'
  m
}
rows <- list()
for (s in strsplit(kv[['sets']], ',')[[1]]) {
  p <- strsplit(s, ':', fixed = TRUE)[[1]]
  d <- read.csv(p[2], stringsAsFactors = FALSE)
  d <- d[d$cal_set %in% c('sparse6', 'fossil10'), ]
  for (i in seq_len(nrow(d))) {
    f <- c(file.path(p[3], d$dataset[i], 'date_error.csv'), file.path(p[3], paste0(d$dataset[i], '.csv')))
    f <- f[file.exists(f)]
    if (!length(f)) next
    x <- read.csv(f[1], stringsAsFactors = FALSE)
    rows[[length(rows) + 1L]] <- data.frame(set = p[1], dataset = d$dataset[i], rep = d$rep[i], rate_model = d$rate_model[i],
                                            cal_set = d$cal_set[i], candidate = x$candidate, method = method_of(x$candidate),
                                            whole = x$mae_scaled, burst = x$burst_mae_scaled, root_err = x$root_rel_err,
                                            stringsAsFactors = FALSE)
  }
}
e <- do.call(rbind, rows)
key <- paste(e$set, e$dataset)
for (v in c('whole', 'burst')) {
  best <- ave(e[[v]], key, FUN = function(z) if (all(is.na(z))) NA_real_ else min(z, na.rm = TRUE))
  e[[paste0(v, '_extra')]] <- e[[v]] / best - 1
}
write.csv(e, file.path(outdir, 'date_errors.csv'), row.names = FALSE)

methods <- c('RelTime', 'MD-Cat', 'treePL', 'chronos_clock', 'chronos_discrete', 'chronos_correlated', 'chronos_relaxed')
sets <- unique(e$set)

## Median extra error per method, by rate model and calibration set
med_tab <- function(v, by) {
  out <- list()
  for (s in sets) for (g in unique(e[[by]])) for (m in methods) {
    z <- e[[v]][e$set == s & e[[by]] == g & e$method == m]
    out[[length(out) + 1L]] <- data.frame(set = s, group = g, method = m, n = sum(is.finite(z)),
                                          median = if (any(is.finite(z))) stats::median(z, na.rm = TRUE) else NA_real_)
  }
  do.call(rbind, out)
}
e$all <- 'all'
e$cell <- paste(e$rate_model, e$cal_set)
ext <- do.call(rbind, lapply(c('whole_extra', 'burst_extra'), function(v)
  do.call(rbind, lapply(c('all', 'cal_set', 'rate_model', 'cell'), function(by) cbind(measure = v, by = by, med_tab(v, by))))))
write.csv(ext, file.path(outdir, 'method_extra_error.csv'), row.names = FALSE)

## Share of datasets where each method is the most accurate (ties split)
share_tab <- function(v, by) {
  out <- list()
  for (s in sets) for (g in unique(e[[by]])) {
    idx <- which(e$set == s & e[[by]] == g & is.finite(e[[v]]))
    sp <- lapply(split(idx, key[idx]), function(r) {
      z <- signif(e[[v]][r], 6); top <- r[z == min(z)]
      tapply(rep(1 / length(top), length(top)), e$method[top], sum)
    })
    nd <- length(sp)
    for (m in methods) {
      out[[length(out) + 1L]] <- data.frame(set = s, group = g, method = m, n_datasets = nd,
        share = sum(vapply(sp, function(x) if (m %in% names(x)) x[[m]] else 0, numeric(1))) / nd)
    }
  }
  do.call(rbind, out)
}
shr <- do.call(rbind, lapply(c('whole', 'burst'), function(v)
  do.call(rbind, lapply(c('all', 'cal_set', 'rate_model'), function(by) cbind(measure = v, by = by, share_tab(v, by))))))
write.csv(shr, file.path(outdir, 'most_accurate_share.csv'), row.names = FALSE)

## Early against late: median raw error (x true root) per method and cell
evl <- list()
for (m in methods) for (g in c('all', unique(e$cell))) for (v in c('whole', 'burst')) {
  sel <- e$method == m & (g == 'all' | e$cell == g)
  a <- e[[v]][sel & e$set == 'early']; b <- e[[v]][sel & e$set == 'late']
  evl[[length(evl) + 1L]] <- data.frame(method = m, cell = g, measure = v, n_early = sum(is.finite(a)), n_late = sum(is.finite(b)),
                                        early = stats::median(a, na.rm = TRUE), late = stats::median(b, na.rm = TRUE))
}
evl <- do.call(rbind, evl)
evl$early_over_late <- evl$early / evl$late
## Root age error (signed, median) per method, set and calibration set
## (sparse6 fixes the root age; fossil10 gives it a range)
roots <- aggregate(root_err ~ set + cal_set + method, e, stats::median)
write.csv(evl, file.path(outdir, 'early_vs_late.csv'), row.names = FALSE)
write.csv(roots, file.path(outdir, 'root_error.csv'), row.names = FALSE)

## Markdown
f2 <- function(v) ifelse(is.finite(v), sprintf('%.2f', v), '—')
pct <- function(v) sprintf('%.0f%%', 100 * v)
wide <- function(tab, groups, fmt, valcol) {
  hdr <- c('| Method | ', paste(groups, collapse = ' | '), ' |')
  lines <- c(paste0(hdr, collapse = ''), paste0('|', paste(rep('---', length(groups) + 1), collapse = '|'), '|'))
  for (m in methods) {
    v <- vapply(groups, function(g) { z <- tab[tab$method == m & tab$group == g, valcol]; if (length(z)) z[1] else NA_real_ }, numeric(1))
    lines <- c(lines, paste0('| ', m, ' | ', paste(fmt(v), collapse = ' | '), ' |'))
  }
  lines
}
cells <- as.vector(outer(c('acln', 'ucln', 'discrete', 'punct'), c('sparse6', 'fossil10'), paste))
md <- c('# Early bursts against late bursts (burst trees)', '',
        'Errors are true-age errors. Extra error = error / lowest error in the dataset - 1.',
        'chronos correlated and relaxed at lambda 0.01 give the same tree in these runs, so their rows are equal.', '')
for (s in sets) for (v in c('whole_extra', 'burst_extra')) {
  t <- ext[ext$measure == v & ext$set == s, ]
  md <- c(md, sprintf('## %s set: median extra error, %s', s, if (v == 'whole_extra') 'whole tree' else 'burst nodes'), '',
          wide(t, c('all', 'sparse6', 'fossil10', cells), f2, 'median'), '')
}
for (v in c('whole', 'burst')) {
  t <- shr[shr$measure == v, ]
  t$group <- paste(t$set, t$group)
  md <- c(md, sprintf('## Share of datasets where the method is the most accurate, %s', if (v == 'whole') 'whole tree' else 'burst nodes'), '',
          wide(t, as.vector(outer(sets, c('all', 'sparse6', 'fossil10'), paste)), pct, 'share'), '')
}
for (v in c('whole', 'burst')) {
  t <- evl[evl$measure == v, c('method', 'cell', 'early_over_late')]; names(t) <- c('method', 'group', 'r')
  md <- c(md, sprintf('## Early / late, median raw error (x true root), %s', if (v == 'whole') 'whole tree' else 'burst nodes'), '',
          wide(t, c('all', cells), f2, 'r'), '')
  t <- evl[evl$measure == v & evl$cell == 'all', ]
  md <- c(md, paste0('Medians (early / late): ', paste(sprintf('%s %.3f / %.3f', t$method, t$early, t$late), collapse = '; '), '.'), '')
}
md <- c(md, '## Median signed root error ((est - true) / true)', '',
        wide(data.frame(method = roots$method, group = paste(roots$set, roots$cal_set), v = roots$root_err),
             as.vector(outer(sets, c('sparse6', 'fossil10'), paste)), f2, 'v'), '')
writeLines(md, file.path(outdir, 'early_burst.md'))
message('Wrote ', file.path(outdir, 'early_burst.md'), ' (', length(unique(key)), ' datasets)')
