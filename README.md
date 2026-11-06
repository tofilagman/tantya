# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-06T00:10 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 271 | 19 | 22% | -0.27 | -0.44 | -118.4 | 118.7 |
| 1h | 233 | 8 | 21% | -0.26 | -0.45 | -104.0 | 104.3 |
| 4h | 38 | 11 | 25% | -0.31 | -0.38 | -14.4 | 24.7 |
| Evidence strong | 22 | 3 | 11% | -0.59 | -0.80 | -17.5 | 17.5 |
| Evidence mixed | 82 | 4 | 31% | -0.11 | -0.31 | -25.6 | 27.4 |
| Evidence weak | 167 | 12 | 19% | -0.30 | -0.45 | -75.3 | 75.3 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-06T00:10 | HBARUSDT | 4h | long | 0.06776 | 0.0649754 | 0.0828371 | A | strong | open | — |
| 2026-11-06T00:10 | UNIUSDT | 4h | long | 6.842 | 6.10293 | 8.15300 | C | weak | open | — |
| 2026-11-06T00:10 | XLMUSDT | 4h | long | 0.1535 | 0.149104 | 0.159925 | 4 | mixed | open | — |
| 2026-11-06T00:10 | XLMUSDT | 1h | long | 0.1535 | 0.150221 | 0.158987 | A | mixed | open | — |
| 2026-11-06T00:10 | LTCUSDT | 1h | long | 51.75 | 50.6718 | 54.0550 | 2 | weak | open | — |
| 2026-11-06T00:10 | DOTUSDT | 4h | long | 0.91 | 0.853821 | 1.01300 | C | weak | open | — |
| 2026-11-06T00:10 | LINKUSDT | 4h | long | 10.729 | 10.3333 | 11.4076 | 1 | weak | open | — |
| 2026-11-06T00:10 | TRXUSDT | 4h | long | 0.319 | 0.314639 | 0.324143 | 5 | strong | open | — |
| 2026-11-06T00:10 | ADAUSDT | 4h | long | 0.1815 | 0.174664 | 0.208948 | A | strong | open | — |
| 2026-11-06T00:10 | DOGEUSDT | 4h | long | 0.07154 | 0.0692468 | 0.0786048 | 1 | weak | open | — |
| 2026-11-06T00:10 | DOGEUSDT | 1h | long | 0.07154 | 0.0696718 | 0.0742700 | 2 | weak | open | — |
| 2026-11-06T00:10 | SOLUSDT | 4h | long | 89.68 | 87.0196 | 96.5800 | C | weak | open | — |
| 2026-11-06T00:10 | SOLUSDT | 1h | long | 89.68 | 87.6104 | 92.0589 | A | mixed | open | — |
| 2026-11-06T00:10 | BNBUSDT | 4h | long | 691.53 | 674.860 | 726.620 | C | weak | open | — |
| 2026-11-06T00:10 | ETHUSDT | 4h | long | 2240.96 | 2178.53 | 2404.25 | 1 | weak | open | — |
| 2026-11-06T00:10 | ETHUSDT | 1h | long | 2240.96 | 2190.13 | 2299.38 | A | mixed | open | — |
| 2026-11-04T21:16 | HBARUSDT | 1h | short | 0.07212 | 0.0745557 | 0.0693647 | 1 | mixed | target | +1.07 |
| 2026-11-04T21:16 | AAVEUSDT | 1h | long | 130.52 | 122.234 | 143.360 | 3 | weak | open | — |
| 2026-11-04T21:16 | UNIUSDT | 1h | short | 7.603 | 7.85171 | 7.18183 | 1 | weak | target | +1.63 |
| 2026-11-04T21:16 | NEARUSDT | 1h | short | 4.036 | 4.61536 | 3.39100 | 3 | weak | open | — |
| 2026-11-04T21:16 | BCHUSDT | 1h | short | 281.1 | 299.661 | 253.300 | 3 | weak | open | — |
| 2026-11-04T21:16 | LTCUSDT | 1h | long | 56.08 | 54.1536 | 58.0900 | 3 | weak | stopped | -1.06 |
| 2026-11-04T21:16 | AVAXUSDT | 1h | long | 8.758 | 8.22018 | 9.57700 | 3 | weak | stopped | -1.03 |
| 2026-11-04T21:16 | LINKUSDT | 1h | long | 11.457 | 10.5499 | 12.4940 | C | mixed | stopped | -1.02 |
| 2026-11-04T21:16 | XRPUSDT | 1h | long | 1.3051 | 1.28449 | 1.33175 | 5 | mixed | stopped | -1.13 |
| 2026-11-04T21:16 | SOLUSDT | 1h | long | 94.99 | 89.2907 | 102.610 | 3 | weak | stopped | -1.03 |
| 2026-11-04T21:16 | BNBUSDT | 1h | short | 718.48 | 724.008 | 701.165 | B | mixed | target | +2.88 |
| 2026-11-04T06:07 | AAVEUSDT | 1h | short | 129.01 | 130.617 | 126.530 | B | weak | stopped | -1.16 |
| 2026-11-04T06:07 | SUIUSDT | 1h | short | 0.8917 | 0.909186 | 0.852200 | C | weak | stopped | -1.10 |
| 2026-11-04T06:07 | UNIUSDT | 1h | short | 7.307 | 7.41696 | 7.01948 | 1 | weak | stopped | -1.13 |
| 2026-11-04T06:07 | XLMUSDT | 1h | short | 0.1629 | 0.164539 | 0.160350 | B | mixed | stopped | -1.20 |
| 2026-11-04T06:07 | BCHUSDT | 1h | short | 273.6 | 280.064 | 261.800 | C | strong | stopped | -1.09 |
| 2026-11-04T06:07 | AVAXUSDT | 1h | short | 8.577 | 8.74307 | 8.20900 | C | weak | stopped | -1.10 |
| 2026-11-04T06:07 | DOGEUSDT | 1h | short | 0.0747 | 0.0760875 | 0.0716700 | C | mixed | stopped | -1.11 |
| 2026-11-04T06:07 | XRPUSDT | 1h | short | 1.2774 | 1.29690 | 1.23400 | C | weak | stopped | -1.13 |
| 2026-11-04T06:07 | BNBUSDT | 1h | short | 698.88 | 704.002 | 691.035 | B | weak | stopped | -1.27 |
| 2026-11-04T06:07 | ETHUSDT | 1h | short | 2293.01 | 2315.59 | 2266.43 | B | weak | stopped | -1.20 |
| 2026-11-04T06:07 | BTCUSDT | 1h | short | 77860.0 | 78433.0 | 76950.2 | 2 | weak | stopped | -1.27 |
| 2026-11-01T13:13 | UNIUSDT | 1h | short | 7.287 | 7.36811 | 7.07909 | 1 | weak | stopped | -1.18 |
| 2026-11-01T13:13 | BCHUSDT | 1h | long | 283.4 | 280.186 | 287.579 | A | mixed | stopped | -1.18 |
| 2026-11-01T13:13 | DOTUSDT | 1h | long | 0.949 | 0.866036 | 1.05300 | C | weak | expired | -0.13 |
| 2026-11-01T13:13 | AVAXUSDT | 1h | long | 8.789 | 8.35746 | 9.33100 | 3 | weak | stopped | -1.04 |
| 2026-11-01T13:13 | SOLUSDT | 1h | long | 94.92 | 92.1036 | 99.8700 | C | weak | stopped | -1.07 |
| 2026-11-01T13:13 | ETHUSDT | 1h | short | 2264.93 | 2383.50 | 2072.53 | 3 | weak | expired | -0.23 |
| 2026-10-31T02:18 | HBARUSDT | 1h | short | 0.0726 | 0.0735421 | 0.0698100 | B | weak | expired | +0.76 |
| 2026-10-31T02:18 | SUIUSDT | 1h | short | 0.9053 | 0.920907 | 0.871050 | 2 | mixed | expired | -0.06 |
| 2026-10-31T02:18 | NEARUSDT | 1h | short | 4.367 | 4.72825 | 3.65300 | 3 | weak | expired | +0.16 |
| 2026-10-31T02:18 | ADAUSDT | 1h | short | 0.1944 | 0.198061 | 0.189500 | B | mixed | expired | +0.09 |
| 2026-10-31T02:18 | SOLUSDT | 1h | short | 96.79 | 97.5679 | 95.3550 | B | weak | target | +1.60 |
| 2026-10-31T02:18 | BNBUSDT | 1h | short | 705.53 | 724.555 | 682.750 | 3 | weak | expired | -0.54 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
