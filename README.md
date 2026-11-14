# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-14T03:08 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 353 | 19 | 23% | -0.25 | -0.40 | -142.4 | 144.6 |
| 1h | 293 | 10 | 24% | -0.21 | -0.38 | -110.9 | 118.4 |
| 4h | 60 | 9 | 19% | -0.45 | -0.53 | -31.5 | 31.8 |
| Evidence strong | 32 | 7 | 14% | -0.52 | -0.70 | -22.4 | 22.9 |
| Evidence mixed | 108 | 7 | 32% | -0.11 | -0.29 | -31.1 | 33.5 |
| Evidence weak | 213 | 5 | 20% | -0.28 | -0.42 | -88.9 | 91.3 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-14T03:08 | UNIUSDT | 1h | long | 5.621 | 5.46029 | 6.14277 | A | strong | open | — |
| 2026-11-14T03:08 | BCHUSDT | 1h | long | 218.8 | 212.439 | 229.700 | C | weak | open | — |
| 2026-11-14T03:08 | DOTUSDT | 1h | long | 0.797 | 0.775000 | 0.837238 | 1 | weak | open | — |
| 2026-11-14T03:08 | BNBUSDT | 1h | long | 624.84 | 615.024 | 646.525 | A | strong | open | — |
| 2026-11-14T03:08 | ETHUSDT | 1h | long | 1910.49 | 1866.75 | 1982.63 | A | strong | open | — |
| 2026-11-14T03:08 | BTCUSDT | 1h | long | 67650.01 | 66611.5 | 70220.5 | A | strong | open | — |
| 2026-11-13T16:15 | HBARUSDT | 4h | long | 0.06285 | 0.0598593 | 0.0795184 | A | strong | open | — |
| 2026-11-13T16:15 | HBARUSDT | 1h | long | 0.06285 | 0.0601407 | 0.0657570 | 1 | mixed | stopped | -1.05 |
| 2026-11-13T16:15 | AAVEUSDT | 1h | long | 111.5 | 108.395 | 117.040 | C | weak | stopped | -1.07 |
| 2026-11-13T16:15 | SUIUSDT | 1h | long | 0.8078 | 0.758611 | 0.861900 | C | mixed | open | — |
| 2026-11-13T16:15 | UNIUSDT | 1h | long | 5.804 | 5.57464 | 6.11800 | C | weak | stopped | -1.05 |
| 2026-11-13T16:15 | NEARUSDT | 1h | long | 3.502 | 3.22132 | 3.82000 | C | mixed | open | — |
| 2026-11-13T16:15 | DOTUSDT | 4h | long | 0.827 | 0.786143 | 0.955912 | A | strong | open | — |
| 2026-11-13T16:15 | DOTUSDT | 1h | long | 0.827 | 0.790643 | 0.873000 | 3 | weak | stopped | -1.04 |
| 2026-11-13T16:15 | AVAXUSDT | 4h | long | 8.333 | 7.65850 | 9.24100 | C | mixed | open | — |
| 2026-11-13T16:15 | LINKUSDT | 4h | long | 9.883 | 9.49464 | 11.0691 | 1 | mixed | open | — |
| 2026-11-13T16:15 | TRXUSDT | 4h | long | 0.3133 | 0.301375 | 0.332900 | C | mixed | open | — |
| 2026-11-13T16:15 | ADAUSDT | 1h | long | 0.1714 | 0.164700 | 0.178100 | 3 | weak | stopped | -1.05 |
| 2026-11-13T16:15 | DOGEUSDT | 4h | long | 0.06495 | 0.0622057 | 0.0678860 | 1 | weak | open | — |
| 2026-11-13T16:15 | XRPUSDT | 4h | long | 1.0155 | 0.985704 | 1.07866 | 4 | mixed | open | — |
| 2026-11-13T16:15 | BNBUSDT | 1h | long | 631.29 | 624.679 | 653.119 | A | mixed | stopped | -1.19 |
| 2026-11-13T16:15 | BTCUSDT | 1h | long | 68600.58 | 67688.7 | 70954.7 | A | mixed | stopped | -1.15 |
| 2026-11-13T00:15 | HBARUSDT | 4h | long | 0.0636 | 0.0622521 | 0.0809151 | A | strong | stopped | -1.09 |
| 2026-11-13T00:15 | AAVEUSDT | 4h | long | 114.23 | 109.305 | 131.854 | A | strong | open | — |
| 2026-11-13T00:15 | SUIUSDT | 1h | short | 0.8058 | 0.814314 | 0.780599 | 5 | strong | target | +2.77 |
| 2026-11-13T00:15 | NEARUSDT | 4h | long | 3.41 | 3.27943 | 3.56024 | 4 | mixed | stopped | -1.05 |
| 2026-11-13T00:15 | XLMUSDT | 1h | short | 0.1488 | 0.153579 | 0.140000 | C | weak | open | — |
| 2026-11-13T00:15 | BCHUSDT | 4h | long | 225.7 | 221.204 | 236.392 | 4 | mixed | stopped | -1.10 |
| 2026-11-13T00:15 | BCHUSDT | 1h | long | 225.7 | 222.021 | 244.554 | A | strong | stopped | -1.12 |
| 2026-11-13T00:15 | LTCUSDT | 1h | short | 50.12 | 51.9611 | 46.9100 | 3 | weak | open | — |
| 2026-11-13T00:15 | AVAXUSDT | 1h | short | 8.364 | 8.76075 | 7.94200 | C | mixed | target | +1.02 |
| 2026-11-13T00:15 | LINKUSDT | 4h | long | 10.142 | 9.67043 | 11.1253 | 1 | weak | stopped | -1.04 |
| 2026-11-13T00:15 | ADAUSDT | 4h | long | 0.175 | 0.165496 | 0.189059 | 4 | mixed | open | — |
| 2026-11-13T00:15 | DOGEUSDT | 4h | short | 0.06651 | 0.0672368 | 0.0638964 | 5 | mixed | target | +3.42 |
| 2026-11-13T00:15 | DOGEUSDT | 1h | short | 0.06651 | 0.0669243 | 0.0655400 | B | mixed | target | +2.02 |
| 2026-11-13T00:15 | XRPUSDT | 4h | long | 1.0411 | 1.00625 | 1.09310 | 4 | mixed | stopped | -1.06 |
| 2026-11-13T00:15 | SOLUSDT | 4h | long | 81.66 | 79.7396 | 87.3857 | A | strong | stopped | -1.08 |
| 2026-11-13T00:15 | BTCUSDT | 4h | long | 71340.95 | 70673.8 | 73492.6 | 4 | weak | stopped | -1.21 |
| 2026-11-13T00:15 | BTCUSDT | 1h | long | 71340.95 | 70860.6 | 72525.8 | A | strong | stopped | -1.30 |
| 2026-11-11T14:10 | HBARUSDT | 1h | short | 0.06614 | 0.0692068 | 0.0626000 | 3 | weak | target | +1.11 |
| 2026-11-11T14:10 | UNIUSDT | 1h | short | 6.467 | 6.66414 | 6.18172 | 5 | mixed | stopped | -1.07 |
| 2026-11-11T14:10 | XLMUSDT | 1h | short | 0.1496 | 0.151021 | 0.147641 | A | mixed | stopped | -1.21 |
| 2026-11-11T14:10 | LTCUSDT | 1h | short | 51.26 | 52.4739 | 48.5900 | 3 | weak | target | +2.12 |
| 2026-11-11T14:10 | DOTUSDT | 1h | short | 0.866 | 0.898929 | 0.800000 | 3 | weak | target | +1.95 |
| 2026-11-11T14:10 | TRXUSDT | 1h | long | 0.3172 | 0.301764 | 0.338000 | C | weak | expired | -0.30 |
| 2026-11-11T14:10 | DOGEUSDT | 1h | short | 0.06819 | 0.0711800 | 0.0645600 | 3 | weak | target | +1.17 |
| 2026-11-11T14:10 | SOLUSDT | 1h | short | 84.16 | 85.1479 | 83.1400 | B | weak | stopped | -1.17 |
| 2026-11-11T14:10 | ETHUSDT | 1h | long | 2049.41 | 2002.60 | 2097.53 | 1 | weak | target | +0.94 |
| 2026-11-11T06:03 | NEARUSDT | 1h | short | 3.651 | 3.79979 | 3.43000 | C | weak | stopped | -1.05 |
| 2026-11-11T06:03 | DOTUSDT | 1h | long | 0.843 | 0.826643 | 0.869934 | 1 | mixed | stopped | -1.10 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
