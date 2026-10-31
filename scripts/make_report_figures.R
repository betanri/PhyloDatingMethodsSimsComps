## Figures for the README. Run from the repository root:
##   Rscript scripts/make_report_figures.R
## Reads results/ and writes figures/fig1..fig4 (PNG).

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})

dir.create("figures", showWarnings = FALSE)

## ---- Names users see -------------------------------------------------------
set_names <- c("sim main" = "Burst trees",
               "sim het"  = "Hard rate models",
               "Codex F"      = "Fossil placement",
               "Codex G"      = "Local bursts",
               "Codex H"      = "Conflicting clocks")
method_names <- c(RelTime = "RelTime", MDCat = "MD-Cat", treePL = "treePL",
                  chronos_clock = "chronos clock", chronos_discrete = "chronos discrete",
                  chronos_relaxed = "chronos relaxed", chronos_correlated = "chronos correlated")

## ---- Look --------------------------------------------------------------------
surface <- "#fcfcfb"; ink <- "#0b0b0b"; ink2 <- "#52514e"; grid_col <- "#e6e5e0"
blue_ramp   <- c("#f0efec", "#cde2fb", "#86b6ef", "#3987e5", "#1c5cab", "#0d366b")
orange_ramp <- c("#f0efec", "#fbd9c6", "#f5a37c", "#eb6834", "#b84a1f", "#7a2f12")

theme_report <- function() {
  theme_minimal(base_size = 11) +
    theme(plot.background = element_rect(fill = surface, colour = NA),
          panel.background = element_rect(fill = surface, colour = NA),
          panel.grid.major = element_line(colour = grid_col, linewidth = 0.3),
          panel.grid.minor = element_blank(),
          text = element_text(colour = ink),
          axis.text = element_text(colour = ink2),
          plot.title = element_text(face = "bold", size = 13),
          plot.subtitle = element_text(colour = ink2, size = 10),
          plot.caption = element_text(colour = ink2, size = 8.5, hjust = 0),
          plot.title.position = "plot", plot.caption.position = "plot",
          strip.text = element_text(face = "bold", hjust = 0),
          legend.position = "top", legend.justification = "left",
          legend.title = element_blank())
}
save_fig <- function(p, file, w, h) {
  ggsave(file.path("figures", file), p, width = w, height = h, dpi = 200, bg = surface)
}
set_levels <- unname(set_names)

## ---- Figure 1: which method is most accurate, per set ------------------------
win <- read.csv("results/winners.csv", stringsAsFactors = FALSE)
win$set <- sub(" \\|.*", "", win$cell)
win <- win[win$set %in% names(set_names), ]
win$set <- set_names[win$set]
share <- as.data.frame(prop.table(table(win$set, win$most_accurate), 1))
names(share) <- c("set", "method", "share")
n_by_set <- table(win$set)
share$method <- method_names[as.character(share$method)]
share$set <- as.character(share$set)
## a method that was not run in a set shows a dash, not 0%
acc <- read.csv("results/accuracy_by_method.csv", check.names = FALSE, stringsAsFactors = FALSE)
acc$set <- set_names[sub(" \\|.*", "", acc$cell)]
fitted <- do.call(rbind, lapply(names(method_names), function(m) {
  ok <- tapply(acc[[m]], acc$set, function(v) any(is.finite(v)))
  data.frame(method = unname(method_names[m]), set = names(ok), fitted = as.logical(ok))
}))
share <- merge(share, fitted, all.x = TRUE)
share$method <- factor(share$method, levels = rev(method_names))
share$set <- factor(share$set, levels = set_levels)
share$label <- ifelse(share$fitted %in% FALSE, "–", sprintf("%.0f%%", 100 * share$share))
share$share[share$fitted %in% FALSE] <- NA
share$set_lab <- factor(sprintf("%s\n(n = %d)", share$set, as.integer(n_by_set[as.character(share$set)])),
                        levels = sprintf("%s\n(n = %d)", set_levels, as.integer(n_by_set[set_levels])))

p1 <- ggplot(share, aes(set_lab, method, fill = share)) +
  geom_tile(colour = surface, linewidth = 1.5) +
  geom_text(aes(label = label, colour = ifelse(is.finite(share) & share > 0.45, "light", "dark")), size = 3.6) +
  scale_colour_manual(values = c(light = "#ffffff", dark = ink), guide = "none") +
  scale_fill_gradientn(colours = blue_ramp, limits = c(0, 1), na.value = "#f7f6f3",
                       labels = scales::percent, name = "Share of datasets",
                       guide = guide_colourbar(title.position = "top")) +
  scale_x_discrete(position = "top") +
  labs(title = "Which method gives the most accurate tree?",
       subtitle = "Share of datasets in which each method had the lowest whole-tree error. – = method not run in that set.",
       x = NULL, y = NULL) +
  theme_report() + theme(panel.grid = element_blank(), legend.title = element_text(size = 9),
                         legend.key.width = unit(1.6, "cm"), legend.key.height = unit(0.3, "cm"))
save_fig(p1, "fig1_most_accurate_method.png", 8.2, 4.6)

## ---- Heat map of median extra error (methods x conditions) ----------------
## The box marks the lowest error in each column.
heat <- function(df, title, subtitle) {
  df$best <- ave(df$extra, df$col, FUN = function(v) v == min(v, na.rm = TRUE))
  ggplot(df, aes(col, who, fill = pmin(extra, 1))) +
    geom_tile(colour = surface, linewidth = 1.5) +
    geom_tile(data = df[df$best == 1, ], fill = NA, colour = ink, linewidth = 0.7, width = 0.92, height = 0.86) +
    geom_text(aes(label = sprintf("%.2f", extra), colour = ifelse(extra > 0.55, "light", "dark")), size = 3.6) +
    scale_colour_manual(values = c(light = "#ffffff", dark = ink), guide = "none") +
    scale_fill_gradientn(colours = orange_ramp, limits = c(0, 1), name = "Median extra error (capped at 1)",
                         guide = guide_colourbar(title.position = "top")) +
    scale_x_discrete(position = "top") +
    labs(title = title, subtitle = subtitle, x = NULL, y = NULL) +
    theme_report() + theme(panel.grid = element_blank(), legend.title = element_text(size = 9),
                           legend.key.width = unit(1.6, "cm"), legend.key.height = unit(0.3, "cm"))
}
heat_methods <- c("RelTime", "MD-Cat", "treePL", "chronos clock", "chronos discrete", "chronos correlated")

## ---- Figure 2: methods across rate-variation levels -------------------------
## Median extra error by level, Burst trees + Hard rate models (README of the sim run)
het <- data.frame(
  level = rep(c("Moderate\n(sd 0.5–0.75)", "High\n(sd 1.0)", "Very high\n(sd 1.5)", "Rate jumps\nat bursts",
                "Clade clocks\n(5–10× shifts)"), each = 4),
  n = rep(c(70, 25, 15, 20, 5), each = 4),
  who = rep(c("RelTime", "MD-Cat", "treePL", "chronos clock"), 5),
  extra = c(0.22, 0.09, 0.29, 0.36,
            0.21, 0.16, 0.65, 0.20,
            0.30, 0.23, 0.87, 0.38,
            0.21, 0.06, 0.37, 0.08,
            0.00, 0.44, 2.03, 3.06))
het$level_lab <- factor(sprintf("%s\nn = %d", het$level, het$n), levels = unique(sprintf("%s\nn = %d", het$level, het$n)))
het$who <- factor(het$who, levels = rev(c("RelTime", "MD-Cat", "treePL", "chronos clock")))
het$best <- ave(het$extra, het$level, FUN = function(v) v == min(v))
p5 <- ggplot(het, aes(level_lab, who, fill = pmin(extra, 1))) +
  geom_tile(colour = surface, linewidth = 1.5) +
  geom_tile(data = het[het$best == 1, ], fill = NA, colour = ink, linewidth = 0.7, width = 0.92, height = 0.86) +
  geom_text(aes(label = sprintf("%.2f", extra), colour = ifelse(extra > 0.55, "light", "dark")), size = 3.6) +
  scale_colour_manual(values = c(light = "#ffffff", dark = ink), guide = "none") +
  scale_fill_gradientn(colours = orange_ramp, limits = c(0, 1), name = "Median extra error (capped at 1)",
                       guide = guide_colourbar(title.position = "top")) +
  scale_x_discrete(position = "top") +
  labs(title = "Error of each method as rates vary more",
       subtitle = "Burst trees and Hard rate models together. Lower is better; the box marks the best method in each column.",
       x = NULL, y = NULL) +
  theme_report() + theme(panel.grid = element_blank(), legend.title = element_text(size = 9),
                         legend.key.width = unit(1.6, "cm"), legend.key.height = unit(0.3, "cm"))
save_fig(p5, "fig2_rate_variation.png", 8.4, 3.8)

## ---- Figure 3: poor fossil minima (burst trees, 10 fossils) ----------------
pf <- read.csv("results/poor_fossils/method_extra_error.csv", stringsAsFactors = FALSE)
lv <- c("sim main refit" = "Original\n(≈0.8×)", "sim main min 0.60" = "0.6×", "sim main min 0.45" = "0.45×",
        "sim main min 0.30" = "0.3×", "sim main min 0.3-0.6" = "Random\n0.3–0.6×")
pf <- pf[pf$level %in% names(lv) & pf$method != "chronos_relaxed", ]
pf <- data.frame(col = factor(lv[pf$level], levels = lv), who = method_names[pf$method], extra = pf$median_extra)
pf$who <- factor(pf$who, levels = rev(heat_methods))
p3 <- heat(pf, "Error of each method as the fossils get poorer",
           "Burst trees with ten fossil minima moved to younger ages (40 datasets per level). Lower is better.")
save_fig(p3, "fig3_poor_fossils.png", 8.4, 4.4)

## ---- Figure 4: early bursts against late bursts ----------------------------
eb <- read.csv("results/early_burst/method_extra_error.csv", stringsAsFactors = FALSE)
eb <- eb[eb$measure == "whole_extra" & eb$by == "cal_set" & eb$method != "chronos_relaxed", ]
eb$method <- sub("^MD-Cat$", "MDCat", eb$method)
cols <- c("late sparse6" = "6 exact ages\nlate bursts", "early sparse6" = "6 exact ages\nearly bursts",
          "late fossil10" = "10 fossils\nlate bursts", "early fossil10" = "10 fossils\nearly bursts")
key <- paste(eb$set, eb$group)
eb <- data.frame(col = factor(cols[key], levels = cols), who = method_names[eb$method], extra = eb$median)
eb$who <- factor(eb$who, levels = rev(heat_methods))
p4 <- heat(eb, "Error of each method with early and late bursts",
           "Early: the 3 bursts start 76–95 Myr ago (root 100). Late: the burst trees (18–59 Myr). 40 datasets per column.")
save_fig(p4, "fig4_early_bursts.png", 8.4, 4.4)

cat("figures written to figures/\n")
