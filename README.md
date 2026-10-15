# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-15T22:15 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 41 | 16 | 21% | -0.25 | -0.35 | -14.5 | 17.1 |
| 1h | 33 | 16 | 28% | -0.07 | -0.18 | -6.0 | 13.5 |
| 4h | 8 | 0 | 0% | -1.00 | -1.07 | -8.6 | 8.6 |
| Evidence strong | 3 | 0 | 0% | -0.55 | -0.63 | -1.9 | 1.9 |
| Evidence mixed | 12 | 7 | 44% | +0.16 | -0.01 | -0.2 | 3.7 |
| Evidence weak | 26 | 9 | 14% | -0.40 | -0.48 | -12.4 | 13.7 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-15T22:15 | SUIUSDT | 1h | short | 1.0383 | 1.05169 | 1.00130 | B | mixed | open | — |
| 2026-10-15T22:15 | XLMUSDT | 1h | long | 0.1839 | 0.175139 | 0.194640 | 1 | mixed | open | — |
| 2026-10-15T22:15 | BCHUSDT | 1h | short | 278.9 | 281.936 | 271.796 | A | mixed | open | — |
| 2026-10-15T22:15 | AVAXUSDT | 1h | short | 10.068 | 10.6760 | 8.81800 | 3 | weak | open | — |
| 2026-10-15T22:15 | TRXUSDT | 1h | short | 0.3326 | 0.333218 | 0.331150 | 2 | mixed | open | — |
| 2026-10-15T22:15 | ADAUSDT | 1h | short | 0.2313 | 0.233893 | 0.224100 | B | mixed | open | — |
| 2026-10-15T22:15 | DOGEUSDT | 1h | short | 0.08161 | 0.0861654 | 0.0738700 | 3 | weak | open | — |
| 2026-10-15T22:15 | BTCUSDT | 1h | short | 82468.04 | 82904.2 | 81801.3 | C | weak | open | — |
| 2026-10-15T19:05 | HBARUSDT | 1h | short | 0.08465 | 0.0895000 | 0.0755300 | 3 | weak | open | — |
| 2026-10-15T19:05 | AAVEUSDT | 1h | short | 156.51 | 164.350 | 141.100 | 3 | weak | open | — |
| 2026-10-15T19:05 | UNIUSDT | 1h | short | 7.473 | 7.71107 | 7.22800 | B | mixed | open | — |
| 2026-10-15T19:05 | DOTUSDT | 1h | short | 1.137 | 1.22964 | 0.965000 | 3 | weak | open | — |
| 2026-10-15T19:05 | LINKUSDT | 1h | short | 12.595 | 12.6796 | 12.2035 | B | mixed | open | — |
| 2026-10-15T19:05 | XRPUSDT | 1h | short | 1.3448 | 1.39532 | 1.24440 | 3 | weak | open | — |
| 2026-10-15T19:05 | SOLUSDT | 1h | short | 106.22 | 109.755 | 98.0600 | 3 | weak | open | — |
| 2026-10-15T19:05 | ETHUSDT | 1h | short | 2453.81 | 2552.53 | 2238.28 | 3 | weak | open | — |
| 2026-10-14T20:11 | HBARUSDT | 4h | long | 0.08433 | 0.0821511 | 0.0935285 | A | mixed | stopped | -1.08 |
| 2026-10-14T20:11 | AAVEUSDT | 1h | long | 155.23 | 153.101 | 157.414 | A | strong | stopped | -1.14 |
| 2026-10-14T20:11 | XLMUSDT | 4h | long | 0.1845 | 0.180014 | 0.201300 | A | strong | stopped | -1.08 |
| 2026-10-14T20:11 | DOTUSDT | 4h | long | 1.139 | 1.09229 | 1.22609 | 1 | weak | stopped | -1.05 |
| 2026-10-14T20:11 | AVAXUSDT | 4h | long | 9.915 | 9.62071 | 10.6016 | 1 | weak | stopped | -1.07 |
| 2026-10-14T20:11 | LINKUSDT | 4h | long | 12.434 | 11.9196 | 13.6740 | C | weak | stopped | -1.05 |
| 2026-10-14T20:11 | DOGEUSDT | 4h | long | 0.0822 | 0.0790839 | 0.0873200 | C | weak | stopped | -1.05 |
| 2026-10-14T20:11 | XRPUSDT | 4h | long | 1.3301 | 1.29708 | 1.39800 | C | weak | stopped | -1.08 |
| 2026-10-14T20:11 | XRPUSDT | 1h | long | 1.33 | 1.30425 | 1.39800 | C | weak | stopped | -1.10 |
| 2026-10-14T20:11 | SOLUSDT | 1h | long | 104.36 | 101.092 | 110.900 | C | weak | stopped | -1.06 |
| 2026-10-14T20:11 | BTCUSDT | 4h | long | 81905.28 | 80512.7 | 84648.6 | C | weak | stopped | -1.12 |
| 2026-10-14T10:07 | LINKUSDT | 1h | long | 12.836 | 12.2071 | 13.6580 | 3 | weak | stopped | -1.04 |
| 2026-10-14T10:07 | TRXUSDT | 1h | short | 0.3337 | 0.334389 | 0.331264 | A | mixed | stopped | -1.97 |
| 2026-10-13T19:13 | HBARUSDT | 1h | short | 0.0878 | 0.0895039 | 0.0860083 | 1 | mixed | target | +0.95 |
| 2026-10-13T19:13 | AAVEUSDT | 1h | short | 162.17 | 167.335 | 155.889 | 5 | mixed | target | +1.15 |
| 2026-10-13T19:13 | SUIUSDT | 1h | short | 1.0574 | 1.14959 | 0.929700 | 3 | weak | expired | +0.26 |
| 2026-10-13T19:13 | UNIUSDT | 1h | short | 7.593 | 7.71886 | 7.09038 | 1 | weak | target | +3.88 |
| 2026-10-13T19:13 | NEARUSDT | 1h | short | 5.051 | 5.10050 | 4.98400 | B | mixed | stopped | -1.21 |
| 2026-10-13T19:13 | XLMUSDT | 1h | short | 0.1929 | 0.207029 | 0.175100 | 3 | mixed | expired | +0.60 |
| 2026-10-13T19:13 | BCHUSDT | 1h | short | 273.8 | 290.521 | 243.900 | 3 | weak | expired | -0.30 |
| 2026-10-13T19:13 | LTCUSDT | 1h | short | 61.99 | 66.1789 | 56.2200 | 3 | mixed | expired | +0.34 |
| 2026-10-13T19:13 | DOTUSDT | 1h | short | 1.183 | 1.29504 | 1.05100 | 3 | weak | target | +1.16 |
| 2026-10-13T19:13 | AVAXUSDT | 1h | short | 10.301 | 11.1788 | 9.30600 | 3 | mixed | expired | +0.34 |
| 2026-10-13T19:13 | TRXUSDT | 1h | short | 0.329 | 0.330811 | 0.325300 | 3 | mixed | stopped | -1.36 |
| 2026-10-13T19:13 | ADAUSDT | 1h | short | 0.2379 | 0.258036 | 0.208200 | 3 | weak | expired | +0.38 |
| 2026-10-13T19:13 | DOGEUSDT | 1h | short | 0.08474 | 0.0885443 | 0.0771700 | 3 | weak | expired | +0.83 |
| 2026-10-13T19:13 | XRPUSDT | 1h | short | 1.3745 | 1.38825 | 1.34680 | B | weak | target | +1.82 |
| 2026-10-13T19:13 | SOLUSDT | 1h | short | 107.96 | 109.626 | 105.380 | B | mixed | target | +1.42 |
| 2026-10-13T19:13 | ETHUSDT | 1h | short | 2510.36 | 2589.33 | 2367.73 | C | mixed | target | +1.74 |
| 2026-10-13T19:13 | BTCUSDT | 1h | long | 83215.35 | 80814.2 | 86107.1 | C | weak | stopped | -1.07 |
| 2026-10-12T22:07 | AAVEUSDT | 1h | long | 159.64 | 157.454 | 161.845 | 4 | weak | stopped | -1.15 |
| 2026-10-12T22:07 | SUIUSDT | 1h | long | 1.0559 | 1.03470 | 1.07774 | A | mixed | stopped | -1.10 |
| 2026-10-12T22:07 | UNIUSDT | 1h | long | 7.266 | 6.94996 | 8.08100 | C | weak | stopped | -1.04 |
| 2026-10-12T22:07 | NEARUSDT | 1h | long | 5.21 | 4.94568 | 5.50800 | B | weak | stopped | -1.04 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
