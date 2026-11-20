# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-20T11:33 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 412 | 16 | 24% | -0.23 | -0.39 | -158.9 | 173.2 |
| 1h | 342 | 11 | 25% | -0.17 | -0.35 | -119.0 | 133.3 |
| 4h | 70 | 5 | 18% | -0.50 | -0.57 | -39.9 | 39.9 |
| Evidence strong | 46 | 6 | 13% | -0.48 | -0.74 | -34.0 | 37.0 |
| Evidence mixed | 129 | 4 | 31% | -0.09 | -0.27 | -34.5 | 41.3 |
| Evidence weak | 237 | 6 | 22% | -0.25 | -0.38 | -90.4 | 94.8 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-20T03:05 | HBARUSDT | 1h | long | 0.05315 | 0.0524329 | 0.0589949 | A | strong | open | — |
| 2026-11-20T03:05 | SUIUSDT | 1h | long | 0.6996 | 0.690168 | 0.725806 | 1 | weak | stopped | -1.15 |
| 2026-11-20T03:05 | BCHUSDT | 1h | short | 205.5 | 230.571 | 180.300 | 3 | mixed | open | — |
| 2026-11-20T03:05 | LTCUSDT | 1h | long | 41.93 | 41.1086 | 44.8456 | A | strong | open | — |
| 2026-11-20T03:05 | DOTUSDT | 1h | long | 0.702 | 0.675857 | 0.761000 | C | mixed | open | — |
| 2026-11-20T03:05 | LINKUSDT | 1h | long | 8.871 | 8.72304 | 9.17240 | 1 | weak | open | — |
| 2026-11-20T03:05 | TRXUSDT | 1h | long | 0.3092 | 0.306939 | 0.312052 | 5 | strong | open | — |
| 2026-11-20T03:05 | DOGEUSDT | 1h | long | 0.05738 | 0.0550386 | 0.0618200 | C | weak | open | — |
| 2026-11-20T03:05 | ETHUSDT | 1h | long | 1743.49 | 1710.87 | 1893.45 | A | strong | open | — |
| 2026-11-19T03:19 | HBARUSDT | 1h | long | 0.0553 | 0.0546668 | 0.0565600 | C | weak | target | +1.81 |
| 2026-11-19T03:19 | UNIUSDT | 1h | long | 5.136 | 4.57950 | 5.88800 | C | weak | open | — |
| 2026-11-19T03:19 | NEARUSDT | 1h | short | 3.347 | 3.46200 | 3.08500 | 3 | weak | stopped | -1.06 |
| 2026-11-19T03:19 | AVAXUSDT | 1h | long | 6.981 | 6.69489 | 7.44500 | C | weak | open | — |
| 2026-11-19T03:19 | LINKUSDT | 1h | long | 9.012 | 8.92939 | 9.09957 | 1 | weak | target | +0.84 |
| 2026-11-19T03:19 | TRXUSDT | 1h | short | 0.3102 | 0.311636 | 0.306750 | B | mixed | stopped | -1.43 |
| 2026-11-19T03:19 | ADAUSDT | 1h | long | 0.1505 | 0.141636 | 0.162200 | C | weak | open | — |
| 2026-11-19T03:19 | BTCUSDT | 1h | long | 62604.77 | 61741.0 | 63655.2 | C | weak | target | +1.07 |
| 2026-11-18T04:14 | AAVEUSDT | 4h | short | 111.04 | 115.972 | 105.555 | B | mixed | target | +1.07 |
| 2026-11-18T04:14 | UNIUSDT | 4h | long | 5.203 | 4.54589 | 6.00000 | C | mixed | open | — |
| 2026-11-18T04:14 | NEARUSDT | 4h | short | 3.384 | 3.74768 | 2.86978 | 5 | strong | open | — |
| 2026-11-18T04:14 | XLMUSDT | 4h | short | 0.1401 | 0.152200 | 0.121600 | 3 | weak | open | — |
| 2026-11-18T04:14 | LTCUSDT | 1h | long | 44.58 | 42.4218 | 46.8400 | C | weak | stopped | -1.04 |
| 2026-11-18T04:14 | LINKUSDT | 4h | short | 9.198 | 9.72782 | 8.66407 | 5 | strong | open | — |
| 2026-11-18T04:14 | XRPUSDT | 1h | short | 0.9783 | 1.04942 | 0.841100 | 3 | weak | expired | +0.09 |
| 2026-11-18T04:14 | BTCUSDT | 4h | long | 64397.56 | 61468.5 | 67462.0 | C | weak | stopped | -1.04 |
| 2026-11-17T22:15 | XRPUSDT | 1h | short | 0.9708 | 0.985000 | 0.956496 | 1 | mixed | stopped | -1.14 |
| 2026-11-17T13:14 | AAVEUSDT | 1h | short | 113.83 | 135.460 | 76.2100 | 3 | weak | expired | +0.26 |
| 2026-11-17T13:14 | SUIUSDT | 1h | short | 0.7397 | 0.769307 | 0.685345 | 5 | strong | expired | +0.42 |
| 2026-11-17T13:14 | UNIUSDT | 1h | short | 5.406 | 5.44704 | 5.01450 | B | weak | stopped | -1.26 |
| 2026-11-17T13:14 | NEARUSDT | 1h | short | 3.264 | 3.34079 | 3.14377 | A | mixed | target | +1.48 |
| 2026-11-17T13:14 | XLMUSDT | 1h | short | 0.1411 | 0.151296 | 0.121500 | 3 | weak | expired | +0.39 |
| 2026-11-17T13:14 | BCHUSDT | 1h | short | 212.8 | 213.361 | 204.100 | B | mixed | stopped | -1.76 |
| 2026-11-17T13:14 | SOLUSDT | 1h | short | 73.93 | 78.2896 | 68.9993 | 5 | strong | expired | -0.27 |
| 2026-11-17T13:14 | BNBUSDT | 1h | short | 593.13 | 601.478 | 582.860 | B | mixed | target | +1.09 |
| 2026-11-16T11:03 | HBARUSDT | 1h | short | 0.05823 | 0.0609432 | 0.0553650 | 5 | strong | expired | +0.35 |
| 2026-11-16T11:03 | AAVEUSDT | 1h | short | 109.94 | 111.121 | 103.525 | B | mixed | stopped | -1.19 |
| 2026-11-16T11:03 | LINKUSDT | 1h | short | 9.188 | 9.67450 | 8.62807 | 5 | strong | expired | +0.06 |
| 2026-11-16T11:03 | TRXUSDT | 1h | long | 0.3038 | 0.301807 | 0.309252 | A | strong | target | +2.43 |
| 2026-11-16T11:03 | BTCUSDT | 1h | short | 64602.17 | 70474.2 | 57923.7 | 3 | weak | expired | +0.07 |
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

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
