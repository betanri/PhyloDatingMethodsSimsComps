# Datasets with a scored tree / all datasets, by set and method

Bold: a gap. Discrete refits: datasets whose chronos discrete tree comes from a refit (a k x lambda fit
had stopped with ape's underflow error). Pick changed: the refit chose another k x lambda than the
original run. From none: the original run had no discrete tree.

| Set | n | RelTime | MD-Cat | treePL | chronos_clock | chronos_discrete | chronos_correlated | chronos_relaxed | Discrete refits | Pick changed | From none |
|---|---|---|---|---|---|---|---|---|---|---|---|
| sim main | 80 | 80 | 80 | 80 | 80 | 80 | 80 | 80 | 4 | 1 |  |
| sim het | 55 | 55 | 55 | 55 | 55 | 55 | 55 | 55 | 2 | 1 |  |
| sim early burst | 80 | 80 | 80 | 80 | 80 | 80 | 80 | 80 | 3 |  |  |
| Codex F | 240 | 240 | **8** | **237** | 240 | 240 | 240 | 240 | 9 | 2 | 7 |
| Codex G | 240 | 240 | **12** | **236** | 240 | 240 | 240 | 240 |  |  |  |
| Codex H | 160 | 160 | **8** | **156** | 160 | 160 | 160 | 160 |  |  |  |
| Codex G/H + MD-Cat | 20 | 20 | 20 | 20 | 20 | 20 | 20 | 20 |  |  |  |
| Codex C | 14 | **13** | **0** | **12** | **4** | **5** | **4** | **0** |  |  |  |
| Codex D | 54 | 54 | **3** | 54 | **0** | **2** | **2** | **0** |  |  |  |
| Codex E | 24 | 24 | **0** | 24 | **6** | **4** | **14** | **0** |  |  |  |
| Codex D + MD-Cat | 3 | 3 | 3 | 3 | **0** | **0** | **0** | **0** |  |  |  |
| Codex F refit | 240 | 240 | **8** | **237** | 240 | 240 | 240 | 240 | 9 | 2 | 7 |
| Codex G refit | 240 | 240 | **12** | **236** | 240 | 240 | 240 | 240 |  |  |  |
| Codex H refit | 160 | 160 | **8** | **156** | 160 | 160 | 160 | 160 |  |  |  |
| sim main refit | 40 | 40 | **37** | 40 | 40 | 40 | 40 | 40 | 1 | 1 |  |
| Codex F min clipped at 1.0 | 240 | 240 | **0** | **226** | 240 | **239** | 240 | 240 | 9 | 2 | 7 |
| Codex G min clipped at 1.0 | 240 | 240 | **0** | **229** | 240 | **239** | 240 | 240 |  |  |  |
| Codex H min clipped at 1.0 | 160 | 160 | **0** | **154** | 160 | 160 | 160 | 160 |  |  |  |
| Codex F min 0.3-0.6 | 240 | 240 | **0** | **221** | 240 | **239** | 240 | 240 | 9 | 2 | 7 |
| Codex G min 0.3-0.6 | 240 | 240 | **0** | **227** | 240 | **239** | 240 | 240 |  |  |  |
| Codex H min 0.3-0.6 | 160 | 160 | **0** | **153** | 160 | 160 | 160 | 160 |  |  |  |
| sim main min 0.3-0.6 | 40 | 40 | **38** | 40 | 40 | 40 | 40 | 40 | 1 | 1 |  |
| Codex F min 0.60 | 24 | 24 | **0** | 24 | 24 | 24 | 24 | 24 | 1 |  | 1 |
| Codex G min 0.60 | 24 | 24 | **0** | 24 | 24 | 24 | 24 | 24 |  |  |  |
| Codex H min 0.60 | 16 | 16 | **0** | 16 | 16 | 16 | 16 | 16 |  |  |  |
| sim main min 0.60 | 40 | 40 | 40 | 40 | 40 | 40 | 40 | 40 | 1 | 1 |  |
| Codex F min 0.45 | 24 | 24 | **0** | 24 | 24 | 24 | 24 | 24 | 1 |  | 1 |
| Codex G min 0.45 | 24 | 24 | **0** | **23** | 24 | 24 | 24 | 24 |  |  |  |
| Codex H min 0.45 | 16 | 16 | **0** | 16 | 16 | 16 | 16 | 16 |  |  |  |
| sim main min 0.45 | 40 | 40 | 40 | 40 | 40 | 40 | 40 | 40 | 1 | 1 |  |
| Codex F min 0.30 | 24 | 24 | **0** | 24 | 24 | 24 | 24 | 24 | 1 |  | 1 |
| Codex G min 0.30 | 24 | 24 | **0** | **23** | 24 | 24 | 24 | 24 |  |  |  |
| Codex H min 0.30 | 16 | 16 | **0** | 16 | 16 | 16 | 16 | 16 |  |  |  |
| sim main min 0.30 | 40 | 40 | 40 | 40 | 40 | 40 | 40 | 40 | 1 | 1 |  |
