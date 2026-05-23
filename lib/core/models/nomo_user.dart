import 'nomo_avatar.dart';

enum NomoDailyStatus {
  unselected,
  canDrinkToday,
  lightDrink,
  wantDrinkHard,
  nonAlcohol,
  liverRest,
  waitingInvite,
  hasPlans,
}

extension NomoDailyStatusX on NomoDailyStatus {
  String get key => switch (this) {
    NomoDailyStatus.unselected => 'unselected',
    NomoDailyStatus.canDrinkToday => 'can_drink_today',
    NomoDailyStatus.lightDrink => 'light_drink',
    NomoDailyStatus.wantDrinkHard => 'want_drink_hard',
    NomoDailyStatus.nonAlcohol => 'non_alcohol',
    NomoDailyStatus.liverRest => 'liver_rest',
    NomoDailyStatus.waitingInvite => 'waiting_invite',
    NomoDailyStatus.hasPlans => 'has_plans',
  };

  String get label => switch (this) {
    NomoDailyStatus.unselected => '未設定',
    NomoDailyStatus.canDrinkToday => '今日飲める',
    NomoDailyStatus.lightDrink => '軽く一杯なら',
    NomoDailyStatus.wantDrinkHard => 'しっかり飲みたい',
    NomoDailyStatus.nonAlcohol => 'ノンアルなら',
    NomoDailyStatus.liverRest => '今日は休肝日',
    NomoDailyStatus.waitingInvite => '誘われ待ち',
    NomoDailyStatus.hasPlans => '予定あり',
  };

  String get description => switch (this) {
    NomoDailyStatus.unselected => 'ステータス未設定のまま、誘いは受けられます。',
    NomoDailyStatus.canDrinkToday => '今夜の誘いを受けやすい状態です。',
    NomoDailyStatus.lightDrink => '短時間・少量なら行ける状態です。',
    NomoDailyStatus.wantDrinkHard => 'しっかり飲みに行きたい気分です。',
    NomoDailyStatus.nonAlcohol => 'ノンアル参加ならOKです。',
    NomoDailyStatus.liverRest => '今日は飲みを控えたい状態です。',
    NomoDailyStatus.waitingInvite => '誰かからの誘いを待っています。',
    NomoDailyStatus.hasPlans => '今日は予定が入っています。',
  };

  bool get isAvailable => switch (this) {
    NomoDailyStatus.unselected ||
    NomoDailyStatus.canDrinkToday ||
    NomoDailyStatus.lightDrink ||
    NomoDailyStatus.wantDrinkHard ||
    NomoDailyStatus.nonAlcohol ||
    NomoDailyStatus.waitingInvite => true,
    NomoDailyStatus.liverRest || NomoDailyStatus.hasPlans => false,
  };
}

NomoDailyStatus nomoDailyStatusFromKey(String? key) => switch (key) {
  'can_drink_today' => NomoDailyStatus.canDrinkToday,
  'light_drink' => NomoDailyStatus.lightDrink,
  'want_drink_hard' => NomoDailyStatus.wantDrinkHard,
  'non_alcohol' => NomoDailyStatus.nonAlcohol,
  'liver_rest' => NomoDailyStatus.liverRest,
  'waiting_invite' => NomoDailyStatus.waitingInvite,
  'has_plans' => NomoDailyStatus.hasPlans,
  _ => NomoDailyStatus.unselected,
};

class NomoUser {
  const NomoUser({
    required this.name,
    required this.userId,
    this.dailyStatus = NomoDailyStatus.unselected,
    this.isPlus = false,
    this.avatar,
  });

  final String name;
  final String userId;
  final NomoDailyStatus dailyStatus;
  final bool isPlus;
  final NomoAvatar? avatar;

  NomoUser copyWith({
    String? name,
    String? userId,
    NomoDailyStatus? dailyStatus,
    bool? isPlus,
    NomoAvatar? avatar,
  }) {
    return NomoUser(
      name: name ?? this.name,
      userId: userId ?? this.userId,
      dailyStatus: dailyStatus ?? this.dailyStatus,
      isPlus: isPlus ?? this.isPlus,
      avatar: avatar ?? this.avatar,
    );
  }
}
