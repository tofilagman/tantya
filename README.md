# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-12T02:55 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 321 | 12 | 21% | -0.29 | -0.45 | -143.6 | 144.4 |
| 1h | 271 | 10 | 21% | -0.26 | -0.44 | -118.4 | 118.4 |
| 4h | 50 | 2 | 21% | -0.43 | -0.50 | -25.2 | 26.1 |
| Evidence strong | 25 | 2 | 9% | -0.64 | -0.83 | -20.7 | 20.7 |
| Evidence mixed | 97 | 2 | 30% | -0.16 | -0.35 | -33.5 | 33.5 |
| Evidence weak | 199 | 8 | 18% | -0.31 | -0.45 | -89.4 | 91.3 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-11T14:10 | HBARUSDT | 1h | short | 0.06614 | 0.0692068 | 0.0626000 | 3 | weak | open | — |
| 2026-11-11T14:10 | UNIUSDT | 1h | short | 6.467 | 6.66414 | 6.18172 | 5 | mixed | stopped | -1.07 |
| 2026-11-11T14:10 | XLMUSDT | 1h | short | 0.1496 | 0.151021 | 0.147641 | A | mixed | stopped | -1.21 |
| 2026-11-11T14:10 | LTCUSDT | 1h | short | 51.26 | 52.4739 | 48.5900 | 3 | weak | open | — |
| 2026-11-11T14:10 | DOTUSDT | 1h | short | 0.866 | 0.898929 | 0.800000 | 3 | weak | open | — |
| 2026-11-11T14:10 | TRXUSDT | 1h | long | 0.3172 | 0.301764 | 0.338000 | C | weak | open | — |
| 2026-11-11T14:10 | DOGEUSDT | 1h | short | 0.06819 | 0.0711800 | 0.0645600 | 3 | weak | open | — |
| 2026-11-11T14:10 | SOLUSDT | 1h | short | 84.16 | 85.1479 | 83.1400 | B | weak | stopped | -1.17 |
| 2026-11-11T14:10 | ETHUSDT | 1h | long | 2049.41 | 2002.60 | 2097.53 | 1 | weak | target | +0.94 |
| 2026-11-11T06:03 | NEARUSDT | 1h | short | 3.651 | 3.79979 | 3.43000 | C | weak | stopped | -1.05 |
| 2026-11-11T06:03 | DOTUSDT | 1h | long | 0.843 | 0.826643 | 0.869934 | 1 | mixed | stopped | -1.10 |
| 2026-11-11T06:03 | AVAXUSDT | 1h | short | 8.506 | 8.59536 | 8.34700 | B | weak | stopped | -1.19 |
| 2026-11-11T06:03 | LINKUSDT | 1h | short | 10.407 | 10.8815 | 9.72200 | 3 | weak | open | — |
| 2026-11-11T06:03 | ADAUSDT | 1h | short | 0.1755 | 0.184179 | 0.163700 | 3 | weak | open | — |
| 2026-11-11T06:03 | XRPUSDT | 1h | short | 1.0625 | 1.08196 | 1.03548 | 5 | strong | open | — |
| 2026-11-11T06:03 | BNBUSDT | 1h | short | 681.91 | 694.640 | 662.060 | 3 | mixed | open | — |
| 2026-11-10T23:14 | SUIUSDT | 1h | short | 0.8196 | 0.852811 | 0.782700 | 3 | mixed | stopped | -1.05 |
| 2026-11-10T23:14 | UNIUSDT | 1h | long | 6.629 | 6.54221 | 6.80500 | C | weak | target | +1.87 |
| 2026-11-10T23:14 | BCHUSDT | 1h | long | 230.5 | 224.943 | 246.593 | A | strong | stopped | -1.08 |
| 2026-11-10T23:14 | BTCUSDT | 1h | short | 73668.01 | 75888.8 | 71214.8 | 3 | mixed | open | — |
| 2026-11-09T06:13 | HBARUSDT | 1h | short | 0.06627 | 0.0696364 | 0.0621900 | 3 | weak | expired | +0.18 |
| 2026-11-09T06:13 | AAVEUSDT | 1h | short | 129.3 | 134.621 | 121.690 | C | weak | stopped | -1.05 |
| 2026-11-09T06:13 | LTCUSDT | 1h | short | 50.61 | 53.8132 | 46.9400 | 3 | mixed | expired | -0.09 |
| 2026-11-09T06:13 | DOGEUSDT | 1h | short | 0.06914 | 0.0738379 | 0.0643600 | 3 | mixed | expired | +0.18 |
| 2026-11-09T06:13 | ETHUSDT | 1h | short | 2131.58 | 2269.01 | 1974.09 | 3 | weak | expired | +0.42 |
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
| 2026-11-07T20:12 | AAVEUSDT | 4h | short | 131.12 | 143.099 | 119.140 | C | weak | target | +0.98 |
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

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
