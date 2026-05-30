import 'ohey_avatar.dart';
import 'ohey_gender.dart';

enum OheyDailyStatus {
  unselected,
  available,
  maybeAvailable,
  dependsOnTime,
  hasPlans,
}

extension OheyDailyStatusX on OheyDailyStatus {
  String get key => switch (this) {
    OheyDailyStatus.unselected => 'unselected',
    OheyDailyStatus.available => 'available',
    OheyDailyStatus.maybeAvailable => 'maybe_available',
    OheyDailyStatus.dependsOnTime => 'depends_on_time',
    OheyDailyStatus.hasPlans => 'has_plans',
  };

  String get label => switch (this) {
    OheyDailyStatus.unselected => 'まだ決めてない',
    OheyDailyStatus.available => '空いてる',
    OheyDailyStatus.maybeAvailable => '多分空いてる',
    OheyDailyStatus.dependsOnTime => '時間次第',
    OheyDailyStatus.hasPlans => '予定ある',
  };

  String get description => switch (this) {
    OheyDailyStatus.unselected => 'あとで返事できます',
    OheyDailyStatus.available => '今日空いてます',
    OheyDailyStatus.maybeAvailable => 'たぶん空いてます',
    OheyDailyStatus.dependsOnTime => '時間が合えばOK',
    OheyDailyStatus.hasPlans => '予定があります',
  };

  String get shortCopy => switch (this) {
    OheyDailyStatus.unselected => 'あとで決める',
    OheyDailyStatus.available => '今日は空いてる',
    OheyDailyStatus.maybeAvailable => 'たぶん空いてる',
    OheyDailyStatus.dependsOnTime => '時間が合えばOK',
    OheyDailyStatus.hasPlans => '予定があります',
  };

  bool get canJoinPlan => switch (this) {
    OheyDailyStatus.available ||
    OheyDailyStatus.maybeAvailable ||
    OheyDailyStatus.dependsOnTime => true,
    OheyDailyStatus.unselected || OheyDailyStatus.hasPlans => false,
  };

  int get availabilityRank => switch (this) {
    OheyDailyStatus.available => 0,
    OheyDailyStatus.maybeAvailable => 1,
    OheyDailyStatus.dependsOnTime => 2,
    OheyDailyStatus.unselected => 3,
    OheyDailyStatus.hasPlans => 4,
  };

  bool get isAvailable => switch (this) {
    OheyDailyStatus.unselected ||
    OheyDailyStatus.available ||
    OheyDailyStatus.maybeAvailable ||
    OheyDailyStatus.dependsOnTime => true,
    OheyDailyStatus.hasPlans => false,
  };
}

OheyDailyStatus oheyDailyStatusFromKey(String? key) => switch (key) {
  'available' => OheyDailyStatus.available,
  'maybe_available' => OheyDailyStatus.maybeAvailable,
  'depends_on_time' => OheyDailyStatus.dependsOnTime,
  'has_plans' => OheyDailyStatus.hasPlans,
  _ => OheyDailyStatus.unselected,
};

class OheyUser {
  const OheyUser({
    required this.name,
    required this.userId,
    this.gender = OheyGender.unspecified,
    this.dailyStatus = OheyDailyStatus.unselected,
    this.isPlus = false,
    this.avatar,
  });

  final String name;
  final String userId;
  final OheyGender gender;
  final OheyDailyStatus dailyStatus;
  final bool isPlus;
  final OheyAvatar? avatar;

  OheyUser copyWith({
    String? name,
    String? userId,
    OheyGender? gender,
    OheyDailyStatus? dailyStatus,
    bool? isPlus,
    OheyAvatar? avatar,
  }) {
    return OheyUser(
      name: name ?? this.name,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      isPlus: isPlus ?? this.isPlus,
      avatar: avatar ?? this.avatar,
    );
  }
}
