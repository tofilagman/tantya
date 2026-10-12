/// Position sizing: how big a trade must be so that hitting the stop loses exactly the
/// amount you chose to risk, fees included, and how much leverage that takes.
///
/// Leverage doesn't change what you lose at the stop (the size does); it only changes how
/// much margin you put up and where the exchange would liquidate you. The one rule that
/// matters: the liquidation price must sit well beyond the stop, or the exchange closes
/// the trade before your stop does.
library;

import 'dart:math' as math;

import 'trade.dart';

/// Binance spot taker fee, per side.
const defaultFeeRate = 0.001;

/// Maintenance margin rate assumed for the liquidation estimate. Binance's first tier is
/// 0.4–0.5% for the big pairs and higher for small ones; 0.5% is on the safe side.
const maintenanceMargin = 0.005;

/// Liquidation must be at least this many stop-distances away from entry (1.5 = the stop
/// plus half again), so a wick past the stop or a slow stop fill can't liquidate you.
const liquidationCushion = 1.5;

class PositionPlan {
  PositionPlan._({
    required this.side,
    required this.balance,
    required this.riskPct,
    required this.entry,
    required this.stop,
    required this.feeRate,
    required this.size,
    this.tp1,
    this.tp2,
  });

  /// Null when the inputs can't make a trade (non-positive values, stop at entry, a
  /// target on the wrong side).
  static PositionPlan? compute({
    required double balance,
    required double riskPct,
    required double entry,
    required double stop,
    double? tp1,
    double? tp2,
    double feeRate = defaultFeeRate,
  }) {
    if (balance <= 0 || riskPct <= 0 || entry <= 0 || stop <= 0 || stop == entry || feeRate < 0) return null;
    final side = stop < entry ? Side.long : Side.short;
    final d = side == Side.long ? 1 : -1;
    if (tp1 != null && d * (tp1 - entry) <= 0) tp1 = null;
    if (tp2 != null && d * (tp2 - entry) <= 0) tp2 = null;
    // Loss per unit at the stop: the distance plus the fee on the way in and out.
    final perUnit = (entry - stop).abs() + feeRate * (entry + stop);
    final size = balance * riskPct / 100 / perUnit;
    return PositionPlan._(
      side: side,
      balance: balance,
      riskPct: riskPct,
      entry: entry,
      stop: stop,
      feeRate: feeRate,
      size: size,
      tp1: tp1,
      tp2: tp2,
    );
  }

  final Side side;
  final double balance, riskPct, entry, stop, feeRate;
  final double? tp1, tp2;

  /// Units to buy or sell (coins, or shares on Polymarket).
  final double size;

  double get riskAmount => balance * riskPct / 100;
  double get notional => size * entry;

  /// Stop distance as a fraction of entry.
  double get stopFraction => (entry - stop).abs() / entry;

  /// Leverage the position needs on this balance; at most 1 means spot can carry it.
  double get leverageNeeded => notional / balance;
  bool get fitsSpot => leverageNeeded <= 1;

  /// The leverage to use: the smallest whole number that carries the position.
  int get leverage => math.max(1, leverageNeeded.ceil());

  /// Highest leverage that keeps liquidation [liquidationCushion] stop-distances away.
  int get maxSafeLeverage => math.max(1, (1 / (liquidationCushion * stopFraction + maintenanceMargin)).floor());

  /// Whether [leverage] is within [maxSafeLeverage].
  bool get leverageSafe => leverage <= maxSafeLeverage;

  /// Margin put up at [leverage].
  double get margin => notional / leverage;

  /// Estimated isolated-margin liquidation price at [leverage]; null without leverage.
  double? get liquidation {
    if (leverage <= 1) return null;
    final f = 1 / leverage - maintenanceMargin;
    return side == Side.long ? entry * (1 - f) : entry * (1 + f);
  }

  /// Net result (after both fees) if the trade closes at [exit], in quote currency.
  double pnlAt(double exit) =>
      (side == Side.long ? exit - entry : entry - exit) * size - feeRate * (entry + exit) * size;

  /// [pnlAt] in multiples of [riskAmount]; −1 at the stop by construction.
  double rAt(double exit) => pnlAt(exit) / riskAmount;

  /// Fees for a round trip to the stop, in quote currency.
  double get feesAtStop => feeRate * (entry + stop) * size;

  /// Spot: the largest position the balance buys, and what it then risks (%).
  double get spotSize => math.min(size, balance / entry);
  double get spotRiskPct => spotSize * ((entry - stop).abs() + feeRate * (entry + stop)) / balance * 100;

  /// Plain-language cautions, most important first.
  List<String> get warnings => [
        if (riskPct > 2) 'Risking ${riskPct.toStringAsFixed(1)}% a trade: a losing streak of 10 (common) costs '
            '${(100 * (1 - math.pow(1 - riskPct / 100, 10))).round()}% of the account. Most traders risk 0.5–2%.',
        if (!leverageSafe)
          'Needs ${leverage}x, but the safe maximum for this stop is ${maxSafeLeverage}x: the exchange could '
              'liquidate you before the stop. Risk less, or skip this trade.',
        if (stopFraction < 0.002) 'The stop is very tight (${(stopFraction * 100).toStringAsFixed(2)}%): fees and '
            'spread will be a large share of the risk.',
      ];
}
