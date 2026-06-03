import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/contracts/ohey_api_values.dart';
import 'package:ohey/core/models/ohey_user.dart';

void main() {
  test('daily status availability weights are centralized', () {
    expect(OheyDailyStatus.available.availabilityWeight, 1.0);
    expect(OheyDailyStatus.maybeAvailable.availabilityWeight, .8);
    expect(OheyDailyStatus.dependsOnTime.availabilityWeight, .5);
    expect(OheyDailyStatus.unselected.availabilityWeight, 0);
    expect(OheyDailyStatus.hasPlans.availabilityWeight, 0);
  });

  test('daily status recommendation helpers are centralized', () {
    expect(OheyDailyStatus.available.recommendationBonus, 60);
    expect(OheyDailyStatus.maybeAvailable.recommendationBonus, 50);
    expect(OheyDailyStatus.dependsOnTime.recommendationBonus, 0);
    expect(OheyDailyStatus.hasPlans.blocksRecommendations, isTrue);
    expect(OheyDailyStatus.unselected.isUndecided, isTrue);
  });

  test('unknown or unset daily status keys normalize to undecided', () {
    expect(oheyDailyStatusFromKey(null).isUndecided, isTrue);
    expect(oheyDailyStatusFromKey('').isUndecided, isTrue);
    expect(oheyDailyStatusFromKey(OheyStatusKeys.unset).isUndecided, isTrue);
    expect(oheyDailyStatusFromKey('unknown').availabilityWeight, 0);
  });
}
