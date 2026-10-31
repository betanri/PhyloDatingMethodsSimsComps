# Dating methods compared on simulated trees

Trees with known true ages were simulated and dated with several methods: RelTime, treePL, chronos (four clock models) and MD-Cat. Each dated tree was then compared with the true tree.

The report answers one question: **which dating method gives the most accurate ages, and under which conditions?**

**Status (31 Oct 2026).** All results in this report are final, including the early-burst set (section 4).

---

## Which method works best, and when

No dating method is the best in every condition. Two things decide which method gives the most accurate ages: how the rate of molecular change varies across the tree, and how good the calibrations are. The numbers in parentheses are each method's median extra error. 0 means it gave the most accurate tree in the dataset. 1 means its error was twice that of the most accurate tree. Most conditions have only 5–20 datasets, so treat differences smaller than about 0.1 as ties.

**Moderate rate variation.** On the burst trees (rate log-sd 0.5–0.75), most methods are close. The best one depends on how rates pass from a parent branch to its daughter branches. When each branch takes a rate close to its parent's rate (*inherited*), RelTime is best (0.05), then treePL (0.13). MD-Cat is worse (0.48). When each branch belongs to one of a few rate classes, MD-Cat is best by far (0.00), and every other method is at 0.6 or more. This model matches how MD-Cat itself models rates, so MD-Cat has an advantage there. When each branch draws its own rate (*independent*), treePL, chronos discrete, MD-Cat and chronos clock tie (0.09–0.11), and RelTime is a little worse (0.19).

**Extreme heterotachy.** With strong rate variation (log-sd 1.0–1.5, the hard rate models), treePL fails. Its extra error is 0.9–3.7 in the strong inherited and strong rate-class models. The best method again depends on the type of rate variation:
- **Strong inherited rates:** RelTime is best at both levels (0.00). chronos relaxed ties with it at the highest level.
- **Strong rate classes:** MD-Cat is best (0.00), and RelTime is far behind (0.8–0.9).
- **Very high independent rates (log-sd 1.5):** RelTime (0.03) and chronos discrete (0.04) are best, ahead of treePL (0.29) and MD-Cat (0.31).
- **Clade clocks** (whole clades shift to a rate 5–10× faster or slower): RelTime is best (0.00) and MD-Cat is second (0.44). The other methods are at 2–3.

Section 2 pools these models by level. There MD-Cat looks best at each level, because it wins the rate-class models by a wide margin. Model by model, RelTime is the safer choice at extreme heterotachy, unless there is a reason to think the rates fall into a few discrete classes. Each of these models has only 5 datasets.

**Phylograms estimated from DNA.** When sequences were simulated and the phylogram was estimated from them, the methods are close again. chronos clock and chronos discrete are best or near best in all four of these models (0.00–0.16). treePL gets much worse when rates vary more (0.42–1.25).

**Bursts.** Two kinds of burst were simulated:
- **Speciation bursts.** In the burst trees, three clades go through a short burst of fast speciation, so they have many short branches.
- **Rate bursts.** In the local-burst set, one or two clades evolve 3–4× faster. In the conflicting-clock set, a nested clade follows a different clock from the backbone.

With speciation bursts plus a rate jump on the burst branches, MD-Cat (0.06), chronos clock (0.08) and chronos discrete (0.10) are best, both for the whole tree and inside the burst clades. RelTime (0.21) and treePL (0.37) are worse. With rate bursts, chronos clock gives the best whole tree for every burst pattern (0.06–0.12) and for both moderate and strong clock conflict (0.07). RelTime and treePL are far behind (0.8–3.8). But inside the burst clades the best method changes. With two medium bursts, chronos relaxed is best (0.00) and chronos clock is poor (1.51). With a slow phase then a shallow burst, treePL is best (0.00). So the method that gives the best whole tree does not always give the best ages for the burst. MD-Cat was not run on the rate-burst sets.

**Early bursts.** In the early-burst trees the speciation bursts start near the root (76–95 million years ago on a 100-million-year tree), not in the middle of the tree. Every method is less accurate than with the later bursts: its median error is 1.25–1.60× larger. Over all 80 datasets, MD-Cat is best (0.08), then RelTime (0.15). The calibrations change the answer. With 6 exact ages, treePL (0.04), chronos clock and chronos discrete (0.07) are best, and MD-Cat (0.16) and RelTime (0.23) are worse. With 10 fossils, MD-Cat (0.01) and RelTime (0.08) are best by far, and the other methods are at 0.66–1.16 (section 4).

**Calibrations.** With 6 exact ages, the methods are close: MD-Cat (0.11), treePL (0.20), chronos discrete (0.22) and RelTime (0.26). With 10 good fossils (minima at 0.60–0.98× the true age), MD-Cat is best by far (0.01), RelTime is second (0.20), and treePL is much worse (0.78). When the fossil minima are much younger than the true ages (0.3–0.6×), RelTime is the best method at most levels (section 3). On the benchmark sets with wide brackets, chronos clock is best whatever the calibration layout (shallow, deep or mixed: 0.03–0.14), the extinction rate (0.00–0.20), and the number of brackets. With only 3 brackets, RelTime and treePL get much worse (2.4–9.1). But in these sets almost every dated tree is too old, so the result mostly shows which method puts the root lowest in the bracket.

**chronos correlated and relaxed.** chronos correlated is far from the best in almost every condition (1–4 in most). chronos relaxed is poor on the burst trees (3.0–4.1), but good in some benchmark conditions. Many of their fits stop at their starting dates (the treePL tree), so the branch lengths have little effect on their ages.

**In short.** With inherited rates or clade clocks, use RelTime. With rates in a few discrete classes, use MD-Cat. With independent rates, rate jumps at bursts, or a phylogram from DNA, MD-Cat, chronos clock and chronos discrete are close. With good fossils, MD-Cat is best; with poor fossils, RelTime. Do not rely on treePL when rates vary strongly or when the calibrations are fossil minima. With real data the type of rate variation is seldom known. So date with both RelTime and MD-Cat, and report where they differ.

---

## Short answer

- **No dating method is the best everywhere.** Which method wins depends on how rates change and on the quality of the calibrations (see the overview above).
- **MD-Cat and RelTime are the best general choices** on the burst trees and the hard rate models. MD-Cat is best with good fossils and with rates in discrete classes; RelTime with inherited rates, clade clocks and poor fossils.
- **treePL is never the best default.** It fails with strong rate variation and with fossil minima.
- **chronos clock and chronos discrete** are best on the benchmark sets with wide brackets and close to the best with phylograms from DNA.
- **Early bursts** (near the root) make every method less accurate, but do not change which methods are best with fossils (MD-Cat, RelTime).

---

## What was simulated

Each dataset was made in the same way:

1. Simulate a **true time tree** (birth–death).
2. Give each branch a **rate of molecular change**, using a rate model (see below).
3. Multiply rate × time to get the **phylogram**: branch lengths in substitutions per site, the input a user has.
4. Make **calibrations** from the true ages: exact ages, age ranges, or fossil minimum ages.
5. **Date** the phylogram with every method, with the same calibrations.
6. **Compare** each dated tree with the true tree.

### The simulation sets

| Set | Datasets | True trees | How rates change | Calibrations |
|---|---|---|---|---|
| **Burst trees** | 80 | 10 trees, 93–118 tips, root age 100. Each tree has 3 clades with a burst of fast speciation, starting 18–59 million years ago. | 4 rate models: *inherited*, *independent*, *rate classes*, *rate jumps at bursts* | Two sets: **6 exact ages** (root + 5 nodes) or **10 fossils** (a root range, 2 age ranges, and 7 minimum ages at 0.60–0.98× the true age) |
| **Hard rate models** | 55 | Trees 1–5 of the burst trees | 11 harder rate models (below) | 6 exact ages |
| **Early-burst trees** | 80 | 10 new trees, 93–120 tips, root age 100. The 3 bursts start 76–95 million years ago, near the root. | The same 4 rate models as the burst trees | The same two sets as the burst trees |
| **Fossil placement** | 240 | 150 tips, sampled from a 1,500-tip tree | 4 clock models (*strict*, *independent*, *inherited*, *rate classes*), 2 levels of rate variation, extinction 0 or 0.8 | Wide brackets. The calibrated nodes are shallow, deep or mixed in the tree. |
| **Local bursts** | 240 | 150 tips | The same 4 clock models, plus a rate burst: one shallow clade evolves 4× faster, two medium-depth clades evolve 3× faster, or a deep clade slows to 0.35× and a shallow clade evolves 4× faster. | 3 or 8 wide brackets |
| **Conflicting clocks** | 160 | 150 tips | The backbone follows one clock (*strict* or *independent*). A nested burst clade follows another (*independent* or *inherited*), with a moderate or strong rate change. | 3 or 8 wide brackets |
| Small side sets | 92 + 23 | 150 tips | 92 datasets from earlier benchmark sets, with only 2–3 methods run; 23 benchmark datasets rerun with MD-Cat added | Used only as side checks |

**Total: 970 datasets.** The fossil placement, local-burst and conflicting-clock sets come from an earlier benchmark suite. They are called "the benchmark sets" below.

### Rate models, in plain words

| Name in this report | What it means |
|---|---|
| strict | One rate for the whole tree (a strict clock). |
| inherited | Each branch takes a rate close to its parent's rate (autocorrelated lognormal). |
| independent | Each branch draws its own rate, with no link to its parent (uncorrelated lognormal). |
| rate classes | Each branch belongs to one of a few rate classes (discrete). |
| rate jumps at bursts | The rate jumps on the branches inside the burst clades (punctuated). |
| high / very high variation | Independent rates with a wider spread (log-sd 1.0 and 1.5). |
| strong inherited / strong rate classes | The benchmark's inherited and rate-class models, at heterotachy 1.0 and 1.5. |
| clade clocks | Some clades shift to a rate 5–10× faster or slower (local clocks). |
| simulated DNA | Sequences simulated on the tree (AliSim) and a new phylogram estimated from them (IQ-TREE), with one rate block or two blocks of different branch rates. |

The 11 hard rate models are: high and very high variation (2), strong inherited (2), strong rate classes (2), clade clocks (1), and simulated DNA (4).

### Calibrations, in plain words

- **Exact ages:** the node age is fixed at the true age. This is the easy case.
- **Fossils:** a **minimum age** says the node is at least this old, the way a fossil does. The ten-fossil set places its minima at 0.60–0.98× the true age, with maxima near 1.2×.
- **Wide brackets (benchmark sets):** each calibrated node has a minimum and a maximum. The root bracket is 0.8–3× the true root age. The minima are at about 0.82× the true age, but **31% of them are older than the true age**, which is not possible for a real fossil.

### Dating methods

| Method | What it does |
|---|---|
| **RelTime** (MEGA) | Relative rates between sister lineages. Changes the phylogram's shape the least. |
| **treePL** | Penalized likelihood. The smoothing value is chosen by cross-validation. |
| **chronos** (R package ape) | Penalized likelihood, with four clock models: *clock*, *correlated*, *relaxed* and *discrete*. The smoothing value λ is chosen from a grid. |
| **MD-Cat** | Maximum likelihood with a set of rate categories. Only run on the burst trees, the hard rate models, the early-burst trees and the MD-Cat side checks. |

All methods ran through the PhyloChronoRank dating pipeline, frozen at commit [a8ba7e0](https://github.com/betanri/PhyloChronoRank/tree/a8ba7e0a3791c0667175093ed2f4f654c41f3d98), with the settings of its worked examples.

---

## How accuracy is measured

- **Whole-tree error:** the mean absolute age error over all internal nodes, divided by the true root age.
- **Burst error:** the same, over the nodes inside the burst clades only.
- **Extra error of a method** = (error of its tree ÷ error of the most accurate tree in that dataset) − 1. **0 means it gave the most accurate tree.** 1 means its error was twice the lowest one.
- **Most accurate share:** the share of datasets in which a method gave the most accurate tree (ties split the share).

---

## Results

### 1. Which method gives the most accurate tree?

![Share of datasets in which each method is the most accurate](figures/fig1_most_accurate_method.png)

- **Burst trees:** MD-Cat is the best tree most often (38%), then RelTime (26%). MD-Cat has the lowest median extra error (0.08).
- **Hard rate models:** RelTime (35%) and MD-Cat (31%) share the top. RelTime has the lowest median extra error (0.13).
- **Benchmark sets:** chronos clock (40–45%) and chronos discrete (27–36%) win. RelTime is almost never the best (0–4%). These sets have very wide calibration brackets, and almost every dated tree is too old. So the result mostly measures which method puts the root lowest inside the bracket.

### 2. How rate variation changes the answer

![Median extra error of each method by level of rate variation](figures/fig2_rate_variation.png)

- **MD-Cat has the lowest error at every level except clade clocks.** But each level pools several rate models. Model by model, MD-Cat wins the rate-class models by a wide margin, and RelTime wins the strong inherited and very high independent models (see [the overview](#which-method-works-best-and-when)).
- With **clade clocks** (5–10× rate shifts in some clades), RelTime is best, and MD-Cat, treePL and chronos clock are much worse.
- **treePL** gets much worse as rates vary more (0.29 → 0.65 → 0.87).
- Only 5 datasets have clade clocks, so that row is the least certain.

### 3. What if the fossils are poor?

The ten-fossil burst trees have fossil minima near the true ages (0.79× on average). Real fossils are often much younger than the node they calibrate. So every fossil minimum was moved to 0.6×, 0.45× and 0.3× the true age, and to a random value between 0.3× and 0.6×, and every method was refit (40 datasets per level).

![Median extra error of each method at each fossil level](figures/fig3_poor_fossils.png)

chronos relaxed is left out: it gave a usable fit in only 1–2 datasets per level.

- **MD-Cat is best with the original fossils, and RelTime with poor fossils.** RelTime has the lowest median extra error at 0.6×, 0.45× and random 0.3–0.6×. At 0.3×, chronos discrete, chronos clock and treePL are lower.
- MD-Cat loses most when the fossils get poor (0.01 → 0.23–0.69).
- The most accurate tree keeps its root near the true root at every level: 1.02× with the original fossils, and 0.92–0.94× with the poor ones.

**On the benchmark sets** all 640 datasets were refit three ways: at the original minima, with only the too-old minima moved down to the true age, and with random minima at 0.3–0.6×. 24 datasets per set (16 for conflicting clocks) were also refit at 0.6×, 0.45× and 0.3×.
- In these refits RelTime is the best method at every level (median extra error 0.00–0.11). It is the most accurate tree in 42–56% of datasets at the original minima, in 65–75% once the too-old minima are moved down, and in 62–94% with poor minima.
- But almost every dated tree is far too old. Even the most accurate tree has its root at 1.6–2.3× the true root, so the youngest tree wins whatever the fossils are.
- In the benchmark's own fits, chronos clock was the best (section 1). The difference comes from how the fits were run: in the refits, treePL roots sit near the top of the root bracket, and chronos often stays at its starting dates (the treePL tree).

### 4. Early bursts

The early-burst trees use the same design as the burst trees (10 trees, 4 rate models, 6 exact ages or 10 fossils, 80 datasets), but the three bursts start 76–95 million years ago on a 100-million-year tree. In the burst trees they start 18–59 million years ago. The burst clades now hold most of the tree (97% of the tips on median, against 84%).

![Median extra error of each method with early and late bursts](figures/fig4_early_bursts.png)

Over all 80 datasets, MD-Cat is best with both early and late bursts (0.08), then RelTime (0.15 early, 0.21 late). chronos relaxed gave the same tree as chronos correlated in these runs, so it is not shown.

- **Every method is less accurate with early bursts.** Its median whole-tree error is 1.25–1.60× the error with late bursts (RelTime 1.42×, MD-Cat 1.60×, treePL 1.49×, chronos clock 1.36×, chronos discrete 1.34×).
- **With fossils, MD-Cat and RelTime stay best.** MD-Cat (0.01) and RelTime (0.08) are far ahead of the other methods (0.66–1.16). They are the most accurate tree in 42% and 45% of the fossil datasets.
- **With exact ages, the best methods change.** treePL (0.04), chronos clock and chronos discrete (0.07) are best, and MD-Cat (0.16) and RelTime (0.23) are worse. treePL is the most accurate tree in 35% of these datasets.
- **With fossils, every method puts the root too old,** and more so with early bursts (median root error +7% for MD-Cat, +14% for RelTime and +23–25% for the other methods, against +1%, +9% and +14–16% with late bursts).
- The results inside the burst clades are almost the same as for the whole tree, because the burst clades hold most of the nodes.

---

## What this means in practice

1. **Pick the method from what is known about the data:**
   - good fossils and moderate rate variation → **MD-Cat** first;
   - poor fossils, very strong inherited or independent rate variation, or clades that shift to a new rate → **RelTime**;
   - **treePL** and **chronos** as checks, not as the main tree, unless there is a reason to prefer them.
2. **Fast radiations near the root** make every method less accurate. With fossils, MD-Cat and RelTime still give the best ages.
3. **Date with more than one method** (at least RelTime and MD-Cat) and report the range of ages across methods.

---

## Limits

- Simulations are simpler than real data. The results depend on how the rates were simulated.
- The benchmark sets have very wide calibration brackets, and 31% of their minima are older than the true age, so they mostly test where the root falls inside a wide bracket.
- MD-Cat was not run on the benchmark sets (only on 23 side-check datasets).
- Some cells are small: clade clocks has 5 datasets, and each hard rate model has 5.
- In the refits of the benchmark sets, chronos often stays at its starting dates (the treePL tree), so RelTime looks stronger there than in the benchmark's own fits. The poor-fossil results on the benchmark sets come from these refits, not from the original fits.

---

## Files

| Path | What it holds |
|---|---|
| `figures/` | The figures in this report |
| `scripts/make_report_figures.R` | Draws the figures from `results/`. Run `Rscript scripts/make_report_figures.R` from the repository root. |
| `scripts/method_by_condition.R` | Prints each method's median extra error by condition (the numbers in the overview) |
| `scripts/poor_fossils_by_method.R` | Each method's error at each fossil level (section 3) |
| `scripts/sim_make_datasets.R` | Makes the burst-tree, hard-rate-model and early-burst datasets (early bursts: `--burst-window=0.03,0.25`) |
| `scripts/sim_date_truth.py` | Dates each dataset with every method (PhyloChronoRank dating pipeline) and runs `sim_date_error.R` |
| `scripts/sim_date_error.R` | Whole-tree, burst and root error of each dated tree against the true tree |
| `scripts/sim_early_burst_report.R` | The early-burst tables (`results/early_burst/`) |
| `results/date_errors.csv` | One row per dated tree, with its true error |
| `results/winners.csv` | One row per dataset: the most accurate method |
| `results/accuracy_by_method.csv` | Mean error by method and by simulation cell |
| `results/poor_fossils/` | The poor-fossil refits: error of each dated tree, and the summary tables |
| `results/early_burst/` | The early-burst set against the burst trees |

The simulated trees and dated trees (about 2 GB) are not in this repository. The scripts have absolute paths from the machine where they ran.

### Names used in the code

| This report | In the code and tables |
|---|---|
| Burst trees | sim main (late set in `results/early_burst/`) |
| Hard rate models | sim het |
| Early-burst trees | early set in `results/early_burst/` |
| Fossil placement | Codex F (benchmark F) |
| Local bursts | Codex G (benchmark G) |
| Conflicting clocks | Codex H (benchmark H) |
| Small side sets | Codex C, D, E, and the MD-Cat side checks |
| 6 exact ages / 10 fossils | sparse6 / fossil10 |
| 3 / 8 wide brackets | sparse3 / dense8 |
| inherited / independent / rate classes / rate jumps at bursts | acln (autocorrelated) / ucln / discrete / punct |
| clade clocks | localclock |
| simulated DNA | seqhomo / seqhet |
| Original fossils, refit / 0.6× / random 0.3–0.6× | sim main refit / sim main min 0.60 / sim main min 0.3-0.6 |
