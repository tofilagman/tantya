# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-24T22:27 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 179 | 8 | 19% | -0.38 | -0.56 | -99.8 | 107.2 |
| 1h | 153 | 2 | 21% | -0.31 | -0.51 | -77.3 | 86.9 |
| 4h | 26 | 6 | 8% | -0.80 | -0.87 | -22.5 | 24.7 |
| Evidence strong | 16 | 0 | 7% | -0.79 | -1.04 | -16.7 | 16.7 |
| Evidence mixed | 51 | 0 | 28% | -0.19 | -0.40 | -20.5 | 24.6 |
| Evidence weak | 112 | 8 | 16% | -0.41 | -0.56 | -62.5 | 68.1 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-24T07:15 | DOTUSDT | 1h | long | 1.076 | 1.05993 | 1.10100 | C | weak | stopped | -1.13 |
| 2026-10-24T07:15 | ETHUSDT | 1h | short | 2379.8 | 2424.75 | 2324.02 | 3 | mixed | target | +1.14 |
| 2026-10-23T23:06 | SUIUSDT | 1h | long | 0.9457 | 0.933786 | 1.01206 | 1 | weak | stopped | -1.16 |
| 2026-10-23T23:06 | SOLUSDT | 1h | long | 102.07 | 101.313 | 103.071 | A | weak | target | +1.05 |
| 2026-10-23T15:00 | SUIUSDT | 1h | long | 0.9896 | 0.960671 | 1.02170 | C | mixed | stopped | -1.07 |
| 2026-10-23T15:00 | AVAXUSDT | 1h | long | 9.119 | 8.93779 | 9.51850 | 2 | weak | stopped | -1.10 |
| 2026-10-23T10:01 | HBARUSDT | 1h | long | 0.07903 | 0.0782607 | 0.0822000 | C | weak | stopped | -1.20 |
| 2026-10-23T10:01 | UNIUSDT | 1h | short | 7.17 | 7.77525 | 6.45700 | 3 | weak | open | — |
| 2026-10-23T10:01 | BCHUSDT | 1h | short | 286.6 | 292.282 | 269.700 | C | mixed | target | +2.88 |
| 2026-10-23T10:01 | AVAXUSDT | 1h | long | 9.221 | 9.01789 | 9.47200 | C | mixed | stopped | -1.09 |
| 2026-10-23T10:01 | LINKUSDT | 1h | short | 12.091 | 12.8620 | 11.2500 | 3 | weak | target | +1.06 |
| 2026-10-23T10:01 | TRXUSDT | 1h | short | 0.3297 | 0.331636 | 0.326500 | 3 | weak | open | — |
| 2026-10-23T10:01 | XRPUSDT | 1h | short | 1.3186 | 1.35754 | 1.27310 | 3 | weak | target | +1.10 |
| 2026-10-23T10:01 | BNBUSDT | 1h | short | 746.61 | 753.558 | 721.630 | C | weak | target | +3.38 |
| 2026-10-22T23:18 | BNBUSDT | 1h | short | 730.8 | 737.213 | 723.530 | C | mixed | stopped | -1.23 |
| 2026-10-22T20:02 | AAVEUSDT | 1h | long | 147.11 | 143.424 | 152.425 | 2 | mixed | stopped | -1.08 |
| 2026-10-22T20:02 | LTCUSDT | 1h | long | 58.7 | 57.8293 | 60.2500 | B | mixed | stopped | -1.13 |
| 2026-10-22T20:02 | TRXUSDT | 4h | long | 0.3283 | 0.327107 | 0.332450 | 2 | weak | open | — |
| 2026-10-22T20:02 | ADAUSDT | 4h | long | 0.2126 | 0.207182 | 0.224432 | 1 | weak | stopped | -1.08 |
| 2026-10-22T20:02 | ADAUSDT | 1h | long | 0.2126 | 0.208479 | 0.224432 | 1 | mixed | stopped | -1.10 |
| 2026-10-22T20:02 | DOGEUSDT | 4h | long | 0.07873 | 0.0753736 | 0.0855800 | C | weak | stopped | -1.05 |
| 2026-10-22T20:02 | XRPUSDT | 4h | long | 1.3065 | 1.24415 | 1.44580 | 3 | weak | open | — |
| 2026-10-22T20:02 | XRPUSDT | 1h | long | 1.3065 | 1.29782 | 1.33962 | A | mixed | stopped | -1.30 |
| 2026-10-22T20:02 | SOLUSDT | 4h | long | 103.73 | 99.5096 | 111.810 | 3 | weak | stopped | -1.05 |
| 2026-10-22T20:02 | SOLUSDT | 1h | long | 103.73 | 102.643 | 105.393 | A | strong | stopped | -1.19 |
| 2026-10-22T20:02 | BNBUSDT | 4h | long | 732.24 | 702.519 | 771.620 | 3 | weak | open | — |
| 2026-10-22T20:02 | ETHUSDT | 4h | long | 2387.83 | 2340.95 | 2443.47 | B | weak | stopped | -1.10 |
| 2026-10-22T20:02 | ETHUSDT | 1h | long | 2387.83 | 2351.76 | 2443.47 | B | weak | stopped | -1.13 |
| 2026-10-22T20:02 | BTCUSDT | 4h | long | 81486.39 | 80221.6 | 85153.2 | C | weak | stopped | -1.13 |
| 2026-10-22T20:02 | BTCUSDT | 1h | long | 81486.39 | 80733.4 | 82893.4 | B | mixed | stopped | -1.22 |
| 2026-10-22T15:16 | BCHUSDT | 1h | long | 273.6 | 272.479 | 279.950 | A | mixed | stopped | -1.49 |
| 2026-10-22T15:16 | XRPUSDT | 1h | long | 1.3183 | 1.31425 | 1.34976 | A | mixed | stopped | -1.65 |
| 2026-10-22T10:06 | HBARUSDT | 1h | long | 0.081 | 0.0799271 | 0.0824892 | A | mixed | stopped | -1.15 |
| 2026-10-22T10:06 | AAVEUSDT | 1h | long | 148.34 | 146.379 | 153.850 | B | weak | stopped | -1.15 |
| 2026-10-22T10:06 | SUIUSDT | 1h | long | 0.989 | 0.972557 | 1.02423 | 1 | weak | stopped | -1.12 |
| 2026-10-22T10:06 | UNIUSDT | 1h | long | 7.102 | 6.94293 | 7.48669 | 1 | weak | stopped | -1.09 |
| 2026-10-22T10:06 | NEARUSDT | 1h | long | 5.003 | 4.71204 | 5.60700 | C | weak | stopped | -1.03 |
| 2026-10-22T10:06 | XLMUSDT | 1h | long | 0.1781 | 0.171043 | 0.192300 | 3 | weak | stopped | -1.05 |
| 2026-10-22T10:06 | LTCUSDT | 1h | long | 59.42 | 58.8354 | 60.7400 | B | weak | stopped | -1.20 |
| 2026-10-22T10:06 | AVAXUSDT | 1h | long | 9.246 | 9.11921 | 9.61200 | 2 | mixed | stopped | -1.14 |
| 2026-10-22T10:06 | LINKUSDT | 1h | long | 12.077 | 11.9305 | 12.2780 | A | mixed | stopped | -1.16 |
| 2026-10-22T10:06 | ADAUSDT | 1h | long | 0.2166 | 0.213221 | 0.222400 | B | weak | stopped | -1.13 |
| 2026-10-22T10:06 | DOGEUSDT | 1h | long | 0.07925 | 0.0757607 | 0.0865100 | 3 | weak | expired | -0.52 |
| 2026-10-22T10:06 | XRPUSDT | 1h | long | 1.3323 | 1.32004 | 1.35347 | A | mixed | stopped | -1.22 |
| 2026-10-22T10:06 | ETHUSDT | 1h | long | 2411.09 | 2388.19 | 2445.62 | A | weak | stopped | -1.21 |
| 2026-10-22T10:06 | BTCUSDT | 1h | long | 82050.87 | 81442.5 | 82873.2 | A | mixed | stopped | -1.27 |
| 2026-10-21T23:18 | NEARUSDT | 1h | long | 5.274 | 5.04607 | 5.51613 | 5 | strong | stopped | -1.05 |
| 2026-10-21T23:18 | DOTUSDT | 1h | long | 1.149 | 1.03821 | 1.26200 | C | weak | expired | -0.68 |
| 2026-10-21T23:18 | AVAXUSDT | 1h | long | 9.689 | 9.47521 | 10.2260 | 3 | weak | stopped | -1.09 |
| 2026-10-21T23:18 | LINKUSDT | 1h | long | 12.539 | 12.4141 | 12.9567 | 5 | strong | stopped | -1.20 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
