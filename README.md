# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-11-27T21:13 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 499 | 20 | 22% | -0.27 | -0.42 | -211.2 | 215.8 |
| 1h | 408 | 16 | 24% | -0.22 | -0.38 | -155.5 | 160.1 |
| 4h | 91 | 4 | 17% | -0.54 | -0.61 | -55.7 | 55.7 |
| Evidence strong | 66 | 2 | 14% | -0.54 | -0.75 | -49.8 | 49.8 |
| Evidence mixed | 163 | 6 | 27% | -0.22 | -0.38 | -62.0 | 63.6 |
| Evidence weak | 270 | 12 | 21% | -0.24 | -0.37 | -99.4 | 103.6 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-11-27T21:13 | HBARUSDT | 1h | long | 0.05402 | 0.0482693 | 0.0604400 | C | weak | open | — |
| 2026-11-27T21:13 | UNIUSDT | 1h | short | 4.834 | 4.96589 | 4.58000 | C | mixed | open | — |
| 2026-11-27T21:13 | NEARUSDT | 1h | short | 3.046 | 3.19132 | 2.83300 | 3 | weak | open | — |
| 2026-11-27T21:13 | BCHUSDT | 1h | long | 206.9 | 189.471 | 231.200 | 3 | weak | open | — |
| 2026-11-27T21:13 | LINKUSDT | 1h | long | 9.365 | 8.41139 | 10.3540 | 3 | weak | open | — |
| 2026-11-27T21:13 | ADAUSDT | 1h | long | 0.1493 | 0.134725 | 0.164000 | 3 | weak | open | — |
| 2026-11-27T21:13 | ETHUSDT | 1h | short | 1667.55 | 1764.35 | 1566.41 | 3 | mixed | open | — |
| 2026-11-27T21:13 | BTCUSDT | 1h | short | 59859.84 | 62544.5 | 57103.1 | C | mixed | open | — |
| 2026-11-27T12:05 | SUIUSDT | 1h | short | 0.688 | 0.696193 | 0.644278 | 1 | weak | open | — |
| 2026-11-27T12:05 | UNIUSDT | 4h | short | 4.894 | 5.38286 | 3.98500 | 3 | weak | open | — |
| 2026-11-27T12:05 | UNIUSDT | 1h | short | 4.894 | 4.96232 | 4.78264 | A | mixed | target | +1.49 |
| 2026-11-27T12:05 | BCHUSDT | 1h | long | 210.6 | 203.036 | 226.300 | 3 | weak | stopped | -1.05 |
| 2026-11-27T12:05 | LTCUSDT | 1h | short | 44.56 | 45.0632 | 41.1844 | 1 | mixed | open | — |
| 2026-11-27T12:05 | TRXUSDT | 1h | short | 0.3048 | 0.312868 | 0.295700 | 3 | weak | open | — |
| 2026-11-27T12:05 | DOGEUSDT | 1h | short | 0.05877 | 0.0591814 | 0.0583146 | 4 | weak | target | +0.82 |
| 2026-11-27T12:05 | BNBUSDT | 1h | short | 563.57 | 570.019 | 542.604 | 1 | mixed | open | — |
| 2026-11-27T12:05 | ETHUSDT | 1h | long | 1722.93 | 1703.15 | 1743.77 | 5 | strong | stopped | -1.17 |
| 2026-11-26T00:16 | AAVEUSDT | 1h | short | 97.12 | 107.157 | 79.5400 | C | weak | open | — |
| 2026-11-26T00:16 | XLMUSDT | 4h | long | 0.1303 | 0.118079 | 0.155188 | A | strong | open | — |
| 2026-11-26T00:16 | XLMUSDT | 1h | short | 0.1303 | 0.139311 | 0.110200 | 3 | weak | open | — |
| 2026-11-26T00:16 | LTCUSDT | 1h | short | 43.34 | 43.9750 | 38.6400 | C | weak | stopped | -1.14 |
| 2026-11-26T00:16 | DOTUSDT | 1h | short | 0.669 | 0.727821 | 0.565000 | 3 | weak | open | — |
| 2026-11-26T00:16 | XRPUSDT | 4h | long | 0.9484 | 0.848182 | 1.05490 | C | strong | open | — |
| 2026-11-26T00:16 | SOLUSDT | 4h | long | 71.46 | 63.9189 | 79.4500 | C | mixed | open | — |
| 2026-11-26T00:16 | SOLUSDT | 1h | short | 71.46 | 78.9607 | 58.4300 | C | weak | open | — |
| 2026-11-24T21:07 | HBARUSDT | 1h | long | 0.04997 | 0.0477221 | 0.0580900 | C | weak | expired | +1.86 |
| 2026-11-24T21:07 | AAVEUSDT | 1h | long | 93.42 | 91.9486 | 96.7977 | 1 | weak | stopped | -1.13 |
| 2026-11-24T21:07 | SUIUSDT | 1h | long | 0.6447 | 0.583779 | 0.782000 | 3 | weak | expired | +0.37 |
| 2026-11-24T21:07 | UNIUSDT | 1h | long | 4.704 | 4.15379 | 5.75500 | C | weak | expired | -0.10 |
| 2026-11-24T21:07 | NEARUSDT | 1h | long | 2.858 | 2.52382 | 3.51900 | 3 | weak | expired | +0.59 |
| 2026-11-24T21:07 | BCHUSDT | 1h | long | 195.9 | 193.039 | 205.818 | 1 | weak | stopped | -1.14 |
| 2026-11-24T21:07 | AVAXUSDT | 1h | long | 6.565 | 5.97336 | 7.68800 | C | weak | expired | +0.05 |
| 2026-11-24T21:07 | LINKUSDT | 1h | long | 8.816 | 7.91832 | 10.3200 | C | weak | expired | +0.53 |
| 2026-11-24T21:07 | TRXUSDT | 1h | long | 0.3084 | 0.303207 | 0.316000 | 3 | weak | stopped | -1.12 |
| 2026-11-24T21:07 | ADAUSDT | 1h | long | 0.144 | 0.132389 | 0.165600 | 3 | weak | expired | +0.38 |
| 2026-11-24T21:07 | DOGEUSDT | 1h | long | 0.05526 | 0.0504661 | 0.0638800 | C | weak | expired | +0.25 |
| 2026-11-24T21:07 | XRPUSDT | 1h | long | 0.9204 | 0.854989 | 1.07530 | 3 | weak | expired | +0.38 |
| 2026-11-24T21:07 | BNBUSDT | 1h | long | 549.21 | 501.367 | 626.870 | C | mixed | expired | +0.08 |
| 2026-11-24T21:07 | ETHUSDT | 1h | long | 1674.74 | 1528.95 | 1971.25 | C | weak | expired | +0.11 |
| 2026-11-22T15:14 | SUIUSDT | 1h | short | 0.6579 | 0.672500 | 0.628450 | B | mixed | stopped | -1.09 |
| 2026-11-22T15:14 | NEARUSDT | 1h | short | 3.016 | 3.50154 | 2.13300 | 3 | weak | expired | +0.39 |
| 2026-11-22T15:14 | LINKUSDT | 1h | short | 8.799 | 8.95457 | 8.44100 | B | mixed | stopped | -1.11 |
| 2026-11-22T15:14 | ADAUSDT | 1h | short | 0.1446 | 0.148282 | 0.140400 | B | mixed | stopped | -1.08 |
| 2026-11-22T15:14 | DOGEUSDT | 1h | short | 0.05523 | 0.0562836 | 0.0533850 | B | mixed | stopped | -1.11 |
| 2026-11-21T23:08 | HBARUSDT | 1h | short | 0.0514 | 0.0525989 | 0.0501550 | B | mixed | stopped | -1.09 |
| 2026-11-21T23:08 | AAVEUSDT | 1h | long | 97.54 | 90.3714 | 107.490 | C | weak | expired | -0.02 |
| 2026-11-21T23:08 | SUIUSDT | 1h | short | 0.6458 | 0.659164 | 0.621650 | B | mixed | stopped | -1.10 |
| 2026-11-21T23:08 | UNIUSDT | 1h | short | 4.734 | 5.49579 | 3.52300 | 3 | weak | expired | -0.17 |
| 2026-11-21T23:08 | XLMUSDT | 1h | short | 0.1286 | 0.130661 | 0.124900 | B | mixed | stopped | -1.13 |
| 2026-11-21T23:08 | BCHUSDT | 1h | short | 199.1 | 201.975 | 190.350 | B | mixed | stopped | -1.14 |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
