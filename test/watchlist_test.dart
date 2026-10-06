import 'package:flutter_test/flutter_test.dart';
import 'package:tantya/api.dart';
import 'package:tantya/watchlist.dart';

WatchItem item({double baseline = 0.50, int move = 5, double? above, double? below}) => WatchItem(
      marketId: '1',
      question: 'Q?',
      outcomeIndex: 0,
      outcome: 'Yes',
      baseline: baseline,
      lastPrice: baseline,
      movePoints: move,
      above: above,
      below: below,
    );

void main() {
  group('evaluate', () {
    test('small move is quiet and keeps the baseline', () {
      final w = item();
      expect(evaluate(w, 0.53, closed: false), isEmpty);
      expect(w.baseline, 0.50);
      expect(w.lastPrice, 0.53);
    });

    test('move of exactly N points fires despite float error, then resets baseline', () {
      final w = item(baseline: 0.55);
      final alerts = evaluate(w, 0.60, closed: false);
      expect(alerts.single, contains('+5.0 pts'));
      expect(w.baseline, 0.60);
      expect(evaluate(w, 0.62, closed: false), isEmpty);
    });

    test('drift accumulates against the baseline, not the last price', () {
      final w = item();
      expect(evaluate(w, 0.53, closed: false), isEmpty);
      expect(evaluate(w, 0.555, closed: false).single, contains('+5.5 pts'));
    });

    test('downward move', () {
      expect(evaluate(item(), 0.40, closed: false).single, contains('−10.0 pts'));
    });

    test('crossing above fires once, staying above is quiet', () {
      final w = item(move: 0, above: 0.70);
      expect(evaluate(w, 0.69, closed: false), isEmpty);
      expect(evaluate(w, 0.71, closed: false).single, contains('rose above 70%'));
      expect(evaluate(w, 0.75, closed: false), isEmpty);
      expect(evaluate(w, 0.65, closed: false), isEmpty);
      expect(evaluate(w, 0.72, closed: false), hasLength(1));
    });

    test('crossing below', () {
      final w = item(move: 0, below: 0.30, baseline: 0.35);
      expect(evaluate(w, 0.30, closed: false).single, contains('fell below 30%'));
    });

    test('closed market notifies once', () {
      final w = item();
      expect(evaluate(w, 1, closed: true).single, contains('settled at 100%'));
      expect(w.resolved, isTrue);
      expect(evaluate(w, 1, closed: true), isEmpty);
    });

    test('round-trips through JSON', () {
      final w = item(above: 0.8);
      final back = WatchItem.fromJson(w.toJson());
      expect(back.key, w.key);
      expect(back.above, 0.8);
      expect(back.below, isNull);
    });
  });

  test('pct edge cases', () {
    expect(pct(0.004), '<1%');
    expect(pct(0.995), '>99%');
    expect(pct(0.634), '63%');
    expect(pct(0), '0%');
    expect(pct(1), '100%');
  });

  test('Market parses Gamma\'s JSON-in-a-string arrays', () {
    final m = Market.fromJson({
      'id': 5323911,
      'question': 'Game 1 Winner?',
      'groupItemTitle': '',
      'outcomes': '["JD Gaming", "LGD Gaming"]',
      'outcomePrices': '["0.25", "0.75"]',
      'clobTokenIds': '["111", "222"]',
      'volume': '701788.46',
      'oneDayPriceChange': -0.7045,
      'closed': false,
      'endDate': '2026-10-06T17:15:00Z',
    });
    expect(m.id, '5323911');
    expect(m.outcomes, ['JD Gaming', 'LGD Gaming']);
    expect(m.prices, [0.25, 0.75]);
    expect(m.tokenIds, ['111', '222']);
    expect(m.volume, closeTo(701788.46, 0.01));
    expect(m.label, 'Game 1 Winner?');
  });

  test('Event keeps only open, active markets, highest first', () {
    final e = Event.fromJson({
      'id': '1',
      'title': 'BTC in October',
      'markets': [
        {'id': 'a', 'outcomePrices': '["0.2","0.8"]', 'closed': false},
        {'id': 'b', 'outcomePrices': '["0.9","0.1"]', 'closed': true},
        {'id': 'c', 'outcomePrices': '["0.6","0.4"]', 'closed': false},
        {'id': 'p', 'outcomePrices': '["0.5","0.5"]', 'closed': false, 'active': false},
      ],
    });
    expect(e.markets.map((m) => m.id), ['c', 'a']);
  });

  test('decided: near-certain or past end date', () {
    Market m(String prices, {String? end}) =>
        Market.fromJson({'id': 1, 'outcomePrices': prices, 'endDate': ?end});
    expect(m('["0.996","0.004"]').decided, isTrue);
    expect(m('["0.004","0.996"]').decided, isTrue);
    expect(m('["0.6","0.4"]').decided, isFalse);
    expect(m('["0.6","0.4"]', end: '2020-01-01T00:00:00Z').decided, isTrue);
    expect(m('["0.6","0.4"]', end: '2999-01-01T00:00:00Z').decided, isFalse);
  });
}
