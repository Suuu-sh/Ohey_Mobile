import 'nomo_avatar.dart';
import 'nomo_gender.dart';

enum NomoDailyStatus {
  unselected,
  canDrinkToday,
  nonAlcohol,
  liverRest,
  hasPlans,
}

extension NomoDailyStatusX on NomoDailyStatus {
  String get key => switch (this) {
    NomoDailyStatus.unselected => 'unselected',
    NomoDailyStatus.canDrinkToday => 'can_drink_today',
    NomoDailyStatus.nonAlcohol => 'non_alcohol',
    NomoDailyStatus.liverRest => 'liver_rest',
    NomoDailyStatus.hasPlans => 'has_plans',
  };

  String get label => switch (this) {
    NomoDailyStatus.unselected => 'まだ決めてない',
    NomoDailyStatus.canDrinkToday => '空いてる',
    NomoDailyStatus.nonAlcohol => '多分空いてる',
    NomoDailyStatus.liverRest => '時間次第',
    NomoDailyStatus.hasPlans => '予定ある',
  };

  String get description => switch (this) {
    NomoDailyStatus.unselected => 'あとで返事できます',
    NomoDailyStatus.canDrinkToday => '今日空いてます',
    NomoDailyStatus.nonAlcohol => 'たぶん空いてます',
    NomoDailyStatus.liverRest => '時間が合えばOK',
    NomoDailyStatus.hasPlans => '予定があります',
  };

  String get shortCopy => switch (this) {
    NomoDailyStatus.unselected => 'あとで決める',
    NomoDailyStatus.canDrinkToday => '今日は空いてる',
    NomoDailyStatus.nonAlcohol => 'たぶん空いてる',
    NomoDailyStatus.liverRest => '時間が合えばOK',
    NomoDailyStatus.hasPlans => '予定があります',
  };

  bool get canJoinPlan => switch (this) {
    NomoDailyStatus.canDrinkToday ||
    NomoDailyStatus.nonAlcohol ||
    NomoDailyStatus.liverRest => true,
    NomoDailyStatus.unselected || NomoDailyStatus.hasPlans => false,
  };

  int get availabilityRank => switch (this) {
    NomoDailyStatus.canDrinkToday => 0,
    NomoDailyStatus.nonAlcohol => 1,
    NomoDailyStatus.liverRest => 2,
    NomoDailyStatus.unselected => 3,
    NomoDailyStatus.hasPlans => 4,
  };

  bool get isAvailable => switch (this) {
    NomoDailyStatus.unselected ||
    NomoDailyStatus.canDrinkToday ||
    NomoDailyStatus.nonAlcohol ||
    NomoDailyStatus.liverRest => true,
    NomoDailyStatus.hasPlans => false,
  };
}

NomoDailyStatus nomoDailyStatusFromKey(String? key) => switch (key) {
  'can_drink_today' => NomoDailyStatus.canDrinkToday,
  'non_alcohol' => NomoDailyStatus.nonAlcohol,
  'liver_rest' => NomoDailyStatus.liverRest,
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
