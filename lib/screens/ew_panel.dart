import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../candles.dart';
import '../elliott.dart';
import '../indicators.dart';
import '../layers.dart';
import '../live.dart';
import '../mtf.dart';
import '../setup.dart';
import '../sources/source.dart';
import 'live_chart.dart';
import 'widgets.dart';

/// Live chart + Elliott Wave count + trade setup for one [CandleSource].
/// Lays out as a column; put it inside a scroll view.
class EwPanel extends StatefulWidget {
  const EwPanel({super.key, required this.source, this.onPrice, this.initialFrame, this.wide = false});

  final CandleSource source;

  /// Desktop/tablet layout: chart filling the left, setup card scrolling on the right.
  /// Needs a bounded height from the parent (don't put it in a ListView).
  final bool wide;

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
  Macd? _macd;
  bool _showMacd = true;

  /// The next timeframe up, counted separately to judge agreement.
  Timeframe? get _higherFrame {
    final h = _frame.higher;
    return h != null && widget.source.timeframes.contains(h) ? h : null;
  }

  /// Every other timeframe's count, for the higher-timeframe check, the coloured layers
  /// and the all-timeframes table. Recounted every few minutes, not live.
  final _others = <Timeframe, ({EwAnalysis analysis, List<Candle> candles})>{};
  final _othersFailed = <Timeframe>{};
  Timer? _othersRefresh;

  EwAnalysis? get _higher => _higherFrame == null ? null : _others[_higherFrame]?.analysis;
  bool get _higherFailed => _othersFailed.contains(_higherFrame);

  /// Timeframes drawn over the chart as coloured layers, besides the chart's own.
  /// Starts with the next one up, and follows the timeframe until the user picks.
  late final Set<Timeframe> _layersOn = {?_higherFrame};
  bool _layersPicked = false;
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
      _others.clear();
      _othersFailed.clear();
      _load();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _othersRefresh?.cancel();
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
    });
    _othersRefresh?.cancel();
    _loadOthers();
    // Other timeframes move slowly relative to this one; recount every few minutes.
    _othersRefresh = Timer.periodic(const Duration(minutes: 5), (_) => _loadOthers());
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

  /// Counts every timeframe other than the chart's own, each as soon as it arrives.
  /// Earlier results stay on screen while a refresh is in flight.
  Future<void> _loadOthers() async {
    final source = widget.source;
    await Future.wait([
      for (final f in source.timeframes)
        if (f != _frame)
          () async {
            try {
              final candles = await source.history(f);
              final a = analyze(candles, bounds: source.bounds);
              if (!mounted || source.id != widget.source.id) return;
              setState(() {
                _others[f] = (analysis: a, candles: candles);
                _othersFailed.remove(f);
              });
            } catch (_) {
              if (mounted && !_others.containsKey(f)) setState(() => _othersFailed.add(f));
            }
          }(),
    ]);
  }

  /// Each timeframe's primary count: the chart's own (the selected count) and the rest.
  Map<Timeframe, Scenario> get _primaries => {
        for (final f in widget.source.timeframes)
          f: ?(f == _frame ? _selected : _others[f]?.analysis.primary),
      };

  List<Layer> get _layers => [
        for (final f in widget.source.timeframes)
          if (f != _frame && _layersOn.contains(f))
            if ((_others[f]?.analysis.primary, _others[f]?.candles) case (final s?, final c?)) Layer.of(f, s, c),
      ];

  void _toggleLayer(Timeframe f) => setState(() {
        _layersPicked = true;
        _layersOn.contains(f) ? _layersOn.remove(f) : _layersOn.add(f);
      });

  /// Switches the chart's timeframe; the default overlay moves to the new next-higher one.
  void _setFrame(Timeframe f) {
    setState(() {
      _frame = f;
      if (!_layersPicked) {
        _layersOn
          ..clear()
          ..addAll({?_higherFrame});
      }
    });
    _load();
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
    _macd = Macd.of(candles);
    widget.onPrice?.call(candles.last.close);
  }

  Scenario? get _selected {
    final a = _analysis;
    if (a == null || a.scenarios.isEmpty) return null;
    return a.scenarios.where((s) => s.key == _selectedKey).firstOrNull ?? a.primary;
  }

  Future<void> _track(TradeSetup s) async {
    final macd = _macd == null ? null : MacdState.of(_macd!)?.verdictFor(s.side);
    await SetupStore.add(TrackedSetup.fromSetup(s, widget.source, _frame, DateTime.now(),
        htf: _htfFor(s)?.verdict, macd: macd));
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

    final layers = _layers;
    final status = _live == null
        ? const SizedBox.shrink()
        : _StatusRow(status: _live!.status, bid: _bid, ask: _ask, format: widget.source.format);
    final chart = _error != null
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
                    primaryColor: colorOf(_frame),
                    layers: _overlay ? layers : const [],
                    macd: _showMacd ? _macd : null,
                    confluence: _overlay
                        ? findConfluence({_frame: ?selected, for (final l in layers) l.frame: l.scenario})
                        : const [],
                  );
    final controls = Row(
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
                        _setFrame(f);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: _showMacd ? 'Hide MACD' : 'Show MACD',
          isSelected: _showMacd,
          icon: const Icon(Icons.stacked_line_chart_outlined),
          selectedIcon: const Icon(Icons.stacked_line_chart),
          onPressed: () => setState(() => _showMacd = !_showMacd),
        ),
        IconButton(
          tooltip: _overlay ? 'Hide wave count' : 'Show wave count',
          isSelected: _overlay,
          icon: const Icon(Icons.waves_outlined),
          selectedIcon: const Icon(Icons.waves),
          onPressed: () => setState(() => _overlay = !_overlay),
        ),
      ],
    );
    final layerChips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text('Overlay', style: Theme.of(context).textTheme.labelMedium),
          ),
          for (final f in widget.source.timeframes)
            if (f != _frame)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  avatar: CircleAvatar(backgroundColor: colorOf(f), radius: 6),
                  label: Text(f.label),
                  selected: _layersOn.contains(f),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Draw the ${f.label} count on this chart',
                  onSelected: (_) => _toggleLayer(f),
                ),
              ),
        ],
      ),
    );
    final controlsAndLayers = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [controls, if (_overlay) ...[const SizedBox(height: 4), layerChips]],
    );
    final card = _analysis == null ? const SizedBox.shrink() : _analysisCard(_analysis!, setup);

    if (widget.wide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                status,
                const SizedBox(height: 6),
                Expanded(child: chart),
                const SizedBox(height: 8),
                controlsAndLayers,
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(width: 400, child: SingleChildScrollView(child: card)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        status,
        const SizedBox(height: 6),
        // Taller with the MACD pane so the price area keeps its height.
        SizedBox(height: _showMacd ? 440 : 360, child: chart),
        const SizedBox(height: 8),
        controlsAndLayers,
        const SizedBox(height: 8),
        card,
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
                    onTap: () => _setFrame(_higherFrame!),
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
            if (_macd != null) ...[
              const SizedBox(height: 10),
              _MacdSection(
                state: MacdState.of(_macd!),
                side: setup?.side,
                notes: _candles == null ? const [] : macdNotes(s, _macd!, _candles!),
              ),
            ],
            const Divider(height: 24),
            _TimeframesTable(
              timeframes: widget.source.timeframes,
              current: _frame,
              primaries: _primaries,
              failed: _othersFailed,
              layersOn: _layersOn,
              format: fmt,
              onToggle: _toggleLayer,
            ),
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

/// Every timeframe's current count at a glance, in its overlay colour, with how many
/// point each way and where their targets coincide. Tapping a row toggles its layer.
class _TimeframesTable extends StatelessWidget {
  const _TimeframesTable({
    required this.timeframes,
    required this.current,
    required this.primaries,
    required this.failed,
    required this.layersOn,
    required this.format,
    required this.onToggle,
  });

  final List<Timeframe> timeframes;
  final Timeframe current;
  final Map<Timeframe, Scenario> primaries;
  final Set<Timeframe> failed;
  final Set<Timeframe> layersOn;
  final String Function(double) format;
  final ValueChanged<Timeframe> onToggle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final a = alignment(primaries);
    final confluence = findConfluence(primaries);
    final total = a.up + a.down;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('All timeframes', style: text.labelLarge),
            const Spacer(),
            if (total > 0)
              Text(
                a.up == total || a.down == total
                    ? 'All $total expect ${a.up > 0 ? '↑' : '↓'}'
                    : '${a.up} expect ↑ · ${a.down} ↓',
                style: text.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: a.up == total
                      ? Colors.green.shade600
                      : a.down == total
                          ? Colors.red.shade400
                          : muted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (final f in timeframes)
          InkWell(
            onTap: f == current ? null : () => onToggle(f),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: f == current || layersOn.contains(f) ? colorOf(f) : Colors.transparent,
                      border: Border.all(color: colorOf(f), width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 34,
                    child: Text(f.label,
                        style: text.labelMedium?.copyWith(fontWeight: f == current ? FontWeight.w800 : null)),
                  ),
                  Expanded(child: _summary(text, muted, f)),
                ],
              ),
            ),
          ),
        if (confluence.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final c in confluence.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '◆ Confluence: ${c.frames.map((f) => f.label).join(' + ')} targets overlap at '
                '${format(c.low)}–${format(c.high)} ${c.direction > 0 ? '↑' : '↓'}',
                style: text.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          Text('Outlined on the chart when both timeframes are shown.', style: text.bodySmall?.copyWith(color: muted)),
        ],
        const SizedBox(height: 2),
        Text('Tap a row to draw that timeframe on the chart, in its colour.',
            style: text.bodySmall?.copyWith(color: muted)),
      ],
    );
  }

  Widget _summary(TextTheme text, Color muted, Timeframe f) {
    final p = primaries[f];
    if (p == null) {
      final note = failed.contains(f) ? 'couldn\'t load' : (f == current ? 'no clear count' : 'counting…');
      return Text(note, style: text.bodySmall?.copyWith(color: muted));
    }
    final up = p.direction > 0;
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: up ? '↑ ' : '↓ ',
          style: TextStyle(color: up ? Colors.green.shade600 : Colors.red.shade400, fontWeight: FontWeight.w800),
        ),
        TextSpan(text: p.shortTitle),
        TextSpan(text: '  ${format(p.targetLow)}–${format(p.targetHigh)}', style: TextStyle(color: muted)),
      ]),
      style: text.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// MACD at the latest candle, whether it backs the setup, and what it says about the count.
class _MacdSection extends StatelessWidget {
  const _MacdSection({required this.state, required this.side, required this.notes});

  final MacdState? state;
  final Side? side;
  final List<MacdNote> notes;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final st = state;
    if (st == null) {
      return Text('MACD: not enough history yet', style: text.bodySmall?.copyWith(color: muted));
    }
    final momentum = '${st.bullish ? 'Bullish' : 'Bearish'}: histogram ${st.histogram >= 0 ? 'above' : 'below'} zero, '
        '${st.rising ? 'rising' : 'falling'}'
        '${st.crossAgo != null && st.crossAgo! <= 5 ? ', crossed ${st.crossAgo == 0 ? 'this candle' : '${st.crossAgo} candles ago'}' : ''}';
    final verdict = side == null ? null : st.verdictFor(side!);
    final (Color vColor, String vText) = switch (verdict) {
      MacdVerdict.agree => (Colors.green.shade600, 'backs the ${side == Side.long ? 'LONG' : 'SHORT'}'),
      MacdVerdict.turning => (Colors.orange.shade800, 'turning toward the ${side == Side.long ? 'LONG' : 'SHORT'}'),
      MacdVerdict.against => (Colors.red.shade400, 'against the ${side == Side.long ? 'LONG' : 'SHORT'}'),
      null => (muted, ''),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('MACD (${Macd.fast}, ${Macd.slow}, ${Macd.smooth})', style: text.labelLarge),
            const Spacer(),
            if (verdict != null)
              Text(vText, style: text.labelMedium?.copyWith(color: vColor, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 2),
        Text(momentum, style: text.bodySmall),
        for (final n in notes)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  n.good == true ? Icons.check_circle : (n.good == false ? Icons.warning_amber : Icons.info_outline),
                  size: 14,
                  color: n.good == true ? Colors.green.shade600 : (n.good == false ? Colors.orange.shade800 : muted),
                ),
                const SizedBox(width: 6),
                Expanded(child: Text(n.text, style: text.bodySmall)),
              ],
            ),
          ),
      ],
    );
  }
}

