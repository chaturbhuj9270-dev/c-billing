import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../billing/offline/controllers/bill_offline_controller.dart';
import '../../../billing/offline/entities/bill_entity.dart';
import '../../../billing/domain/sale_return_math.dart';

/// Time window for the Sales Analysis chart.
enum SalesChartPeriod { week, month, year }

/// Which business metric the area chart displays.
enum SalesChartMetric { sales, profit, order, quantity, returnOrder }

/// One point on the area chart.
class SalesChartPoint {
  final DateTime date;
  final String label;
  final double value;

  const SalesChartPoint({
    required this.date,
    required this.label,
    required this.value,
  });
}

class _DayMetrics {
  double sales = 0;
  double profit = 0;
  int orders = 0;
  double quantity = 0;
  double returnOrders = 0;
}

/// Builds time-series points from local bills for the selected metric + period.
///
/// Profit math matches [DashboardLocalDataSource._getSalesDataForPeriod]:
/// `netRevenue = netSoldQty * sellingPrice * bill.itemChargeRatio`.
class SalesChartAggregator {
  SalesChartAggregator._();

  static Future<List<SalesChartPoint>> load({
    required SalesChartPeriod period,
    required SalesChartMetric metric,
  }) async {
    final now = DateTime.now();
    final range = _rangeFor(period, now);
    final bills = await BillOfflineController.instance.getBillsByDateRange(
      range.$1,
      range.$2,
    );

    final byDay = <DateTime, _DayMetrics>{};
    for (final bill in bills) {
      final key = DateTime(
        bill.billDate.year,
        bill.billDate.month,
        bill.billDate.day,
      );
      final day = byDay.putIfAbsent(key, _DayMetrics.new);
      _accumulateBill(day, bill);
    }

    return switch (period) {
      SalesChartPeriod.week => _pointsForWeek(range.$1, byDay, metric),
      SalesChartPeriod.month => _pointsForMonth(now, byDay, metric),
      SalesChartPeriod.year => _pointsForYear(now, byDay, metric),
    };
  }

  static void _accumulateBill(_DayMetrics day, BillEntity bill) {
    day.orders += 1;
    // Item charge ratio (discount/tax, excludes labour/service extras) —
    // same as dashboard KPIs and the return refund.
    final chargeRatio = bill.itemChargeRatio;
    var returnedValue = 0.0;

    for (final item in bill.items) {
      final qty = item.quantity;
      final returned = item.returnedQuantity;
      final net = qty - returned;
      day.quantity += qty;
      day.returnOrders += returned;
      returnedValue += SaleReturnMath.returnedValue(
        sellingPrice: item.sellingPrice,
        returnedQuantity: returned,
        chargeRatio: chargeRatio,
      );

      final netRevenue = net * item.sellingPrice * chargeRatio;
      final netCost = net * item.purchasePrice;
      day.profit += netRevenue - netCost;
    }
    // Sales after returns, consistent with the dashboard cards.
    day.sales += SaleReturnMath.netSales(
      finalAmount: bill.finalAmount,
      returnedValue: returnedValue,
    );
  }

  static (DateTime, DateTime) _rangeFor(SalesChartPeriod period, DateTime now) {
    switch (period) {
      case SalesChartPeriod.week:
        final start = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final end = start
            .add(const Duration(days: 7))
            .subtract(const Duration(milliseconds: 1));
        return (start, end);
      case SalesChartPeriod.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1)
            .subtract(const Duration(milliseconds: 1));
        return (start, end);
      case SalesChartPeriod.year:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, 12, 31, 23, 59, 59);
        return (start, end);
    }
  }

  static double _metricOf(_DayMetrics? m, SalesChartMetric metric) {
    if (m == null) return 0;
    return switch (metric) {
      SalesChartMetric.sales => m.sales,
      SalesChartMetric.profit => m.profit,
      SalesChartMetric.order => m.orders.toDouble(),
      SalesChartMetric.quantity => m.quantity,
      SalesChartMetric.returnOrder => m.returnOrders,
    };
  }

  static List<SalesChartPoint> _pointsForWeek(
    DateTime weekStart,
    Map<DateTime, _DayMetrics> byDay,
    SalesChartMetric metric,
  ) {
    final fmt = DateFormat('E');
    return List.generate(7, (i) {
      final day = weekStart.add(Duration(days: i));
      final key = DateTime(day.year, day.month, day.day);
      return SalesChartPoint(
        date: key,
        label: fmt.format(day),
        value: _metricOf(byDay[key], metric),
      );
    });
  }

  static List<SalesChartPoint> _pointsForMonth(
    DateTime now,
    Map<DateTime, _DayMetrics> byDay,
    SalesChartMetric metric,
  ) {
    final days = DateTime(now.year, now.month + 1, 0).day;
    final fmt = DateFormat('d');
    return List.generate(days, (i) {
      final day = DateTime(now.year, now.month, i + 1);
      return SalesChartPoint(
        date: day,
        label: fmt.format(day),
        value: _metricOf(byDay[day], metric),
      );
    });
  }

  static List<SalesChartPoint> _pointsForYear(
    DateTime now,
    Map<DateTime, _DayMetrics> byDay,
    SalesChartMetric metric,
  ) {
    final fmt = DateFormat('MMM');
    return List.generate(now.month, (i) {
      final month = i + 1;
      final start = DateTime(now.year, month, 1);
      final endDay = DateTime(now.year, month + 1, 0).day;
      double sum = 0;
      for (var d = 1; d <= endDay; d++) {
        sum += _metricOf(byDay[DateTime(now.year, month, d)], metric);
      }
      return SalesChartPoint(
        date: start,
        label: fmt.format(start),
        value: sum,
      );
    });
  }
}

/// Easy-to-read Sales Analysis area chart with metric + period filters.
class SalesAnalysisChart extends StatefulWidget {
  const SalesAnalysisChart({
    super.key,
    this.reloadToken,
    this.compact = false,
  });

  final Object? reloadToken;
  final bool compact;

  @override
  State<SalesAnalysisChart> createState() => _SalesAnalysisChartState();
}

class _SalesAnalysisChartState extends State<SalesAnalysisChart>
    with SingleTickerProviderStateMixin {
  SalesChartPeriod _period = SalesChartPeriod.month;
  SalesChartMetric _metric = SalesChartMetric.sales;
  List<SalesChartPoint> _points = const [];
  bool _loading = true;
  int? _selectedIndex;
  late final AnimationController _anim;

  static const _lineBlue = Color(0xFF7B8CDE);
  static const _fillTop = Color(0xFFB8C4F0);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _load();
  }

  @override
  void didUpdateWidget(covariant SalesAnalysisChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _load();
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _selectedIndex = null;
    });
    try {
      final points = await SalesChartAggregator.load(
        period: _period,
        metric: _metric,
      );
      if (!mounted) return;
      setState(() {
        _points = points;
        _loading = false;
      });
      _anim
        ..reset()
        ..forward();
    } catch (e, st) {
      debugPrint('[SalesAnalysisChart] load failed: $e\n$st');
      if (!mounted) return;
      setState(() {
        _points = const [];
        _loading = false;
      });
    }
  }

  void _setPeriod(SalesChartPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    _load();
  }

  void _setMetric(SalesChartMetric metric) {
    if (_metric == metric) return;
    setState(() => _metric = metric);
    _load();
  }

  double get _total => _points.fold(0.0, (s, p) => s + p.value);

  bool get _isMoney =>
      _metric == SalesChartMetric.sales || _metric == SalesChartMetric.profit;

  String _formatValue(double v, {bool axis = false}) {
    final abs = v.abs();
    if (_isMoney) {
      if (abs >= 10000000) {
        return '${axis ? '' : '₹'}${(v / 10000000).toStringAsFixed(1)}Cr';
      }
      if (abs >= 100000) {
        return '${axis ? '' : '₹'}${(v / 100000).toStringAsFixed(1)}L';
      }
      if (abs >= 1000) {
        return '${axis ? '' : '₹'}${(v / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k';
      }
      return axis ? v.toStringAsFixed(0) : '₹${v.toStringAsFixed(0)}';
    }
    if (abs >= 1000) {
      return '${(v / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}k';
    }
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  String get _metricLabel => switch (_metric) {
        SalesChartMetric.sales => 'Sales',
        SalesChartMetric.profit => 'Profit',
        SalesChartMetric.order => 'Orders',
        SalesChartMetric.quantity => 'Quantity',
        SalesChartMetric.returnOrder => 'Returns',
      };

  /// Chart heading follows the selected metric tab (Sales / Profit / …).
  String get _chartTitle => switch (_metric) {
        SalesChartMetric.sales => 'Sales Analysis',
        SalesChartMetric.profit => 'Profit Analysis',
        SalesChartMetric.order => 'Order Analysis',
        SalesChartMetric.quantity => 'Quantity Analysis',
        SalesChartMetric.returnOrder => 'Return Order Analysis',
      };

  String get _periodCaption {
    final now = DateTime.now();
    return switch (_period) {
      SalesChartPeriod.week => 'This week',
      SalesChartPeriod.month => DateFormat('MMMM yyyy').format(now),
      SalesChartPeriod.year => DateFormat('yyyy').format(now),
    };
  }

  @override
  Widget build(BuildContext context) {
    final chartHeight = widget.compact ? 200.0 : 240.0;
    final lineColor = Color.lerp(AppColors.action(context), _lineBlue, 0.55)!;
    final fillColor = Color.lerp(AppColors.action(context), _fillTop, 0.72)!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        widget.compact ? 12 : 16,
        widget.compact ? 12 : 14,
        widget.compact ? 12 : 16,
        widget.compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _chartTitle,
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontSize: widget.compact ? 15 : 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Literata',
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _loading
                          ? 'Loading…'
                          : '$_metricLabel · $_periodCaption · ${_formatValue(_total)} total',
                      style: TextStyle(
                        color: AppColors.mutedText(context),
                        fontSize: 12,
                        fontFamily: 'Literata',
                      ),
                    ),
                  ],
                ),
              ),
              _PeriodSegment(
                period: _period,
                onChanged: _setPeriod,
                compact: widget.compact,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MetricTabs(
            metric: _metric,
            onChanged: _setMetric,
            compact: widget.compact,
            activeColor: lineColor,
          ),
          if (_selectedIndex != null &&
              _selectedIndex! >= 0 &&
              _selectedIndex! < _points.length) ...[
            const SizedBox(height: 10),
            _ValueChip(
              point: _points[_selectedIndex!],
              metricLabel: _metricLabel,
              formatValue: _formatValue,
              accent: lineColor,
              period: _period,
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            height: chartHeight,
            child: _loading
                ? Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: lineColor,
                      ),
                    ),
                  )
                : _points.every((p) => p.value <= 0)
                    ? _EmptyChart(color: AppColors.mutedText(context))
                    : AnimatedBuilder(
                        animation: _anim,
                        builder: (context, _) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) {
                                  final idx = _hitIndex(
                                    details.localPosition,
                                    Size(constraints.maxWidth, chartHeight),
                                    _points.length,
                                  );
                                  setState(() => _selectedIndex = idx);
                                },
                                onPanUpdate: (details) {
                                  final idx = _hitIndex(
                                    details.localPosition,
                                    Size(constraints.maxWidth, chartHeight),
                                    _points.length,
                                  );
                                  if (idx != _selectedIndex) {
                                    setState(() => _selectedIndex = idx);
                                  }
                                },
                                child: CustomPaint(
                                  size: Size(
                                    constraints.maxWidth,
                                    chartHeight,
                                  ),
                                  painter: _AreaChartPainter(
                                    points: _points,
                                    progress: Curves.easeOutCubic
                                        .transform(_anim.value),
                                    lineColor: lineColor,
                                    fillColor: fillColor,
                                    gridColor: AppColors.border(context),
                                    labelColor: AppColors.mutedText(context),
                                    selectedIndex: _selectedIndex,
                                    formatAxis: (v) =>
                                        _formatValue(v, axis: true),
                                    period: _period,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  int? _hitIndex(Offset local, Size size, int count) {
    if (count <= 1) return count == 1 ? 0 : null;
    const leftPad = 44.0;
    const rightPad = 10.0;
    final chartW = size.width - leftPad - rightPad;
    if (chartW <= 0) return null;
    final x = (local.dx - leftPad).clamp(0.0, chartW);
    return ((x / chartW) * (count - 1)).round().clamp(0, count - 1);
  }
}

class _MetricTabs extends StatelessWidget {
  const _MetricTabs({
    required this.metric,
    required this.onChanged,
    required this.compact,
    required this.activeColor,
  });

  final SalesChartMetric metric;
  final ValueChanged<SalesChartMetric> onChanged;
  final bool compact;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final items = const [
      (SalesChartMetric.sales, 'Sales'),
      (SalesChartMetric.profit, 'Profit'),
      (SalesChartMetric.order, 'Order'),
      (SalesChartMetric.quantity, 'Quantity'),
      (SalesChartMetric.returnOrder, 'Return Order'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: compact ? 6 : 8),
            _MetricChip(
              label: items[i].$2,
              selected: metric == items[i].$1,
              compact: compact,
              activeColor: activeColor,
              onTap: () => onChanged(items[i].$1),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.selected,
    required this.compact,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool compact;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? activeColor : AppColors.card(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 7 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? activeColor : AppColors.border(context),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? AppTheme.white
                  : AppColors.secondaryText(context),
              fontSize: compact ? 11.5 : 12.5,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontFamily: 'Literata',
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({
    required this.period,
    required this.onChanged,
    required this.compact,
  });

  final SalesChartPeriod period;
  final ValueChanged<SalesChartPeriod> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final items = const [
      (SalesChartPeriod.week, 'Week'),
      (SalesChartPeriod.month, 'Month'),
      (SalesChartPeriod.year, 'Year'),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.chipFill(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in items)
            Material(
              color: period == item.$1
                  ? AppColors.action(context)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              child: InkWell(
                onTap: () => onChanged(item.$1),
                borderRadius: BorderRadius.circular(9),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 9 : 11,
                    vertical: compact ? 5 : 6,
                  ),
                  child: Text(
                    item.$2,
                    style: TextStyle(
                      color: period == item.$1
                          ? AppTheme.white
                          : AppColors.secondaryText(context),
                      fontSize: compact ? 11 : 12,
                      fontWeight: period == item.$1
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontFamily: 'Literata',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    required this.point,
    required this.metricLabel,
    required this.formatValue,
    required this.accent,
    required this.period,
  });

  final SalesChartPoint point;
  final String metricLabel;
  final String Function(double) formatValue;
  final Color accent;
  final SalesChartPeriod period;

  @override
  Widget build(BuildContext context) {
    final dateLabel = switch (period) {
      SalesChartPeriod.week => DateFormat('EEE, d MMM').format(point.date),
      SalesChartPeriod.month => DateFormat('d MMM yyyy').format(point.date),
      SalesChartPeriod.year => DateFormat('MMMM yyyy').format(point.date),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.timeline_rounded, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$metricLabel · $dateLabel',
              style: TextStyle(
                color: AppColors.primaryText(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                fontFamily: 'Literata',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            formatValue(point.value),
            style: TextStyle(
              color: accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'Literata',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 36,
            color: color.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 8),
          Text(
            'No data for this metric in the selected period',
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontFamily: 'Literata',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AreaChartPainter extends CustomPainter {
  _AreaChartPainter({
    required this.points,
    required this.progress,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
    required this.selectedIndex,
    required this.formatAxis,
    required this.period,
  });

  final List<SalesChartPoint> points;
  final double progress;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color labelColor;
  final int? selectedIndex;
  final String Function(double) formatAxis;
  final SalesChartPeriod period;

  static const double _leftPad = 44;
  static const double _rightPad = 10;
  static const double _topPad = 12;
  static const double _bottomPad = 28;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chart = Rect.fromLTRB(
      _leftPad,
      _topPad,
      size.width - _rightPad,
      size.height - _bottomPad,
    );
    if (chart.width <= 0 || chart.height <= 0) return;

    final rawMax = points.map((p) => p.value).reduce(math.max);
    final maxY = _niceMax(rawMax <= 0 ? 1 : rawMax);
    const gridCount = 7;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.7)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final labelTp = TextPainter(textDirection: ui.TextDirection.ltr);
    for (var i = 0; i <= gridCount; i++) {
      final t = i / gridCount;
      final y = chart.bottom - chart.height * t;
      _drawDashedLine(
        canvas,
        Offset(chart.left, y),
        Offset(chart.right, y),
        gridPaint,
      );
      final value = maxY * t;
      labelTp.text = TextSpan(
        text: formatAxis(value),
        style: TextStyle(
          color: labelColor,
          fontSize: 10,
          fontFamily: 'Literata',
        ),
      );
      labelTp.layout(maxWidth: _leftPad - 4);
      labelTp.paint(
        canvas,
        Offset(chart.left - labelTp.width - 6, y - labelTp.height / 2),
      );
    }

    final n = points.length;
    final coords = <Offset>[];
    for (var i = 0; i < n; i++) {
      final x = n == 1
          ? chart.left + chart.width / 2
          : chart.left + (chart.width * i / (n - 1));
      final yNorm = (points[i].value / maxY).clamp(0.0, 1.0) * progress;
      final y = chart.bottom - chart.height * yNorm;
      coords.add(Offset(x, y));
    }

    final linePath = _smoothPath(coords);
    final fillPath = Path.from(linePath)
      ..lineTo(coords.last.dx, chart.bottom)
      ..lineTo(coords.first.dx, chart.bottom)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(chart.left, chart.top),
          Offset(chart.left, chart.bottom),
          [
            fillColor.withValues(alpha: 0.45),
            fillColor.withValues(alpha: 0.05),
          ],
        )
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..isAntiAlias = true,
    );

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < coords.length) {
      final c = coords[selectedIndex!];
      canvas.drawLine(
        Offset(c.dx, chart.top),
        Offset(c.dx, chart.bottom),
        Paint()
          ..color = lineColor.withValues(alpha: 0.28)
          ..strokeWidth = 1.2,
      );
      canvas.drawCircle(c, 5.5, Paint()..color = AppTheme.white);
      canvas.drawCircle(c, 4, Paint()..color = lineColor);
    }

    final labelIndexes = _xLabelIndexes(n, period);
    for (final i in labelIndexes) {
      final p = points[i];
      final x = coords[i].dx;
      final text = switch (period) {
        SalesChartPeriod.week => DateFormat('E').format(p.date),
        SalesChartPeriod.month => DateFormat('d MMM').format(p.date),
        SalesChartPeriod.year => DateFormat('MMM').format(p.date),
      };
      labelTp.text = TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: 10.5,
          fontFamily: 'Literata',
          fontWeight: FontWeight.w600,
        ),
      );
      labelTp.layout();
      labelTp.paint(
        canvas,
        Offset(
          (x - labelTp.width / 2)
              .clamp(chart.left, chart.right - labelTp.width),
          chart.bottom + 8,
        ),
      );
    }
  }

  List<int> _xLabelIndexes(int n, SalesChartPeriod period) {
    if (n <= 1) return [0];
    final maxLabels = switch (period) {
      SalesChartPeriod.week => n,
      SalesChartPeriod.month => 6,
      SalesChartPeriod.year => math.min(n, 6),
    };
    if (n <= maxLabels) return List.generate(n, (i) => i);
    final indexes = <int>{0, n - 1};
    for (var i = 1; i < maxLabels - 1; i++) {
      indexes.add(((n - 1) * i / (maxLabels - 1)).round());
    }
    return indexes.toList()..sort();
  }

  Path _smoothPath(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    path.moveTo(pts.first.dx, pts.first.dy);
    if (pts.length == 1) return path;
    if (pts.length == 2) {
      path.lineTo(pts[1].dx, pts[1].dy);
      return path;
    }

    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[i == 0 ? i : i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = pts[i + 2 < pts.length ? i + 2 : i + 1];
      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;
    final total = (b - a).distance;
    if (total <= 0) return;
    final direction = (b - a) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final start = a + direction * drawn;
      final end = a + direction * math.min(drawn + dash, total);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  double _niceMax(double value) {
    if (value <= 0) return 1;
    final exp = (math.log(value) / math.ln10).floor();
    final f = value / math.pow(10, exp);
    final nice = f <= 1
        ? 1.0
        : f <= 2
            ? 2.0
            : f <= 5
                ? 5.0
                : 10.0;
    return nice * math.pow(10, exp).toDouble();
  }

  @override
  bool shouldRepaint(covariant _AreaChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.period != period;
  }
}
