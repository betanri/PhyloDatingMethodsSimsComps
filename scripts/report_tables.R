## Summary tables for the README and the figures. Run from the repository root:
##   Rscript scripts/report_tables.R
## Reads results/accuracy/date_errors_*.csv (one row per dated tree, one tree
## per method and dataset) and writes results/summary/.
##
## Extra error of a method = its whole-tree error / the lowest error among the
## methods compared in that dataset - 1. Ties (two methods with the same tree)
## split the most-accurate share.

dir.create("results/summary", showWarnings = FALSE)
METHODS <- c("RelTime", "MD-Cat", "treePL", "chronos_clock", "chronos_discrete", "chronos_correlated", "chronos_relaxed")
rd <- function(f) { d <- read.csv(file.path("results/accuracy", f), stringsAsFactors = FALSE); d[is.finite(d$whole), ] }
main <- rd("date_errors_main.csv")
early <- rd("date_errors_early.csv")
poor <- rd("date_errors_poor_fossils.csv")

## Extra error and tie-split win share within each dataset (key columns)
score <- function(x, key = c("set", "dataset"), v = "whole") {
  k <- do.call(paste, x[key])
  best <- ave(x[[v]], k, FUN = function(z) if (all(is.na(z))) NA else min(z, na.rm = TRUE))
  x$extra <- x[[v]] / best - 1
  win <- as.numeric(is.finite(x$extra) & x$extra < 1e-9)
  x$win <- win / ave(win, k, FUN = sum)
  x
}
## Keep only datasets where every method has a tree
complete <- function(x, key = c("set", "dataset")) {
  k <- do.call(paste, x[key])
  x[ave(x$method, k, FUN = function(m) length(unique(m))) == length(METHODS), ]
}
summ <- function(x, by) {
  n <- tapply(x$dataset, x[[by]], function(v) length(unique(v)))
  a <- aggregate(cbind(median_extra = x$extra, share = x$win), list(group = x[[by]], method = x$method),
                 function(v) c(median(v, na.rm = TRUE), sum(v, na.rm = TRUE)))
  out <- data.frame(group = a$group, method = a$method, median_extra = a$median_extra[, 1],
                    share = a$share[, 2] / as.integer(n[a$group]), n_datasets = as.integer(n[a$group]))
  out[order(out$group, out$median_extra), ]
}

## ---- 1. By set: all datasets, and datasets where every method has a tree ----
sets <- c("sim main", "sim het", "Codex F", "Codex G", "Codex H")
m <- main[main$set %in% sets, ]
eb <- early; eb$set <- "sim early burst"
m <- rbind(m, eb[, names(m)])
by_all <- summ(score(m), "set"); by_all$scope <- "all datasets"
by_cmp <- summ(score(complete(m)), "set"); by_cmp$scope <- "every method"
write.csv(rbind(by_cmp, by_all), "results/summary/by_set.csv", row.names = FALSE)

## ---- 2. Burst trees and hard rate models by level of rate variation ----
lev <- c(acln = "moderate", ucln = "moderate", discrete = "moderate", seqhet050 = "moderate", seqhomo050 = "moderate",
         codex_ac_h100 = "high", codex_disc_h100 = "high", ucln_s100 = "high", seqhet100 = "high", seqhomo100 = "high",
         codex_ac_h150 = "very high", codex_disc_h150 = "very high", ucln_s150 = "very high",
         punct = "rate jumps", localclock = "clade clocks")
s <- score(m[m$set %in% c("sim main", "sim het"), ])
s$level <- lev[s$rate_model]
write.csv(summ(s, "level"), "results/summary/rate_levels.csv", row.names = FALSE)
s$model <- paste(s$set, s$rate_model)
write.csv(summ(s, "model"), "results/summary/rate_models.csv", row.names = FALSE)
s$model_cal <- paste(s$set, s$rate_model, s$cal_set)
write.csv(summ(s, "model_cal"), "results/summary/rate_models_by_calibration.csv", row.names = FALSE)
s$cal <- paste(s$set, s$cal_set)
write.csv(summ(s, "cal"), "results/summary/calibrations.csv", row.names = FALSE)

## ---- 3. Poor fossil minima ----
p <- score(poor, c("level", "set", "dataset"))
pf <- summ(p, "set")
write.csv(pf, "results/summary/poor_fossils.csv", row.names = FALSE)
b <- p[p$win > 0, ]
r <- aggregate(cbind(median_root_over_true = 1 + b$root_err), list(set = b$set), median)
write.csv(r, "results/summary/poor_fossils_best_root.csv", row.names = FALSE)

## ---- 4. Early bursts against the burst trees (late bursts) ----
el <- rbind(transform(early, timing = "early"), transform(main[main$set == "sim main", ], timing = "late")[, c(names(early), "timing")])
el <- score(el, c("timing", "dataset"))
el$group <- paste(el$timing, "all")
x <- rbind(el, transform(el, group = paste(timing, cal_set)))
eb_whole <- summ(x, "group"); eb_whole$measure <- "whole"
elb <- score(el, c("timing", "dataset"), "burst"); elb$group <- paste(elb$timing, "all")
xb <- rbind(elb, transform(elb, group = paste(timing, cal_set)))
eb_burst <- summ(xb, "group"); eb_burst$measure <- "burst"
write.csv(rbind(eb_whole, eb_burst), "results/summary/early_bursts.csv", row.names = FALSE)
## raw error, early over late, and median root error
raw <- aggregate(cbind(whole = el$whole), list(timing = el$timing, method = el$method), median)
raw <- reshape(raw, idvar = "method", timevar = "timing", direction = "wide")
raw$early_over_late <- raw$whole.early / raw$whole.late
write.csv(raw, "results/summary/early_over_late.csv", row.names = FALSE)
re <- aggregate(cbind(median_root_err = el$root_err), list(timing = el$timing, cal_set = el$cal_set, method = el$method), median)
write.csv(re, "results/summary/early_root_error.csv", row.names = FALSE)

## ---- Print ----
options(width = 200)
show <- function(t, lab) {
  w <- reshape(t[, c("group", "method", "median_extra")], idvar = "group", timevar = "method", direction = "wide")
  names(w) <- sub("median_extra.", "", names(w), fixed = TRUE)
  w[, -1] <- round(w[, -1], 2)
  w$n <- t$n_datasets[match(w$group, t$group)]
  cat("==", lab, "(median extra error) ==\n"); print(w[, c("group", intersect(METHODS, names(w)), "n")], row.names = FALSE)
  sh <- reshape(t[, c("group", "method", "share")], idvar = "group", timevar = "method", direction = "wide")
  names(sh) <- sub("share.", "", names(sh), fixed = TRUE); sh[, -1] <- round(100 * sh[, -1])
  cat("--", lab, "(most accurate share, %) --\n"); print(sh[, c("group", intersect(METHODS, names(sh)))], row.names = FALSE)
}
show(by_cmp, "by set, every method"); show(by_all, "by set, all datasets")
show(summ(s, "level"), "rate levels"); show(summ(s, "model"), "rate models")
show(summ(s, "model_cal"), "rate models x calibration"); show(summ(s, "cal"), "calibrations")
show(pf, "poor fossils"); print(r, row.names = FALSE)
show(eb_whole, "early bursts, whole"); show(eb_burst, "early bursts, burst")
print(raw, row.names = FALSE); print(reshape(re, idvar = c("cal_set", "method"), timevar = "timing", direction = "wide"), row.names = FALSE)
