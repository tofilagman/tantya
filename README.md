# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-04T21:16 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 263 | 11 | 21% | -0.28 | -0.45 | -118.7 | 118.7 |
| 1h | 225 | 11 | 21% | -0.28 | -0.46 | -104.3 | 104.3 |
| 4h | 38 | 0 | 25% | -0.31 | -0.38 | -14.4 | 24.7 |
| Evidence strong | 22 | 0 | 11% | -0.59 | -0.80 | -17.5 | 17.5 |
| Evidence mixed | 78 | 4 | 30% | -0.15 | -0.35 | -27.4 | 27.4 |
| Evidence weak | 163 | 7 | 18% | -0.30 | -0.45 | -73.9 | 73.9 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-04T21:16 | HBARUSDT | 1h | short | 0.07212 | 0.0745557 | 0.0693647 | 1 | mixed | open | — |
| 2026-11-04T21:16 | AAVEUSDT | 1h | long | 130.52 | 122.234 | 143.360 | 3 | weak | open | — |
| 2026-11-04T21:16 | UNIUSDT | 1h | short | 7.603 | 7.85171 | 7.18183 | 1 | weak | open | — |
| 2026-11-04T21:16 | NEARUSDT | 1h | short | 4.036 | 4.61536 | 3.39100 | 3 | weak | open | — |
| 2026-11-04T21:16 | BCHUSDT | 1h | short | 281.1 | 299.661 | 253.300 | 3 | weak | open | — |
| 2026-11-04T21:16 | LTCUSDT | 1h | long | 56.08 | 54.1536 | 58.0900 | 3 | weak | open | — |
| 2026-11-04T21:16 | AVAXUSDT | 1h | long | 8.758 | 8.22018 | 9.57700 | 3 | weak | open | — |
| 2026-11-04T21:16 | LINKUSDT | 1h | long | 11.457 | 10.5499 | 12.4940 | C | mixed | open | — |
| 2026-11-04T21:16 | XRPUSDT | 1h | long | 1.3051 | 1.28449 | 1.33175 | 5 | mixed | open | — |
| 2026-11-04T21:16 | SOLUSDT | 1h | long | 94.99 | 89.2907 | 102.610 | 3 | weak | open | — |
| 2026-11-04T21:16 | BNBUSDT | 1h | short | 718.48 | 724.008 | 701.165 | B | mixed | open | — |
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
| 2026-10-31T02:18 | ETHUSDT | 1h | short | 2247.29 | 2271.47 | 2207.85 | 1 | mixed | stopped | -1.19 |
| 2026-10-29T23:15 | AAVEUSDT | 1h | long | 119.78 | 117.825 | 131.357 | 1 | weak | stopped | -1.12 |
| 2026-10-29T23:15 | SUIUSDT | 1h | long | 0.8817 | 0.849571 | 0.924508 | 1 | mixed | stopped | -1.05 |
| 2026-10-29T23:15 | UNIUSDT | 1h | long | 6.388 | 6.14900 | 6.80300 | C | weak | target | +1.68 |
| 2026-10-29T23:15 | AVAXUSDT | 1h | long | 8.34 | 8.17936 | 8.81705 | 1 | mixed | stopped | -1.10 |
| 2026-10-29T23:15 | LINKUSDT | 1h | long | 10.702 | 10.6044 | 11.2107 | A | mixed | stopped | -1.22 |
| 2026-10-29T23:15 | DOGEUSDT | 1h | short | 0.07607 | 0.0801189 | 0.0718200 | 3 | strong | expired | +0.03 |
| 2026-10-29T23:15 | ETHUSDT | 1h | long | 2267.97 | 2219.13 | 2330.98 | 1 | mixed | stopped | -1.09 |
| 2026-10-28T23:09 | BCHUSDT | 1h | short | 290.3 | 306.796 | 270.100 | C | mixed | target | +1.19 |
| 2026-10-28T23:09 | TRXUSDT | 1h | short | 0.33 | 0.330321 | 0.329650 | B | mixed | target | -0.96 |
| 2026-10-28T23:09 | ADAUSDT | 1h | long | 0.206 | 0.199489 | 0.214800 | 3 | weak | stopped | -1.06 |
| 2026-10-28T23:09 | XRPUSDT | 1h | long | 1.327 | 1.30288 | 1.36160 | C | strong | stopped | -1.11 |
| 2026-10-28T23:09 | SOLUSDT | 1h | long | 102.51 | 100.020 | 105.560 | 3 | weak | stopped | -1.08 |
| 2026-10-28T23:09 | BNBUSDT | 1h | short | 757.35 | 761.744 | 748.582 | 1 | weak | target | +1.65 |
| 2026-10-28T23:09 | ETHUSDT | 1h | long | 2361.56 | 2314.25 | 2423.56 | 3 | weak | stopped | -1.10 |
| 2026-10-27T13:09 | HBARUSDT | 1h | long | 0.07614 | 0.0751914 | 0.0774505 | 1 | mixed | stopped | -1.16 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
