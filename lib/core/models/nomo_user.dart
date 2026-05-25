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
    NomoDailyStatus.unselected => 'まだ決めてない。',
    NomoDailyStatus.canDrinkToday => '遊べる！',
    NomoDailyStatus.nonAlcohol => '多分いける！',
    NomoDailyStatus.liverRest => '休ませて。',
    NomoDailyStatus.hasPlans => '予定ある。ごめん',
  };

  String get description => switch (this) {
    NomoDailyStatus.unselected => 'まだ決めてないけど、あとで返事できます。',
    NomoDailyStatus.canDrinkToday => '誘ってくれてOKな気分です。',
    NomoDailyStatus.nonAlcohol => 'たぶん行けそうな気分です。',
    NomoDailyStatus.liverRest => 'ゆっくり休みたい気分です。',
    NomoDailyStatus.hasPlans => 'もう予定が入っています。',
  };

  bool get isAvailable => switch (this) {
    NomoDailyStatus.unselected ||
    NomoDailyStatus.canDrinkToday ||
    NomoDailyStatus.nonAlcohol => true,
    NomoDailyStatus.liverRest || NomoDailyStatus.hasPlans => false,
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
