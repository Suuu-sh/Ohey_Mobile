import 'ohey_avatar.dart';
import 'ohey_gender.dart';
import '../contracts/ohey_api_values.dart';

enum OheyDailyStatus {
  unselected,
  available,
  maybeAvailable,
  dependsOnTime,
  hasPlans;

  static const selectable = <OheyDailyStatus>[
    OheyDailyStatus.available,
    OheyDailyStatus.maybeAvailable,
    OheyDailyStatus.dependsOnTime,
    OheyDailyStatus.hasPlans,
  ];

  static const adminSelectable = <OheyDailyStatus>[
    OheyDailyStatus.unselected,
    ...selectable,
  ];
}

extension OheyDailyStatusX on OheyDailyStatus {
  String get key => switch (this) {
    OheyDailyStatus.unselected => OheyStatusKeys.unselected,
    OheyDailyStatus.available => OheyStatusKeys.available,
    OheyDailyStatus.maybeAvailable => OheyStatusKeys.maybeAvailable,
    OheyDailyStatus.dependsOnTime => OheyStatusKeys.dependsOnTime,
    OheyDailyStatus.hasPlans => OheyStatusKeys.hasPlans,
  };

  String get label => switch (this) {
    OheyDailyStatus.unselected => 'まだ決めてない',
    OheyDailyStatus.available => '空いてる',
    OheyDailyStatus.maybeAvailable => 'たぶん空いてる',
    OheyDailyStatus.dependsOnTime => '時間次第',
    OheyDailyStatus.hasPlans => '空いてない',
  };

  String get description => switch (this) {
    OheyDailyStatus.unselected => 'あとで返事できます',
    OheyDailyStatus.available => '空いてます',
    OheyDailyStatus.maybeAvailable => 'たぶん空いてます',
    OheyDailyStatus.dependsOnTime => '時間が合えばOK',
    OheyDailyStatus.hasPlans => '空いていません',
  };

  String get shortCopy => switch (this) {
    OheyDailyStatus.unselected => 'あとで決める',
    OheyDailyStatus.available => '空いてる',
    OheyDailyStatus.maybeAvailable => 'たぶん空いてる',
    OheyDailyStatus.dependsOnTime => '時間が合えばOK',
    OheyDailyStatus.hasPlans => '空いていません',
  };

  bool get canJoinPlan => switch (this) {
    OheyDailyStatus.available ||
    OheyDailyStatus.maybeAvailable ||
    OheyDailyStatus.dependsOnTime => true,
    OheyDailyStatus.unselected || OheyDailyStatus.hasPlans => false,
  };

  double get availabilityWeight => switch (this) {
    OheyDailyStatus.available => 1.0,
    OheyDailyStatus.maybeAvailable => .8,
    OheyDailyStatus.dependsOnTime => .5,
    OheyDailyStatus.unselected || OheyDailyStatus.hasPlans => 0,
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

  bool get isUndecided => this == OheyDailyStatus.unselected;

  bool get blocksRecommendations => this == OheyDailyStatus.hasPlans;

  int get recommendationBonus => switch (this) {
    OheyDailyStatus.available => 60,
    OheyDailyStatus.maybeAvailable => 50,
    OheyDailyStatus.unselected ||
    OheyDailyStatus.dependsOnTime ||
    OheyDailyStatus.hasPlans => 0,
  };
}

OheyDailyStatus oheyDailyStatusFromKey(String? key) => switch (key) {
  OheyStatusKeys.available => OheyDailyStatus.available,
  OheyStatusKeys.maybeAvailable => OheyDailyStatus.maybeAvailable,
  OheyStatusKeys.dependsOnTime => OheyDailyStatus.dependsOnTime,
  OheyStatusKeys.hasPlans => OheyDailyStatus.hasPlans,
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
