# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-21T15:13 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 103 | 25 | 21% | -0.31 | -0.47 | -48.8 | 50.1 |
| 1h | 91 | 15 | 23% | -0.24 | -0.42 | -38.0 | 39.2 |
| 4h | 12 | 10 | 8% | -0.83 | -0.90 | -10.8 | 10.8 |
| Evidence strong | 7 | 3 | 17% | -0.51 | -0.71 | -5.0 | 5.0 |
| Evidence mixed | 25 | 7 | 38% | -0.01 | -0.22 | -5.4 | 7.1 |
| Evidence weak | 71 | 15 | 14% | -0.39 | -0.54 | -38.4 | 39.7 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-21T15:13 | SUIUSDT | 1h | short | 1.0454 | 1.05206 | 1.01664 | 1 | weak | open | — |
| 2026-10-21T15:13 | XLMUSDT | 1h | short | 0.186 | 0.186857 | 0.184118 | 4 | weak | open | — |
| 2026-10-21T15:13 | BCHUSDT | 1h | short | 289.1 | 292.036 | 279.205 | 1 | mixed | open | — |
| 2026-10-21T15:13 | DOGEUSDT | 1h | short | 0.08345 | 0.0837271 | 0.0826069 | 4 | weak | open | — |
| 2026-10-21T15:13 | XRPUSDT | 1h | short | 1.3815 | 1.39381 | 1.35810 | A | mixed | open | — |
| 2026-10-21T15:13 | BNBUSDT | 1h | short | 749.11 | 751.528 | 745.534 | 4 | weak | open | — |
| 2026-10-21T15:13 | ETHUSDT | 1h | short | 2507.46 | 2511.43 | 2453.19 | A | strong | open | — |
| 2026-10-21T15:13 | BTCUSDT | 1h | short | 84691.36 | 84928.0 | 83836.3 | A | weak | open | — |
| 2026-10-21T10:04 | AAVEUSDT | 1h | long | 155.28 | 149.068 | 162.090 | 3 | mixed | open | — |
| 2026-10-21T10:04 | UNIUSDT | 1h | long | 7.486 | 7.13379 | 7.99400 | 3 | weak | open | — |
| 2026-10-21T10:04 | BCHUSDT | 1h | long | 286.5 | 285.711 | 288.850 | B | strong | stopped | -1.72 |
| 2026-10-21T10:04 | LTCUSDT | 1h | long | 61.55 | 60.7432 | 62.6786 | 5 | strong | open | — |
| 2026-10-21T10:04 | SOLUSDT | 1h | long | 106.46 | 103.215 | 109.720 | 3 | weak | open | — |
| 2026-10-20T00:17 | HBARUSDT | 4h | long | 0.08259 | 0.0785971 | 0.0912400 | C | weak | open | — |
| 2026-10-20T00:17 | XLMUSDT | 4h | long | 0.1768 | 0.170154 | 0.194811 | A | strong | open | — |
| 2026-10-20T00:17 | LINKUSDT | 4h | short | 11.963 | 12.9028 | 11.0220 | 3 | weak | open | — |
| 2026-10-20T00:17 | TRXUSDT | 4h | long | 0.3318 | 0.328936 | 0.338300 | C | weak | open | — |
| 2026-10-20T00:17 | DOGEUSDT | 4h | short | 0.07931 | 0.0836811 | 0.0734600 | 3 | weak | open | — |
| 2026-10-20T00:17 | SOLUSDT | 4h | short | 104.47 | 108.403 | 99.2100 | C | mixed | open | — |
| 2026-10-20T00:17 | BNBUSDT | 4h | short | 728.52 | 739.888 | 703.370 | C | weak | stopped | -1.13 |
| 2026-10-19T21:01 | NEARUSDT | 1h | short | 4.921 | 5.48486 | 4.32200 | 3 | mixed | open | — |
| 2026-10-19T21:01 | LTCUSDT | 1h | short | 59.7 | 60.7214 | 58.5850 | 2 | mixed | target | +0.98 |
| 2026-10-19T21:01 | AVAXUSDT | 1h | long | 9.545 | 9.21186 | 10.0660 | 3 | weak | open | — |
| 2026-10-19T21:01 | TRXUSDT | 1h | long | 0.3312 | 0.330307 | 0.332900 | C | mixed | open | — |
| 2026-10-19T21:01 | BTCUSDT | 1h | long | 82043.05 | 80462.8 | 84222.5 | 3 | weak | target | +1.27 |
| 2026-10-19T01:14 | SUIUSDT | 1h | short | 1.0011 | 1.06818 | 0.880200 | 3 | weak | expired | -0.45 |
| 2026-10-19T01:14 | UNIUSDT | 1h | short | 7.245 | 7.68686 | 6.42200 | 3 | weak | stopped | -1.03 |
| 2026-10-19T01:14 | NEARUSDT | 1h | short | 5.046 | 5.09811 | 4.83550 | B | weak | stopped | -1.19 |
| 2026-10-19T01:14 | XLMUSDT | 1h | short | 0.1787 | 0.187046 | 0.164400 | 3 | weak | expired | -0.47 |
| 2026-10-19T01:14 | BCHUSDT | 1h | short | 276.9 | 285.871 | 256.000 | 3 | weak | stopped | -1.06 |
| 2026-10-19T01:14 | LINKUSDT | 1h | short | 12.134 | 12.8393 | 10.8970 | 3 | weak | expired | -0.35 |
| 2026-10-19T01:14 | TRXUSDT | 1h | long | 0.3326 | 0.331325 | 0.333900 | C | mixed | stopped | -1.52 |
| 2026-10-19T01:14 | ADAUSDT | 1h | short | 0.2216 | 0.234854 | 0.200100 | 3 | weak | expired | -0.22 |
| 2026-10-19T01:14 | XRPUSDT | 1h | short | 1.3103 | 1.35923 | 1.21310 | 3 | weak | expired | -0.56 |
| 2026-10-19T01:14 | SOLUSDT | 1h | short | 104.72 | 107.922 | 97.6000 | 3 | weak | stopped | -1.07 |
| 2026-10-19T01:14 | ETHUSDT | 1h | short | 2421.4 | 2504.31 | 2254.52 | 3 | weak | expired | -0.39 |
| 2026-10-18T23:05 | HBARUSDT | 1h | short | 0.08558 | 0.0906471 | 0.0774600 | 3 | weak | expired | +0.24 |
| 2026-10-18T23:05 | AAVEUSDT | 1h | short | 151.17 | 155.901 | 142.740 | 3 | weak | stopped | -1.06 |
| 2026-10-18T23:05 | NEARUSDT | 1h | short | 4.947 | 5.01961 | 4.79700 | B | weak | stopped | -1.14 |
| 2026-10-18T23:05 | DOTUSDT | 1h | short | 1.106 | 1.15171 | 1.00800 | 3 | weak | stopped | -1.05 |
| 2026-10-18T23:05 | BNBUSDT | 1h | short | 719.66 | 738.050 | 690.310 | 3 | weak | stopped | -1.08 |
| 2026-10-18T23:05 | BTCUSDT | 1h | short | 81761.24 | 83111.2 | 80163.9 | 3 | weak | stopped | -1.12 |
| 2026-10-18T18:03 | XLMUSDT | 1h | long | 0.1745 | 0.173157 | 0.178537 | A | strong | stopped | -1.26 |
| 2026-10-18T18:03 | LINKUSDT | 1h | long | 11.786 | 11.6650 | 11.9675 | 1 | weak | stopped | -1.19 |
| 2026-10-18T18:03 | ADAUSDT | 1h | long | 0.2162 | 0.213232 | 0.231900 | C | weak | stopped | -1.14 |
| 2026-10-17T22:14 | AAVEUSDT | 1h | long | 151.38 | 148.384 | 157.540 | B | weak | stopped | -1.10 |
| 2026-10-17T22:14 | DOTUSDT | 1h | long | 1.11 | 1.08429 | 1.16678 | 1 | weak | stopped | -1.09 |
| 2026-10-17T22:14 | TRXUSDT | 1h | long | 0.3335 | 0.333282 | 0.335400 | 2 | weak | stopped | -4.06 |
| 2026-10-17T17:06 | AAVEUSDT | 1h | long | 150.25 | 149.748 | 158.165 | B | weak | stopped | -1.60 |
| 2026-10-17T17:06 | BCHUSDT | 1h | long | 272.1 | 269.750 | 277.700 | B | weak | target | +2.15 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
