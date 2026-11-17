# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-17T22:15 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 393 | 10 | 23% | -0.25 | -0.41 | -160.6 | 173.2 |
| 1h | 325 | 9 | 25% | -0.19 | -0.37 | -120.7 | 133.3 |
| 4h | 68 | 1 | 17% | -0.51 | -0.59 | -39.9 | 39.9 |
| Evidence strong | 41 | 5 | 11% | -0.63 | -0.90 | -37.0 | 37.0 |
| Evidence mixed | 126 | 2 | 31% | -0.09 | -0.26 | -33.0 | 41.3 |
| Evidence weak | 226 | 3 | 21% | -0.27 | -0.40 | -90.7 | 94.8 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-17T22:15 | XRPUSDT | 1h | short | 0.9708 | 0.985000 | 0.956496 | 1 | mixed | open | — |
| 2026-11-17T13:14 | AAVEUSDT | 1h | short | 113.83 | 135.460 | 76.2100 | 3 | weak | open | — |
| 2026-11-17T13:14 | SUIUSDT | 1h | short | 0.7397 | 0.769307 | 0.685345 | 5 | strong | open | — |
| 2026-11-17T13:14 | UNIUSDT | 1h | short | 5.406 | 5.44704 | 5.01450 | B | weak | stopped | -1.26 |
| 2026-11-17T13:14 | NEARUSDT | 1h | short | 3.264 | 3.34079 | 3.14377 | A | mixed | target | +1.48 |
| 2026-11-17T13:14 | XLMUSDT | 1h | short | 0.1411 | 0.151296 | 0.121500 | 3 | weak | open | — |
| 2026-11-17T13:14 | BCHUSDT | 1h | short | 212.8 | 213.361 | 204.100 | B | mixed | stopped | -1.76 |
| 2026-11-17T13:14 | SOLUSDT | 1h | short | 73.93 | 78.2896 | 68.9993 | 5 | strong | open | — |
| 2026-11-17T13:14 | BNBUSDT | 1h | short | 593.13 | 601.478 | 582.860 | B | mixed | target | +1.09 |
| 2026-11-16T11:03 | HBARUSDT | 1h | short | 0.05823 | 0.0609432 | 0.0553650 | 5 | strong | open | — |
| 2026-11-16T11:03 | AAVEUSDT | 1h | short | 109.94 | 111.121 | 103.525 | B | mixed | stopped | -1.19 |
| 2026-11-16T11:03 | LINKUSDT | 1h | short | 9.188 | 9.67450 | 8.62807 | 5 | strong | open | — |
| 2026-11-16T11:03 | TRXUSDT | 1h | long | 0.3038 | 0.301807 | 0.309252 | A | strong | open | — |
| 2026-11-16T11:03 | BTCUSDT | 1h | short | 64602.17 | 70474.2 | 57923.7 | 3 | weak | open | — |
| 2026-11-14T22:17 | HBARUSDT | 1h | long | 0.0553 | 0.0546589 | 0.0574031 | 4 | weak | target | +3.10 |
| 2026-11-14T22:17 | SUIUSDT | 1h | long | 0.683 | 0.668993 | 0.729183 | A | mixed | target | +3.20 |
| 2026-11-14T22:17 | UNIUSDT | 1h | long | 4.729 | 4.55575 | 5.15647 | A | mixed | target | +2.41 |
| 2026-11-14T22:17 | NEARUSDT | 1h | long | 2.948 | 2.83096 | 3.07361 | A | mixed | target | +1.02 |
| 2026-11-14T22:17 | BCHUSDT | 1h | long | 198.4 | 195.239 | 232.817 | A | mixed | expired | +3.10 |
| 2026-11-14T22:17 | LTCUSDT | 1h | long | 43.81 | 43.1489 | 45.6003 | 4 | weak | stopped | -1.13 |
| 2026-11-14T22:17 | DOTUSDT | 1h | long | 0.693 | 0.681679 | 0.750360 | 4 | weak | stopped | -1.12 |
| 2026-11-14T22:17 | AVAXUSDT | 1h | long | 7.01 | 6.90986 | 7.61383 | A | weak | stopped | -1.14 |
| 2026-11-14T22:17 | LINKUSDT | 1h | long | 8.675 | 8.54132 | 9.00697 | 4 | weak | target | +2.35 |
| 2026-11-14T22:17 | TRXUSDT | 1h | long | 0.3067 | 0.306232 | 0.312224 | A | strong | stopped | -2.31 |
| 2026-11-14T22:17 | ADAUSDT | 1h | long | 0.1445 | 0.143268 | 0.152684 | A | mixed | stopped | -1.23 |
| 2026-11-14T22:17 | DOGEUSDT | 1h | long | 0.05587 | 0.0555093 | 0.0600939 | A | weak | stopped | -1.31 |
| 2026-11-14T22:17 | XRPUSDT | 1h | long | 0.8994 | 0.896118 | 0.937198 | 4 | weak | stopped | -1.55 |
| 2026-11-14T22:17 | SOLUSDT | 1h | long | 69.13 | 68.2850 | 74.0370 | A | mixed | stopped | -1.16 |
| 2026-11-14T22:17 | BNBUSDT | 1h | long | 572.03 | 568.092 | 618.084 | A | mixed | stopped | -1.29 |
| 2026-11-14T22:17 | ETHUSDT | 1h | long | 1750.65 | 1737.69 | 1910.93 | A | mixed | stopped | -1.27 |
| 2026-11-14T22:17 | BTCUSDT | 1h | long | 63629.28 | 63595.6 | 68448.0 | A | strong | stopped | -4.77 |
| 2026-11-14T03:08 | UNIUSDT | 1h | long | 5.621 | 5.46029 | 6.14277 | A | strong | stopped | -1.07 |
| 2026-11-14T03:08 | BCHUSDT | 1h | long | 218.8 | 212.439 | 229.700 | C | weak | stopped | -1.07 |
| 2026-11-14T03:08 | DOTUSDT | 1h | long | 0.797 | 0.775000 | 0.837238 | 1 | weak | stopped | -1.07 |
| 2026-11-14T03:08 | BNBUSDT | 1h | long | 624.84 | 615.024 | 646.525 | A | strong | stopped | -1.13 |
| 2026-11-14T03:08 | ETHUSDT | 1h | long | 1910.49 | 1866.75 | 1982.63 | A | strong | stopped | -1.09 |
| 2026-11-14T03:08 | BTCUSDT | 1h | long | 67650.01 | 66611.5 | 70220.5 | A | strong | stopped | -1.13 |
| 2026-11-13T16:15 | HBARUSDT | 4h | long | 0.06285 | 0.0598593 | 0.0795184 | A | strong | stopped | -1.04 |
| 2026-11-13T16:15 | HBARUSDT | 1h | long | 0.06285 | 0.0601407 | 0.0657570 | 1 | mixed | stopped | -1.05 |
| 2026-11-13T16:15 | AAVEUSDT | 1h | long | 111.5 | 108.395 | 117.040 | C | weak | stopped | -1.07 |
| 2026-11-13T16:15 | SUIUSDT | 1h | long | 0.8078 | 0.758611 | 0.861900 | C | mixed | stopped | -1.03 |
| 2026-11-13T16:15 | UNIUSDT | 1h | long | 5.804 | 5.57464 | 6.11800 | C | weak | stopped | -1.05 |
| 2026-11-13T16:15 | NEARUSDT | 1h | long | 3.502 | 3.22132 | 3.82000 | C | mixed | stopped | -1.02 |
| 2026-11-13T16:15 | DOTUSDT | 4h | long | 0.827 | 0.786143 | 0.955912 | A | strong | stopped | -1.04 |
| 2026-11-13T16:15 | DOTUSDT | 1h | long | 0.827 | 0.790643 | 0.873000 | 3 | weak | stopped | -1.04 |
| 2026-11-13T16:15 | AVAXUSDT | 4h | long | 8.333 | 7.65850 | 9.24100 | C | mixed | stopped | -1.02 |
| 2026-11-13T16:15 | LINKUSDT | 4h | long | 9.883 | 9.49464 | 11.0691 | 1 | mixed | stopped | -1.05 |
| 2026-11-13T16:15 | TRXUSDT | 4h | long | 0.3133 | 0.301375 | 0.332900 | C | mixed | open | — |
| 2026-11-13T16:15 | ADAUSDT | 1h | long | 0.1714 | 0.164700 | 0.178100 | 3 | weak | stopped | -1.05 |
| 2026-11-13T16:15 | DOGEUSDT | 4h | long | 0.06495 | 0.0622057 | 0.0678860 | 1 | weak | stopped | -1.05 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
