# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-18T18:03 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 71 | 15 | 24% | -0.19 | -0.37 | -26.5 | 26.5 |
| 1h | 62 | 9 | 28% | -0.07 | -0.27 | -16.9 | 16.9 |
| 4h | 9 | 6 | 0% | -1.00 | -1.07 | -9.6 | 9.6 |
| Evidence strong | 4 | 2 | 0% | -0.66 | -0.74 | -3.0 | 3.0 |
| Evidence mixed | 23 | 1 | 37% | -0.01 | -0.21 | -4.8 | 7.1 |
| Evidence weak | 44 | 12 | 18% | -0.23 | -0.42 | -18.7 | 18.7 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-18T18:03 | XLMUSDT | 1h | long | 0.1745 | 0.173157 | 0.178537 | A | strong | open | — |
| 2026-10-18T18:03 | LINKUSDT | 1h | long | 11.786 | 11.6650 | 11.9675 | 1 | weak | open | — |
| 2026-10-18T18:03 | ADAUSDT | 1h | long | 0.2162 | 0.213232 | 0.231900 | C | weak | open | — |
| 2026-10-17T22:14 | AAVEUSDT | 1h | long | 151.38 | 148.384 | 157.540 | B | weak | open | — |
| 2026-10-17T22:14 | DOTUSDT | 1h | long | 1.11 | 1.08429 | 1.16678 | 1 | weak | stopped | -1.09 |
| 2026-10-17T22:14 | TRXUSDT | 1h | long | 0.3335 | 0.333282 | 0.335400 | 2 | weak | stopped | -4.06 |
| 2026-10-17T17:06 | AAVEUSDT | 1h | long | 150.25 | 149.748 | 158.165 | B | weak | stopped | -1.60 |
| 2026-10-17T17:06 | BCHUSDT | 1h | long | 272.1 | 269.750 | 277.700 | B | weak | target | +2.15 |
| 2026-10-17T17:06 | TRXUSDT | 1h | long | 0.3347 | 0.333868 | 0.337600 | C | weak | stopped | -1.80 |
| 2026-10-17T09:17 | TRXUSDT | 1h | short | 0.3359 | 0.336679 | 0.333900 | C | weak | stopped | -1.86 |
| 2026-10-17T04:18 | AAVEUSDT | 4h | long | 156.11 | 144.839 | 172.810 | C | weak | open | — |
| 2026-10-17T04:18 | NEARUSDT | 4h | short | 5.088 | 6.12157 | 3.96700 | 3 | weak | open | — |
| 2026-10-17T04:18 | XLMUSDT | 4h | long | 0.1796 | 0.174325 | 0.197530 | A | strong | stopped | -1.07 |
| 2026-10-17T04:18 | LTCUSDT | 4h | long | 59.8 | 56.6014 | 63.9300 | C | mixed | open | — |
| 2026-10-17T04:18 | LTCUSDT | 1h | long | 59.8 | 57.1425 | 63.7400 | 3 | weak | open | — |
| 2026-10-17T04:18 | AVAXUSDT | 4h | long | 9.986 | 9.20082 | 11.0720 | C | weak | open | — |
| 2026-10-17T04:18 | ADAUSDT | 4h | long | 0.2244 | 0.213043 | 0.239000 | C | weak | open | — |
| 2026-10-17T04:18 | ETHUSDT | 4h | short | 2426.51 | 2516.67 | 2332.37 | C | strong | open | — |
| 2026-10-16T21:01 | AAVEUSDT | 1h | long | 155.64 | 152.825 | 159.930 | B | mixed | stopped | -1.11 |
| 2026-10-16T21:01 | SUIUSDT | 1h | long | 1.0144 | 0.952057 | 1.10230 | C | weak | open | — |
| 2026-10-16T21:01 | UNIUSDT | 1h | long | 7.234 | 6.72914 | 7.94200 | 3 | weak | open | — |
| 2026-10-16T21:01 | LINKUSDT | 1h | long | 12.29 | 11.7510 | 13.1170 | C | weak | stopped | -1.04 |
| 2026-10-16T21:01 | ADAUSDT | 1h | long | 0.2247 | 0.214621 | 0.239000 | C | weak | stopped | -1.04 |
| 2026-10-16T21:01 | BNBUSDT | 1h | long | 721.0 | 706.872 | 746.030 | 3 | weak | open | — |
| 2026-10-16T21:01 | BTCUSDT | 1h | long | 81693.61 | 79539.9 | 83950.1 | 3 | weak | open | — |
| 2026-10-16T07:05 | SUIUSDT | 1h | short | 1.0466 | 1.05826 | 1.00585 | B | mixed | stopped | -1.18 |
| 2026-10-16T07:05 | NEARUSDT | 1h | long | 5.211 | 4.47200 | 6.03300 | C | mixed | expired | -0.35 |
| 2026-10-16T07:05 | LTCUSDT | 1h | short | 61.17 | 62.2479 | 59.7900 | C | mixed | target | +1.17 |
| 2026-10-16T01:16 | NEARUSDT | 1h | short | 5.388 | 5.50918 | 5.16200 | C | weak | target | +1.78 |
| 2026-10-15T22:15 | SUIUSDT | 1h | short | 1.0383 | 1.05169 | 1.00130 | B | mixed | stopped | -1.16 |
| 2026-10-15T22:15 | XLMUSDT | 1h | long | 0.1839 | 0.175139 | 0.194640 | 1 | mixed | stopped | -1.04 |
| 2026-10-15T22:15 | BCHUSDT | 1h | short | 278.9 | 281.936 | 271.796 | A | mixed | stopped | -1.18 |
| 2026-10-15T22:15 | AVAXUSDT | 1h | short | 10.068 | 10.6760 | 8.81800 | 3 | weak | expired | +0.46 |
| 2026-10-15T22:15 | TRXUSDT | 1h | short | 0.3326 | 0.333218 | 0.331150 | 2 | mixed | stopped | -2.08 |
| 2026-10-15T22:15 | ADAUSDT | 1h | short | 0.2313 | 0.233893 | 0.224100 | B | mixed | target | +2.60 |
| 2026-10-15T22:15 | DOGEUSDT | 1h | short | 0.08161 | 0.0861654 | 0.0738700 | 3 | weak | expired | +0.46 |
| 2026-10-15T22:15 | BTCUSDT | 1h | short | 82468.04 | 82904.2 | 81801.3 | C | weak | target | +1.15 |
| 2026-10-15T19:05 | HBARUSDT | 1h | short | 0.08465 | 0.0895000 | 0.0755300 | 3 | weak | expired | -0.22 |
| 2026-10-15T19:05 | AAVEUSDT | 1h | short | 156.51 | 164.350 | 141.100 | 3 | weak | stopped | -1.04 |
| 2026-10-15T19:05 | UNIUSDT | 1h | short | 7.473 | 7.71107 | 7.22800 | B | mixed | target | +0.97 |
| 2026-10-15T19:05 | DOTUSDT | 1h | short | 1.137 | 1.22964 | 0.965000 | 3 | weak | expired | -0.05 |
| 2026-10-15T19:05 | LINKUSDT | 1h | short | 12.595 | 12.6796 | 12.2035 | B | mixed | stopped | -1.30 |
| 2026-10-15T19:05 | XRPUSDT | 1h | short | 1.3448 | 1.39532 | 1.24440 | 3 | weak | expired | +0.78 |
| 2026-10-15T19:05 | SOLUSDT | 1h | short | 106.22 | 109.755 | 98.0600 | 3 | weak | expired | +0.51 |
| 2026-10-15T19:05 | ETHUSDT | 1h | short | 2453.81 | 2552.53 | 2238.28 | 3 | weak | expired | +0.28 |
| 2026-10-14T20:11 | HBARUSDT | 4h | long | 0.08433 | 0.0821511 | 0.0935285 | A | mixed | stopped | -1.08 |
| 2026-10-14T20:11 | AAVEUSDT | 1h | long | 155.23 | 153.101 | 157.414 | A | strong | stopped | -1.14 |
| 2026-10-14T20:11 | XLMUSDT | 4h | long | 0.1845 | 0.180014 | 0.201300 | A | strong | stopped | -1.08 |
| 2026-10-14T20:11 | DOTUSDT | 4h | long | 1.139 | 1.09229 | 1.22609 | 1 | weak | stopped | -1.05 |
| 2026-10-14T20:11 | AVAXUSDT | 4h | long | 9.915 | 9.62071 | 10.6016 | 1 | weak | stopped | -1.07 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
