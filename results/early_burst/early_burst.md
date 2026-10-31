# Early bursts against late bursts (burst trees)

Errors are true-age errors. Extra error = error / lowest error in the dataset - 1.
chronos correlated and relaxed at lambda 0.01 give the same tree in these runs, so their rows are equal.

## early set: median extra error, whole tree

| Method | all | sparse6 | fossil10 | acln sparse6 | ucln sparse6 | discrete sparse6 | punct sparse6 | acln fossil10 | ucln fossil10 | discrete fossil10 | punct fossil10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RelTime | 0.15 | 0.23 | 0.08 | 0.26 | 0.20 | 0.52 | 0.12 | 0.00 | 0.11 | 0.30 | 0.10 |
| MD-Cat | 0.08 | 0.16 | 0.01 | 1.28 | 0.14 | 0.00 | 0.07 | 0.61 | 0.03 | 0.00 | 0.00 |
| treePL | 0.48 | 0.04 | 1.16 | 0.00 | 0.29 | 0.55 | 0.02 | 1.06 | 0.68 | 2.03 | 0.98 |
| chronos_clock | 0.44 | 0.07 | 0.71 | 1.54 | 0.00 | 0.15 | 0.00 | 0.93 | 0.64 | 0.67 | 0.80 |
| chronos_discrete | 0.34 | 0.07 | 0.66 | 1.54 | 0.00 | 0.21 | 0.00 | 1.22 | 0.26 | 0.62 | 0.78 |
| chronos_correlated | 2.94 | 3.11 | 2.70 | 4.20 | 2.45 | 1.78 | 4.30 | 2.39 | 2.19 | 2.52 | 4.14 |
| chronos_relaxed | 2.94 | 3.11 | 2.70 | 4.20 | 2.45 | 1.78 | 4.30 | 2.39 | 2.19 | 2.52 | 4.14 |

## early set: median extra error, burst nodes

| Method | all | sparse6 | fossil10 | acln sparse6 | ucln sparse6 | discrete sparse6 | punct sparse6 | acln fossil10 | ucln fossil10 | discrete fossil10 | punct fossil10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RelTime | 0.14 | 0.24 | 0.05 | 0.22 | 0.19 | 0.46 | 0.13 | 0.00 | 0.08 | 0.28 | 0.04 |
| MD-Cat | 0.09 | 0.17 | 0.03 | 1.30 | 0.14 | 0.00 | 0.12 | 0.62 | 0.05 | 0.00 | 0.00 |
| treePL | 0.45 | 0.04 | 1.17 | 0.00 | 0.27 | 0.49 | 0.02 | 1.08 | 0.72 | 1.98 | 0.94 |
| chronos_clock | 0.43 | 0.06 | 0.69 | 1.57 | 0.00 | 0.11 | 0.00 | 1.08 | 0.61 | 0.66 | 0.81 |
| chronos_discrete | 0.32 | 0.07 | 0.68 | 1.57 | 0.00 | 0.20 | 0.00 | 1.29 | 0.25 | 0.63 | 0.79 |
| chronos_correlated | 2.95 | 3.08 | 2.69 | 4.12 | 2.28 | 1.73 | 4.05 | 2.43 | 2.08 | 2.42 | 3.89 |
| chronos_relaxed | 2.95 | 3.08 | 2.69 | 4.12 | 2.28 | 1.73 | 4.05 | 2.43 | 2.08 | 2.42 | 3.89 |

## late set: median extra error, whole tree

| Method | all | sparse6 | fossil10 | acln sparse6 | ucln sparse6 | discrete sparse6 | punct sparse6 | acln fossil10 | ucln fossil10 | discrete fossil10 | punct fossil10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RelTime | 0.21 | 0.26 | 0.20 | 0.05 | 0.18 | 0.58 | 0.23 | 0.04 | 0.20 | 0.60 | 0.18 |
| MD-Cat | 0.08 | 0.11 | 0.01 | 0.95 | 0.10 | 0.00 | 0.09 | 0.24 | 0.14 | 0.00 | 0.00 |
| treePL | 0.38 | 0.20 | 0.78 | 0.00 | 0.06 | 0.90 | 0.08 | 0.27 | 0.21 | 0.86 | 1.12 |
| chronos_clock | 0.35 | 0.27 | 0.38 | 1.67 | 0.02 | 0.70 | 0.04 | 0.56 | 0.13 | 0.56 | 0.29 |
| chronos_discrete | 0.43 | 0.22 | 0.59 | 1.37 | 0.04 | 0.54 | 0.04 | 1.01 | 0.39 | 0.66 | 0.57 |
| chronos_correlated | 3.46 | 3.71 | 2.69 | 5.42 | 3.12 | 3.34 | 4.15 | 2.62 | 2.29 | 2.32 | 3.83 |
| chronos_relaxed | 3.46 | 3.71 | 2.69 | 5.42 | 3.12 | 3.34 | 4.15 | 2.62 | 2.29 | 2.32 | 3.83 |

## late set: median extra error, burst nodes

| Method | all | sparse6 | fossil10 | acln sparse6 | ucln sparse6 | discrete sparse6 | punct sparse6 | acln fossil10 | ucln fossil10 | discrete fossil10 | punct fossil10 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| RelTime | 0.25 | 0.24 | 0.25 | 0.07 | 0.18 | 0.45 | 0.25 | 0.18 | 0.22 | 0.64 | 0.11 |
| MD-Cat | 0.07 | 0.12 | 0.07 | 0.79 | 0.18 | 0.00 | 0.05 | 0.20 | 0.21 | 0.00 | 0.03 |
| treePL | 0.37 | 0.13 | 0.63 | 0.00 | 0.09 | 0.84 | 0.07 | 0.38 | 0.13 | 1.00 | 0.73 |
| chronos_clock | 0.40 | 0.31 | 0.45 | 1.49 | 0.03 | 0.57 | 0.02 | 0.69 | 0.16 | 0.47 | 0.17 |
| chronos_discrete | 0.37 | 0.18 | 0.68 | 1.12 | 0.09 | 0.45 | 0.02 | 1.31 | 0.57 | 0.86 | 0.47 |
| chronos_correlated | 3.22 | 3.40 | 2.42 | 5.11 | 3.25 | 3.26 | 3.84 | 2.62 | 1.96 | 2.23 | 3.31 |
| chronos_relaxed | 3.22 | 3.40 | 2.42 | 5.11 | 3.25 | 3.26 | 3.84 | 2.62 | 1.96 | 2.23 | 3.31 |

## Share of datasets where the method is the most accurate, whole tree

| Method | early all | late all | early sparse6 | late sparse6 | early fossil10 | late fossil10 |
|---|---|---|---|---|---|---|
| RelTime | 30% | 26% | 15% | 22% | 45% | 30% |
| MD-Cat | 30% | 38% | 18% | 30% | 42% | 45% |
| treePL | 20% | 15% | 35% | 22% | 5% | 8% |
| chronos_clock | 10% | 11% | 15% | 12% | 5% | 10% |
| chronos_discrete | 10% | 10% | 18% | 12% | 2% | 8% |
| chronos_correlated | 0% | 0% | 0% | 0% | 0% | 0% |
| chronos_relaxed | 0% | 0% | 0% | 0% | 0% | 0% |

## Share of datasets where the method is the most accurate, burst nodes

| Method | early all | late all | early sparse6 | late sparse6 | early fossil10 | late fossil10 |
|---|---|---|---|---|---|---|
| RelTime | 29% | 24% | 15% | 18% | 42% | 30% |
| MD-Cat | 32% | 38% | 18% | 32% | 48% | 42% |
| treePL | 19% | 12% | 35% | 20% | 2% | 5% |
| chronos_clock | 10% | 15% | 15% | 18% | 5% | 12% |
| chronos_discrete | 10% | 11% | 18% | 12% | 2% | 10% |
| chronos_correlated | 0% | 0% | 0% | 0% | 0% | 0% |
| chronos_relaxed | 0% | 0% | 0% | 0% | 0% | 0% |

## Early / late, median raw error (x true root), whole tree

| Method | all | acln sparse6 | ucln sparse6 | discrete sparse6 | punct sparse6 | acln fossil10 | ucln fossil10 | discrete fossil10 | punct fossil10 |
|---|---|---|---|---|---|---|---|---|---|
| RelTime | 1.42 | 1.71 | 1.56 | 1.53 | 1.13 | 1.21 | 1.45 | 1.70 | 1.11 |
| MD-Cat | 1.60 | 1.48 | 1.44 | 1.67 | 1.27 | 1.86 | 1.45 | 1.76 | 1.19 |
| treePL | 1.49 | 1.22 | 1.74 | 1.25 | 1.12 | 1.48 | 2.61 | 3.50 | 1.36 |
| chronos_clock | 1.36 | 1.10 | 1.48 | 1.17 | 1.20 | 1.39 | 1.59 | 1.99 | 1.58 |
| chronos_discrete | 1.34 | 1.31 | 1.32 | 1.23 | 1.20 | 1.20 | 1.38 | 1.74 | 1.58 |
| chronos_correlated | 1.25 | 1.17 | 1.17 | 1.17 | 1.17 | 1.53 | 1.99 | 1.79 | 1.17 |
| chronos_relaxed | 1.25 | 1.17 | 1.17 | 1.17 | 1.17 | 1.53 | 1.99 | 1.79 | 1.17 |

Medians (early / late): RelTime 0.046 / 0.032; MD-Cat 0.044 / 0.027; treePL 0.055 / 0.037; chronos_clock 0.052 / 0.038; chronos_discrete 0.053 / 0.040; chronos_correlated 0.125 / 0.100; chronos_relaxed 0.125 / 0.100.

## Early / late, median raw error (x true root), burst nodes

| Method | all | acln sparse6 | ucln sparse6 | discrete sparse6 | punct sparse6 | acln fossil10 | ucln fossil10 | discrete fossil10 | punct fossil10 |
|---|---|---|---|---|---|---|---|---|---|
| RelTime | 1.49 | 1.71 | 1.66 | 1.62 | 1.23 | 1.24 | 1.61 | 1.74 | 1.13 |
| MD-Cat | 1.76 | 1.66 | 1.44 | 1.83 | 1.28 | 2.21 | 1.53 | 1.71 | 1.23 |
| treePL | 1.67 | 1.21 | 1.78 | 1.26 | 1.11 | 1.41 | 2.81 | 3.49 | 1.73 |
| chronos_clock | 1.50 | 1.30 | 1.60 | 1.33 | 1.17 | 1.46 | 1.65 | 1.92 | 1.67 |
| chronos_discrete | 1.53 | 1.46 | 1.59 | 1.37 | 1.17 | 1.38 | 1.44 | 1.98 | 1.66 |
| chronos_correlated | 1.33 | 1.29 | 1.29 | 1.29 | 1.29 | 1.64 | 2.05 | 2.01 | 1.35 |
| chronos_relaxed | 1.33 | 1.29 | 1.29 | 1.29 | 1.29 | 1.64 | 2.05 | 2.01 | 1.35 |

Medians (early / late): RelTime 0.046 / 0.031; MD-Cat 0.045 / 0.025; treePL 0.057 / 0.034; chronos_clock 0.051 / 0.034; chronos_discrete 0.053 / 0.035; chronos_correlated 0.125 / 0.094; chronos_relaxed 0.125 / 0.094.

## Median signed root error ((est - true) / true)

| Method | early sparse6 | late sparse6 | early fossil10 | late fossil10 |
|---|---|---|---|---|
| RelTime | 0.00 | 0.00 | 0.14 | 0.09 |
| MD-Cat | 0.00 | 0.00 | 0.07 | 0.01 |
| treePL | 0.00 | 0.00 | 0.25 | 0.16 |
| chronos_clock | 0.00 | 0.00 | 0.24 | 0.14 |
| chronos_discrete | 0.00 | 0.00 | 0.23 | 0.15 |
| chronos_correlated | 0.00 | 0.00 | 0.25 | 0.16 |
| chronos_relaxed | 0.00 | 0.00 | 0.25 | 0.16 |

