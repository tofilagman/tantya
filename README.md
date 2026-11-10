# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-10T17:44 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 306 | 7 | 21% | -0.29 | -0.45 | -139.1 | 140.1 |
| 1h | 257 | 4 | 21% | -0.26 | -0.44 | -113.0 | 113.9 |
| 4h | 49 | 3 | 19% | -0.46 | -0.53 | -26.1 | 26.1 |
| Evidence strong | 24 | 1 | 10% | -0.62 | -0.82 | -19.6 | 19.6 |
| Evidence mixed | 91 | 2 | 31% | -0.13 | -0.32 | -29.2 | 29.2 |
| Evidence weak | 191 | 4 | 17% | -0.33 | -0.47 | -90.3 | 91.3 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-09T06:13 | HBARUSDT | 1h | short | 0.06627 | 0.0696364 | 0.0621900 | 3 | weak | open | — |
| 2026-11-09T06:13 | AAVEUSDT | 1h | short | 129.3 | 134.621 | 121.690 | C | weak | stopped | -1.05 |
| 2026-11-09T06:13 | LTCUSDT | 1h | short | 50.61 | 53.8132 | 46.9400 | 3 | mixed | open | — |
| 2026-11-09T06:13 | DOGEUSDT | 1h | short | 0.06914 | 0.0738379 | 0.0643600 | 3 | mixed | open | — |
| 2026-11-09T06:13 | ETHUSDT | 1h | short | 2131.58 | 2269.01 | 1974.09 | 3 | weak | open | — |
| 2026-11-09T06:13 | BTCUSDT | 1h | long | 74560.01 | 74007.9 | 75194.2 | 1 | weak | stopped | -1.27 |
| 2026-11-08T15:06 | HBARUSDT | 1h | long | 0.06658 | 0.0661129 | 0.0673300 | C | weak | stopped | -1.28 |
| 2026-11-08T15:06 | BNBUSDT | 1h | short | 697.97 | 724.342 | 662.520 | 3 | weak | expired | +0.96 |
| 2026-11-08T15:06 | ETHUSDT | 1h | short | 2240.42 | 2257.03 | 2214.89 | C | mixed | target | +1.27 |
| 2026-11-08T07:16 | UNIUSDT | 1h | long | 7.102 | 6.82100 | 7.43200 | 3 | weak | stopped | -1.05 |
| 2026-11-08T07:16 | LTCUSDT | 1h | long | 52.15 | 50.9489 | 54.0300 | C | mixed | stopped | -1.09 |
| 2026-11-08T07:16 | DOTUSDT | 1h | short | 0.898 | 0.916000 | 0.866000 | 3 | weak | target | +1.68 |
| 2026-11-08T07:16 | LINKUSDT | 1h | long | 10.751 | 10.4804 | 11.2490 | C | weak | stopped | -1.08 |
| 2026-11-08T07:16 | DOGEUSDT | 1h | long | 0.07118 | 0.0700332 | 0.0740300 | C | mixed | stopped | -1.12 |
| 2026-11-08T07:16 | SOLUSDT | 1h | long | 89.2 | 88.0893 | 92.0500 | C | weak | stopped | -1.16 |
| 2026-11-07T20:12 | AAVEUSDT | 4h | short | 131.12 | 143.099 | 119.140 | C | weak | open | — |
| 2026-11-07T20:12 | AAVEUSDT | 1h | long | 131.12 | 128.147 | 135.190 | 3 | weak | stopped | -1.09 |
| 2026-11-07T20:12 | SUIUSDT | 1h | long | 0.8599 | 0.828296 | 0.906600 | 3 | weak | stopped | -1.05 |
| 2026-11-07T20:12 | BCHUSDT | 4h | long | 257.2 | 252.175 | 281.894 | 1 | weak | stopped | -1.10 |
| 2026-11-07T20:12 | ADAUSDT | 1h | long | 0.1814 | 0.177221 | 0.192900 | C | weak | stopped | -1.09 |
| 2026-11-07T20:12 | XRPUSDT | 4h | long | 1.1624 | 1.13805 | 1.19662 | 4 | mixed | stopped | -1.09 |
| 2026-11-07T20:12 | BNBUSDT | 1h | short | 697.28 | 700.148 | 689.888 | 1 | weak | stopped | -1.49 |
| 2026-11-07T20:12 | BTCUSDT | 1h | short | 75801.92 | 77073.1 | 74132.0 | 3 | mixed | target | +1.20 |
| 2026-11-06T00:10 | HBARUSDT | 4h | long | 0.06776 | 0.0649754 | 0.0828371 | A | strong | stopped | -1.05 |
| 2026-11-06T00:10 | UNIUSDT | 4h | long | 6.842 | 6.10293 | 8.15300 | C | weak | open | — |
| 2026-11-06T00:10 | XLMUSDT | 4h | long | 0.1535 | 0.149104 | 0.159925 | 4 | mixed | stopped | -1.07 |
| 2026-11-06T00:10 | XLMUSDT | 1h | long | 0.1535 | 0.150221 | 0.158987 | A | mixed | stopped | -1.09 |
| 2026-11-06T00:10 | LTCUSDT | 1h | long | 51.75 | 50.6718 | 54.0550 | 2 | weak | expired | +0.21 |
| 2026-11-06T00:10 | DOTUSDT | 4h | long | 0.91 | 0.853821 | 1.01300 | C | weak | stopped | -1.03 |
| 2026-11-06T00:10 | LINKUSDT | 4h | long | 10.729 | 10.3333 | 11.4076 | 1 | weak | stopped | -1.05 |
| 2026-11-06T00:10 | TRXUSDT | 4h | long | 0.319 | 0.314639 | 0.324143 | 5 | strong | open | — |
| 2026-11-06T00:10 | ADAUSDT | 4h | long | 0.1815 | 0.174664 | 0.208948 | A | strong | stopped | -1.05 |
| 2026-11-06T00:10 | DOGEUSDT | 4h | long | 0.07154 | 0.0692468 | 0.0786048 | 1 | weak | stopped | -1.06 |
| 2026-11-06T00:10 | DOGEUSDT | 1h | long | 0.07154 | 0.0696718 | 0.0742700 | 2 | weak | expired | -0.20 |
| 2026-11-06T00:10 | SOLUSDT | 4h | long | 89.68 | 87.0196 | 96.5800 | C | weak | stopped | -1.07 |
| 2026-11-06T00:10 | SOLUSDT | 1h | long | 89.68 | 87.6104 | 92.0589 | A | mixed | expired | -0.37 |
| 2026-11-06T00:10 | BNBUSDT | 4h | long | 691.53 | 674.860 | 726.620 | C | weak | stopped | -1.08 |
| 2026-11-06T00:10 | ETHUSDT | 4h | long | 2240.96 | 2178.53 | 2404.25 | 1 | weak | stopped | -1.07 |
| 2026-11-06T00:10 | ETHUSDT | 1h | long | 2240.96 | 2190.13 | 2299.38 | A | mixed | expired | -0.22 |
| 2026-11-04T21:16 | HBARUSDT | 1h | short | 0.07212 | 0.0745557 | 0.0693647 | 1 | mixed | target | +1.07 |
| 2026-11-04T21:16 | AAVEUSDT | 1h | long | 130.52 | 122.234 | 143.360 | 3 | weak | expired | -0.04 |
| 2026-11-04T21:16 | UNIUSDT | 1h | short | 7.603 | 7.85171 | 7.18183 | 1 | weak | target | +1.63 |
| 2026-11-04T21:16 | NEARUSDT | 1h | short | 4.036 | 4.61536 | 3.39100 | 3 | weak | expired | +0.56 |
| 2026-11-04T21:16 | BCHUSDT | 1h | short | 281.1 | 299.661 | 253.300 | 3 | weak | expired | +0.89 |
| 2026-11-04T21:16 | LTCUSDT | 1h | long | 56.08 | 54.1536 | 58.0900 | 3 | weak | stopped | -1.06 |
| 2026-11-04T21:16 | AVAXUSDT | 1h | long | 8.758 | 8.22018 | 9.57700 | 3 | weak | stopped | -1.03 |
| 2026-11-04T21:16 | LINKUSDT | 1h | long | 11.457 | 10.5499 | 12.4940 | C | mixed | stopped | -1.02 |
| 2026-11-04T21:16 | XRPUSDT | 1h | long | 1.3051 | 1.28449 | 1.33175 | 5 | mixed | stopped | -1.13 |
| 2026-11-04T21:16 | SOLUSDT | 1h | long | 94.99 | 89.2907 | 102.610 | 3 | weak | stopped | -1.03 |
| 2026-11-04T21:16 | BNBUSDT | 1h | short | 718.48 | 724.008 | 701.165 | B | mixed | target | +2.88 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
