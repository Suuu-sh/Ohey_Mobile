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
    NomoDailyStatus.unselected => '未設定',
    NomoDailyStatus.canDrinkToday => '今日遊べる',
    NomoDailyStatus.nonAlcohol => '軽めなら',
    NomoDailyStatus.liverRest => '今日はおやすみ',
    NomoDailyStatus.hasPlans => '予定あり',
  };

  String get description => switch (this) {
    NomoDailyStatus.unselected => 'ステータス未設定のまま、誘いは受けられます。',
    NomoDailyStatus.canDrinkToday => '今日の誘いを受けやすい状態です。',
    NomoDailyStatus.nonAlcohol => '軽めに参加ならOKです。',
    NomoDailyStatus.liverRest => '今日はゆっくりしたい状態です。',
    NomoDailyStatus.hasPlans => '今日は予定が入っています。',
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
