# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-25T06:05 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 181 | 23 | 18% | -0.39 | -0.57 | -102.5 | 109.4 |
| 1h | 155 | 17 | 21% | -0.32 | -0.52 | -80.0 | 85.8 |
| 4h | 26 | 6 | 8% | -0.80 | -0.87 | -22.5 | 24.7 |
| Evidence strong | 16 | 1 | 7% | -0.79 | -1.04 | -16.7 | 16.7 |
| Evidence mixed | 51 | 5 | 28% | -0.19 | -0.40 | -20.5 | 24.6 |
| Evidence weak | 114 | 17 | 15% | -0.42 | -0.57 | -65.3 | 69.2 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-25T06:05 | HBARUSDT | 1h | long | 0.07722 | 0.0746539 | 0.0808400 | C | mixed | open | — |
| 2026-10-25T06:05 | ADAUSDT | 1h | short | 0.2056 | 0.219575 | 0.191200 | 3 | mixed | open | — |
| 2026-10-25T06:05 | DOGEUSDT | 1h | long | 0.07694 | 0.0745411 | 0.0803544 | 1 | mixed | open | — |
| 2026-10-25T06:05 | BNBUSDT | 1h | short | 743.05 | 750.420 | 733.325 | 2 | weak | open | — |
| 2026-10-25T01:05 | HBARUSDT | 1h | short | 0.07797 | 0.0785046 | 0.0765600 | B | weak | stopped | -1.29 |
| 2026-10-25T01:05 | NEARUSDT | 1h | short | 4.506 | 5.04864 | 3.77100 | C | mixed | open | — |
| 2026-10-25T01:05 | XLMUSDT | 1h | short | 0.172 | 0.179643 | 0.159600 | 3 | weak | open | — |
| 2026-10-25T01:05 | BCHUSDT | 1h | short | 277.3 | 284.089 | 263.700 | 3 | weak | open | — |
| 2026-10-25T01:05 | LTCUSDT | 1h | short | 57.04 | 57.3929 | 56.1300 | B | weak | open | — |
| 2026-10-25T01:05 | DOTUSDT | 1h | short | 1.053 | 1.10025 | 0.983000 | 3 | mixed | open | — |
| 2026-10-25T01:05 | AVAXUSDT | 1h | short | 9.011 | 9.39054 | 8.35300 | 3 | weak | open | — |
| 2026-10-25T01:05 | LINKUSDT | 1h | short | 11.621 | 11.8309 | 11.0128 | 5 | strong | open | — |
| 2026-10-25T01:05 | XRPUSDT | 1h | short | 1.3041 | 1.33565 | 1.23070 | 3 | weak | open | — |
| 2026-10-25T01:05 | SOLUSDT | 1h | short | 102.38 | 105.630 | 95.9900 | 3 | weak | open | — |
| 2026-10-25T01:05 | BNBUSDT | 1h | short | 741.3 | 744.714 | 730.405 | 2 | weak | stopped | -1.44 |
| 2026-10-25T01:05 | ETHUSDT | 1h | short | 2358.6 | 2426.66 | 2228.17 | 3 | weak | open | — |
| 2026-10-25T01:05 | BTCUSDT | 1h | short | 80820.0 | 82241.9 | 78093.4 | 3 | weak | open | — |
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

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
