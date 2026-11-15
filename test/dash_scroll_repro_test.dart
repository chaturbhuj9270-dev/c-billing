import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors dashboard finger-scroll physics.
class DashboardFingerScrollPhysics extends ScrollPhysics {
  const DashboardFingerScrollPhysics();

  @override
  DashboardFingerScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return const DashboardFingerScrollPhysics();
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    final next = oldPosition.pixels;
    if (!next.isFinite) return newPosition.minScrollExtent;
    return next.clamp(newPosition.minScrollExtent, newPosition.maxScrollExtent);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    if (value < position.pixels && position.pixels <= position.minScrollExtent) {
      return value - position.pixels;
    }
    if (position.maxScrollExtent <= position.pixels && position.pixels < value) {
      return value - position.pixels;
    }
    if (value < position.minScrollExtent &&
        position.minScrollExtent < position.pixels) {
      return value - position.minScrollExtent;
    }
    if (position.pixels < position.maxScrollExtent &&
        position.maxScrollExtent < value) {
      return value - position.maxScrollExtent;
    }
    return 0.0;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    if (position.outOfRange) {
      final end = position.pixels > position.maxScrollExtent
          ? position.maxScrollExtent
          : position.minScrollExtent;
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        end,
        velocity < 0.0 ? velocity : 0.0,
        tolerance: tolerance,
      );
    }
    return null;
  }
}

void main() {
  testWidgets(
    'default fling wipes short dashboard; finger physics stops with finger',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      Future<double> run(ScrollPhysics physics) async {
        final controller = ScrollController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                controller: controller,
                physics: physics,
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(height: 1400, color: Colors.teal),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.fling(
          find.byType(CustomScrollView),
          const Offset(0, -80),
          3000,
        );
        await tester.pumpAndSettle();
        final offset = controller.offset;
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        return offset;
      }

      const maxExtent = 1400 - 844.0;
      final withDefault = await run(const ClampingScrollPhysics());
      final withFinger = await run(const DashboardFingerScrollPhysics());

      expect(withDefault, closeTo(maxExtent, 1));
      expect(withFinger, closeTo(80, 5));
    },
  );

  testWidgets('finger physics keeps pull-to-refresh drag when content fits', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var refreshed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              refreshed = true;
            },
            child: CustomScrollView(
              physics: const DashboardFingerScrollPhysics(),
              slivers: const [
                SliverToBoxAdapter(
                  child: SizedBox(height: 200, child: Text('short')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.text('short'), const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(refreshed, isTrue);
  });
}
