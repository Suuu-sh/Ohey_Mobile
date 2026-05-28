import 'nomo_avatar.dart';
import 'nomo_gender.dart';

enum NomoDailyStatus {
  unselected,
  available,
  maybeAvailable,
  dependsOnTime,
  hasPlans,
}

extension NomoDailyStatusX on NomoDailyStatus {
  String get key => switch (this) {
    NomoDailyStatus.unselected => 'unselected',
    NomoDailyStatus.available => 'available',
    NomoDailyStatus.maybeAvailable => 'maybe_available',
    NomoDailyStatus.dependsOnTime => 'depends_on_time',
    NomoDailyStatus.hasPlans => 'has_plans',
  };

  String get label => switch (this) {
    NomoDailyStatus.unselected => 'まだ決めてない',
    NomoDailyStatus.available => '空いてる',
    NomoDailyStatus.maybeAvailable => '多分空いてる',
    NomoDailyStatus.dependsOnTime => '時間次第',
    NomoDailyStatus.hasPlans => '予定ある',
  };

  String get description => switch (this) {
    NomoDailyStatus.unselected => 'あとで返事できます',
    NomoDailyStatus.available => '今日空いてます',
    NomoDailyStatus.maybeAvailable => 'たぶん空いてます',
    NomoDailyStatus.dependsOnTime => '時間が合えばOK',
    NomoDailyStatus.hasPlans => '予定があります',
  };

  String get shortCopy => switch (this) {
    NomoDailyStatus.unselected => 'あとで決める',
    NomoDailyStatus.available => '今日は空いてる',
    NomoDailyStatus.maybeAvailable => 'たぶん空いてる',
    NomoDailyStatus.dependsOnTime => '時間が合えばOK',
    NomoDailyStatus.hasPlans => '予定があります',
  };

  bool get canJoinPlan => switch (this) {
    NomoDailyStatus.available ||
    NomoDailyStatus.maybeAvailable ||
    NomoDailyStatus.dependsOnTime => true,
    NomoDailyStatus.unselected || NomoDailyStatus.hasPlans => false,
  };

  int get availabilityRank => switch (this) {
    NomoDailyStatus.available => 0,
    NomoDailyStatus.maybeAvailable => 1,
    NomoDailyStatus.dependsOnTime => 2,
    NomoDailyStatus.unselected => 3,
    NomoDailyStatus.hasPlans => 4,
  };

  bool get isAvailable => switch (this) {
    NomoDailyStatus.unselected ||
    NomoDailyStatus.available ||
    NomoDailyStatus.maybeAvailable ||
    NomoDailyStatus.dependsOnTime => true,
    NomoDailyStatus.hasPlans => false,
  };
}

NomoDailyStatus nomoDailyStatusFromKey(String? key) => switch (key) {
  'available' => NomoDailyStatus.available,
  'maybe_available' => NomoDailyStatus.maybeAvailable,
  'depends_on_time' => NomoDailyStatus.dependsOnTime,
  'has_plans' => NomoDailyStatus.hasPlans,
  _ => NomoDailyStatus.unselected,
};

class NomoUser {
  const NomoUser({
    required this.name,
    required this.userId,
    this.gender = NomoGender.unspecified,
    this.dailyStatus = NomoDailyStatus.unselected,
    this.isPlus = false,
    this.avatar,
  });

  final String name;
  final String userId;
  final NomoGender gender;
  final NomoDailyStatus dailyStatus;
  final bool isPlus;
  final NomoAvatar? avatar;

  NomoUser copyWith({
    String? name,
    String? userId,
    NomoGender? gender,
    NomoDailyStatus? dailyStatus,
    bool? isPlus,
    NomoAvatar? avatar,
  }) {
    return NomoUser(
      name: name ?? this.name,
      userId: userId ?? this.userId,
      gender: gender ?? this.gender,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      isPlus: isPlus ?? this.isPlus,
      avatar: avatar ?? this.avatar,
    );
  }
}
