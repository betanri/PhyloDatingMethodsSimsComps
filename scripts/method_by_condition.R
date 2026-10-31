## Median extra error of each method by simulation condition (numbers in the README overview).
## Run from the repository root: Rscript scripts/method_by_condition.R
d <- read.csv("results/date_errors.csv")
d <- d[d$source %in% c("sim main","sim het","Codex F","Codex G","Codex H") & is.finite(d$mae_scaled), ]
d <- do.call(rbind, lapply(split(d, paste(d$source, d$dataset, d$method)), function(x) x[which.min(x$mae_scaled), ]))
d$best <- ave(d$mae_scaled, d$source, d$dataset, FUN = min)
d$extra <- d$mae_scaled / d$best - 1
d$bbest <- ave(d$burst_mae_scaled, d$source, d$dataset, FUN = function(v) if (all(is.na(v))) NA else min(v, na.rm = TRUE))
d$bextra <- d$burst_mae_scaled / d$bbest - 1
nm <- d$dataset
g <- function(p) ifelse(grepl(p, nm), sub(paste0(".*", p, ".*"), "\\1", nm), NA)
d$layout <- g("_layout([a-z]+)"); d$pat <- g("_burst(shallow_single|medium_double|deep_slow_shallow_burst)_")
d$cal <- g("_cal([a-z0-9]+)"); d$het <- g("_het([0-9.]+)_"); d$int <- g("_int([a-z]+)_"); d$bclock <- g("burstclock([a-z]+)_")
d$mu <- g("_mu([0-9.]+)_")
show <- function(sub, by, val = "extra") {
  x <- d[sub & is.finite(d[[val]]), ]; x$cond <- do.call(paste, x[by])
  a <- aggregate(x[[val]], list(cond = x$cond, method = x$method), median)
  w <- aggregate(x$extra == 0, list(cond = x$cond, method = x$method), mean)
  r <- reshape(a, idvar = "cond", timevar = "method", direction = "wide"); names(r) <- sub("x.", "", names(r))
  r[, -1] <- round(r[, -1], 2); n <- table(x$cond[!duplicated(x$dataset)]); r$n <- n[r$cond]; print(r, row.names = FALSE)
}
options(width = 220)
cat("== F by layout, whole ==\n"); show(d$source == "Codex F", c("layout"))
cat("== F by het, whole ==\n"); show(d$source == "Codex F", c("het"))
cat("== G by pattern, whole ==\n"); show(d$source == "Codex G", c("pat"))
cat("== G by pattern, burst nodes ==\n"); show(d$source == "Codex G", c("pat"), "bextra")
cat("== G by cal ==\n"); show(d$source == "Codex G", c("cal"))
cat("== H by strength, whole ==\n"); show(d$source == "Codex H", c("int"))
cat("== H by strength, burst ==\n"); show(d$source == "Codex H", c("int"), "bextra")
cat("== H by cal ==\n"); show(d$source == "Codex H", c("cal"))
cat("== main by rate model, whole ==\n"); show(d$source == "sim main", c("rate_model"))
cat("== main by rate model, burst ==\n"); show(d$source == "sim main", c("rate_model"), "bextra")
cat("== main by cal ==\n"); show(d$source == "sim main", c("cal_set"))
cat("== win share by set ==\n"); x <- aggregate(d$extra == 0, list(s = d$source, m = d$method), mean); x$x <- round(x$x, 2); print(reshape(x, idvar = "s", timevar = "m", direction = "wide"), row.names = FALSE)
