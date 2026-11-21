# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-21T09:41 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 459 | 0 | 23% | -0.27 | -0.42 | -195.0 | 195.0 |
| 1h | 368 | 0 | 24% | -0.20 | -0.38 | -139.3 | 140.3 |
| 4h | 91 | 0 | 17% | -0.54 | -0.61 | -55.7 | 55.7 |
| Evidence strong | 65 | 0 | 14% | -0.53 | -0.75 | -48.6 | 48.6 |
| Evidence mixed | 145 | 0 | 29% | -0.16 | -0.33 | -48.0 | 49.0 |
| Evidence weak | 249 | 0 | 21% | -0.26 | -0.40 | -98.4 | 98.4 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-20T20:04 | HBARUSDT | 4h | long | 0.05057 | 0.0493371 | 0.0673011 | A | mixed | stopped | -1.08 |
| 2026-11-20T20:04 | HBARUSDT | 1h | long | 0.05057 | 0.0496196 | 0.0572583 | A | strong | stopped | -1.11 |
| 2026-11-20T20:04 | AAVEUSDT | 4h | long | 95.2 | 92.2011 | 110.382 | A | strong | stopped | -1.06 |
| 2026-11-20T20:04 | SUIUSDT | 4h | long | 0.6404 | 0.627171 | 0.719747 | A | mixed | stopped | -1.10 |
| 2026-11-20T20:04 | SUIUSDT | 1h | long | 0.6404 | 0.630761 | 0.719747 | A | strong | stopped | -1.13 |
| 2026-11-20T20:04 | UNIUSDT | 4h | long | 4.338 | 4.23682 | 5.65885 | A | strong | stopped | -1.08 |
| 2026-11-20T20:04 | UNIUSDT | 1h | long | 4.338 | 4.27493 | 4.60492 | A | mixed | stopped | -1.14 |
| 2026-11-20T20:04 | NEARUSDT | 4h | long | 2.825 | 2.72925 | 3.47143 | A | strong | stopped | -1.06 |
| 2026-11-20T20:04 | XLMUSDT | 1h | long | 0.1261 | 0.124000 | 0.130463 | A | mixed | stopped | -1.12 |
| 2026-11-20T20:04 | LTCUSDT | 4h | long | 39.93 | 39.0046 | 43.6394 | 4 | weak | stopped | -1.09 |
| 2026-11-20T20:04 | LTCUSDT | 1h | long | 39.93 | 39.1939 | 44.3781 | A | strong | stopped | -1.11 |
| 2026-11-20T20:04 | DOTUSDT | 4h | long | 0.659 | 0.641964 | 0.743826 | A | strong | stopped | -1.08 |
| 2026-11-20T20:04 | DOTUSDT | 1h | long | 0.659 | 0.645464 | 0.676594 | A | mixed | target | +1.20 |
| 2026-11-20T20:04 | AVAXUSDT | 4h | long | 6.488 | 6.31650 | 6.96012 | 4 | weak | stopped | -1.07 |
| 2026-11-20T20:04 | AVAXUSDT | 1h | long | 6.487 | 6.35011 | 6.64990 | A | mixed | stopped | -1.09 |
| 2026-11-20T20:04 | LINKUSDT | 4h | long | 8.358 | 8.13436 | 9.23309 | A | mixed | stopped | -1.07 |
| 2026-11-20T20:04 | LINKUSDT | 1h | long | 8.358 | 8.17468 | 9.14217 | A | strong | stopped | -1.09 |
| 2026-11-20T20:04 | TRXUSDT | 4h | long | 0.3014 | 0.299954 | 0.309862 | A | strong | stopped | -1.42 |
| 2026-11-20T20:04 | TRXUSDT | 1h | long | 0.3014 | 0.300393 | 0.304820 | A | mixed | stopped | -1.60 |
| 2026-11-20T20:04 | ADAUSDT | 4h | long | 0.1395 | 0.135993 | 0.157688 | A | mixed | stopped | -1.08 |
| 2026-11-20T20:04 | ADAUSDT | 1h | long | 0.1395 | 0.136704 | 0.142751 | A | strong | target | +1.06 |
| 2026-11-20T20:04 | DOGEUSDT | 4h | long | 0.05316 | 0.0521104 | 0.0588274 | 4 | weak | stopped | -1.10 |
| 2026-11-20T20:04 | DOGEUSDT | 1h | long | 0.05316 | 0.0523529 | 0.0597142 | A | strong | stopped | -1.13 |
| 2026-11-20T20:04 | XRPUSDT | 4h | long | 0.8951 | 0.880396 | 1.06457 | A | mixed | stopped | -1.12 |
| 2026-11-20T20:04 | XRPUSDT | 1h | long | 0.8951 | 0.884093 | 0.910858 | 4 | weak | target | +1.27 |
| 2026-11-20T20:04 | SOLUSDT | 1h | long | 68.25 | 66.9018 | 69.7902 | A | mixed | stopped | -1.10 |
| 2026-11-20T20:04 | BNBUSDT | 4h | long | 535.54 | 524.572 | 584.799 | 4 | weak | stopped | -1.10 |
| 2026-11-20T20:04 | BNBUSDT | 1h | long | 535.54 | 526.324 | 554.448 | A | weak | stopped | -1.12 |
| 2026-11-20T20:04 | ETHUSDT | 4h | long | 1605.45 | 1559.22 | 1802.66 | A | mixed | stopped | -1.07 |
| 2026-11-20T20:04 | BTCUSDT | 4h | long | 58548.01 | 57155.0 | 68138.1 | A | strong | stopped | -1.08 |
| 2026-11-20T20:04 | BTCUSDT | 1h | long | 58548.01 | 57359.6 | 64637.6 | A | strong | stopped | -1.10 |
| 2026-11-20T03:05 | HBARUSDT | 1h | long | 0.05315 | 0.0524329 | 0.0589949 | A | strong | stopped | -1.15 |
| 2026-11-20T03:05 | SUIUSDT | 1h | long | 0.6996 | 0.690168 | 0.725806 | 1 | weak | stopped | -1.15 |
| 2026-11-20T03:05 | BCHUSDT | 1h | short | 205.5 | 230.571 | 180.300 | 3 | mixed | target | +0.99 |
| 2026-11-20T03:05 | LTCUSDT | 1h | long | 41.93 | 41.1086 | 44.8456 | A | strong | stopped | -1.10 |
| 2026-11-20T03:05 | DOTUSDT | 1h | long | 0.702 | 0.675857 | 0.761000 | C | mixed | stopped | -1.05 |
| 2026-11-20T03:05 | LINKUSDT | 1h | long | 8.871 | 8.72304 | 9.17240 | 1 | weak | stopped | -1.12 |
| 2026-11-20T03:05 | TRXUSDT | 1h | long | 0.3092 | 0.306939 | 0.312052 | 5 | strong | stopped | -1.27 |
| 2026-11-20T03:05 | DOGEUSDT | 1h | long | 0.05738 | 0.0550386 | 0.0618200 | C | weak | stopped | -1.05 |
| 2026-11-20T03:05 | ETHUSDT | 1h | long | 1743.49 | 1710.87 | 1893.45 | A | strong | stopped | -1.11 |
| 2026-11-19T03:19 | HBARUSDT | 1h | long | 0.0553 | 0.0546668 | 0.0565600 | C | weak | target | +1.81 |
| 2026-11-19T03:19 | UNIUSDT | 1h | long | 5.136 | 4.57950 | 5.88800 | C | weak | stopped | -1.02 |
| 2026-11-19T03:19 | NEARUSDT | 1h | short | 3.347 | 3.46200 | 3.08500 | 3 | weak | stopped | -1.06 |
| 2026-11-19T03:19 | AVAXUSDT | 1h | long | 6.981 | 6.69489 | 7.44500 | C | weak | stopped | -1.05 |
| 2026-11-19T03:19 | LINKUSDT | 1h | long | 9.012 | 8.92939 | 9.09957 | 1 | weak | target | +0.84 |
| 2026-11-19T03:19 | TRXUSDT | 1h | short | 0.3102 | 0.311636 | 0.306750 | B | mixed | stopped | -1.43 |
| 2026-11-19T03:19 | ADAUSDT | 1h | long | 0.1505 | 0.141636 | 0.162200 | C | weak | stopped | -1.03 |
| 2026-11-19T03:19 | BTCUSDT | 1h | long | 62604.77 | 61741.0 | 63655.2 | C | weak | target | +1.07 |
| 2026-11-18T04:14 | AAVEUSDT | 4h | short | 111.04 | 115.972 | 105.555 | B | mixed | target | +1.07 |
| 2026-11-18T04:14 | UNIUSDT | 4h | long | 5.203 | 4.54589 | 6.00000 | C | mixed | stopped | -1.01 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
