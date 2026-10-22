# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-22T15:16 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 132 | 25 | 20% | -0.32 | -0.51 | -67.9 | 67.9 |
| 1h | 117 | 16 | 22% | -0.25 | -0.46 | -53.9 | 53.9 |
| 4h | 15 | 9 | 7% | -0.86 | -0.93 | -13.9 | 13.9 |
| Evidence strong | 14 | 1 | 8% | -0.76 | -1.03 | -14.5 | 14.5 |
| Evidence mixed | 35 | 6 | 37% | -0.00 | -0.22 | -7.7 | 7.7 |
| Evidence weak | 83 | 18 | 15% | -0.38 | -0.55 | -45.7 | 45.7 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-22T15:16 | BCHUSDT | 1h | long | 273.6 | 272.479 | 279.950 | A | mixed | open | — |
| 2026-10-22T15:16 | XRPUSDT | 1h | long | 1.3183 | 1.31425 | 1.34976 | A | mixed | open | — |
| 2026-10-22T10:06 | HBARUSDT | 1h | long | 0.081 | 0.0799271 | 0.0824892 | A | mixed | open | — |
| 2026-10-22T10:06 | AAVEUSDT | 1h | long | 148.34 | 146.379 | 153.850 | B | weak | open | — |
| 2026-10-22T10:06 | SUIUSDT | 1h | long | 0.989 | 0.972557 | 1.02423 | 1 | weak | open | — |
| 2026-10-22T10:06 | UNIUSDT | 1h | long | 7.102 | 6.94293 | 7.48669 | 1 | weak | open | — |
| 2026-10-22T10:06 | NEARUSDT | 1h | long | 5.003 | 4.71204 | 5.60700 | C | weak | open | — |
| 2026-10-22T10:06 | XLMUSDT | 1h | long | 0.1781 | 0.171043 | 0.192300 | 3 | weak | open | — |
| 2026-10-22T10:06 | LTCUSDT | 1h | long | 59.42 | 58.8354 | 60.7400 | B | weak | open | — |
| 2026-10-22T10:06 | AVAXUSDT | 1h | long | 9.246 | 9.11921 | 9.61200 | 2 | mixed | open | — |
| 2026-10-22T10:06 | LINKUSDT | 1h | long | 12.077 | 11.9305 | 12.2780 | A | mixed | open | — |
| 2026-10-22T10:06 | ADAUSDT | 1h | long | 0.2166 | 0.213221 | 0.222400 | B | weak | open | — |
| 2026-10-22T10:06 | DOGEUSDT | 1h | long | 0.07925 | 0.0757607 | 0.0865100 | 3 | weak | open | — |
| 2026-10-22T10:06 | XRPUSDT | 1h | long | 1.3323 | 1.32004 | 1.35347 | A | mixed | stopped | -1.22 |
| 2026-10-22T10:06 | ETHUSDT | 1h | long | 2411.09 | 2388.19 | 2445.62 | A | weak | open | — |
| 2026-10-22T10:06 | BTCUSDT | 1h | long | 82050.87 | 81442.5 | 82873.2 | A | mixed | stopped | -1.27 |
| 2026-10-21T23:18 | NEARUSDT | 1h | long | 5.274 | 5.04607 | 5.51613 | 5 | strong | stopped | -1.05 |
| 2026-10-21T23:18 | DOTUSDT | 1h | long | 1.149 | 1.03821 | 1.26200 | C | weak | open | — |
| 2026-10-21T23:18 | AVAXUSDT | 1h | long | 9.689 | 9.47521 | 10.2260 | 3 | weak | stopped | -1.09 |
| 2026-10-21T23:18 | LINKUSDT | 1h | long | 12.539 | 12.4141 | 12.9567 | 5 | strong | stopped | -1.20 |
| 2026-10-21T23:18 | DOGEUSDT | 1h | long | 0.08201 | 0.0817304 | 0.0844139 | 5 | strong | stopped | -1.59 |
| 2026-10-21T23:18 | XRPUSDT | 1h | long | 1.3674 | 1.33990 | 1.40668 | 5 | strong | stopped | -1.10 |
| 2026-10-21T23:18 | ETHUSDT | 1h | long | 2478.88 | 2468.55 | 2545.90 | 5 | mixed | stopped | -1.48 |
| 2026-10-21T20:06 | HBARUSDT | 1h | short | 0.08551 | 0.0868511 | 0.0835910 | 1 | mixed | target | +1.30 |
| 2026-10-21T20:06 | SUIUSDT | 4h | short | 1.0422 | 1.15379 | 0.851600 | 3 | weak | open | — |
| 2026-10-21T20:06 | SUIUSDT | 1h | short | 1.0422 | 1.06226 | 1.02039 | 1 | weak | target | +0.98 |
| 2026-10-21T20:06 | XLMUSDT | 1h | long | 0.1853 | 0.182986 | 0.187970 | 5 | strong | stopped | -1.16 |
| 2026-10-21T20:06 | DOTUSDT | 4h | short | 1.167 | 1.23004 | 1.02500 | C | weak | open | — |
| 2026-10-21T20:06 | TRXUSDT | 1h | long | 0.3318 | 0.330207 | 0.335000 | 3 | weak | stopped | -1.42 |
| 2026-10-21T15:13 | SUIUSDT | 1h | short | 1.0454 | 1.05206 | 1.01664 | 1 | weak | stopped | -1.31 |
| 2026-10-21T15:13 | XLMUSDT | 1h | short | 0.186 | 0.186857 | 0.184118 | 4 | weak | stopped | -1.44 |
| 2026-10-21T15:13 | BCHUSDT | 1h | short | 289.1 | 292.036 | 279.205 | 1 | mixed | target | +3.18 |
| 2026-10-21T15:13 | DOGEUSDT | 1h | short | 0.08345 | 0.0837271 | 0.0826069 | 4 | weak | stopped | -1.60 |
| 2026-10-21T15:13 | XRPUSDT | 1h | short | 1.3815 | 1.39381 | 1.35810 | A | mixed | stopped | -1.23 |
| 2026-10-21T15:13 | BNBUSDT | 1h | short | 749.11 | 751.528 | 745.534 | 4 | weak | stopped | -1.62 |
| 2026-10-21T15:13 | ETHUSDT | 1h | short | 2507.46 | 2511.43 | 2453.19 | A | strong | stopped | -2.26 |
| 2026-10-21T15:13 | BTCUSDT | 1h | short | 84691.36 | 84928.0 | 83836.3 | A | weak | target | +2.90 |
| 2026-10-21T10:04 | AAVEUSDT | 1h | long | 155.28 | 149.068 | 162.090 | 3 | mixed | stopped | -1.05 |
| 2026-10-21T10:04 | UNIUSDT | 1h | long | 7.486 | 7.13379 | 7.99400 | 3 | weak | stopped | -1.04 |
| 2026-10-21T10:04 | BCHUSDT | 1h | long | 286.5 | 285.711 | 288.850 | B | strong | stopped | -1.72 |
| 2026-10-21T10:04 | LTCUSDT | 1h | long | 61.55 | 60.7432 | 62.6786 | 5 | strong | stopped | -1.15 |
| 2026-10-21T10:04 | SOLUSDT | 1h | long | 106.46 | 103.215 | 109.720 | 3 | weak | open | — |
| 2026-10-20T00:17 | HBARUSDT | 4h | long | 0.08259 | 0.0785971 | 0.0912400 | C | weak | open | — |
| 2026-10-20T00:17 | XLMUSDT | 4h | long | 0.1768 | 0.170154 | 0.194811 | A | strong | open | — |
| 2026-10-20T00:17 | LINKUSDT | 4h | short | 11.963 | 12.9028 | 11.0220 | 3 | weak | open | — |
| 2026-10-20T00:17 | TRXUSDT | 4h | long | 0.3318 | 0.328936 | 0.338300 | C | weak | open | — |
| 2026-10-20T00:17 | DOGEUSDT | 4h | short | 0.07931 | 0.0836811 | 0.0734600 | 3 | weak | stopped | -1.04 |
| 2026-10-20T00:17 | SOLUSDT | 4h | short | 104.47 | 108.403 | 99.2100 | C | mixed | stopped | -1.05 |
| 2026-10-20T00:17 | BNBUSDT | 4h | short | 728.52 | 739.888 | 703.370 | C | weak | stopped | -1.13 |
| 2026-10-19T21:01 | NEARUSDT | 1h | short | 4.921 | 5.48486 | 4.32200 | 3 | mixed | expired | -0.68 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
