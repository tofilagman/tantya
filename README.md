# Tantya public track record

Every setup the Tantya Elliott Wave engine produces on 20 Binance pairs (1h, 4h), logged automatically by a scheduled GitHub Action when it appears and settled later. Nothing is chosen by hand and nothing is deleted: the [commit history](https://github.com/tofilagman/tantya/commits/track-record) shows each signal was published before its outcome.

Rules: enter at the price when the signal is published; stop beyond the invalidation level (+½ ATR); take profit at TP1; a candle touching both counts as the stop; closed at market after 50 candles. Net R deducts 0.1% taker fees on entry and exit. Not financial advice — an out-of-sample test before launch found **no edge** after fees.

Updated 2026-10-12T22:07 UTC · since 2026-10-12

| | Closed | Open | Hit rate | Avg R | Avg net R | Total net R | Max DD (R) |
|---|---:|---:|---:|---:|---:|---:|---:|
| **All** | 0 | 11 | — | — | — | +0.0 | 0.0 |
| 1h | 0 | 11 | — | — | — | +0.0 | 0.0 |
| 4h | 0 | 0 | — | — | — | +0.0 | 0.0 |
| Evidence strong | 0 | 1 | — | — | — | +0.0 | 0.0 |
| Evidence mixed | 0 | 1 | — | — | — | +0.0 | 0.0 |
| Evidence weak | 0 | 9 | — | — | — | +0.0 | 0.0 |

## Latest signals

| Published (UTC) | Pair | TF | Side | Entry | Stop | TP1 | Wave | Evidence | Status | Net R |
|---|---|---|---|---:|---:|---:|---|---|---|---:|
| 2026-10-12T22:07 | AAVEUSDT | 1h | long | 159.64 | 157.454 | 161.845 | 4 | weak | open | — |
| 2026-10-12T22:07 | SUIUSDT | 1h | long | 1.0559 | 1.03470 | 1.07774 | A | mixed | open | — |
| 2026-10-12T22:07 | UNIUSDT | 1h | long | 7.266 | 6.94996 | 8.08100 | C | weak | open | — |
| 2026-10-12T22:07 | NEARUSDT | 1h | long | 5.21 | 4.94568 | 5.50800 | B | weak | open | — |
| 2026-10-12T22:07 | BCHUSDT | 1h | long | 271.8 | 267.664 | 279.050 | B | weak | open | — |
| 2026-10-12T22:07 | DOTUSDT | 1h | long | 1.203 | 1.17811 | 1.25474 | 1 | weak | open | — |
| 2026-10-12T22:07 | ADAUSDT | 1h | long | 0.2402 | 0.235536 | 0.250943 | 1 | weak | open | — |
| 2026-10-12T22:07 | DOGEUSDT | 1h | long | 0.08418 | 0.0806361 | 0.0899800 | C | weak | open | — |
| 2026-10-12T22:07 | XRPUSDT | 1h | long | 1.3565 | 1.31251 | 1.45420 | C | weak | open | — |
| 2026-10-12T22:07 | SOLUSDT | 1h | long | 107.53 | 105.865 | 111.330 | C | weak | open | — |
| 2026-10-12T22:07 | BNBUSDT | 1h | short | 743.23 | 778.027 | 699.280 | 3 | strong | open | — |

All signals: [signals.json](signals.json) · totals: [summary.json](summary.json)
