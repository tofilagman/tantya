# Tantya

An Elliott Wave trading companion for Android. Open the pair you're trading on
Binance and Tantya shows the same live candlestick chart with an algorithmic wave
count drawn on it. It projects the next wave and gives a trade setup: bias, entry,
stop, TP1/TP2 and reward:risk. Polymarket prediction markets are a second source
that runs on the same engine.

No account, wallet or API key is needed. It reads public market data only and
never places orders.

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
- the projected next wave: a dashed arrow to the middle of the target zone
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
15-minute background job, which notifies when a setup closes.

## Scanner (`lib/scanner.dart`)

`evaluate()` runs the chart's exact pipeline on each pair: `analyze` → primary
count → `TradeSetup.from` with the ATR stop buffer. A scan result is therefore
always the setup you see when you open the chart. Pairs are ranked by:

```
rank = fit × min(R:R to TP1, 3)/3 × (1 − ½·progress) × (1 if counts agree else 0.8)
```

`progress` is how much of the way from the wave's start to TP1 price has already
travelled, so fresh setups rank above ones that have mostly played out. Results
can be filtered by long/short, R:R ≥ 1.5 and agreeing counts. Candles are fetched
6 pairs at a time (50 pairs on 1h take about 10 seconds); a new scan, or leaving
the screen, cancels the one running.

### Background alerts (`lib/scan_alerts.dart`)

"Alert me about new setups like these" saves the scanner's current settings
(timeframe 15m–1D, top N, long/short, R:R, agreeing counts) plus two of its own:
**fit ≥ 60** and **under 50% of the move done**. The 15-minute WorkManager job then:

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
5m is excluded because the job can't run more often than every 15 minutes.

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

## Build

Requires Flutter 3.47+ and JDK 21 (`flutter config --jdk-dir <jdk21>`).

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

## Gotchas

- `res/raw/keep.xml` keeps `@drawable/ic_notification`, which Dart refers to only
  by name. Without it the release shrinker deletes it and notification setup throws.
- WorkManager refuses to run a periodic job early, even with
  `cmd jobscheduler run -f`.
- Android serves SharedPreferences from memory, so editing the prefs XML with
  `run-as` while the app process is alive is invisible to the app. Kill the
  process first.
