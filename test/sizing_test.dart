import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/journal.dart';
import 'package:tantya/sizing.dart';
import 'package:tantya/trade.dart';

void main() {
  group('PositionPlan', () {
    test('size so the stop loses exactly the risk, fees included', () {
      final p = PositionPlan.compute(balance: 1000, riskPct: 1, entry: 100, stop: 95, tp1: 110)!;
      expect(p.side, Side.long);
      expect(p.riskAmount, 10);
      expect(p.size, closeTo(10 / 5.195, 1e-9));
      expect(p.pnlAt(95), closeTo(-10, 1e-9));
      expect(p.rAt(95), closeTo(-1, 1e-9));
      expect(p.rAt(110), closeTo((10 * p.size - 0.001 * 210 * p.size) / 10, 1e-9));
      expect(p.fitsSpot, isTrue);
      expect(p.leverage, 1);
      expect(p.liquidation, isNull);
      expect(p.warnings, isEmpty);
    });

    test('short side and leverage with a liquidation estimate', () {
      final p = PositionPlan.compute(balance: 1000, riskPct: 2, entry: 100, stop: 101)!;
      expect(p.side, Side.short);
      expect(p.leverageNeeded, closeTo(20 / 1.201 * 100 / 1000, 1e-9));
      expect(p.leverage, 2);
      expect(p.maxSafeLeverage, 50); // 1 / (1.5 × 1% + 0.5%)
      expect(p.liquidation, closeTo(100 * (1 + 0.5 - 0.005), 1e-9));
      expect(p.margin, closeTo(p.notional / 2, 1e-9));
      expect(p.fitsSpot, isFalse);
      expect(p.spotSize, closeTo(10, 1e-9));
      expect(p.spotRiskPct, closeTo(10 * 1.201 / 1000 * 100, 1e-9));
    });

    test('warns when the leverage needed would liquidate before the stop', () {
      final p = PositionPlan.compute(balance: 1000, riskPct: 70, entry: 100, stop: 90)!;
      expect(p.maxSafeLeverage, 6);
      expect(p.leverageSafe, isFalse);
      expect(p.warnings.length, 2); // too much risk, unsafe leverage
    });

    test('rejects impossible inputs and wrong-side targets', () {
      expect(PositionPlan.compute(balance: 1000, riskPct: 1, entry: 100, stop: 100), isNull);
      expect(PositionPlan.compute(balance: 0, riskPct: 1, entry: 100, stop: 95), isNull);
      expect(PositionPlan.compute(balance: 1000, riskPct: 1, entry: 100, stop: 95, tp1: 90)!.tp1, isNull);
    });
  });

  group('Journal', () {
    JournalEntry closed(double exit, {bool? followed, List<String>? mistakes, int day = 1}) {
      final p = PositionPlan.compute(balance: 1000, riskPct: 1, entry: 100, stop: 95)!;
      return JournalEntry.fromPlan(p, title: 'BTC/USDT', now: DateTime(2026, 10, day))
        ..status = JournalStatus.closed
        ..exit = exit
        ..closedAt = DateTime(2026, 10, day, 12)
        ..followedPlan = followed
        ..mistakes = mistakes ?? [];
    }

    test('P&L and R after fees', () {
      expect(closed(95).r, closeTo(-1, 1e-9));
      expect(closed(95).pnl, closeTo(-10, 1e-9));
      expect(JournalEntry.fromPlan(PositionPlan.compute(balance: 1000, riskPct: 1, entry: 100, stop: 95)!, title: 'x').pnl,
          isNull);
    });

    test('stats, mistakes and equity', () {
      final s = JournalStats([
        closed(110, followed: true, day: 1),
        closed(95, followed: false, mistakes: ['Moved my stop'], day: 2),
        closed(95, followed: false, mistakes: ['Moved my stop', 'Chased the entry'], day: 3),
      ]);
      expect(s.closed.length, 3);
      expect(s.winRate, closeTo(1 / 3, 1e-9));
      expect(s.byMistake['Moved my stop']!.totalPnl, closeTo(-20, 1e-9));
      expect(s.byMistake.keys, ['Moved my stop', 'Chased the entry']);
      expect(s.where((e) => e.followedPlan == true).avgR, greaterThan(0));
      expect(s.equity.last, closeTo(s.totalPnl, 1e-9));
    });

    test('JSON round trip and CSV quoting', () {
      final e = closed(110, followed: true, mistakes: ['Exited early'])..notes = 'said "wait"';
      expect(JournalEntry.fromJson(e.toJson()).toJson(), e.toJson());
      expect(e.toCsv(), contains('"said ""wait"""'));
      expect(e.toCsv().split(',').length, greaterThanOrEqualTo(JournalEntry.csvHeader.split(',').length));
    });
  });
}
