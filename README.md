# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-28T12:44 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 215 | 10 | 21% | -0.28 | -0.45 | -96.8 | 110.5 |
| 1h | 185 | 2 | 22% | -0.24 | -0.43 | -78.9 | 85.8 |
| 4h | 30 | 8 | 14% | -0.51 | -0.60 | -17.9 | 24.7 |
| Evidence strong | 17 | 2 | 7% | -0.66 | -0.91 | -15.4 | 16.7 |
| Evidence mixed | 62 | 4 | 29% | -0.14 | -0.34 | -21.1 | 24.6 |
| Evidence weak | 136 | 4 | 18% | -0.29 | -0.44 | -60.3 | 66.0 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-27T13:09 | HBARUSDT | 1h | long | 0.07614 | 0.0751914 | 0.0774505 | 1 | mixed | open | — |
| 2026-10-27T13:09 | LTCUSDT | 1h | short | 56.42 | 57.4939 | 55.2100 | 3 | weak | stopped | -1.11 |
| 2026-10-27T13:09 | TRXUSDT | 1h | short | 0.3286 | 0.330257 | 0.326000 | 3 | mixed | stopped | -1.40 |
| 2026-10-27T13:09 | ADAUSDT | 1h | short | 0.2043 | 0.209121 | 0.198900 | 3 | weak | open | — |
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
| 2026-10-25T16:07 | UNIUSDT | 4h | long | 6.873 | 6.42400 | 8.20673 | A | strong | open | — |
| 2026-10-25T16:07 | UNIUSDT | 1h | short | 6.873 | 6.93150 | 6.66078 | 1 | weak | stopped | -1.24 |
| 2026-10-25T16:07 | ADAUSDT | 4h | short | 0.2055 | 0.211746 | 0.196584 | 5 | mixed | open | — |
| 2026-10-25T16:07 | DOGEUSDT | 4h | long | 0.07721 | 0.0740907 | 0.0803544 | 1 | weak | target | +0.96 |
| 2026-10-25T16:07 | SOLUSDT | 4h | short | 101.54 | 109.959 | 92.1900 | C | strong | open | — |
| 2026-10-25T16:07 | ETHUSDT | 4h | short | 2345.21 | 2434.12 | 2236.21 | 3 | mixed | open | — |
| 2026-10-25T16:07 | BTCUSDT | 4h | short | 80612.44 | 82402.6 | 78193.6 | 3 | mixed | open | — |
| 2026-10-25T06:05 | HBARUSDT | 1h | long | 0.07722 | 0.0746539 | 0.0808400 | C | mixed | expired | -0.29 |
| 2026-10-25T06:05 | ADAUSDT | 1h | short | 0.2056 | 0.219575 | 0.191200 | 3 | mixed | expired | +0.09 |
| 2026-10-25T06:05 | DOGEUSDT | 1h | long | 0.07694 | 0.0745411 | 0.0803544 | 1 | mixed | expired | +0.14 |
| 2026-10-25T06:05 | BNBUSDT | 1h | short | 743.05 | 750.420 | 733.325 | 2 | weak | target | +1.12 |
| 2026-10-25T01:05 | HBARUSDT | 1h | short | 0.07797 | 0.0785046 | 0.0765600 | B | weak | stopped | -1.29 |
| 2026-10-25T01:05 | NEARUSDT | 1h | short | 4.506 | 5.04864 | 3.77100 | C | mixed | expired | +0.07 |
| 2026-10-25T01:05 | XLMUSDT | 1h | short | 0.172 | 0.179643 | 0.159600 | 3 | weak | expired | +0.44 |
| 2026-10-25T01:05 | BCHUSDT | 1h | short | 277.3 | 284.089 | 263.700 | 3 | weak | stopped | -1.08 |
| 2026-10-25T01:05 | LTCUSDT | 1h | short | 57.04 | 57.3929 | 56.1300 | B | weak | target | +2.26 |
| 2026-10-25T01:05 | DOTUSDT | 1h | short | 1.053 | 1.10025 | 0.983000 | 3 | mixed | expired | +1.14 |
| 2026-10-25T01:05 | AVAXUSDT | 1h | short | 9.011 | 9.39054 | 8.35300 | 3 | weak | expired | +0.44 |
| 2026-10-25T01:05 | LINKUSDT | 1h | short | 11.621 | 11.8309 | 11.0128 | 5 | strong | expired | +1.31 |
| 2026-10-25T01:05 | XRPUSDT | 1h | short | 1.3041 | 1.33565 | 1.23070 | 3 | weak | expired | +0.06 |
| 2026-10-25T01:05 | SOLUSDT | 1h | short | 102.38 | 105.630 | 95.9900 | 3 | weak | expired | +0.58 |
| 2026-10-25T01:05 | BNBUSDT | 1h | short | 741.3 | 744.714 | 730.405 | 2 | weak | stopped | -1.44 |
| 2026-10-25T01:05 | ETHUSDT | 1h | short | 2358.6 | 2426.66 | 2228.17 | 3 | weak | expired | +0.59 |
| 2026-10-25T01:05 | BTCUSDT | 1h | short | 80820.0 | 82241.9 | 78093.4 | 3 | weak | expired | +0.59 |
| 2026-10-24T07:15 | DOTUSDT | 1h | long | 1.076 | 1.05993 | 1.10100 | C | weak | stopped | -1.13 |
| 2026-10-24T07:15 | ETHUSDT | 1h | short | 2379.8 | 2424.75 | 2324.02 | 3 | mixed | target | +1.14 |
| 2026-10-23T23:06 | SUIUSDT | 1h | long | 0.9457 | 0.933786 | 1.01206 | 1 | weak | stopped | -1.16 |
| 2026-10-23T23:06 | SOLUSDT | 1h | long | 102.07 | 101.313 | 103.071 | A | weak | target | +1.05 |
| 2026-10-23T15:00 | SUIUSDT | 1h | long | 0.9896 | 0.960671 | 1.02170 | C | mixed | stopped | -1.07 |
| 2026-10-23T15:00 | AVAXUSDT | 1h | long | 9.119 | 8.93779 | 9.51850 | 2 | weak | stopped | -1.10 |
| 2026-10-23T10:01 | HBARUSDT | 1h | long | 0.07903 | 0.0782607 | 0.0822000 | C | weak | stopped | -1.20 |
| 2026-10-23T10:01 | UNIUSDT | 1h | short | 7.17 | 7.77525 | 6.45700 | 3 | weak | expired | +0.65 |
| 2026-10-23T10:01 | BCHUSDT | 1h | short | 286.6 | 292.282 | 269.700 | C | mixed | target | +2.88 |
| 2026-10-23T10:01 | AVAXUSDT | 1h | long | 9.221 | 9.01789 | 9.47200 | C | mixed | stopped | -1.09 |
| 2026-10-23T10:01 | LINKUSDT | 1h | short | 12.091 | 12.8620 | 11.2500 | 3 | weak | target | +1.06 |
| 2026-10-23T10:01 | TRXUSDT | 1h | short | 0.3297 | 0.331636 | 0.326500 | 3 | weak | expired | -0.13 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
