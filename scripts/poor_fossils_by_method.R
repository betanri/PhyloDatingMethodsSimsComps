## Median extra error of each method at each fossil level (numbers in section 3).
## Run from the repository root: Rscript scripts/poor_fossils_by_method.R
## Writes results/poor_fossils/method_extra_error.csv, most_accurate_share.csv
## and best_tree_root.csv.
d <- read.csv("results/poor_fossils/date_errors.csv", stringsAsFactors = FALSE)
d <- d[is.finite(d$mae_scaled), ]
## one tree per method and dataset (the most accurate one when a method has two)
d <- do.call(rbind, lapply(split(d, paste(d$level, d$dataset, d$method)), function(x) x[which.min(x$mae_scaled), ]))
d$extra <- d$mae_scaled / ave(d$mae_scaled, d$level, d$dataset, FUN = min) - 1
n_ds <- tapply(d$dataset, d$level, function(v) length(unique(v)))

a <- aggregate(d$extra, list(level = d$level, method = d$method), median)
names(a)[3] <- "median_extra"
a$n <- aggregate(d$extra, list(level = d$level, method = d$method), length)$x
a$n_datasets <- as.integer(n_ds[a$level])
write.csv(a, "results/poor_fossils/method_extra_error.csv", row.names = FALSE)

## ties split the share
w <- do.call(rbind, lapply(split(d, paste(d$level, d$dataset)), function(x) {
  best <- x$extra == 0
  data.frame(level = x$level, method = x$method, share = best / sum(best))
}))
w <- aggregate(w$share, list(level = w$level, method = w$method), function(v) sum(v))
w$share <- w$x / as.integer(n_ds[w$level]); w$x <- NULL
write.csv(w, "results/poor_fossils/most_accurate_share.csv", row.names = FALSE)

b <- d[d$extra == 0, ]
r <- aggregate(1 + b$root_rel_err, list(level = b$level), median)
names(r)[2] <- "median_root_over_true"
write.csv(r, "results/poor_fossils/best_tree_root.csv", row.names = FALSE)

options(width = 220)
wide <- reshape(a[, c("level", "method", "median_extra")], idvar = "level", timevar = "method", direction = "wide")
names(wide) <- sub("median_extra.", "", names(wide), fixed = TRUE)
wide[, -1] <- round(wide[, -1], 2); wide$n <- as.integer(n_ds[wide$level])
print(wide[order(wide$level), ], row.names = FALSE)
ws <- reshape(w, idvar = "level", timevar = "method", direction = "wide")
names(ws) <- sub("share.", "", names(ws), fixed = TRUE); ws[, -1] <- round(100 * ws[, -1])
print(ws[order(ws$level), ], row.names = FALSE)
print(r, row.names = FALSE)
