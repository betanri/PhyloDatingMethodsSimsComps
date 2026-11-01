## Figures for the README. Run from the repository root:
##   Rscript scripts/make_report_figures.R
## Reads results/summary/ (from scripts/report_tables.R) and writes figures/fig1..fig4 (PNG).

suppressPackageStartupMessages({
  library(ggplot2)
  library(patchwork)
})

dir.create("figures", showWarnings = FALSE)

## ---- Names users see -------------------------------------------------------
set_names <- c("sim main" = "Burst trees",
               "sim het"  = "Hard rate models",
               "sim early burst" = "Early-burst trees",
               "Codex F"      = "Fossil placement",
               "Codex G"      = "Local bursts",
               "Codex H"      = "Conflicting clocks")
method_names <- c(RelTime = "RelTime", "MD-Cat" = "MD-Cat", treePL = "treePL",
                  chronos_clock = "chronos clock", chronos_discrete = "chronos discrete",
                  chronos_correlated = "chronos correlated", chronos_relaxed = "chronos relaxed")

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
## Datasets where every method has a tree (results/summary/by_set.csv)
bs <- read.csv("results/summary/by_set.csv", stringsAsFactors = FALSE, check.names = FALSE)
bs <- bs[bs$scope == "every method" & bs$group %in% names(set_names), ]
n_all <- c("sim main" = 80, "sim het" = 55, "sim early burst" = 80, "Codex F" = 240, "Codex G" = 240, "Codex H" = 160)
share <- data.frame(set = bs$group, method = factor(method_names[bs$method], levels = rev(method_names)),
                    share = bs$share, n = bs$n_datasets)
share$set_lab <- ifelse(share$n < n_all[share$set],
                        sprintf("%s\n(n = %d of %d)", set_names[share$set], share$n, n_all[share$set]),
                        sprintf("%s\n(n = %d)", set_names[share$set], share$n))
share$set_lab <- factor(share$set_lab, levels = unique(share$set_lab[order(match(share$set, names(set_names)))]))
share$label <- sprintf("%.0f%%", 100 * share$share)

p1 <- ggplot(share, aes(set_lab, method, fill = share)) +
  geom_tile(colour = surface, linewidth = 1.5) +
  geom_text(aes(label = label, colour = ifelse(share > 0.45, "light", "dark")), size = 3.4) +
  scale_colour_manual(values = c(light = "#ffffff", dark = ink), guide = "none") +
  scale_fill_gradientn(colours = blue_ramp, limits = c(0, 1),
                       labels = scales::percent, name = "Share of datasets",
                       guide = guide_colourbar(title.position = "top")) +
  scale_x_discrete(position = "top") +
  labs(title = "Which method gives the most accurate tree?",
       subtitle = "Share of datasets in which each method had the lowest whole-tree error (ties split).",
       caption = paste("Preliminary. Benchmark sets (right): only the datasets with an MD-Cat tree so far.",
                       "The MD-Cat runs on all benchmark datasets end about 2 Nov 2026."),
       x = NULL, y = NULL) +
  theme_report() + theme(panel.grid = element_blank(), legend.title = element_text(size = 9),
                         legend.key.width = unit(1.6, "cm"), legend.key.height = unit(0.3, "cm"))
save_fig(p1, "fig1_most_accurate_method.png", 9.6, 4.8)

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
heat_methods <- unname(method_names[c("RelTime", "MD-Cat", "treePL", "chronos_clock", "chronos_discrete",
                                      "chronos_correlated", "chronos_relaxed")])

## ---- Figure 2: methods across rate-variation levels -------------------------
## Burst trees + hard rate models pooled by level (results/summary/rate_levels.csv)
rl <- read.csv("results/summary/rate_levels.csv", stringsAsFactors = FALSE)
lv2 <- c("moderate" = "Moderate\n(sd 0.5–0.75)", "high" = "High\n(sd 1.0)", "very high" = "Very high\n(sd 1.5)",
         "rate jumps" = "Rate jumps\nat bursts", "clade clocks" = "Clade clocks\n(5–10× shifts)")
rl$col <- sprintf("%s\nn = %d", lv2[rl$group], rl$n_datasets)
rl <- data.frame(col = factor(rl$col, levels = unique(rl$col[order(match(rl$group, names(lv2)))])),
                 who = factor(method_names[rl$method], levels = rev(heat_methods)), extra = rl$median_extra)
p5 <- heat(rl, "Error of each method as rates vary more",
           "Burst trees and Hard rate models together. Lower is better; the box marks the best method in each column.")
save_fig(p5, "fig2_rate_variation.png", 8.4, 4.6)

## ---- Figure 3: poor fossil minima (burst trees, 10 fossils) ----------------
pf <- read.csv("results/summary/poor_fossils.csv", stringsAsFactors = FALSE)
lv <- c("sim main refit" = "Original\n(≈0.8×)", "sim main min 0.60" = "0.6×", "sim main min 0.45" = "0.45×",
        "sim main min 0.30" = "0.3×", "sim main min 0.3-0.6" = "Random\n0.3–0.6×")
pf <- pf[pf$group %in% names(lv), ]
pf <- data.frame(col = factor(lv[pf$group], levels = lv), who = method_names[pf$method], extra = pf$median_extra)
pf$who <- factor(pf$who, levels = rev(heat_methods))
p3 <- heat(pf, "Error of each method as the fossils get poorer",
           "Burst trees with ten fossil minima moved to younger ages (40 datasets per level). Lower is better.")
save_fig(p3, "fig3_poor_fossils.png", 8.4, 4.6)

## ---- Figure 4: early bursts against late bursts ----------------------------
eb <- read.csv("results/summary/early_bursts.csv", stringsAsFactors = FALSE)
eb <- eb[eb$measure == "whole", ]
cols <- c("late sparse6" = "6 exact ages\nlate bursts", "early sparse6" = "6 exact ages\nearly bursts",
          "late fossil10" = "10 fossils\nlate bursts", "early fossil10" = "10 fossils\nearly bursts")
eb <- eb[eb$group %in% names(cols), ]
eb <- data.frame(col = factor(cols[eb$group], levels = cols), who = method_names[eb$method], extra = eb$median_extra)
eb$who <- factor(eb$who, levels = rev(heat_methods))
p4 <- heat(eb, "Error of each method with early and late bursts",
           "Early: the 3 bursts start 76–95 Myr ago (root 100). Late: the burst trees (18–59 Myr). 40 datasets per column.")
save_fig(p4, "fig4_early_bursts.png", 8.4, 4.6)

cat("figures written to figures/\n")
