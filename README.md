# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-24T01:35 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 164 | 21 | 15% | -0.45 | -0.64 | -104.4 | 104.4 |
| 1h | 144 | 9 | 17% | -0.39 | -0.59 | -85.1 | 85.1 |
| 4h | 20 | 12 | 5% | -0.90 | -0.97 | -19.3 | 19.3 |
| Evidence strong | 15 | 1 | 7% | -0.77 | -1.04 | -15.7 | 15.7 |
| Evidence mixed | 49 | 1 | 25% | -0.29 | -0.50 | -24.6 | 24.6 |
| Evidence weak | 100 | 19 | 12% | -0.48 | -0.64 | -64.2 | 64.2 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-23T23:06 | SUIUSDT | 1h | long | 0.9457 | 0.933786 | 1.01206 | 1 | weak | open | — |
| 2026-10-23T23:06 | SOLUSDT | 1h | long | 102.07 | 101.313 | 103.071 | A | weak | open | — |
| 2026-10-23T15:00 | SUIUSDT | 1h | long | 0.9896 | 0.960671 | 1.02170 | C | mixed | stopped | -1.07 |
| 2026-10-23T15:00 | AVAXUSDT | 1h | long | 9.119 | 8.93779 | 9.51850 | 2 | weak | stopped | -1.10 |
| 2026-10-23T10:01 | HBARUSDT | 1h | long | 0.07903 | 0.0782607 | 0.0822000 | C | weak | stopped | -1.20 |
| 2026-10-23T10:01 | UNIUSDT | 1h | short | 7.17 | 7.77525 | 6.45700 | 3 | weak | open | — |
| 2026-10-23T10:01 | BCHUSDT | 1h | short | 286.6 | 292.282 | 269.700 | C | mixed | open | — |
| 2026-10-23T10:01 | AVAXUSDT | 1h | long | 9.221 | 9.01789 | 9.47200 | C | mixed | stopped | -1.09 |
| 2026-10-23T10:01 | LINKUSDT | 1h | short | 12.091 | 12.8620 | 11.2500 | 3 | weak | open | — |
| 2026-10-23T10:01 | TRXUSDT | 1h | short | 0.3297 | 0.331636 | 0.326500 | 3 | weak | open | — |
| 2026-10-23T10:01 | XRPUSDT | 1h | short | 1.3186 | 1.35754 | 1.27310 | 3 | weak | open | — |
| 2026-10-23T10:01 | BNBUSDT | 1h | short | 746.61 | 753.558 | 721.630 | C | weak | open | — |
| 2026-10-22T23:18 | BNBUSDT | 1h | short | 730.8 | 737.213 | 723.530 | C | mixed | stopped | -1.23 |
| 2026-10-22T20:02 | AAVEUSDT | 1h | long | 147.11 | 143.424 | 152.425 | 2 | mixed | stopped | -1.08 |
| 2026-10-22T20:02 | LTCUSDT | 1h | long | 58.7 | 57.8293 | 60.2500 | B | mixed | stopped | -1.13 |
| 2026-10-22T20:02 | TRXUSDT | 4h | long | 0.3283 | 0.327107 | 0.332450 | 2 | weak | open | — |
| 2026-10-22T20:02 | ADAUSDT | 4h | long | 0.2126 | 0.207182 | 0.224432 | 1 | weak | stopped | -1.08 |
| 2026-10-22T20:02 | ADAUSDT | 1h | long | 0.2126 | 0.208479 | 0.224432 | 1 | mixed | stopped | -1.10 |
| 2026-10-22T20:02 | DOGEUSDT | 4h | long | 0.07873 | 0.0753736 | 0.0855800 | C | weak | open | — |
| 2026-10-22T20:02 | XRPUSDT | 4h | long | 1.3065 | 1.24415 | 1.44580 | 3 | weak | open | — |
| 2026-10-22T20:02 | XRPUSDT | 1h | long | 1.3065 | 1.29782 | 1.33962 | A | mixed | stopped | -1.30 |
| 2026-10-22T20:02 | SOLUSDT | 4h | long | 103.73 | 99.5096 | 111.810 | 3 | weak | open | — |
| 2026-10-22T20:02 | SOLUSDT | 1h | long | 103.73 | 102.643 | 105.393 | A | strong | stopped | -1.19 |
| 2026-10-22T20:02 | BNBUSDT | 4h | long | 732.24 | 702.519 | 771.620 | 3 | weak | open | — |
| 2026-10-22T20:02 | ETHUSDT | 4h | long | 2387.83 | 2340.95 | 2443.47 | B | weak | open | — |
| 2026-10-22T20:02 | ETHUSDT | 1h | long | 2387.83 | 2351.76 | 2443.47 | B | weak | stopped | -1.13 |
| 2026-10-22T20:02 | BTCUSDT | 4h | long | 81486.39 | 80221.6 | 85153.2 | C | weak | open | — |
| 2026-10-22T20:02 | BTCUSDT | 1h | long | 81486.39 | 80733.4 | 82893.4 | B | mixed | stopped | -1.22 |
| 2026-10-22T15:16 | BCHUSDT | 1h | long | 273.6 | 272.479 | 279.950 | A | mixed | stopped | -1.49 |
| 2026-10-22T15:16 | XRPUSDT | 1h | long | 1.3183 | 1.31425 | 1.34976 | A | mixed | stopped | -1.65 |
| 2026-10-22T10:06 | HBARUSDT | 1h | long | 0.081 | 0.0799271 | 0.0824892 | A | mixed | stopped | -1.15 |
| 2026-10-22T10:06 | AAVEUSDT | 1h | long | 148.34 | 146.379 | 153.850 | B | weak | stopped | -1.15 |
| 2026-10-22T10:06 | SUIUSDT | 1h | long | 0.989 | 0.972557 | 1.02423 | 1 | weak | stopped | -1.12 |
| 2026-10-22T10:06 | UNIUSDT | 1h | long | 7.102 | 6.94293 | 7.48669 | 1 | weak | stopped | -1.09 |
| 2026-10-22T10:06 | NEARUSDT | 1h | long | 5.003 | 4.71204 | 5.60700 | C | weak | stopped | -1.03 |
| 2026-10-22T10:06 | XLMUSDT | 1h | long | 0.1781 | 0.171043 | 0.192300 | 3 | weak | stopped | -1.05 |
| 2026-10-22T10:06 | LTCUSDT | 1h | long | 59.42 | 58.8354 | 60.7400 | B | weak | stopped | -1.20 |
| 2026-10-22T10:06 | AVAXUSDT | 1h | long | 9.246 | 9.11921 | 9.61200 | 2 | mixed | stopped | -1.14 |
| 2026-10-22T10:06 | LINKUSDT | 1h | long | 12.077 | 11.9305 | 12.2780 | A | mixed | stopped | -1.16 |
| 2026-10-22T10:06 | ADAUSDT | 1h | long | 0.2166 | 0.213221 | 0.222400 | B | weak | stopped | -1.13 |
| 2026-10-22T10:06 | DOGEUSDT | 1h | long | 0.07925 | 0.0757607 | 0.0865100 | 3 | weak | open | — |
| 2026-10-22T10:06 | XRPUSDT | 1h | long | 1.3323 | 1.32004 | 1.35347 | A | mixed | stopped | -1.22 |
| 2026-10-22T10:06 | ETHUSDT | 1h | long | 2411.09 | 2388.19 | 2445.62 | A | weak | stopped | -1.21 |
| 2026-10-22T10:06 | BTCUSDT | 1h | long | 82050.87 | 81442.5 | 82873.2 | A | mixed | stopped | -1.27 |
| 2026-10-21T23:18 | NEARUSDT | 1h | long | 5.274 | 5.04607 | 5.51613 | 5 | strong | stopped | -1.05 |
| 2026-10-21T23:18 | DOTUSDT | 1h | long | 1.149 | 1.03821 | 1.26200 | C | weak | expired | -0.68 |
| 2026-10-21T23:18 | AVAXUSDT | 1h | long | 9.689 | 9.47521 | 10.2260 | 3 | weak | stopped | -1.09 |
| 2026-10-21T23:18 | LINKUSDT | 1h | long | 12.539 | 12.4141 | 12.9567 | 5 | strong | stopped | -1.20 |
| 2026-10-21T23:18 | DOGEUSDT | 1h | long | 0.08201 | 0.0817304 | 0.0844139 | 5 | strong | stopped | -1.59 |
| 2026-10-21T23:18 | XRPUSDT | 1h | long | 1.3674 | 1.33990 | 1.40668 | 5 | strong | stopped | -1.10 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
