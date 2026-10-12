import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/pair_watch.dart';
import 'package:tantya/trade.dart';

/// Impulse up, wave 3 in progress from 100: target 120–130, invalid below 90.
Scenario wave3({String next = '3'}) => Scenario(
      kind: ScenarioKind.impulse,
      trend: 1,
      points: const [WavePoint(Pivot(0, 90, high: false), ''), WavePoint(Pivot(5, 110, high: true), '1'),
        WavePoint(Pivot(9, 100, high: false), '2')],
      next: next,
      direction: 1,
      targetLow: 120,
      targetHigh: 130,
      invalidation: 90,
      score: 0.6,
      notes: const [],
      legBars: 10,
    );

PairSnapshot snap(double price, {Scenario? s, bool setup = false}) => PairSnapshot(
      price: price,
      scenario: s,
      setup: setup && s != null ? TradeSetup.from(s, price) : null,
    );

PairWatch watch() => PairWatch(symbol: 'BTCUSDT', title: 'BTC/USDT', frame: Timeframe.h1, lastPrice: 100, baseline: 100);

void main() {
  test('first check only records state', () {
    final w = watch();
    expect(applySnapshot(w, snap(102, s: wave3(), setup: true)), isEmpty);
    expect(w.count, contains('wave 3'));
    expect(w.primed, isTrue);
  });

  test('a new setup alerts once', () {
    final w = watch()..prime(snap(101, s: wave3()));
    final a = applySnapshot(w, snap(102, s: wave3(), setup: true));
    expect(a.single.kind, PairAlertKind.setup);
    expect(a.single.text, startsWith('LONG setup'));
    expect(applySnapshot(w, snap(103, s: wave3(), setup: true)), isEmpty);
  });

  test('target reached and invalidation fire once per count', () {
    final w = watch()..prime(snap(101, s: wave3()));
    expect(applySnapshot(w, snap(121, s: wave3())).map((a) => a.kind), [PairAlertKind.target]);
    expect(applySnapshot(w, snap(125, s: wave3())), isEmpty);
    expect(applySnapshot(w, snap(89, s: wave3())).map((a) => a.kind), [PairAlertKind.invalidated]);
    expect(applySnapshot(w, snap(85, s: wave3())), isEmpty);
  });

  test('count change alerts and resets target tracking', () {
    final w = watch()..prime(snap(101, s: wave3()));
    final a = applySnapshot(w, snap(105, s: wave3(next: '4')));
    expect(a.single.kind, PairAlertKind.countChanged);
    expect(a.single.text, contains('wave 3 in progress → Impulse ↑ · wave 4'));
    expect(w.targetHit, isFalse);
  });

  test('price levels and moves', () {
    final w = watch()
      ..above = 105
      ..below = 95
      ..movePct = 5
      ..prime(snap(100));
    expect(applySnapshot(w, snap(104)), isEmpty);
    final up = applySnapshot(w, snap(106));
    expect(up.map((a) => a.kind), [PairAlertKind.level, PairAlertKind.move]);
    expect(w.baseline, 106);
    expect(applySnapshot(w, snap(94)).map((a) => a.kind), [PairAlertKind.level, PairAlertKind.move]);
  });

  test('switched-off rules stay quiet but state still updates', () {
    final w = watch()
      ..setups = false
      ..targets = false
      ..countChanges = false
      ..prime(snap(101, s: wave3()));
    expect(applySnapshot(w, snap(121, s: wave3(next: '4'), setup: true)), isEmpty);
    expect(w.count, contains('wave 4'));
  });

  test('JSON round trip', () {
    final w = watch()
      ..above = 110
      ..prime(snap(101, s: wave3(), setup: true));
    expect(PairWatch.fromJson(w.toJson()).toJson(), w.toJson());
  });
}
