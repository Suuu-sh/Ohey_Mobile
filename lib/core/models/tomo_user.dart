import 'tomo_avatar.dart';
import 'tomo_gender.dart';

enum TomoDailyStatus {
  unselected,
  available,
  maybeAvailable,
  dependsOnTime,
  hasPlans,
}

extension TomoDailyStatusX on TomoDailyStatus {
  String get key => switch (this) {
    TomoDailyStatus.unselected => 'unselected',
    TomoDailyStatus.available => 'available',
    TomoDailyStatus.maybeAvailable => 'maybe_available',
    TomoDailyStatus.dependsOnTime => 'depends_on_time',
    TomoDailyStatus.hasPlans => 'has_plans',
  };

  String get label => switch (this) {
    TomoDailyStatus.unselected => 'まだ決めてない',
    TomoDailyStatus.available => '空いてる',
    TomoDailyStatus.maybeAvailable => '多分空いてる',
    TomoDailyStatus.dependsOnTime => '時間次第',
    TomoDailyStatus.hasPlans => '予定ある',
  };

  String get description => switch (this) {
    TomoDailyStatus.unselected => 'あとで返事できます',
    TomoDailyStatus.available => '今日空いてます',
    TomoDailyStatus.maybeAvailable => 'たぶん空いてます',
    TomoDailyStatus.dependsOnTime => '時間が合えばOK',
    TomoDailyStatus.hasPlans => '予定があります',
  };

  String get shortCopy => switch (this) {
    TomoDailyStatus.unselected => 'あとで決める',
    TomoDailyStatus.available => '今日は空いてる',
    TomoDailyStatus.maybeAvailable => 'たぶん空いてる',
    TomoDailyStatus.dependsOnTime => '時間が合えばOK',
    TomoDailyStatus.hasPlans => '予定があります',
  };

  bool get canJoinPlan => switch (this) {
    TomoDailyStatus.available ||
    TomoDailyStatus.maybeAvailable ||
    TomoDailyStatus.dependsOnTime => true,
    TomoDailyStatus.unselected || TomoDailyStatus.hasPlans => false,
  };

  int get availabilityRank => switch (this) {
    TomoDailyStatus.available => 0,
    TomoDailyStatus.maybeAvailable => 1,
    TomoDailyStatus.dependsOnTime => 2,
    TomoDailyStatus.unselected => 3,
    TomoDailyStatus.hasPlans => 4,
  };

  bool get isAvailable => switch (this) {
    TomoDailyStatus.unselected ||
    TomoDailyStatus.available ||
    TomoDailyStatus.maybeAvailable ||
    TomoDailyStatus.dependsOnTime => true,
    TomoDailyStatus.hasPlans => false,
  };
}

TomoDailyStatus tomoDailyStatusFromKey(String? key) => switch (key) {
  'available' => TomoDailyStatus.available,
  'maybe_available' => TomoDailyStatus.maybeAvailable,
  'depends_on_time' => TomoDailyStatus.dependsOnTime,
  'has_plans' => TomoDailyStatus.hasPlans,
  _ => TomoDailyStatus.unselected,
};

class TomoUser {
  const TomoUser({
    required this.name,
    required this.userId,
    this.gender = TomoGender.unspecified,
    this.dailyStatus = TomoDailyStatus.unselected,
    this.isPlus = false,
    this.avatar,
  });

  final String name;
  final String userId;
  final TomoGender gender;
  final TomoDailyStatus dailyStatus;
  final bool isPlus;
  final TomoAvatar? avatar;

  TomoUser copyWith({
    String? name,
    String? userId,
    TomoGender? gender,
    TomoDailyStatus? dailyStatus,
    bool? isPlus,
    TomoAvatar? avatar,
  }) {
    return TomoUser(
      name: name ?? this.name,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      isPlus: isPlus ?? this.isPlus,
      avatar: avatar ?? this.avatar,
    );
  }
}
