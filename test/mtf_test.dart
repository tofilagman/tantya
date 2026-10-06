import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/candles.dart';
import 'package:tantya/elliott.dart';
import 'package:tantya/mtf.dart';
import 'package:tantya/setup.dart';

Scenario dir(int d) => Scenario(
      kind: ScenarioKind.impulse,
      trend: d,
      points: [WavePoint(Pivot(0, 1, high: d < 0), '2')],
      next: '3',
      direction: d,
      targetLow: 1,
      targetHigh: 2,
      invalidation: 0.5,
      score: 0.7,
      notes: [],
      legBars: 5,
    );

void main() {
  test('higher timeframe ladder', () {
    expect(Timeframe.m1.higher, Timeframe.m15);
    expect(Timeframe.m5.higher, Timeframe.h1);
    expect(Timeframe.h1.higher, Timeframe.h4);
    expect(Timeframe.h4.higher, Timeframe.d1);
    expect(Timeframe.d1.higher, isNull);
    for (final f in Timeframe.values) {
      final h = f.higher;
      if (h != null) expect(h.size > f.size, isTrue);
    }
  });

  test('agree, conflict, unknown', () {
    final up = EwAnalysis([dir(1)], 1.5);
    final down = EwAnalysis([dir(-1)], 1.5);
    expect(HtfCheck.judge(Side.long, Timeframe.h4, up).verdict, HtfVerdict.agree);
    expect(HtfCheck.judge(Side.short, Timeframe.h4, down).verdict, HtfVerdict.agree);
    expect(HtfCheck.judge(Side.long, Timeframe.h4, down).verdict, HtfVerdict.conflict);
    expect(HtfCheck.judge(Side.long, Timeframe.h4, const EwAnalysis([], 1)).verdict, HtfVerdict.unknown);
    expect(HtfCheck.judge(Side.long, Timeframe.h4, null).verdict, HtfVerdict.unknown);
  });

  test('rank factors order agree > unknown > conflict', () {
    double f(HtfVerdict v) => HtfCheck(Timeframe.h4, null, v).rankFactor;
    expect(f(HtfVerdict.agree), greaterThan(f(HtfVerdict.unknown)));
    expect(f(HtfVerdict.unknown), greaterThan(f(HtfVerdict.conflict)));
  });
}
