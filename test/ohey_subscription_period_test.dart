import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/services/ohey_subscription_period.dart';

void main() {
  group('oheySubscriptionPeriodLabel', () {
    test('formats supported recurring periods', () {
      expect(oheySubscriptionPeriodLabel('P1W'), '1週間ごと');
      expect(oheySubscriptionPeriodLabel('P1M'), '1か月ごと');
      expect(oheySubscriptionPeriodLabel('P3M'), '3か月ごと');
      expect(oheySubscriptionPeriodLabel('P1Y'), '1年ごと');
    });

    test('returns null for missing or unsupported periods', () {
      expect(oheySubscriptionPeriodLabel(null), isNull);
      expect(oheySubscriptionPeriodLabel(''), isNull);
      expect(oheySubscriptionPeriodLabel('P0M'), isNull);
      expect(oheySubscriptionPeriodLabel('P1D'), isNull);
      expect(oheySubscriptionPeriodLabel('1M'), isNull);
    });
  });
}
