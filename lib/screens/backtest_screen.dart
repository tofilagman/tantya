import 'dart:math' as math;

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../backtest.dart';
import '../burst.dart';
import '../candles.dart';
import '../evidence.dart';
import '../indicators.dart';
import '../setup.dart';
import '../sources/source.dart';

(BacktestResult, BurstStats) _backtestEntry((List<Candle>, Timeframe, BacktestConfig) a) {
  final candles = a.$1;
  return (runBacktest(candles, a.$2, a.$3), burstStats(candles, detectBursts(candles, Indicators.of(candles))));
}

/// Replays the app's setups over past candles for one pair and timeframe.
class BacktestScreen extends StatefulWidget {
  const BacktestScreen({super.key, required this.source, required this.frame});

  final CandleSource source;
  final Timeframe frame;

  @override
  State<BacktestScreen> createState() => _BacktestScreenState();
}

class _BacktestScreenState extends State<BacktestScreen> {
  late final _sizes = [1000, 2000, 5000].where((n) => n <= widget.source.maxBacktestCandles).toList();
  late int _candles = _sizes.isEmpty ? widget.source.maxBacktestCandles : _sizes[_sizes.length > 1 ? 1 : 0];
  double _minRR = 1;
  double _minScore = 0;

  String? _stage;
  BacktestResult? _result;
  BurstStats? _bursts;
  Object? _error;
  int _run = 0;

  Future<void> _start() async {
    final run = ++_run;
    setState(() {
      _stage = 'Fetching $_candles candles…';
      _error = null;
    });
    try {
      final candles = await widget.source.backtestHistory(widget.frame, _candles);
      if (!mounted || run != _run) return;
      setState(() => _stage = 'Replaying ${candles.length} candles…');
      final cfg = BacktestConfig(minRR: _minRR, minScore: _minScore, bounds: widget.source.bounds);
      // Off the UI thread. The entry point is top-level so the message carries only
      // plain data, not this screen.
      final (result, bursts) = await compute(_backtestEntry, (candles, widget.frame, cfg));
      if (!mounted || run != _run) return;
      setState(() {
        _result = result;
        _bursts = bursts;
        _stage = null;
      });
    } catch (e) {
      if (mounted && run == _run) {
        setState(() {
          _error = e;
          _stage = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final r = _result;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backtest · ${widget.source.title}'),
            Text('${widget.frame.label} · ${widget.source.subtitle}', style: text.labelSmall),
          ],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
            children: [
              _settings(text),
              if (_stage != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(_stage!, style: text.bodyMedium),
                  ]),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Backtest failed: $_error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              if (r != null && _stage == null) ..._results(r, text),
              if (_bursts != null && _stage == null) _BurstCard(_bursts!),
              const SizedBox(height: 12),
              Text(
                'How it works: at every candle the engine sees only the 300 candles up to that moment, exactly as the '
                'live chart would have, and takes the setup it would have shown (if it passes the filters). Entry is '
                'that candle\'s close; it settles at TP1 or the stop, whichever is touched first (a candle touching '
                'both counts as the stop), or at the market after $expiryCandles candles. One trade at a time. '
                'Not included: fees, funding, slippage, the higher-timeframe check. Past results don\'t guarantee '
                'future ones.',
                style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settings(TextTheme text) {
    Widget chips<T>(String label, List<(T, String)> options, T value, ValueChanged<T> set) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(label, style: text.labelLarge)),
              Expanded(
                child: Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final (v, l) in options)
                    ChoiceChip(
                      label: Text(l),
                      selected: v == value,
                      visualDensity: VisualDensity.compact,
                      onSelected: _stage != null ? null : (_) => setState(() => set(v)),
                    ),
                ]),
              ),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_sizes.isNotEmpty)
              chips('Candles', [for (final n in _sizes) (n, '$n')], _candles, (v) => _candles = v)
            else
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('History: the last ${widget.source.maxBacktestCandles} candles (all this source provides).',
                    style: text.bodySmall),
              ),
            chips('Min R:R', [(0.0, 'any'), (1.0, '1'), (1.5, '1.5'), (2.0, '2')], _minRR, (v) => _minRR = v),
            chips('Min score', [(0.0, 'any'), (0.4, '40'), (0.6, '60')], _minScore, (v) => _minScore = v),
            const SizedBox(height: 6),
            FilledButton.icon(
              onPressed: _stage != null ? null : _start,
              icon: const Icon(Icons.history),
              label: Text(_result == null ? 'Run backtest' : 'Run again'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(BacktestResult r, TextTheme text) {
    final fmtDate = DateFormat('MMM d, y');
    if (r.trades.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text('No setups passed the filters in this history. Loosen the filters or use more history.',
              textAlign: TextAlign.center),
        ),
      ];
    }
    final avg = r.avgR!;
    final good = Colors.green.shade600, bad = Colors.red.shade400;
    Widget tile(String label, String value, {Color? color}) => SizedBox(
          width: 130,
          child: Column(children: [
            Text(value, style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: color)),
            Text(label, style: text.labelSmall, textAlign: TextAlign.center),
          ]),
        );
    String sr(double v) => '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}';
    return [
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('${fmtDate.format(r.from)} – ${fmtDate.format(r.to)} · ${r.candles} candles',
                  style: text.labelMedium),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.spaceAround,
                runSpacing: 10,
                children: [
                  tile('trades', '${r.trades.length}'),
                  tile('hit rate', r.hitRate == null ? '—' : '${(r.hitRate! * 100).round()}%'),
                  tile('avg R / trade', sr(avg), color: avg >= 0 ? good : bad),
                  tile('total R', sr(r.totalR), color: r.totalR >= 0 ? good : bad),
                  tile('max drawdown', '${r.maxDrawdownR.toStringAsFixed(1)} R', color: bad),
                  tile('worst losing streak', '${r.longestLosingStreak}'),
                ],
              ),
              const SizedBox(height: 6),
              Text('${r.wins} hit TP1 · ${r.losses} stopped · ${r.expired} expired', style: text.bodySmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text('Equity (cumulative R)', style: text.labelLarge),
              const SizedBox(height: 6),
              SizedBox(height: 140, child: CustomPaint(painter: _EquityPainter(r.equity, Theme.of(context).colorScheme))),
              const SizedBox(height: 8),
              Text(
                avg > 0.1
                    ? 'Positive over this period: about ${sr(avg)} R per trade before fees.'
                    : avg < -0.1
                        ? 'Losing over this period: these settings would have lost about ${sr(avg).substring(1)} R per trade.'
                        : 'Roughly breakeven over this period, before fees. Fees would turn it slightly negative.',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
      _Breakdown('By evidence when entered', {
        for (final MapEntry(key: k, value: g)
            in r.groupBy((t) => EvidenceReport.levelOf(t.evidence), EvidenceLevel.values).entries)
          switch (k) {
            EvidenceLevel.strong => 'Strong',
            EvidenceLevel.mixed => 'Mixed',
            EvidenceLevel.weak => 'Weak',
          }: g,
      }, footer: 'If strong evidence wins clearly more here, only taking strong-evidence setups is worth considering.'),
      _Breakdown('By MACD', {
        for (final MapEntry(key: k, value: g) in r.groupBy((t) => t.macd, MacdVerdict.values).entries)
          switch (k) {
            MacdVerdict.agree => 'Backed',
            MacdVerdict.turning => 'Turning',
            MacdVerdict.against => 'Against',
          }: g,
      }),
      _Breakdown('By wave traded', {
        for (final MapEntry(key: k, value: g)
            in r.groupBy((t) => t.wave, const ['1', '2', '3', '4', '5', 'A', 'B', 'C']).entries)
          'Wave $k': g,
      }),
      _Breakdown('By direction', {
        for (final MapEntry(key: k, value: g) in r.groupBy((t) => t.side, Side.values).entries)
          k == Side.long ? 'Long' : 'Short': g,
      }),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Latest trades', style: text.titleSmall),
              const SizedBox(height: 6),
              for (final t in r.trades.reversed.take(30))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    SizedBox(width: 92, child: Text(DateFormat('MMM d HH:mm').format(t.madeAt), style: text.bodySmall)),
                    SizedBox(
                      width: 48,
                      child: Text(t.side == Side.long ? 'LONG' : 'SHORT',
                          style: text.labelSmall?.copyWith(
                              color: t.side == Side.long ? good : bad, fontWeight: FontWeight.w800)),
                    ),
                    Expanded(child: Text(t.count, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text(sr(t.r ?? 0),
                        style: text.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700, color: (t.r ?? 0) >= 0 ? good : bad)),
                  ]),
                ),
            ],
          ),
        ),
      ),
    ];
  }
}

class _Breakdown extends StatelessWidget {
  const _Breakdown(this.title, this.groups, {this.footer});
  final String title;
  final Map<String, BacktestResult> groups;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    Widget row(String a, String b, String c, String d, {TextStyle? style, Color? dColor}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(flex: 3, child: Text(a, style: style)),
            Expanded(flex: 2, child: Text(b, style: style, textAlign: TextAlign.end)),
            Expanded(flex: 2, child: Text(c, style: style, textAlign: TextAlign.end)),
            Expanded(
                flex: 2,
                child: Text(d,
                    style: (style ?? text.bodyMedium)?.copyWith(color: dColor, fontWeight: dColor == null ? null : FontWeight.w700),
                    textAlign: TextAlign.end)),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: text.titleSmall),
            const SizedBox(height: 4),
            row('', 'trades', 'hit', 'avg R', style: text.labelSmall?.copyWith(color: muted)),
            for (final MapEntry(key: k, value: g) in groups.entries)
              row(
                k,
                '${g.trades.length}',
                g.hitRate == null ? '—' : '${(g.hitRate! * 100).round()}%',
                '${g.avgR! >= 0 ? '+' : ''}${g.avgR!.toStringAsFixed(2)}',
                style: text.bodyMedium,
                dColor: g.avgR! >= 0 ? Colors.green.shade600 : Colors.red.shade400,
              ),
            if (footer != null) ...[
              const SizedBox(height: 4),
              Text(footer!, style: text.bodySmall?.copyWith(color: muted)),
            ],
            Text('Small groups (under ~30 trades) can mislead.', style: text.bodySmall?.copyWith(color: muted)),
          ],
        ),
      ),
    );
  }
}

class _EquityPainter extends CustomPainter {
  _EquityPainter(this.equity, this.scheme);
  final List<double> equity;
  final ColorScheme scheme;

  @override
  void paint(Canvas canvas, Size size) {
    if (equity.isEmpty) return;
    final pts = [0.0, ...equity];
    final lo = math.min(0.0, pts.reduce(math.min)), hi = math.max(0.0, pts.reduce(math.max));
    final span = hi - lo == 0 ? 1 : hi - lo;
    double y(double v) => size.height - (v - lo) / span * size.height;
    double x(int i) => i / (pts.length - 1) * size.width;
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), Paint()..color = scheme.outlineVariant);
    final path = Path()..moveTo(0, y(0));
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(x(i), y(pts[i]));
    }
    final up = pts.last >= 0;
    canvas.drawPath(
      path,
      Paint()
        ..color = up ? Colors.green.shade600 : Colors.red.shade400
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    final tp = TextPainter(
      text: TextSpan(
          text: '${pts.last >= 0 ? '+' : ''}${pts.last.toStringAsFixed(1)} R',
          style: TextStyle(color: scheme.onSurface, fontSize: 11, fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(size.width - tp.width, math.max(0, y(pts.last) - tp.height - 2)));
  }

  @override
  bool shouldRepaint(_EquityPainter old) => old.equity != equity || old.scheme != scheme;
}

/// The burst check: after each momentum burst in this history, did price keep going?
class _BurstCard extends StatelessWidget {
  const _BurstCard(this.stats);
  final BurstStats stats;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final s = stats;
    String pct(double? v) => v == null ? '—' : '${(v * 100).round()}%';
    String ret(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${(v * 100).toStringAsFixed(2)}%';
    String r(double? v) => v == null ? '—' : '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)}';
    Color? tone(double? v) => v == null ? null : (v >= 0 ? Colors.green.shade600 : Colors.red.shade400);
    Widget row(String label, BurstStats g) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(flex: 3, child: Text(label, style: text.bodyMedium)),
            Expanded(flex: 2, child: Text('${g.count}', style: text.bodyMedium, textAlign: TextAlign.end)),
            Expanded(flex: 2, child: Text(pct(g.continuation(12)), style: text.bodyMedium, textAlign: TextAlign.end)),
            Expanded(
              flex: 2,
              child: Text(r(g.tradeAvgR),
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: tone(g.tradeAvgR)),
                  textAlign: TextAlign.end),
            ),
          ]),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.bolt, color: Color(0xFFFFA000)),
              const SizedBox(width: 4),
              Text('Momentum bursts: did they keep going?', style: text.titleSmall),
            ]),
            const SizedBox(height: 6),
            if (s.count == 0)
              Text('No bursts in this history.', style: text.bodyMedium)
            else ...[
              Text('${s.count} bursts. Price was further in the burst\'s direction after:', style: text.bodyMedium),
              const SizedBox(height: 4),
              Row(children: [
                for (final h in BurstStats.horizons)
                  Expanded(
                    child: Column(children: [
                      Text(pct(s.continuation(h)), style: text.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                      Text('$h candles · avg ${ret(s.avgForward(h))}', style: text.labelSmall, textAlign: TextAlign.center),
                    ]),
                  ),
              ]),
              const SizedBox(height: 10),
              Text(
                'Riding each burst (enter at its close, stop where it started, target ${BurstStats.targetR.toStringAsFixed(0)}× '
                'the risk, out after ${BurstStats.tradeExpiry} candles): win rate ${pct(s.tradeWinRate)}, '
                'average ${r(s.tradeAvgR)} R per trade, before fees.',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(flex: 3, child: SizedBox()),
                for (final h in ['bursts', 'kept going (12)', 'avg R'])
                  Expanded(flex: 2, child: Text(h, style: text.labelSmall?.copyWith(color: muted), textAlign: TextAlign.end)),
              ]),
              row('All', s),
              row('Up bursts', s.where((e) => e.dir > 0)),
              row('Down bursts', s.where((e) => e.dir < 0)),
              row('3 of 4 signals', s.where((e) => e.strength == 3)),
              row('All 4 signals', s.where((e) => e.strength == 4)),
              const SizedBox(height: 4),
              Text(
                () {
                  final c = s.continuation(12) ?? 0.5, avg = s.tradeAvgR ?? 0;
                  final verdict = c >= 0.6 && avg >= 0.15
                      ? 'Bursts here leaned toward continuing, but check it holds on other periods and after fees.'
                      : c <= 0.4 || avg <= -0.15
                          ? 'Bursts here tended to reverse: chasing them lost money.'
                          : 'Bursts here were close to a coin flip: as likely to reverse as to continue.';
                  return '$verdict Small groups (under ~30) can mislead.';
                }(),
                style: text.bodySmall?.copyWith(color: muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

