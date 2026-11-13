# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-13T00:15 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 327 | 23 | 23% | -0.27 | -0.42 | -137.5 | 144.6 |
| 1h | 276 | 12 | 23% | -0.23 | -0.40 | -111.3 | 118.4 |
| 4h | 51 | 11 | 20% | -0.44 | -0.51 | -26.2 | 26.2 |
| Evidence strong | 26 | 7 | 13% | -0.56 | -0.75 | -19.4 | 20.7 |
| Evidence mixed | 99 | 7 | 31% | -0.13 | -0.31 | -31.0 | 33.5 |
| Evidence weak | 202 | 9 | 19% | -0.29 | -0.43 | -87.1 | 91.3 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-13T00:15 | HBARUSDT | 4h | long | 0.0636 | 0.0622521 | 0.0809151 | A | strong | open | — |
| 2026-11-13T00:15 | AAVEUSDT | 4h | long | 114.23 | 109.305 | 131.854 | A | strong | open | — |
| 2026-11-13T00:15 | SUIUSDT | 1h | short | 0.8058 | 0.814314 | 0.780599 | 5 | strong | open | — |
| 2026-11-13T00:15 | NEARUSDT | 4h | long | 3.41 | 3.27943 | 3.56024 | 4 | mixed | open | — |
| 2026-11-13T00:15 | XLMUSDT | 1h | short | 0.1488 | 0.153579 | 0.140000 | C | weak | open | — |
| 2026-11-13T00:15 | BCHUSDT | 4h | long | 225.7 | 221.204 | 236.392 | 4 | mixed | open | — |
| 2026-11-13T00:15 | BCHUSDT | 1h | long | 225.7 | 222.021 | 244.554 | A | strong | open | — |
| 2026-11-13T00:15 | LTCUSDT | 1h | short | 50.12 | 51.9611 | 46.9100 | 3 | weak | open | — |
| 2026-11-13T00:15 | AVAXUSDT | 1h | short | 8.364 | 8.76075 | 7.94200 | C | mixed | open | — |
| 2026-11-13T00:15 | LINKUSDT | 4h | long | 10.142 | 9.67043 | 11.1253 | 1 | weak | open | — |
| 2026-11-13T00:15 | ADAUSDT | 4h | long | 0.175 | 0.165496 | 0.189059 | 4 | mixed | open | — |
| 2026-11-13T00:15 | DOGEUSDT | 4h | short | 0.06651 | 0.0672368 | 0.0638964 | 5 | mixed | open | — |
| 2026-11-13T00:15 | DOGEUSDT | 1h | short | 0.06651 | 0.0669243 | 0.0655400 | B | mixed | open | — |
| 2026-11-13T00:15 | XRPUSDT | 4h | long | 1.0411 | 1.00625 | 1.09310 | 4 | mixed | open | — |
| 2026-11-13T00:15 | SOLUSDT | 4h | long | 81.66 | 79.7396 | 87.3857 | A | strong | open | — |
| 2026-11-13T00:15 | BTCUSDT | 4h | long | 71340.95 | 70673.8 | 73492.6 | 4 | weak | open | — |
| 2026-11-13T00:15 | BTCUSDT | 1h | long | 71340.95 | 70860.6 | 72525.8 | A | strong | open | — |
| 2026-11-11T14:10 | HBARUSDT | 1h | short | 0.06614 | 0.0692068 | 0.0626000 | 3 | weak | open | — |
| 2026-11-11T14:10 | UNIUSDT | 1h | short | 6.467 | 6.66414 | 6.18172 | 5 | mixed | stopped | -1.07 |
| 2026-11-11T14:10 | XLMUSDT | 1h | short | 0.1496 | 0.151021 | 0.147641 | A | mixed | stopped | -1.21 |
| 2026-11-11T14:10 | LTCUSDT | 1h | short | 51.26 | 52.4739 | 48.5900 | 3 | weak | target | +2.12 |
| 2026-11-11T14:10 | DOTUSDT | 1h | short | 0.866 | 0.898929 | 0.800000 | 3 | weak | open | — |
| 2026-11-11T14:10 | TRXUSDT | 1h | long | 0.3172 | 0.301764 | 0.338000 | C | weak | open | — |
| 2026-11-11T14:10 | DOGEUSDT | 1h | short | 0.06819 | 0.0711800 | 0.0645600 | 3 | weak | target | +1.17 |
| 2026-11-11T14:10 | SOLUSDT | 1h | short | 84.16 | 85.1479 | 83.1400 | B | weak | stopped | -1.17 |
| 2026-11-11T14:10 | ETHUSDT | 1h | long | 2049.41 | 2002.60 | 2097.53 | 1 | weak | target | +0.94 |
| 2026-11-11T06:03 | NEARUSDT | 1h | short | 3.651 | 3.79979 | 3.43000 | C | weak | stopped | -1.05 |
| 2026-11-11T06:03 | DOTUSDT | 1h | long | 0.843 | 0.826643 | 0.869934 | 1 | mixed | stopped | -1.10 |
| 2026-11-11T06:03 | AVAXUSDT | 1h | short | 8.506 | 8.59536 | 8.34700 | B | weak | stopped | -1.19 |
| 2026-11-11T06:03 | LINKUSDT | 1h | short | 10.407 | 10.8815 | 9.72200 | 3 | weak | open | — |
| 2026-11-11T06:03 | ADAUSDT | 1h | short | 0.1755 | 0.184179 | 0.163700 | 3 | weak | open | — |
| 2026-11-11T06:03 | XRPUSDT | 1h | short | 1.0625 | 1.08196 | 1.03548 | 5 | strong | target | +1.28 |
| 2026-11-11T06:03 | BNBUSDT | 1h | short | 681.91 | 694.640 | 662.060 | 3 | mixed | target | +1.45 |
| 2026-11-10T23:14 | SUIUSDT | 1h | short | 0.8196 | 0.852811 | 0.782700 | 3 | mixed | stopped | -1.05 |
| 2026-11-10T23:14 | UNIUSDT | 1h | long | 6.629 | 6.54221 | 6.80500 | C | weak | target | +1.87 |
| 2026-11-10T23:14 | BCHUSDT | 1h | long | 230.5 | 224.943 | 246.593 | A | strong | stopped | -1.08 |
| 2026-11-10T23:14 | BTCUSDT | 1h | short | 73668.01 | 75888.8 | 71214.8 | 3 | mixed | target | +1.04 |
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

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
