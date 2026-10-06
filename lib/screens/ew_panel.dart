import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../candles.dart';
import '../elliott.dart';
import '../live.dart';
import '../mtf.dart';
import '../setup.dart';
import '../sources/source.dart';
import 'live_chart.dart';
import 'widgets.dart';

/// Live chart + Elliott Wave count + trade setup for one [CandleSource].
/// Lays out as a column; put it inside a scroll view.
class EwPanel extends StatefulWidget {
  const EwPanel({super.key, required this.source, this.onPrice, this.initialFrame});

  final CandleSource source;

  /// Timeframe to open on; defaults to the source's own default.
  final Timeframe? initialFrame;

  /// Latest price, for a header owned by the parent.
  final ValueChanged<double>? onPrice;

  @override
  State<EwPanel> createState() => _EwPanelState();
}

class _EwPanelState extends State<EwPanel> with WidgetsBindingObserver {
  late Timeframe _frame = widget.initialFrame ?? widget.source.defaultFrame;
  List<Candle>? _candles;
  Object? _error;
  int _revision = 0;

  LiveConnection? _live;
  StreamSubscription<LiveUpdate>? _sub;
  double? _bid, _ask;
  Timer? _tick;

  EwAnalysis? _analysis;
  String? _selectedKey;

  /// The next timeframe up, counted separately to judge agreement.
  Timeframe? get _higherFrame {
    final h = _frame.higher;
    return h != null && widget.source.timeframes.contains(h) ? h : null;
  }

  EwAnalysis? _higher;
  bool _higherFailed = false;
  Timer? _higherRefresh;
  bool _overlay = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void didUpdateWidget(EwPanel old) {
    super.didUpdateWidget(old);
    if (old.source.id != widget.source.id) {
      if (!widget.source.timeframes.contains(_frame)) _frame = widget.source.defaultFrame;
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _higherRefresh?.cancel();
    _disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // No socket in the background; reload on return so the gap is filled.
    if (state == AppLifecycleState.paused) {
      _live?.pause();
    } else if (state == AppLifecycleState.resumed && _live != null) {
      _load();
    }
  }

  void _disconnect() {
    _sub?.cancel();
    _sub = null;
    _live?.close();
    _live = null;
  }

  Future<void> _load() async {
    final source = widget.source;
    final frame = _frame;
    _disconnect();
    setState(() {
      _candles = null;
      _error = null;
      _analysis = null;
      _bid = _ask = null;
      _higher = null;
      _higherFailed = false;
    });
    _higherRefresh?.cancel();
    _loadHigher();
    // The higher timeframe moves slowly; recount it every few minutes, not every tick.
    _higherRefresh = Timer.periodic(const Duration(minutes: 5), (_) => _loadHigher());
    try {
      final candles = await source.history(frame);
      if (!mounted || frame != _frame || source.id != widget.source.id) return;
      _candles = candles;
      _analyze();
      setState(() {});
      final live = source.live(frame);
      _live = live;
      _sub = live.updates.listen(_onUpdate);
    } catch (e) {
      if (mounted && frame == _frame) setState(() => _error = e);
    }
  }

  Future<void> _loadHigher() async {
    final h = _higherFrame;
    final source = widget.source;
    if (h == null) return;
    try {
      final a = analyze(await source.history(h), bounds: source.bounds);
      if (mounted && h == _higherFrame && source.id == widget.source.id) {
        setState(() {
          _higher = a;
          _higherFailed = false;
        });
      }
    } catch (_) {
      if (mounted && _higher == null) setState(() => _higherFailed = true);
    }
  }

  HtfCheck? _htfFor(TradeSetup s) {
    final h = _higherFrame;
    if (h == null || _higher == null) return null;
    return HtfCheck.judge(s.side, h, _higher);
  }

  void _onUpdate(LiveUpdate u) {
    final candles = _candles;
    if (candles == null) return;
    switch (u) {
      case CandleUpdate(:final candle):
        mergeCandle(candles, candle);
      case TickUpdate(:final time, :final price, :final bid, :final ask):
        applyTick(candles, _frame, time, price);
        _bid = bid;
        _ask = ask;
    }
    // Re-count and repaint at most ~3 times a second.
    _tick ??= Timer(const Duration(milliseconds: 350), () {
      _tick = null;
      if (!mounted) return;
      _analyze();
      setState(() => _revision++);
    });
  }

  void _analyze() {
    final candles = _candles;
    if (candles == null || candles.isEmpty) return;
    _analysis = analyze(candles, bounds: widget.source.bounds);
    widget.onPrice?.call(candles.last.close);
  }

  Scenario? get _selected {
    final a = _analysis;
    if (a == null || a.scenarios.isEmpty) return null;
    return a.scenarios.where((s) => s.key == _selectedKey).firstOrNull ?? a.primary;
  }

  Future<void> _track(TradeSetup s) async {
    await SetupStore.add(
        TrackedSetup.fromSetup(s, widget.source, _frame, DateTime.now(), htf: _htfFor(s)?.verdict));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Tracking — see the Setups tab for the result'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final candles = _candles;
    final selected = _selected;
    final setup = selected == null || candles == null || candles.isEmpty
        ? null
        // A buffer beyond the invalidation level keeps routine wicks from stopping it out.
        : TradeSetup.from(selected, candles.last.close, buffer: atr(candles) * stopBufferAtr);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_live != null) _StatusRow(status: _live!.status, bid: _bid, ask: _ask, format: widget.source.format),
        const SizedBox(height: 6),
        SizedBox(
          height: 360,
          child: _error != null
              ? ErrorRetry(error: _error!, onRetry: _load)
              : candles == null
                  ? const Center(child: CircularProgressIndicator())
                  : candles.length < 2
                      ? const Center(child: Text('Not enough trading history yet'))
                      : LiveChart(
                          candles: candles,
                          frame: _frame,
                          format: widget.source.format,
                          scenario: _overlay ? selected : null,
                          setup: _overlay ? setup : null,
                          revision: _revision,
                        ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in widget.source.timeframes)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(f.label),
                          selected: f == _frame,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) {
                            if (f == _frame) return;
                            setState(() => _frame = f);
                            _load();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            IconButton(
              tooltip: _overlay ? 'Hide wave count' : 'Show wave count',
              isSelected: _overlay,
              icon: const Icon(Icons.waves_outlined),
              selectedIcon: const Icon(Icons.waves),
              onPressed: () => setState(() => _overlay = !_overlay),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_analysis != null) _analysisCard(_analysis!, setup),
      ],
    );
  }

  Widget _analysisCard(EwAnalysis a, TradeSetup? setup) {
    final text = Theme.of(context).textTheme;
    final s = _selected;
    if (s == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No clear wave structure on this timeframe. Try another one.'),
        ),
      );
    }
    final fmt = widget.source.format;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(s.title, style: text.titleMedium)),
                Text('score ${(s.score * 100).round()}', style: text.labelMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s == a.primary
                  ? (a.consensus ? 'Top counts agree on direction' : 'Alternate counts disagree, so conviction is lower')
                  : 'Alternate count (${(s.share * 100).round()}% weight)',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            if (setup == null)
              Text('No trade at this price: it is already at the target or the stop.', style: text.bodyMedium)
            else ...[
              _SetupGrid(setup: setup, format: fmt),
              if (_higherFrame != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: HtfBadge(
                    frame: _higherFrame!,
                    check: _htfFor(setup),
                    failed: _higherFailed,
                    onTap: () {
                      setState(() => _frame = _higherFrame!);
                      _load();
                    },
                  ),
                ),
              if (setup.poorRR)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '⚠ Reward:risk to TP1 is under 1. Price has run toward the target; waiting for a pullback gives a better entry.',
                    style: text.bodySmall?.copyWith(color: Colors.orange.shade800),
                  ),
                ),
            ],
            if (s.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [for (final n in s.notes) Chip(label: Text(n), visualDensity: VisualDensity.compact)],
              ),
            ],
            if (setup != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () => _track(setup),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Track this setup'),
                ),
              ),
            if (a.scenarios.length > 1) ...[
              const Divider(height: 24),
              Text('Other counts', style: text.labelLarge),
              RadioGroup<String>(
                groupValue: s.key,
                onChanged: (k) => setState(() => _selectedKey = k),
                child: Column(
                  children: [
                    for (final alt in a.scenarios)
                      RadioListTile<String>(
                        value: alt.key,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(alt.title),
                        subtitle: Text(
                          '${alt.direction > 0 ? '↑' : '↓'} to ${fmt(alt.targetLow)}–${fmt(alt.targetHigh)} · '
                          'wrong past ${fmt(alt.invalidation)} · ${(alt.share * 100).round()}%',
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              'Algorithmic Elliott Wave reading, not financial advice. Counts are subjective and change as '
              'price moves. The Setups tab shows how this method has actually performed.',
              style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SetupGrid extends StatelessWidget {
  const _SetupGrid({required this.setup, required this.format});

  final TradeSetup setup;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final long = setup.side == Side.long;
    final color = long ? Colors.green.shade600 : Colors.red.shade400;
    Widget cell(String label, String value, {String? sub, Color? valueColor}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: text.labelSmall),
              Text(value, style: text.titleSmall?.copyWith(color: valueColor, fontWeight: FontWeight.w700)),
              if (sub != null) Text(sub, style: text.labelSmall),
            ],
          ),
        );
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              child: Text(long ? 'LONG' : 'SHORT',
                  style: text.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            cell('Entry (now)', format(setup.entry)),
            cell('Stop', format(setup.stop), valueColor: Colors.red.shade400),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            cell('TP1', format(setup.tp1), sub: 'R:R ${setup.rr1.toStringAsFixed(2)}', valueColor: Colors.green.shade600),
            cell('TP2', format(setup.tp2), sub: 'R:R ${setup.rr2.toStringAsFixed(2)}', valueColor: Colors.green.shade600),
            cell('Risk', '${(setup.risk / setup.entry * 100).toStringAsFixed(2)}%'),
          ],
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.status, required this.bid, required this.ask, required this.format});

  final ValueListenable<LiveStatus> status;
  final double? bid, ask;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium;
    return ValueListenableBuilder(
      valueListenable: status,
      builder: (context, s, _) {
        final (color, label) = switch (s) {
          LiveStatus.live => (Colors.green.shade600, 'Live'),
          LiveStatus.connecting => (Colors.amber.shade700, 'Connecting'),
          LiveStatus.offline => (Colors.grey, 'Offline, retrying'),
        };
        return Row(
          children: [
            Icon(Icons.circle, size: 8, color: color),
            const SizedBox(width: 6),
            Text(label, style: style),
            const Spacer(),
            if (bid != null && ask != null) Text('Bid ${format(bid!)} · Ask ${format(ask!)}', style: style),
          ],
        );
      },
    );
  }
}

/// Whether the next timeframe up points the same way as the setup.
class HtfBadge extends StatelessWidget {
  const HtfBadge({super.key, required this.frame, required this.check, this.failed = false, this.onTap, this.compact = false});

  final Timeframe frame;

  /// Null while the higher timeframe is still loading.
  final HtfCheck? check;
  final bool failed;
  final VoidCallback? onTap;

  /// One line, for list rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = check;
    final (IconData icon, Color color, String head, String? detail) = switch (c?.verdict) {
      null => failed
          ? (Icons.cloud_off, Colors.grey, 'Couldn\'t load ${frame.label}', null)
          : (Icons.hourglass_empty, Colors.grey, 'Checking ${frame.label}…', null),
      HtfVerdict.agree => (Icons.verified, Colors.green.shade600, '${frame.label} agrees', c!.primary!.title),
      HtfVerdict.conflict => (
          Icons.warning_amber,
          Colors.orange.shade800,
          '${frame.label} expects ${c!.primary!.direction > 0 ? '↑' : '↓'}',
          compact ? c.primary!.title : '${c.primary!.title}. This setup trades against the bigger picture.',
        ),
      HtfVerdict.unknown => (Icons.help_outline, Colors.grey, '${frame.label}: no clear count', null),
    };
    final body = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: head, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              if (detail != null) TextSpan(text: ' · $detail'),
            ]),
            style: text.bodySmall,
            maxLines: compact ? 1 : 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (onTap != null && !compact) Icon(Icons.chevron_right, size: 18, color: color),
      ],
    );
    if (compact || onTap == null) return body;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: body,
      ),
    );
  }
}

