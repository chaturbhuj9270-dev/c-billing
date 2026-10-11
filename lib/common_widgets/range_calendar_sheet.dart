import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:c_billing/core/services/language_service.dart';
import 'package:c_billing/core/theme/app_theme.dart';

/// Full-screen range calendar matching the light and dark reference.
Future<DateTimeRange?> showAppRangeCalendar({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
}) {
  return Navigator.of(context).push<DateTimeRange>(
    PageRouteBuilder<DateTimeRange>(
      fullscreenDialog: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AppRangeCalendarPage(
          firstDate: firstDate,
          lastDate: lastDate,
          initialDateRange: initialDateRange,
        );
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class AppRangeCalendarPage extends StatefulWidget {
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTimeRange? initialDateRange;

  const AppRangeCalendarPage({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.initialDateRange,
  });

  @override
  State<AppRangeCalendarPage> createState() => _AppRangeCalendarPageState();
}

class _AppRangeCalendarPageState extends State<AppRangeCalendarPage> {
  late final DateTime _first;
  late final DateTime _last;
  late final List<DateTime> _months;
  final Map<DateTime, GlobalKey> _monthKeys = {};
  final ScrollController _scroll = ScrollController();
  final TextEditingController _startField = TextEditingController();
  final TextEditingController _endField = TextEditingController();

  DateTime? _start;
  DateTime? _end;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    var first = _dateOnly(widget.firstDate);
    var last = _dateOnly(widget.lastDate);
    if (last.isBefore(first)) {
      final swap = first;
      first = last;
      last = swap;
    }
    _first = first;
    _last = last;

    final months = <DateTime>[];
    var cursor = DateTime(_first.year, _first.month);
    final endMonth = DateTime(_last.year, _last.month);
    while (!cursor.isAfter(endMonth)) {
      months.add(cursor);
      _monthKeys[cursor] = GlobalKey();
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    _months = months;

    final initial = widget.initialDateRange;
    if (initial != null) {
      var start = _clamp(_dateOnly(initial.start));
      var end = _clamp(_dateOnly(initial.end));
      if (end.isBefore(start)) {
        final swap = start;
        start = end;
        end = swap;
      }
      _start = start;
      _end = end;
    }
    _syncFields();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _revealMonth(_start ?? _today());
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _startField.dispose();
    _endField.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  DateTime _today() => _dateOnly(DateTime.now());

  DateTime _clamp(DateTime value) {
    final day = _dateOnly(value);
    if (day.isBefore(_first)) return _first;
    if (day.isAfter(_last)) return _last;
    return day;
  }

  bool _enabled(DateTime day) {
    final date = _dateOnly(day);
    return !date.isBefore(_first) && !date.isAfter(_last);
  }

  bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isEndpoint(DateTime day) {
    if (_start != null && _same(_start!, day)) return true;
    if (_end != null && _same(_end!, day)) return true;
    return false;
  }

  bool _inRange(DateTime day) {
    if (_start == null) return false;
    final date = _dateOnly(day);
    final end = _end ?? _start!;
    return !date.isBefore(_start!) && !date.isAfter(end);
  }

  int get _dayCount {
    if (_start == null || _end == null) return 0;
    return _end!.difference(_start!).inDays + 1;
  }

  void _syncFields() {
    final format = DateFormat('MMM d, yyyy');
    _startField.text = _start == null ? '' : format.format(_start!);
    _endField.text = _end == null ? '' : format.format(_end!);
  }

  void _revealMonth(DateTime day) {
    final month = DateTime(day.year, day.month);
    final context = _monthKeys[month]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.02,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _selectDay(DateTime day) {
    if (!_enabled(day)) return;
    final date = _dateOnly(day);
    setState(() {
      if (_start == null || _end != null) {
        _start = date;
        _end = null;
      } else if (date.isBefore(_start!)) {
        _end = _start;
        _start = date;
      } else {
        _end = date;
      }
      _syncFields();
    });
  }

  void _applyPreset(_RangePreset preset) {
    final today = _clamp(_today());
    late DateTime start;
    late DateTime end;
    switch (preset) {
      case _RangePreset.today:
        start = today;
        end = today;
      case _RangePreset.last7:
        start = _clamp(today.subtract(const Duration(days: 6)));
        end = today;
      case _RangePreset.thisMonth:
        start = _clamp(DateTime(today.year, today.month, 1));
        end = _clamp(DateTime(today.year, today.month + 1, 0));
      case _RangePreset.lastMonth:
        start = _clamp(DateTime(today.year, today.month - 1, 1));
        end = _clamp(DateTime(today.year, today.month, 0));
    }
    if (end.isBefore(start)) end = start;
    setState(() {
      _start = start;
      _end = end;
      _syncFields();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _revealMonth(start));
  }

  void _applyTypedRange() {
    final start = _tryParse(_startField.text);
    final end = _tryParse(_endField.text);
    if (start == null || end == null) return;
    var clampedStart = _clamp(start);
    var clampedEnd = _clamp(end);
    if (clampedEnd.isBefore(clampedStart)) {
      final swap = clampedStart;
      clampedStart = clampedEnd;
      clampedEnd = swap;
    }
    setState(() {
      _start = clampedStart;
      _end = clampedEnd;
      _syncFields();
    });
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _revealMonth(clampedStart),
    );
  }

  DateTime? _tryParse(String text) {
    final value = text.trim();
    if (value.isEmpty) return null;
    for (final pattern in const [
      'MMM d, yyyy',
      'MMM d yyyy',
      'd MMM yyyy',
      'dd/MM/yyyy',
      'yyyy-MM-dd',
    ]) {
      try {
        return _dateOnly(DateFormat(pattern).parseStrict(value));
      } on FormatException {
        continue;
      }
    }
    return null;
  }

  void _apply() {
    if (_start == null || _end == null) return;
    Navigator.of(context).pop(DateTimeRange(start: _start!, end: _end!));
  }

  String _copy(String english, String hindi, String marathi) {
    switch (LanguageService.instance.currentLanguage) {
      case 'Hindi':
        return hindi;
      case 'Marathi':
        return marathi;
      default:
        return english;
    }
  }

  String _title() {
    if (_start == null) {
      return _copy('Select dates', 'तारीख चुनें', 'तारीख निवडा');
    }
    final start = DateFormat('MMM d').format(_start!);
    if (_end == null) return start;
    return '$start – ${DateFormat('MMM d').format(_end!)}';
  }

  String _countLabel() {
    final count = _dayCount;
    if (count <= 0) {
      return _copy('Select dates', 'तारीख चुनें', 'तारीख निवडा');
    }
    if (count == 1) {
      return _copy('1 day selected', '1 दिन चुना गया', '1 दिवस निवडला');
    }
    return _copy(
      '$count days selected',
      '$count दिन चुने गए',
      '$count दिवस निवडले',
    );
  }

  String _footerRange() {
    if (_start == null) return '';
    if (_end == null) return DateFormat('MMM d, yyyy').format(_start!);
    if (_start!.year == _end!.year) {
      return '${DateFormat('MMM d').format(_start!)} – ${DateFormat('MMM d, yyyy').format(_end!)}';
    }
    final format = DateFormat('MMM d, yyyy');
    return '${format.format(_start!)} – ${format.format(_end!)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    final background = isDark ? AppTheme.paletteFF0E0E0E : AppTheme.paletteFFF4F7F4;
    final titleColor = isDark ? AppTheme.white : AppTheme.paletteFF121816;
    final muted = isDark ? AppTheme.paletteFF8E9892 : AppTheme.paletteFF7C8680;
    final line = isDark ? AppTheme.paletteFF242826 : AppTheme.paletteFFE3E8E4;
    final canApply = _start != null && _end != null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    _RoundIconButton(
                      isDark: isDark,
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    _RoundIconButton(
                      isDark: isDark,
                      icon: _editing
                          ? Icons.calendar_month_rounded
                          : Icons.edit_outlined,
                      onTap: () {
                        if (_editing) _applyTypedRange();
                        setState(() {
                          _editing = !_editing;
                          if (_editing) _syncFields();
                        });
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Text(
                  _copy('Select range', 'रेंज चुनें', 'श्रेणी निवडा'),
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: muted,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  _title(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: titleColor,
                  ),
                ),
              ),
              if (_editing)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          isDark: isDark,
                          controller: _startField,
                          hint: _copy('Start', 'शुरू', 'सुरुवात'),
                          onSubmitted: (_) => _applyTypedRange(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '–',
                          style: TextStyle(
                            color: muted,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _DateField(
                          isDark: isDark,
                          controller: _endField,
                          hint: _copy('End', 'अंत', 'शेवट'),
                          onSubmitted: (_) => _applyTypedRange(),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _PresetChip(
                      isDark: isDark,
                      label: _copy('Today', 'आज', 'आज'),
                      onTap: () => _applyPreset(_RangePreset.today),
                    ),
                    _PresetChip(
                      isDark: isDark,
                      label: _copy('Last 7 days', 'पिछले 7 दिन', 'मागील 7 दिवस'),
                      onTap: () => _applyPreset(_RangePreset.last7),
                    ),
                    _PresetChip(
                      isDark: isDark,
                      label: _copy('This month', 'इस महीने', 'या महिन्यात'),
                      onTap: () => _applyPreset(_RangePreset.thisMonth),
                    ),
                    _PresetChip(
                      isDark: isDark,
                      label: _copy('Last month', 'पिछला महीना', 'मागील महिना'),
                      onTap: () => _applyPreset(_RangePreset.lastMonth),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: line),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Row(
                  children: [
                    for (final label in const ['S', 'M', 'T', 'W', 'T', 'F', 'S'])
                      Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: muted,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: line),
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  children: [
                    for (final month in _months)
                      _MonthBlock(
                        key: _monthKeys[month],
                        month: month,
                        titleColor: titleColor,
                        dayColor: isDark
                            ? AppTheme.paletteFFE8EEEA
                            : AppTheme.paletteFF1C2420,
                        disabledColor: isDark
                            ? AppTheme.paletteFF3C4440
                            : AppTheme.paletteFFC5CBC7,
                        rangeColor: isDark
                            ? AppTheme.paletteFF16382C
                            : AppTheme.paletteFFD7EDE3,
                        inRangeText: isDark
                            ? AppTheme.white
                            : AppTheme.paletteFF163028,
                        endpointColor: isDark
                            ? AppTheme.mint
                            : AppTheme.paletteFF1B7A4A,
                        endpointText: isDark ? AppTheme.onMint : AppTheme.white,
                        enabled: _enabled,
                        inRange: _inRange,
                        isEndpoint: _isEndpoint,
                        onDayTap: _selectDay,
                      ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: line),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _countLabel(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: muted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _footerRange(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontFamily: 'Literata',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _ApplyButton(
                  isDark: isDark,
                  enabled: canApply,
                  label: _copy('Apply range', 'रेंज लागू करें', 'श्रेणी लागू करा'),
                  onTap: _apply,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _RangePreset { today, last7, thisMonth, lastMonth }

class _RoundIconButton extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? AppTheme.paletteFF1A1C1B : AppTheme.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppTheme.paletteFF2A2E2C : AppTheme.paletteFFE6ECE8,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppTheme.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? AppTheme.white : AppTheme.paletteFF1A1F1C,
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final bool isDark;
  final String label;
  final VoidCallback onTap;

  const _PresetChip({
    required this.isDark,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isDark ? AppTheme.paletteFF171918 : AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppTheme.paletteFF2C322F
                    : AppTheme.paletteFFE4E9E5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.paletteFFE6ECE8 : AppTheme.paletteFF1C2420,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final bool isDark;
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onSubmitted;

  const _DateField({
    required this.isDark,
    required this.controller,
    required this.hint,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      style: TextStyle(
        fontFamily: 'Literata',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.white : AppTheme.paletteFF121816,
      ),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: isDark ? AppTheme.paletteFF171918 : AppTheme.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: TextStyle(
          fontFamily: 'Literata',
          color: isDark ? AppTheme.paletteFF6E7872 : AppTheme.paletteFF9AA39D,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppTheme.paletteFF2C322F : AppTheme.paletteFFE4E9E5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppTheme.paletteFF2C322F : AppTheme.paletteFFE4E9E5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? AppTheme.mint : AppTheme.primary,
          ),
        ),
      ),
    );
  }
}

class _ApplyButton extends StatelessWidget {
  final bool isDark;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  const _ApplyButton({
    required this.isDark,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? null : AppTheme.paletteFF1B7A4A,
          gradient: isDark
              ? const LinearGradient(
                  colors: [
                    AppTheme.paletteFF146B45,
                    AppTheme.paletteFF1E9A62,
                    AppTheme.mint,
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: (isDark ? AppTheme.mint : AppTheme.primary)
                        .withValues(alpha: isDark ? 0.32 : 0.16),
                    blurRadius: isDark ? 22 : 12,
                    offset: Offset(0, isDark ? 8 : 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: AppTheme.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 52,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Literata',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthBlock extends StatelessWidget {
  final DateTime month;
  final Color titleColor;
  final Color dayColor;
  final Color disabledColor;
  final Color rangeColor;
  final Color inRangeText;
  final Color endpointColor;
  final Color endpointText;
  final bool Function(DateTime day) enabled;
  final bool Function(DateTime day) inRange;
  final bool Function(DateTime day) isEndpoint;
  final ValueChanged<DateTime> onDayTap;

  const _MonthBlock({
    super.key,
    required this.month,
    required this.titleColor,
    required this.dayColor,
    required this.disabledColor,
    required this.rangeColor,
    required this.inRangeText,
    required this.endpointColor,
    required this.endpointText,
    required this.enabled,
    required this.inRange,
    required this.isEndpoint,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final leading = DateTime(month.year, month.month, 1).weekday % 7;
    final cells = List<DateTime?>.filled(
      leading + daysInMonth,
      null,
      growable: true,
    );
    for (var day = 1; day <= daysInMonth; day++) {
      cells[leading + day - 1] = DateTime(month.year, month.month, day);
    }
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final weeks = <List<DateTime?>>[];
    for (var index = 0; index < cells.length; index += 7) {
      weeks.add(cells.sublist(index, index + 7));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ),
          for (final week in weeks)
            _WeekRow(
              days: week,
              rangeColor: rangeColor,
              dayColor: dayColor,
              disabledColor: disabledColor,
              inRangeText: inRangeText,
              endpointColor: endpointColor,
              endpointText: endpointText,
              enabled: enabled,
              inRange: inRange,
              isEndpoint: isEndpoint,
              onDayTap: onDayTap,
            ),
        ],
      ),
    );
  }
}

class _WeekRow extends StatelessWidget {
  final List<DateTime?> days;
  final Color rangeColor;
  final Color dayColor;
  final Color disabledColor;
  final Color inRangeText;
  final Color endpointColor;
  final Color endpointText;
  final bool Function(DateTime day) enabled;
  final bool Function(DateTime day) inRange;
  final bool Function(DateTime day) isEndpoint;
  final ValueChanged<DateTime> onDayTap;

  const _WeekRow({
    required this.days,
    required this.rangeColor,
    required this.dayColor,
    required this.disabledColor,
    required this.inRangeText,
    required this.endpointColor,
    required this.endpointText,
    required this.enabled,
    required this.inRange,
    required this.isEndpoint,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cellWidth = constraints.maxWidth / 7;
          return Stack(
            children: [
              ..._rangeBars(cellWidth),
              Row(
                children: [
                  for (final day in days)
                    Expanded(child: _dayCell(day)),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _rangeBars(double cellWidth) {
    final bars = <Widget>[];
    var index = 0;
    while (index < days.length) {
      final day = days[index];
      final selected = day != null && inRange(day);
      if (!selected) {
        index++;
        continue;
      }
      final startIndex = index;
      while (index < days.length &&
          days[index] != null &&
          inRange(days[index]!)) {
        index++;
      }
      final endIndex = index - 1;
      if (endIndex == startIndex) continue;

      final startDay = days[startIndex]!;
      final endDay = days[endIndex]!;
      final left = startIndex * cellWidth +
          (isEndpoint(startDay) ? cellWidth * 0.5 : 3);
      final right = (endIndex + 1) * cellWidth -
          (isEndpoint(endDay) ? cellWidth * 0.5 : 3);
      if (right - left < 8) continue;

      bars.add(
        Positioned(
          left: left,
          width: right - left,
          top: 6,
          height: 34,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: rangeColor,
              borderRadius: BorderRadius.circular(17),
            ),
          ),
        ),
      );
    }
    return bars;
  }

  Widget _dayCell(DateTime? day) {
    if (day == null) return const SizedBox.expand();
    final isEnabled = enabled(day);
    final endpoint = isEnabled && isEndpoint(day);
    final inside = isEnabled && inRange(day);
    return GestureDetector(
      onTap: isEnabled ? () => onDayTap(day) : null,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: endpoint
              ? BoxDecoration(color: endpointColor, shape: BoxShape.circle)
              : null,
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontFamily: 'Literata',
              fontSize: 14,
              fontWeight: endpoint ? FontWeight.w700 : FontWeight.w500,
              color: !isEnabled
                  ? disabledColor
                  : endpoint
                  ? endpointText
                  : inside
                  ? inRangeText
                  : dayColor,
            ),
          ),
        ),
      ),
    );
  }
}
