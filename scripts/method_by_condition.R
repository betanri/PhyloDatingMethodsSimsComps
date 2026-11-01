## Median extra error of each method by simulation condition (numbers in the README overview).
## Run from the repository root: Rscript scripts/method_by_condition.R
## Benchmark sets: extra error among the methods with a tree in each dataset;
## n_md = datasets with an MD-Cat tree.
d <- read.csv("results/accuracy/date_errors_main.csv", stringsAsFactors = FALSE)
d <- d[d$set %in% c("sim main", "sim het", "Codex F", "Codex G", "Codex H") & is.finite(d$whole), ]
k <- paste(d$set, d$dataset)
d$extra <- d$whole / ave(d$whole, k, FUN = min) - 1
d$bextra <- d$burst / ave(d$burst, k, FUN = function(v) if (all(is.na(v))) NA else min(v, na.rm = TRUE)) - 1
nm <- d$dataset
g <- function(p) ifelse(grepl(p, nm), sub(paste0(".*", p, ".*"), "\\1", nm), NA)
d$layout <- g("_layout([a-z]+)"); d$pat <- g("_burst(shallow_single|medium_double|deep_slow_shallow_burst)_")
d$cal <- g("_cal([a-z0-9]+)"); d$het <- g("_het([0-9.]+)_"); d$int <- g("_int([a-z]+)_"); d$bclock <- g("burstclock([a-z]+)_")
d$mu <- g("_mu([0-9.]+)_")
show <- function(sub, by, val = "extra") {
  x <- d[sub & is.finite(d[[val]]), ]; x$cond <- do.call(paste, x[by])
  a <- aggregate(x[[val]], list(cond = x$cond, method = x$method), median)
  r <- reshape(a, idvar = "cond", timevar = "method", direction = "wide"); names(r) <- sub("x.", "", names(r))
  r[, -1] <- round(r[, -1], 2); n <- table(x$cond[!duplicated(paste(x$cond, x$dataset))]); r$n <- as.integer(n[r$cond])
  md <- table(x$cond[x$method == "MD-Cat"]); r$n_md <- as.integer(md[r$cond]); r$n_md[is.na(r$n_md)] <- 0L
  print(r, row.names = FALSE)
}
options(width = 220)
cat("== F by layout, whole ==\n"); show(d$set == "Codex F", c("layout"))
cat("== F by extinction, whole ==\n"); show(d$set == "Codex F", c("mu"))
cat("== F by het, whole ==\n"); show(d$set == "Codex F", c("het"))
cat("== G by pattern, whole ==\n"); show(d$set == "Codex G", c("pat"))
cat("== G by pattern, burst nodes ==\n"); show(d$set == "Codex G", c("pat"), "bextra")
cat("== G by cal ==\n"); show(d$set == "Codex G", c("cal"))
cat("== H by strength, whole ==\n"); show(d$set == "Codex H", c("int"))
cat("== H by strength, burst ==\n"); show(d$set == "Codex H", c("int"), "bextra")
cat("== H by cal ==\n"); show(d$set == "Codex H", c("cal"))
cat("== main by rate model, whole ==\n"); show(d$set == "sim main", c("rate_model"))
cat("== main by rate model, burst ==\n"); show(d$set == "sim main", c("rate_model"), "bextra")
cat("== main by cal ==\n"); show(d$set == "sim main", c("cal_set"))
cat("== het by rate model ==\n"); show(d$set == "sim het", c("rate_model"))
