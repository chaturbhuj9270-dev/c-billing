import 'package:c_billing/features/customer/presentation/widgets/customer_filter_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> customer(Object? createdAt) => {
    'firstName': 'A',
    'createdAt': createdAt,
  };

  final feb = DateTimeRange(
    start: DateTime(2026, 2, 1),
    end: DateTime(2026, 2, 28),
  );

  test('no range means every customer is shown (default unchanged)', () {
    expect(
      customerCreatedInRange(customer(DateTime(2020, 1, 1)), null),
      isTrue,
    );
    expect(customerCreatedInRange(customer(null), null), isTrue);
  });

  test('range is whole days and inclusive on both ends', () {
    expect(
      customerCreatedInRange(customer(DateTime(2026, 2, 1, 0, 0)), feb),
      isTrue,
    );
    expect(
      customerCreatedInRange(customer(DateTime(2026, 2, 28, 23, 59)), feb),
      isTrue,
    );
    expect(
      customerCreatedInRange(customer(DateTime(2026, 1, 31, 23, 59)), feb),
      isFalse,
    );
    expect(
      customerCreatedInRange(customer(DateTime(2026, 3, 1)), feb),
      isFalse,
    );
  });

  test('ISO string dates work and missing dates are hidden under a range', () {
    expect(
      customerCreatedInRange(
        customer(DateTime(2026, 2, 10).toIso8601String()),
        feb,
      ),
      isTrue,
    );
    expect(customerCreatedInRange(customer(null), feb), isFalse);
    expect(customerCreatedInRange(customer('not a date'), feb), isFalse);
  });

  test('preset chips map to whole-day ranges and All means no filter', () {
    final now = DateTime(2026, 2, 15, 10);
    expect(customerDateFilterRange(CustomerDateFilter.all, now: now), isNull);

    final month = customerDateFilterRange(
      CustomerDateFilter.thisMonth,
      now: now,
    )!;
    expect(month.start, DateTime(2026, 2, 1));
    expect(month.end, DateTime(2026, 2, 28));

    final year = customerDateFilterRange(
      CustomerDateFilter.thisYear,
      now: now,
    )!;
    expect(year.start, DateTime(2026, 1, 1));
    expect(year.end, DateTime(2026, 12, 31));

    final last = customerDateFilterRange(
      CustomerDateFilter.lastYear,
      now: now,
    )!;
    expect(last.start, DateTime(2025, 1, 1));
    expect(last.end, DateTime(2025, 12, 31));
    expect(
      customerCreatedInRange(customer(DateTime(2025, 12, 31, 23, 59)), last),
      isTrue,
    );
  });

  test('custom preset without both dates applies no filter', () {
    expect(
      customerDateFilterRange(
        CustomerDateFilter.custom,
        customStart: DateTime(2026, 2, 1),
      ),
      isNull,
    );
    expect(
      customerMatchesDateFilter(
        createdAt: null,
        filter: CustomerDateFilter.custom,
      ),
      isTrue,
    );
  });
}
