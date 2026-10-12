# Tantya

**An Elliott Wave trading companion for Android, iOS, Windows, macOS and Linux.**

Open the pair you're trading on Binance and Tantya shows the same live
candlestick chart with an algorithmic wave count drawn on it. It projects the next
wave and turns that into a trade setup: bias, entry, stop, TP1/TP2 and
reward:risk. Polymarket prediction markets are a second source that runs on the
same engine.

No account, wallet or API key is needed. It reads public market data only and
never places orders. *It is an analysis tool, not financial advice.*

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/chart-1h.png" width="200" alt="1h chart with an A-B-C count, projected wave C, SL/TP tags and a LONG setup"><br><sub><b>Live chart + setup</b><br>count, projection, SL/TP, 4h check</sub></td>
    <td align="center"><img src="docs/screenshots/chart-4h.png" width="200" alt="4h chart after a completed correction, projecting a new wave 1"><br><sub><b>Any timeframe</b><br>4h: correction done, new wave 1</sub></td>
    <td align="center"><img src="docs/screenshots/scanner.png" width="200" alt="Scanner results ranked across the top 50 pairs"><br><sub><b>Scanner</b><br>best setups across the top pairs</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/pairs.png" width="200" alt="Binance pairs sorted by 24h volume"><br><sub><b>Pairs</b><br>Binance spot by 24h volume</sub></td>
    <td align="center"><img src="docs/screenshots/about.png" width="200" alt="About tab with an Elliott Wave diagram and the three rules"><br><sub><b>About</b><br>how to use it, and the algorithm</sub></td>
    <td align="center"><img src="docs/screenshots/overlays.png" width="200" alt="5m count with another timeframe's count overlaid in its own colour"><br><sub><b>Timeframe overlays</b><br>several timeframes on one chart</sub></td>
  </tr>
</table>

<sub>Screenshots from the iPhone simulator (iOS 27) with live Binance data on
2026-10-07. Android, Windows and macOS run the same Flutter code.</sub>

## What it does

- **Live chart with the prediction drawn on it**: wave labels on the swings, a
  dashed projection of the next wave into the empty space on the right, the target
  zone, and SL / TP1 / TP2 on the price axis.
- **Trade setup** from the best count: LONG/SHORT, entry, an ATR-buffered stop,
  two targets and reward:risk, plus the alternate counts.
- **Higher-timeframe check**: does the 4h agree with your 1h setup?
- **Timeframe overlays**: other timeframes' counts drawn on the same chart, one
  colour each (5m red, 15m yellow, 30m blue, 1h orange, …), with their target overlaps (confluence)
  outlined, and an "All timeframes" table showing how many point which way.
- **Scanner** across the top 30/50/100 pairs, and **background alerts** for fresh
  setups.
- **Track record**: tracked setups are settled at their target or stop, and
  scored in R per timeframe and by higher-timeframe agreement, so you can see
  whether the method actually works.
- **Evidence report**: EMA 3/25/50/100/200, volume per wave, MACD, RSI 14 and CCI 20
  checked against the wave in progress ("Healthy wave 3?", "Wave 5 exhaustion?"),
  following the layered method: indicators are evidence, price is the result.
- **MACD**: a momentum pane under the chart, read against the wave count (does
  wave 3 carry the most momentum? does wave 5 diverge?), and whether momentum
  backs the setup.
- **Momentum bursts**: flags fast, heavy moves (volume spike + MACD jump, RSI
  jump, EMA 3 twisting through 25/50) with ⚡ on the chart, and measures in the
  backtest whether riding them paid.
- **Volume buckets**: volume by price for each of the last three years
  (2024 / 2025 / 2026), showing where each year's buyers are now trapped above the
  price ("water left in the bucket") and where support was built.
- **Backtest**: replay the app's own setups over up to 5,000 past candles, with no
  look-ahead, and see the hit rate, average R, drawdown and equity curve, broken
  down by evidence, MACD, wave and direction.
- **How this was computed**: every setup's numbers step by step: swings, Fibonacci
  fit, score, target zone, stop (with the ATR buffer), R:R and the projected path.
- **Light / dark theme**: System, Light or Dark in the About tab (and a one-tap
  toggle at the bottom of the desktop side rail), remembered across restarts.
- **Desktop**: a big chart with the setup beside it, a side navigation rail,
  mouse-wheel zoom and a crosshair that follows the pointer.

## Tabs

- **Crypto**: two views.
  - **Pairs**: Binance spot pairs by 24h volume (stablecoin pairs and leveraged
    tokens hidden), with search across every symbol.
  - **Scanner**: runs the EW engine on the top 30/50/100 USDT pairs for one
    timeframe and ranks their setups. Tapping a result opens the pair on that
    timeframe. See *Scanner* below.
- **Polymarket**: trending prediction markets, categories and search. A market
  opens on the same live chart and wave count, per outcome.
- **Setups**: setups you chose to track, settled against real prices, with a
  track record (hit rate and average R).
- **Watchlist**: Polymarket price alerts (moves ±N points, level crossings, close).
- **About**: what the app does, a step-by-step guide to using it while trading, a
  chart legend, a one-minute Elliott Wave primer with a diagram, the full
  prediction algorithm, setup and track-record rules, limitations, data sources
  and a disclaimer. The swing sensitivities, Fibonacci table, stop buffer and
  expiry are read from the engine's constants. The projection table is
  hand-written, so keep it in step with `_impulse` / `_correction`.

## The chart (`lib/screens/live_chart.dart`)

A custom painter, not a chart library, so the prediction can be drawn in empty
space right of the last candle:

- live candles and volume; drag to pan, pinch to zoom, long-press for an OHLC
  crosshair, double-tap to reset
- the wave count: a zigzag through the labelled swings (1–5, A–C)
- the **projected path** (`projectPath` in `lib/elliott.dart`): the next few waves
  the count implies (e.g. from wave 3: 4 → 5 → A), each with its price, so you can
  see where price is expected to go. The first step is the middle of the count's
  target zone. Later steps use textbook ratios (W4 38.2% of W3, W5 = W1, A 50% of
  1–5, B 50% of A, C = A) and are drawn fainter, since each rests on the guesses
  before it. The path stops at wave C; after a finished A-B-C only the new trend's
  wave 1 is shown.
- the target zone band, plus SL / TP1 / TP2 / last-price tags on the price axis

## How the wave count works (`lib/elliott.dart`)

1. **Swings**: zigzag pivots at four sensitivities (5/8/12/18% of the visible
   range). Each sensitivity is roughly a wave degree.
2. **Candidates**: every impulse (1–5, then A–B–C after it) and standalone A–B–C
   ending at the latest swing. Each is read two ways: the last swing ended a wave,
   or it is still part of the wave in progress.
3. **Hard rules** reject a count: wave 2 retraces past wave 1's start, wave 3 doesn't
   pass wave 1, wave 4 overlaps wave 1, or wave 3 is the shortest of 1/3/5.
4. **Score**: how close the ratios are to the Fibonacci guidelines (W2 50/61.8%,
   W3 1.618/2.618/1×, W4 23.6/38.2/50%, W5 0.618/1/1.618×, B 38–79%, C 0.618/1/1.618×),
   plus alternation. This is multiplied by completeness, because more confirmed
   waves means less guessing. **The score says how textbook the count is, not how
   likely it is.**
5. **Size discount**: a count should span at least 8% of the chart's candles
   (minimum 12) and 25% of its price range. Size = √(span fit × amplitude fit),
   and score = fit × (0.3 + 0.7 × size). This stops a three-candle A-B-C inside a big
   trend from outranking the trend. Counts with size < 0.5 get a "Small count" note.
   Measured on the top 50 pairs on 1h, primary counts under 10 candles went from
   15 to 2, and the median span from ~21 to 37 candles. Rerun with
   `dart run tool/count_sizes.dart 1h 50`.
6. **Projection** for the wave in progress: a Fibonacci target zone and an
   invalidation level. Counts already invalidated, or whose target is already
   behind price, are dropped.

The top count is primary, and up to four alternates are listed and can be chosen
on the chart.

## Multi-timeframe agreement (`lib/mtf.dart`)

Each timeframe is checked one degree up: 1m→15m, 5m→1h, 15m→1h, 1h→4h, 4h→1D.
1D has no higher timeframe. The higher timeframe's primary count *agrees* when it
expects the same direction as the setup, *conflicts* when it expects the opposite,
and is *unknown* when there is no count.

- **Chart**: a badge under the setup ("✓ 4h agrees · Impulse ↑ · wave 3…" or
  "⚠ 4h expects ↓…"). It refreshes every 5 minutes, and tapping it switches the
  chart to the higher timeframe.
- **Scanner**: one extra request per pair with a setup. Rank × 1 / 0.85 / 0.6 for
  agree / unknown / conflict. The "4h agrees" filter is on by default.
- **Background alerts**: "higher TF must agree" follows that filter (on by default)
  and doubles the data estimate. Alerts saved before this feature keep it off.
- **Track record**: tracked setups store the verdict, and the scorecard compares
  hit rate and average R for *agreed* vs *against*. That's the evidence for
  whether the check helps.

## Timeframe overlays & confluence (`lib/layers.dart`)

Every timeframe has a fixed colour everywhere in the app: **1m purple, 5m red,
15m yellow, 30m blue, 1h orange, 4h cyan, 1D magenta**. Neighbouring timeframes
get contrasting hues rather than a gradient (a red→orange→yellow run was hard to
tell apart); a test keeps neighbours at least 40° apart in hue. The chart's own count uses its
timeframe's colour.

- **Overlay chips** under the timeframes draw other timeframes' counts on the
  chart: their swings, labels, projected next wave and target band, thinner than
  the chart's own. Points are placed **by time** (`indexAt`), so a 1h count lines
  up on a 5m chart and the other way round. The next-higher timeframe is on by
  default and follows timeframe changes until you pick overlays yourself.
- **Off-screen targets**: a longer timeframe's target is often outside a short
  chart's price range, so it is pinned as a coloured marker to the top or bottom
  edge ("1h ↑ 84,893").
- **Confluence** (`findConfluence`): where two shown timeframes' target zones
  overlap *and* expect the same direction, the overlap is outlined on the chart
  ("5m+15m ↑"). Pairs spanning more degrees are listed first.
- **All timeframes table** in the setup card: each timeframe's count as
  "↑ wave 4 of impulse ↓" (the arrow is the expected next move; the structure's own
  direction is in the text), its target, alignment ("All 6 expect ↑" or
  "4 expect ↑ · 2 ↓"), and the confluences. Tap a row to toggle its overlay.

Opening a chart now counts every timeframe (about six history requests, then a
recount every 5 minutes). The same data feeds the higher-timeframe badge.

## MACD (`lib/indicators.dart`)

Standard MACD (12, 26, 9): EMAs seeded with a simple average, signal = EMA(9) of
MACD, histogram = MACD − signal. The pane under the chart shows histogram bars
(paler while shrinking), the MACD line (dark) and the signal line (grey), in
neutral colours because the timeframe overlays use the bright hues.
Toggle it with the line-chart icon. The crosshair shows MACD and signal values.

The setup card's **MACD** section reads it three ways:

- **State**: bullish or bearish (histogram above or below zero), rising or
  falling, and a recent cross.
- **Does momentum back the setup?** *Backs* (histogram on the trade's side),
  *turning* (wrong side but moving toward it) or *against*.
- **Against the wave count** (`macdNotes`), measuring each wave's momentum as the
  MACD line's extreme during that wave:
  - wave 3 should be the momentum peak among waves 1, 3 and 5 (✓, or ⚠ if not);
  - wave 5 past wave 3 on weaker MACD is **divergence**, the classic sign an
    impulse is ending (✓); no divergence means it may extend (⚠); while wave 5 is
    still running, "divergence building" is an early warning;
  - wave C past wave A on weaker MACD is typical as a correction ends (✓); a
    stronger C means it may not be finished (⚠).

**MACD doesn't change scores or setups yet.** Each tracked setup records the MACD
verdict, and the Setups tab's **By MACD momentum** table compares results for
*backed* / *turning* / *against*. Folding MACD into the ranking should wait until
that comparison shows it helps.

## Evidence report (`lib/evidence.dart`, `lib/indicators.dart`)

Built on a layered analysis method the users sent (a ChatGPT write-up on studying
past futures data): **price → EMA + volume → MACD → RSI / CCI → Elliott Wave**,
where each indicator answers one question (EMA: which direction? volume: how many
are participating? MACD: how fast? RSI: how tired? CCI: how strong?) and
"indicators = evidence, price = actual result".

Indicators (all standard): EMA 3/25/50/100/200 (`K = 2/(N+1)`), drawn in
Binance's colours (3 yellow, 25 pink, 50 purple, 100 red, 200 green) with a
Binance-style legend strip on top showing each value ("EMA(25) 83,473.09"), which
follows the crosshair; the fast EMA 3 makes it easy to see candles flip. Toggled
with the timeline icon. The evidence report's "EMAs stacked" check uses 25/50/200. RSI 14 (Wilder smoothing), CCI 20 (typical price,
0.015 × mean deviation), and average volume per wave. MACD, RSI and CCI each get
their own pane under the chart, in any combination: tick them in the pane menu
(checkboxes; it stays open while ticking). The choice is remembered across charts
and restarts (`chart.panes.v1`), and on phones each pane adds height so the price
area doesn't shrink.

The card's checklist picks a template from the wave in progress:

| Wave | Checks (✓ = supports the reading) |
|---|---|
| **3** "Healthy wave 3?" | EMAs stacked with the move · MACD speeding up · CCI beyond ±100 · RSI strong, not exhausted (55–75, or 25–45 down) · volume higher than wave 2 |
| **5**, or just after 5 "Wave 5 exhaustion?" | price past wave 3 · MACD, RSI and CCI weaker than in wave 3 (divergence) · volume lower than wave 3 |
| other waves "Evidence for wave X" | EMAs stacked · MACD speeding up · RSI has room · CCI on the move's side · volume rising for impulsive waves (1, 3, 5, A, C), lighter for pullbacks (2, 4, B) |

The score is "n of m" (unknowns don't count) and reads as strong (≥ ⅔), mixed or
weak. It's **informational**: tracked setups record it, and the Setups tab's
**By evidence** table compares results, so we can see whether strong evidence
actually wins more before letting it affect scores. Open interest (mentioned in the
write-up) needs Binance futures data and isn't included; the app uses spot.

## Momentum bursts (`lib/burst.dart`)

From the users: bots and whales show up as *"a sudden boost in MACD and RSI and a
twist of the EMA combination in a short time — ride with the whale."*

**Detection** (within 5 candles, all causal: no look-ahead):

- **Volume spike (required)**: the window's heaviest candle is ≥ 3× the 50-candle
  average before it.
- **At least two of**:
  - MACD histogram ≥ 2.5 standard deviations from its last 100 candles, in the
    move's direction;
  - RSI moves ≥ 15 points;
  - the EMA twist: EMA 3 was not beyond EMA 25 and 50 at the window's start, and is
    beyond both now.
- A burst can't re-fire in the same direction within 5 candles.

**Shown**: ⚡↑/⚡↓ on the burst candle (bolt toggle), and a card section with the
latest burst and its signals. The backtest screen has a **"Momentum bursts: did they
keep going?"** card: continuation after 3 / 12 / 24 candles, average move, and a
ride-the-burst trade (entry at the burst close, stop at the burst's start, target 2R,
24-candle expiry), split by direction and by 3 vs 4 signals.

**Result (2026-10-12, 5 majors × 5m / 15m / 1h, 5,000 candles each, 722 bursts):**
price kept going after 12 candles **44–58%** of the time, and the ride-the-burst
trade averaged **−0.02 to +0.04 R** per timeframe, before fees: a coin flip. Bursts
with all 4 signals were *not* better (24–47% continuation). The detector finds the
footprint; it doesn't tell you which way it resolves. Reproduce with
`BURSTS=BTCUSDT,ETHUSDT:5m,1h flutter test test/live_burst_test.dart`.

## Volume buckets (`lib/volume_profile.dart`)

From the users: *"the volume is what I'm after, to find who has a lot of trapped
volume. Like buckets: which ones still have water left in them, being squeezed.
Bucket 1 is 2026, bucket 2 is 2025, bucket 3 is 2024."*

- **Data**: daily Binance spot candles since January 1 two years back (about 1,000
  days, one request), fetched once per pair per session.
- **Profile**: one volume profile per calendar year on a shared 100-level price grid.
  Each day's quote volume (USDT) is spread evenly over its high–low range.
- **Chart** (drop icon): stacked horizontal bars from the left edge, one muted
  colour per year (2024 brown, 2025 slate, 2026 teal), plus each year's POC (the
  busiest price) as a line. Best viewed on 1D, where years of price fit on screen.
- **Card**: per year, the volume traded, its busiest price, and the share that traded
  **above today's price**. That share is the "trapped water": buyers from that year
  who still hold are underwater. Also listed: the heaviest volume zone above the price
  (likely resistance) and below it (support), with the year that built each.
- **Limits**: exchange data shows what *traded* at a price, not who still holds or
  which corporates. This is the standard estimate. Binance spot volume only (no
  futures or other exchanges).

Example (BTC, 2026-10-12, price 82,700): 2025 traded $768B with 94% of it above
today's price (POC 103,850), so most of 2025's buyers are underwater, and the
heaviest overhead zone is 93,771–98,153, mostly 2025. Reproduce with
`BUCKETS=BTCUSDT flutter test test/live_buckets_test.dart`.

## Backtest (`lib/backtest.dart`, `lib/screens/backtest_screen.dart`)

"Backtest <pair> on <timeframe>" in the setup card replays the app over past
candles (Binance: 1,000 / 2,000 / 5,000, paged 1,000 per request; Polymarket:
what its history API gives).

- **No look-ahead.** At each candle the engine sees only the 300 candles up to it,
  the same window the live chart uses, and takes the setup it would have shown.
  A test checks that adding later candles never changes earlier trades.
- **Settling.** Same rules as tracked setups: entry at that candle's close, then
  TP1 or the stop, whichever is touched first. A candle touching both counts as the
  stop, and after 50 candles the trade closes at the market. One trade at a time.
- **Filters.** Minimum R:R (default 1) and minimum score.
- **Results.** Trades, hit rate, average and total R, max drawdown (R), worst
  losing streak, equity curve, and breakdowns by evidence level, MACD verdict,
  wave traded and direction, plus the latest trades.
- **Not modelled.** Fees, funding, slippage and the higher-timeframe check.
- Runs in a background isolate (`compute`). 5,000 candles take about 0.1 s.

First results (1h, 5,000 candles to 2026-10-11, all setups with R:R ≥ 1): roughly
**breakeven before fees** (BTC +0.08 R per trade, ETH −0.19, XRP −0.05).
Setups entered with **strong evidence** did better than weak ones on 4 of 5 pairs
(e.g. BTC +0.38 R vs +0.06, ETH +0.11 vs −0.13), but on only 30–50 trades each.
That's a hint worth tracking, not proof. Reproduce with
`BACKTEST=BTCUSDT,ETHUSDT:1h:5000 flutter test test/live_backtest_test.dart`
(network; skipped by default).

## Pair alerts (`lib/pair_watch.dart`, `lib/screens/pair_alert_sheet.dart`)

Tap the bell on any Binance pair's chart to watch it on one timeframe (15m–1D). The background check
(`checkPairs` in `lib/alerts.dart`, with the other checks: about every 15 min on Android, when iOS allows,
every 15 min while open on desktop) notifies:

- **New buy / sell setup:** the count gives a trade with R:R ≥ 1 that wasn't there at the last check.
- **Wave count changes**, e.g. wave 3 → wave 4, or no valid count any more.
- **Target reached / count invalidated:** price enters the count's target zone or breaks its
  invalidation level (once per count).
- **Price levels** (rises above / falls below) and **big moves** (±N% since the last move alert).

The count and setup come from closed candles only, so a forming candle can't make them flicker; price
rules use the latest price. A new watch records what the chart shows now, so the first alert is a real
change. Watched pairs appear at the top of the Watchlist tab; tapping a notification opens the chart.

## Position sizing and trade journal (`lib/sizing.dart`, `lib/journal.dart`)

**Size this trade** (on a setup) works out how much to buy or sell so that hitting the stop loses exactly
your chosen risk (balance × risk %), fees on the way in and out included. It shows the result at the stop,
TP1 and TP2, and the leverage the size needs. Leverage only changes margin and liquidation, so it suggests
the smallest that carries the position. It also gives a safe maximum: liquidation must stay at least 1.5
stop-distances from entry, assuming 0.5% maintenance margin. It warns about unsafe leverage, risk above 2%
and very tight stops. Balance, risk and fee are remembered.

**Trade journal** (Setups → Trade journal) holds the trades you actually took: log one from the sizing
sheet or add it by hand, then close it with your exit. It shows win rate, P&L and R after fees, an equity
curve, results when you followed your plan versus broke it, and what each tagged mistake cost (moved stop,
chased entry, exited early, …). Trades can be copied as CSV for Sheets or Excel. R is measured against the
original stop.

## Out-of-sample validation (`test/live_validate_test.dart`)

Before making "strong evidence" setups the default, they were tested on 30 liquid Binance pairs × 1h and 4h
(5,000 candles each, ~14,500 trades), with the newest 30% of trades held out. Fees: 0.1% taker per side.

- Before fees the setups were about breakeven; after fees every group lost (1h: −0.15 R/trade older
  data, −0.25 R on the holdout). On 1h, fees alone are ~0.19 R per trade because the stops are tight.
- The best filter found on the older data (strong evidence + ADX ≥ 30 + MACD agreeing, +0.16 R)
  fell to −0.01 R on the holdout: overfitting, not an edge.
- A trend filter (ADX ≥ 25) chosen before looking did not help; strong trends did slightly worse.

So there is no "high-confidence" default. Re-run with
`VALIDATE=BTCUSDT,ETHUSDT:1h:5000 OUT=trades.csv flutter test test/live_validate_test.dart`.

## Public track record (`lib/track_record.dart`, `tool/track_record.dart`)

An hourly GitHub Action (`.github/workflows/track-record.yml`) runs the engine on 20 fixed pairs
(1h and 4h), settles open signals and logs new ones, and commits `signals.json`, `summary.json` and a
`README.md` to the [`track-record`](https://github.com/tofilagman/tantya/tree/track-record) branch.
Nothing is picked or deleted by hand, and the branch history shows each signal was published before
its outcome. The app shows it under Setups → Public track record.

- Entry is the live price when the job runs. A signal is only logged if the job runs within 20 minutes
  of the candle opening; late runs skip that candle, which never depends on the outcome.
- Same rules as tracked setups (TP1 or stop first; a candle touching both counts as the stop; 50-candle
  expiry), one open signal per pair and timeframe. Results are shown before and after fees.
- Each signal records the engine's commit, so changes to the method show up in the record.
- The engine path (`candles`, `elliott`, `indicators`, `evidence`, `trade`, `backtest`) is pure Dart so
  the job can run it with `dart run`. Keep Flutter imports out of it.
- Dry run locally: `TRACK_MAX_DELAY_MIN=240 dart run tool/track_record.dart /tmp/track`. Point the app
  at local data with `--dart-define=TRACK_RECORD_RAW=http://localhost:8765`.

## How this was computed (`lib/explain.dart`)

A collapsible panel in the setup card that walks through the setup with real
numbers:

1. the swings: each wave's start → end, size, % and candles;
2. the Fibonacci fit: each measured ratio against its ideals, its fit, and the average;
3. the score: average fit × completeness × rule adjustments = fit; span and
   amplitude → size; score = fit × (0.3 + 0.7 × size);
4. the target and invalidation: which wave, its base length, the ratio range and
   the rule that invalidates it;
5. the trade levels: entry, stop = invalidation ± ½ ATR(14), risk, TP1/TP2 with R:R;
6. the projected path: each step's price and ratio.

The explanation recomputes everything from the count's points. A test runs the
real engine over several price paths and checks that the explained rule reproduces
every count's target zone and invalidation exactly, so the panel can't drift away
from the engine.

## Trade setups (`lib/setup.dart`)

- **Bias** is the direction of the wave in progress. **Entry** is the current price.
- **Stop** sits at the invalidation level plus a buffer of ½ ATR(14), so a wick
  to the exact wave extreme doesn't stop it out. When invalidation is on the
  target side (wave 2, wave 4), the stop goes at the start of the wave in
  progress instead.
- **TP1/TP2** are the near and far edges of the target zone. A setup with R:R
  under 1 to TP1 gets a warning.

**Track record splits:** the Setups tab breaks results down **by timeframe**
(closed and open counts, hit rate and average R per timeframe) and **by
higher-timeframe verdict**. Timeframe chips filter both the list and the whole
scorecard, so you can ask questions like "do 1h setups that 4h agreed with
actually pay?". `Scorecard.groupBy` builds both splits; each group is itself a
`Scorecard`.

**Tracking:** a tracked setup settles at whichever it touches first, TP1 or the
stop. If one candle spans both, it counts as stopped, which is the conservative
choice. After 50 candles of its timeframe it expires at the market price. Results
are in R (multiples of the risk). Checks run when the Setups tab opens and in the
background job, which notifies when a setup closes.

## Scanner (`lib/scanner.dart`)

`evaluatePair()` runs the chart's exact pipeline on each pair: `analyze` → primary
count → `TradeSetup.from` with the ATR stop buffer. A scan result is therefore
always the setup you see when you open the chart. Pairs are ranked by:

```
rank = score × min(R:R to TP1, 3)/3 × (1 − ½·progress) × (1 if counts agree else 0.8)
       × higher-timeframe factor (agree 1, unclear 0.85, conflict 0.6)
```

`progress` is how much of the way from the wave's start to TP1 price has already
travelled, so fresh setups rank above ones that have mostly played out. Results
can be filtered by long/short, R:R ≥ 1.5 and agreeing counts. Candles are fetched
6 pairs at a time (50 pairs on 1h take about 10 seconds); a new scan, or leaving
the screen, cancels the one running.

### Background alerts (`lib/scan_alerts.dart`)

"Alert me about new setups like these" saves the scanner's current settings
(timeframe 15m–1D, top N, long/short, R:R, agreeing counts) plus two of its own:
**score ≥ 60** and **under 50% of the move done**. The background job (every
15 minutes on Android) then:

- scans **at most once per candle** of that timeframe (skipped if the current
  candle was already scanned);
- reuses the top-pair list for a day, because the full ticker list is about 2 MB;
- notifies only setups not seen before. A setup is keyed by
  `symbol|frame|side|wave|wave-start time`. Times are used, not candle indexes,
  because indexes shift as candles arrive. Seen keys are kept for 3 days;
- sends one notification for each of the best three new setups (tapping opens
  that pair on that timeframe), plus a summary when there are more (tapping
  opens the scanner).

Estimated data use is shown on the card: about 15 KB gzipped per pair per scan.
5m is excluded because the job can't run more often than every 15 minutes (on
iOS, far less often; see *iOS*).

Crypto pairs are highly correlated, so one market-wide swing often produces the
same pattern on many pairs at once. Ten "SHORT · ABC complete" results are closer
to one trade than ten.

## Data sources (`lib/sources/`)

| | History | Live |
|---|---|---|
| Binance | `data-api.binance.vision/api/v3/klines` (real OHLCV, 300 candles) | `wss://data-stream.binance.vision/ws/<sym>@kline_<tf>` |
| Polymarket | CLOB `prices-history`, bucketed into candles (no OHLC exists) | market channel WebSocket: book, price_change, last_trade_price |

Both implement `CandleSource`, which the chart, the EW engine and the setup
tracker all depend on. Adding an exchange means adding one source.

Binance quirks: the `data-api` / `data-stream` hosts are market-data-only, need no
key and were reachable from the PH. The all-symbol 24h ticker is about 2 MB, so
it's fetched once per tab load.

Polymarket quirks (in `lib/api.dart`): `outcomes` / `outcomePrices` /
`clobTokenIds` are JSON strings inside the JSON. Placeholder markets
(`active: false`) and effectively settled ones are filtered out. Price-history
windows are capped at about 15 days.

**Polymarket may be blocked where you are.** On 2026-10-07 the Philippine ISP
Converge answered Polymarket's API hostnames with its own server (161.49.61.85)
instead of Cloudflare's. Its certificate can't match, so the TLS handshake fails.
The app reports "Your network or internet provider may be blocking it" instead
of a raw TLS error. It deliberately doesn't work around the block: such blocks
usually follow a regulator's order. The Binance side is unaffected.

## Build

Requires Flutter 3.47+, JDK 21 (`flutter config --jdk-dir <jdk21>`) for Android,
and Xcode for iOS (see *iOS*).

```bash
flutter test
flutter build apk --release
```

For a phone, build per-architecture (arm64 is about 19 MB vs 53 MB universal):

```bash
flutter build apk --release --split-per-abi
```

**Release signing:** `keystore.properties` and `keystore/tantya-release.jks` at the
repo root (both gitignored) sign release builds. Without them, e.g. on a fresh
clone, Gradle falls back to the debug key, and that APK **cannot update** a phone
running a release-signed install. **Back up both files somewhere other than this
laptop.** If they're lost, every install has to be uninstalled (losing tracked
setups) before a new build can go on.

## Desktop (Windows, macOS, Linux)

Same Flutter code. On windows at least 900 px wide the app uses a side navigation
rail. Chart screens at least 1000 px wide put the chart on the left (filling the
window) and the setup card on the right. On the chart, the mouse wheel zooms and
the crosshair follows the pointer. Tablets get the same layout.

- **Alerts run only while the app is open.** Desktop has no WorkManager-style
  scheduler for Flutter, so watchlist, setup and scanner checks run on a 15-minute
  timer inside the app (`isDesktop` / `_startDesktopChecks` in `lib/alerts.dart`).
  Minimised is fine; quitting stops them. Notifications use the system notification
  centre on each platform.
- **macOS**: universal (Intel and Apple Silicon), sandboxed with the
  `network.client` entitlement. Without that entitlement every request fails in
  release builds. It is ad-hoc signed, not notarized (that needs a paid Apple
  Developer account), so on first launch macOS blocks it: open
  **System Settings → Privacy & Security → Open Anyway** (or right-click → Open on
  older macOS).
- **Linux**: built on GitHub Actions (Ubuntu). Ships as `tantya-linux-x64.tar.gz`:
  unpack and run `./tantya/tantya`. Needs GTK 3, which every desktop distribution has.
  Untested on a real Linux machine so far.
- **Windows**: built only on GitHub Actions (`.github/workflows/desktop.yml`), since
  a Mac can't build Windows apps. Unsigned, so SmartScreen warns on first run
  (**More info → Run anyway**). Unzip and run `tantya.exe`; keep the DLLs and
  `data/` folder next to it.
- Window: opens at 1280×820, minimum 900×620 (`macos/Runner/MainFlutterWindow.swift`,
  `windows/runner/main.cpp`, and `WM_GETMINMAXINFO` in `win32_window.cpp`).
- Icons: `tool/render_icon.swift macos|windows` (the Windows `.ico` packs 16–256 px PNGs).

```bash
flutter build macos --release   # → build/macos/Build/Products/Release/Tantya.app
```

**CI** (`.github/workflows/desktop.yml`): every push to `master` builds Windows
(and runs the tests), Linux and macOS, and keeps `tantya-windows-x64.zip`,
`tantya-linux-x64.tar.gz` and `tantya-macos.zip` as workflow artifacts. Pushing a tag like `v0.2.0` also
attaches them to a GitHub Release.

## iOS

**Status (2026-10-07):** builds with Xcode 27 and runs on the iPhone simulator,
where the live charts, wave counts, setups, scanner and the notification
permission flow were checked. An unsigned device build (arm64 release, 18 MB)
compiles. Not yet installed on a physical iPhone (needs signing), and a
background refresh hasn't yet been observed firing.

```bash
flutter build ios --simulator --debug     # Simulator
flutter build ios --release --no-codesign # device build, compile check only
```

**To install on an iPhone:** sign in to Xcode → Settings → Accounts with an Apple
ID, open `ios/Runner.xcworkspace`, set Runner → Signing & Capabilities → **Team**,
connect the phone (trust this Mac, enable Developer Mode), then
`flutter run --release`. A **free** Apple ID's installs stop opening after 7 days.
The paid developer program gives 1-year installs and TestFlight.

Plugins come in through Swift Package Manager (Flutter's default), so CocoaPods
is not needed, despite `flutter doctor`'s warning.

What's iOS-specific:

- `ios/Runner/AppDelegate.swift` registers the background task
  (`tantya.checkWatchlist`, the same name as `_taskName` in `lib/alerts.dart`) before
  `didFinishLaunching` returns, as the UIScene lifecycle requires. It also gives the
  background engine its plugins and makes notifications show in the foreground.
- `Info.plist`: `BGTaskSchedulerPermittedIdentifiers` and `UIBackgroundModes: fetch`.
  A task ID missing from that list crashes the app at launch, so a clean launch
  confirms the wiring.
- Notifications ask permission only when the user turns an alert on, never at launch
  (the background isolate also initialises them and can't prompt).
- **Background checks are much less frequent than on Android.** iOS runs
  `BGAppRefreshTask` when it decides to (often hourly or less, less still for rarely
  opened apps). In-app texts say so via `backgroundCadence` in `lib/alerts.dart`.
  Charts, counts, setups and the scanner are unaffected while the app is open.
- The app icon is a single 1024 px image rendered by `tool/render_icon.swift ios`
  (same design as Android, scaled up because iOS doesn't crop it to a safe zone).
- Apple verifies TLS certificates through the system trust store, more strictly
  than Android. That is why the Polymarket DNS block showed up on iOS first.

To force a background run while debugging (pause in Xcode, then in the lldb console):

```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"tantya.checkWatchlist"]
```

## Gotchas

- **Don't mix split and universal APKs on one phone.** `--split-per-abi` adds 1000×ABI
  to the version code (arm64 0.2.0 = 2003), but the universal APK keeps the plain
  code (3). Android treats universal-after-split as a downgrade and refuses to
  install it over the existing app. Phones should stay on the arm64 APK.

- `res/raw/keep.xml` keeps `@drawable/ic_notification`, which Dart refers to only
  by name. Without it the release shrinker deletes it and notification setup throws.
- WorkManager refuses to run a periodic job early, even with
  `cmd jobscheduler run -f`.
- Android serves SharedPreferences from memory, so editing the prefs XML with
  `run-as` while the app process is alive is invisible to the app. Kill the
  process first.
