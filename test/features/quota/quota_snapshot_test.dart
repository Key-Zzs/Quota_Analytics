import 'package:quota_analytics/features/quota/domain/entities/quota_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuotaWindow', () {
    test('computes remaining and ok status from usage', () {
      final window = QuotaWindow.fromUsage(
        label: '5-hour window',
        used: 60,
        limit: 100,
        resetAt: null,
      );

      expect(window.remaining, 40);
      expect(window.remainingRatio, 0.4);
      expect(window.remainingPercentage, 40);
      expect(window.status, QuotaWindowStatus.ok);
    });

    test('uses warning status when remaining ratio is low', () {
      final window = QuotaWindow.fromUsage(
        label: 'Weekly window',
        used: 80,
        limit: 100,
        resetAt: null,
      );

      expect(window.remainingRatio, 0.2);
      expect(window.status, QuotaWindowStatus.warning);
    });

    test('uses critical status when remaining ratio is very low', () {
      final window = QuotaWindow.fromUsage(
        label: '5-hour window',
        used: 95,
        limit: 100,
        resetAt: null,
      );

      expect(window.remainingRatio, 0.05);
      expect(window.status, QuotaWindowStatus.critical);
    });

    test('uses unknown status when usage is incomplete', () {
      final window = QuotaWindow.fromUsage(
        label: 'Weekly window',
        used: null,
        limit: 100,
        resetAt: null,
      );

      expect(window.remaining, isNull);
      expect(window.remainingRatio, isNull);
      expect(window.status, QuotaWindowStatus.unknown);
    });
  });
}
