import 'package:flutter/material.dart';

import '../elliott.dart';
import '../layers.dart';
import '../setup.dart';

const appVersion = '0.2.0';

/// What the app is, how to use it while trading, and exactly how predictions are made.
/// The swing sensitivities, Fibonacci table, stop buffer and expiry are read from the
/// engine's constants. The projection table mirrors `_impulse`/`_correction` in
/// elliott.dart by hand; update both together.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: const Color(0xFF2D6BEA), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.show_chart, color: Colors.white, size: 34),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tantya', style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text('Elliott Wave companion for active traders', style: text.bodyMedium),
                    Text('Version $appVersion', style: text.labelSmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Tantya ("estimate" in Tagalog) reads the market you are trading as an Elliott Wave pattern. '
            'It shows the same live candlestick chart, draws the most likely wave count on it, projects '
            'the next wave, and turns that into a trade setup with an entry, a stop and targets.',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 8),
          const _Section(
            icon: Icons.route,
            title: 'Using it while you trade',
            initiallyExpanded: true,
            children: [
              _Step(1, 'Open the same pair and timeframe you are trading on Binance (Crypto tab), '
                  'or a prediction market (Polymarket tab).'),
              _Step(2, 'Read the primary count at the top of the card ("Impulse ↑ · wave 3 in progress") '
                  'and follow the dashed arrow on the chart: that is the projected next wave.'),
              _Step(3, 'Check the setup: LONG or SHORT, the stop (SL) and the targets (TP1, TP2). '
                  'Skip it when reward:risk to TP1 is under 1, or when the card says the alternate counts disagree.'),
              _Step(4, 'Check the badge under the setup. It shows whether the next timeframe up (e.g. 4h for a 1h '
                  'setup) expects the same direction. Setups that trade against the bigger picture are marked. '
                  'Tap the badge to open that chart.'),
              _Step(5, 'Place the order yourself on your exchange. Tantya only reads public market data. '
                  'It never connects to your account or trades for you.'),
              _Step(6, 'Tap "Track this setup". The Setups tab records whether it hit the target or the stop '
                  'first, so you can judge the method by real results.'),
              _Step(7, 'Too many pairs to watch? Crypto → Scanner ranks the strongest setups across the top pairs. '
                  'Turn on background alerts and you\'ll be notified when a fresh one appears, even with the app '
                  'closed. Tap the notification to open that chart.'),
            ],
          ),
          _Section(
            icon: Icons.candlestick_chart,
            title: 'Reading the chart',
            children: [
              _Legend(swatch: _bubble(context, '3'), text: 'A completed wave, labelled at its swing high or low.'),
              _Legend(swatch: _bubble(context, '4', outline: true), text: 'The wave in progress, at its projected target.'),
              _Legend(swatch: _line(scheme.primary, dashed: true), text: 'Projection: where the next wave is expected to go.'),
              _Legend(swatch: _box(Colors.green.shade600.withValues(alpha: 0.2)), text: 'Target zone (green for up, red for down).'),
              _Legend(swatch: _tag('SL', Colors.red.shade400), text: 'Stop: where the count is proven wrong.'),
              _Legend(swatch: _tag('TP1', Colors.green.shade600), text: 'First and second targets: near and far edge of the zone.'),
              _Legend(
                swatch: Row(mainAxisSize: MainAxisSize.min, children: [
                  for (final f in timeframeColors.values)
                    Container(width: 6, height: 16, color: f, margin: const EdgeInsets.only(right: 1)),
                ]),
                text: 'Overlays: other timeframes\' counts in their own colour (1m purple, 5m red, 15m orange, '
                    '1h yellow, 4h blue, 1D teal). Turn them on with the Overlay chips under the chart.',
              ),
              _Legend(
                swatch: Container(
                  width: 28,
                  height: 16,
                  decoration: BoxDecoration(border: Border.all(width: 1.5)),
                ),
                text: 'Confluence: two timeframes\' targets overlap and point the same way.',
              ),
              _Legend(
                swatch: const Icon(Icons.stacked_line_chart, size: 20),
                text: 'MACD pane (12, 26, 9): histogram bars, MACD line (dark) and signal line (grey). '
                    'The card says whether momentum backs the setup and what it means for the wave count.',
              ),
              const SizedBox(height: 8),
              Text('Drag to scroll back in time, pinch to zoom, long-press for a candle\'s OHLC and volume, '
                  'double-tap to snap back to live. The wave icon next to the timeframes hides or shows the count.',
                  style: text.bodyMedium),
            ],
          ),
          _Section(
            icon: Icons.waves,
            title: 'Elliott Wave in one minute',
            children: [
              Text(
                'Ralph N. Elliott observed in the 1930s that crowd psychology moves prices in a repeating rhythm: '
                'five waves with the trend (1–5), then three against it (A–B–C). Waves 1, 3 and 5 push; 2 and 4 '
                'pause. The pattern is fractal: every wave is made of smaller waves of the same shape.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 170, child: _WaveDiagram()),
              const SizedBox(height: 12),
              Text('Three rules can never be broken:', style: text.titleSmall),
              const SizedBox(height: 4),
              const _Bullet('Wave 2 never retraces beyond the start of wave 1.'),
              const _Bullet('Wave 3 is never the shortest of waves 1, 3 and 5.'),
              const _Bullet('Wave 4 never enters wave 1\'s price territory.'),
              const SizedBox(height: 6),
              Text('Everything else, such as the Fibonacci proportions, is a guideline that holds often but not always.',
                  style: text.bodyMedium),
            ],
          ),
          _Section(
            icon: Icons.memory,
            title: 'The prediction algorithm',
            children: [
              _Algo(
                n: 1,
                title: 'Find the swings',
                body: 'A zigzag filter marks swing highs and lows: a new swing starts once price reverses by a '
                    'set fraction of the chart\'s range. It runs at ${swingSensitivities.length} sensitivities '
                    '(${swingSensitivities.map((s) => '${(s * 100).round()}%').join(', ')}), roughly one per wave degree.',
              ),
              const _Algo(
                n: 2,
                title: 'List every possible count',
                body: 'Every impulse (1–5, then A–B–C after it) and every standalone correction (A–B–C) ending '
                    'at the latest swing becomes a candidate. Each is read two ways: either the last swing '
                    'finished a wave, or it is still part of the wave in progress.',
              ),
              const _Algo(
                n: 3,
                title: 'Apply the hard rules',
                body: 'Candidates that break any of the three rules are thrown out. So is any count where wave 3 '
                    'fails to go past the end of wave 1.',
              ),
              const _Algo(
                n: 4,
                title: 'Score against Fibonacci guidelines',
                body: 'Each wave\'s size is compared with the ideal ratios below. A match scores 1, falling off '
                    'smoothly within about ±15%. Alternation between waves 2 and 4 (one sharp, one shallow) adds '
                    'to the score. The average is weighted by completeness: a count with more confirmed waves '
                    'involves less guessing. Standalone corrections get a slight discount, and so do counts that '
                    'only make sense if a small wave started a much larger move.',
              ),
              const SizedBox(height: 4),
              const _FibTable(),
              const SizedBox(height: 12),
              _Algo(
                n: 5,
                title: 'Discount small counts',
                body: 'A count should span at least ${(minCountSpan * 100).round()}% of the chart\'s candles '
                    '(minimum $minCountBars) and ${(minCountAmplitude * 100).round()}% of its price range. Smaller counts '
                    'are valid but mostly noise at that timeframe, so their score shrinks, down to 30% for a tiny '
                    'one. A three-candle A-B-C inside a big trend can\'t outrank the trend. Such counts are '
                    'labelled "Small count".',
              ),
              const _Algo(
                n: 6,
                title: 'Project the next wave',
                body: 'The best count\'s wave in progress gets a target zone and an invalidation level:',
              ),
              const _ProjectionTable(),
              const SizedBox(height: 12),
              const _Algo(
                n: 7,
                title: 'Check the higher timeframe',
                body: 'The same analysis runs one timeframe up (1m→15m, 5m→1h, 15m→1h, 1h→4h, 4h→1D). If its '
                    'primary count expects the same direction as the setup, the setup "agrees". If it expects '
                    'the opposite, it "conflicts". In the scanner a conflict cuts the ranking to 60% and an '
                    'unclear higher timeframe to 85%. 1D has no higher timeframe and is not adjusted.',
              ),
              const _Algo(
                n: 8,
                title: 'Compare every timeframe',
                body: 'Each timeframe is counted separately. The All timeframes table shows what each one expects '
                    'next, how many agree, and where two timeframes\' target zones overlap in the same direction '
                    '(confluence). Overlapping targets from different degrees are a stronger level than '
                    'either alone.',
              ),
              const _Algo(
                n: 9,
                title: 'Check momentum with MACD',
                body: 'Elliott Wave makes momentum claims MACD can test: wave 3 should carry the strongest '
                    'momentum, and a wave 5 that makes a new extreme on weaker MACD (divergence) usually ends '
                    'the impulse. The same goes for wave C against wave A. These checks are shown as ✓ or ⚠ '
                    'but don\'t change the score yet: the Setups tab measures whether they help first.',
              ),
              const _Algo(
                n: 10,
                title: 'Rank and update',
                body: 'Counts already invalidated, or whose target is already behind the price, are dropped. '
                    'The highest score becomes the primary count, and up to four alternates are listed with '
                    'their share of the total score. The whole analysis reruns on every live update, '
                    'a few times a second.',
              ),
            ],
          ),
          _Section(
            icon: Icons.tune,
            title: 'How a setup is built',
            children: [
              const _Bullet('Bias: LONG if the wave in progress is expected to rise, SHORT if it is expected to fall.'),
              const _Bullet('Entry: the current price.'),
              _Bullet('Stop: at the invalidation level, plus a buffer of $stopBufferAtr × ATR(14) so a wick to the '
                  'exact wave extreme doesn\'t stop you out. For waves 2 and 4 the invalidation level is on the '
                  'target side, so the stop goes at the start of the wave instead.'),
              const _Bullet('TP1 / TP2: the near and far edges of the target zone.'),
              const _Bullet('R:R: distance to the target divided by distance to the stop. Below 1 to TP1 gets a '
                  'warning: price has already moved toward the target, so a pullback entry is better.'),
              const _Bullet('Score (0–100) is the count\'s fit to the guidelines, discounted if the count is small. '
                  'It ranks counts against each other. It is not a probability of winning.'),
            ],
          ),
          _Section(
            icon: Icons.fact_check,
            title: 'The track record',
            children: [
              const _Bullet('A tracked setup closes at whichever it touches first: TP1 (win) or the stop (loss).'),
              const _Bullet('If one candle spans both, it counts as a loss. That is the conservative choice.'),
              _Bullet('If neither is hit within $expiryCandles candles, it expires at the market price.'),
              const _Bullet('Results are in R, multiples of the risk taken: a win at R:R 2 is +2 R, a stop is −1 R.'),
              const _Bullet('Average R above 0 means the method made money per unit of risk. Judge it after 30 or '
                  'more setups, not 3.'),
              const _Bullet('Each tracked setup remembers whether the higher timeframe agreed, and the scorecard '
                  'compares the two groups. That tells you whether the higher-timeframe check actually helps.'),
              const _Bullet('Results are also split by timeframe, and the chips at the top of the Setups tab filter '
                  'everything to one timeframe. The method may work on 4h and fail on 5m; this is how you find out.'),
            ],
          ),
          _Section(
            icon: Icons.warning_amber,
            title: 'Limitations',
            children: [
              const _Bullet('Elliott Wave is interpretive. Experienced analysts often disagree on the same chart, '
                  'and studies of its predictive power are mixed at best.'),
              const _Bullet('Counts change as new candles arrive. A setup that looked clean an hour ago can be invalidated.'),
              const _Bullet('Lower timeframes (1m, 5m) are noisy, so counts there are less reliable.'),
              const _Bullet('Polymarket has no real candles. They are built from sampled prices, and those markets jump on news.'),
              const _Bullet('Live data can lag or drop. Check the Live dot above the chart.'),
            ],
          ),
          _Section(
            icon: Icons.cloud_outlined,
            title: 'Data & privacy',
            children: [
              const _Bullet('Crypto: Binance public market data (data-api.binance.vision and its WebSocket stream).'),
              const _Bullet('Prediction markets: Polymarket\'s public Gamma and CLOB APIs.'),
              const _Bullet('No account, login, wallet or API key is needed. Tracked setups and watchlists stay on '
                  'this phone.'),
              const _Bullet('Background scanner alerts, when on, download about 15 KB per pair per new candle. '
                  'The scanner card shows the daily estimate (e.g. ~20 MB/day for 50 pairs on 1h).'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Tantya is an analysis tool, not financial advice. Trading crypto and prediction markets can lose '
              'you money, including more than you expect. Only risk what you can afford to lose, and make your '
              'own decisions.',
              style: text.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bubble(BuildContext context, String label, {bool outline = false}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: outline ? scheme.surface : scheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.primary, width: 1.2),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: outline ? scheme.primary : scheme.onPrimary)),
    );
  }

  static Widget _line(Color color, {bool dashed = false}) => SizedBox(
        width: 28,
        height: 22,
        child: CustomPaint(painter: _DashPainter(color)),
      );

  static Widget _box(Color color) =>
      Container(width: 28, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)));

  static Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, required this.children, this.initiallyExpanded = false});

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step(this.n, this.text);
  final int n;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: scheme.primaryContainer,
            child: Text('$n', style: TextStyle(fontSize: 12, color: scheme.onPrimaryContainer, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.only(top: 7, right: 8), child: Icon(Icons.circle, size: 5)),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.swatch, required this.text});
  final Widget swatch;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(width: 44, child: Center(child: swatch)),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
          ],
        ),
      );
}

class _Algo extends StatelessWidget {
  const _Algo({required this.n, required this.title, required this.body});
  final int n;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$n. $title', style: text.titleSmall),
          const SizedBox(height: 2),
          Text(body, style: text.bodyMedium),
        ],
      ),
    );
  }
}

class _FibTable extends StatelessWidget {
  const _FibTable();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    String fmt(double r) => r < 1 ? '${(r * 100).toStringAsFixed(r * 1000 % 10 == 0 ? 0 : 1)}%' : '${r.toStringAsFixed(3).replaceAll(RegExp(r'\.?0+$'), '')}×';
    return Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(children: [
          Padding(padding: const EdgeInsets.only(right: 12, bottom: 6), child: Text('Wave', style: text.labelLarge)),
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('Ideal ratios', style: text.labelLarge)),
        ]),
        for (final g in fibGuides)
          TableRow(children: [
            Padding(padding: const EdgeInsets.only(right: 12, bottom: 4), child: Text(g.wave, style: text.bodyMedium)),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text('${([...g.ratios]..sort()).map(fmt).join(' · ')}  ${g.measure.replaceFirst('× ', 'of ')}',
                  style: text.bodyMedium),
            ),
          ]),
      ],
    );
  }
}

class _ProjectionTable extends StatelessWidget {
  const _ProjectionTable();

  static const _rows = [
    ('Wave 2', '50–61.8% retrace of wave 1', 'start of wave 1'),
    ('Wave 3', '1–1.618 × wave 1, from wave 2\'s end', 'start of wave 1'),
    ('Wave 4', '23.6–38.2% retrace of wave 3', 'end of wave 1 (overlap)'),
    ('Wave 5', '0.618–1 × wave 1 (capped so wave 3 isn\'t shortest)', 'end of wave 1'),
    ('Wave A', '38.2–61.8% retrace of the whole 1–5', 'beyond the end of wave 5'),
    ('Wave B', '50–61.8% retrace of A', 'beyond the end of wave 5'),
    ('Wave C', '1–1.618 × wave A, from B', 'beyond the end of wave 5'),
    ('After ABC', '61.8–100% retrace of A–C (trend resumes)', 'beyond the end of C'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final (wave, target, invalid) in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 72, child: Text(wave, style: text.labelLarge)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target: $target', style: text.bodySmall),
                      Text('Wrong past: $invalid', style: text.bodySmall?.copyWith(color: Colors.red.shade400)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A textbook 5-3 cycle with the wave-4 overlap rule marked.
class _WaveDiagram extends StatelessWidget {
  const _WaveDiagram();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.infinite, painter: _WavePainter(Theme.of(context).colorScheme));
}

class _WavePainter extends CustomPainter {
  _WavePainter(this.scheme);
  final ColorScheme scheme;

  // y: 0 = top. Impulse up, then A-B-C down.
  static const _ys = [0.92, 0.58, 0.74, 0.18, 0.40, 0.06, 0.42, 0.26, 0.62];
  static const _labels = ['', '1', '2', '3', '4', '5', 'A', 'B', 'C'];

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 16.0;
    final w = size.width - pad * 2, h = size.height - pad * 2;
    Offset pt(int i) => Offset(pad + w * i / (_ys.length - 1), pad + h * _ys[i]);

    // Wave 4 must stay above wave 1's top.
    final y1 = pt(1).dy;
    final rule = Paint()
      ..color = Colors.red.shade400
      ..strokeWidth = 1;
    for (var x = pt(1).dx; x < pt(5).dx; x += 8) {
      canvas.drawLine(Offset(x, y1), Offset(x + 4, y1), rule);
    }
    // Label under wave 4, the one empty stretch below the line.
    _text(canvas, 'wave 4 stays above wave 1', Offset(pt(3).dx + 4, y1 + 3), Colors.red.shade400, 9);

    void leg(int from, int to, Color color) {
      final p = Path()..moveTo(pt(from).dx, pt(from).dy);
      for (var i = from + 1; i <= to; i++) {
        p.lineTo(pt(i).dx, pt(i).dy);
      }
      canvas.drawPath(p, Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round);
    }

    leg(0, 5, scheme.primary);
    leg(5, 8, scheme.tertiary);

    for (var i = 1; i < _ys.length; i++) {
      final o = pt(i);
      final high = i == _ys.length - 1 ? false : _ys[i] < _ys[i - 1];
      final c = o + Offset(0, high ? -12 : 12);
      final color = i <= 5 ? scheme.primary : scheme.tertiary;
      canvas.drawCircle(c, 9, Paint()..color = color);
      _text(canvas, _labels[i], c, Colors.white, 10, center: true);
    }
    _text(canvas, 'impulse', Offset(pad, pad - 4), scheme.primary, 10);
    _text(canvas, 'correction', Offset(pt(6).dx - 10, pad - 4), scheme.tertiary, 10);
  }

  void _text(Canvas canvas, String s, Offset at, Color color, double size, {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.scheme != scheme;
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6;
    for (var x = 0.0; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, size.height / 2), Offset(x + 4, size.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
