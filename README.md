# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-02T10:55 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 247 | 5 | 22% | -0.25 | -0.42 | -104.6 | 107.2 |
| 1h | 210 | 4 | 22% | -0.23 | -0.42 | -89.1 | 90.0 |
| 4h | 37 | 1 | 23% | -0.34 | -0.42 | -15.5 | 24.7 |
| Evidence strong | 20 | 1 | 6% | -0.66 | -0.88 | -17.5 | 17.5 |
| Evidence mixed | 76 | 0 | 31% | -0.12 | -0.33 | -25.1 | 25.1 |
| Evidence weak | 151 | 4 | 20% | -0.26 | -0.41 | -62.0 | 69.2 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-01T13:13 | UNIUSDT | 1h | short | 7.287 | 7.36811 | 7.07909 | 1 | weak | stopped | -1.18 |
| 2026-11-01T13:13 | BCHUSDT | 1h | long | 283.4 | 280.186 | 287.579 | A | mixed | stopped | -1.18 |
| 2026-11-01T13:13 | DOTUSDT | 1h | long | 0.949 | 0.866036 | 1.05300 | C | weak | open | — |
| 2026-11-01T13:13 | AVAXUSDT | 1h | long | 8.789 | 8.35746 | 9.33100 | 3 | weak | open | — |
| 2026-11-01T13:13 | SOLUSDT | 1h | long | 94.92 | 92.1036 | 99.8700 | C | weak | open | — |
| 2026-11-01T13:13 | ETHUSDT | 1h | short | 2264.93 | 2383.50 | 2072.53 | 3 | weak | open | — |
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
| 2026-10-27T13:09 | LTCUSDT | 1h | short | 56.42 | 57.4939 | 55.2100 | 3 | weak | stopped | -1.11 |
| 2026-10-27T13:09 | TRXUSDT | 1h | short | 0.3286 | 0.330257 | 0.326000 | 3 | mixed | stopped | -1.40 |
| 2026-10-27T13:09 | ADAUSDT | 1h | short | 0.2043 | 0.209121 | 0.198900 | 3 | weak | stopped | -1.09 |
| 2026-10-27T13:09 | SOLUSDT | 1h | short | 100.68 | 103.070 | 97.6600 | 3 | weak | stopped | -1.09 |
| 2026-10-27T06:14 | AAVEUSDT | 1h | long | 131.93 | 131.174 | 135.022 | 1 | weak | stopped | -1.35 |
| 2026-10-27T06:14 | SUIUSDT | 1h | long | 0.91 | 0.895796 | 0.935700 | C | mixed | target | +1.68 |
| 2026-10-27T06:14 | NEARUSDT | 1h | long | 4.429 | 4.35582 | 4.58058 | 1 | weak | target | +1.95 |
| 2026-10-27T06:14 | DOTUSDT | 1h | long | 0.99 | 0.979750 | 1.02332 | 1 | weak | stopped | -1.19 |
| 2026-10-27T06:14 | XRPUSDT | 1h | short | 1.3011 | 1.31823 | 1.27706 | 1 | mixed | stopped | -1.15 |
| 2026-10-27T06:14 | BNBUSDT | 1h | long | 738.16 | 730.903 | 751.180 | C | mixed | target | +1.59 |
| 2026-10-26T06:13 | UNIUSDT | 1h | short | 6.941 | 7.08857 | 6.71617 | 1 | mixed | stopped | -1.10 |
| 2026-10-26T01:07 | AAVEUSDT | 1h | long | 135.3 | 133.299 | 150.408 | 1 | weak | stopped | -1.13 |
| 2026-10-26T01:07 | TRXUSDT | 1h | long | 0.3304 | 0.328421 | 0.333100 | 3 | mixed | stopped | -1.33 |
| 2026-10-25T16:07 | UNIUSDT | 4h | long | 6.873 | 6.42400 | 8.20673 | A | strong | stopped | -1.03 |
| 2026-10-25T16:07 | UNIUSDT | 1h | short | 6.873 | 6.93150 | 6.66078 | 1 | weak | stopped | -1.24 |
| 2026-10-25T16:07 | ADAUSDT | 4h | short | 0.2055 | 0.211746 | 0.196584 | 5 | mixed | target | +1.36 |
| 2026-10-25T16:07 | DOGEUSDT | 4h | long | 0.07721 | 0.0740907 | 0.0803544 | 1 | weak | target | +0.96 |
| 2026-10-25T16:07 | SOLUSDT | 4h | short | 101.54 | 109.959 | 92.1900 | C | strong | open | — |
| 2026-10-25T16:07 | ETHUSDT | 4h | short | 2345.21 | 2434.12 | 2236.21 | 3 | mixed | target | +1.17 |
| 2026-10-25T16:07 | BTCUSDT | 4h | short | 80612.44 | 82402.6 | 78193.6 | 3 | mixed | target | +1.26 |
| 2026-10-25T06:05 | HBARUSDT | 1h | long | 0.07722 | 0.0746539 | 0.0808400 | C | mixed | expired | -0.29 |
| 2026-10-25T06:05 | ADAUSDT | 1h | short | 0.2056 | 0.219575 | 0.191200 | 3 | mixed | expired | +0.09 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
