enum OheyFriendMood { lonely, calm, smile, fun, spark, hype, tired, sleep }

extension OheyFriendMoodX on OheyFriendMood {
  String get label => switch (this) {
    OheyFriendMood.lonely => 'さみしい',
    OheyFriendMood.calm => 'ゆったり',
    OheyFriendMood.smile => 'にこにこ',
    OheyFriendMood.fun => 'たのしい',
    OheyFriendMood.spark => 'きらきら',
    OheyFriendMood.hype => 'ハイテンション',
    OheyFriendMood.tired => 'つかれた',
    OheyFriendMood.sleep => 'おやすみ',
  };

  String get message => switch (this) {
    OheyFriendMood.lonely => '今月はまだ静かなスタート。誰かに声をかけてみよ。',
    OheyFriendMood.calm => 'ゆったりいい感じ。無理せずゆるぼを増やそう。',
    OheyFriendMood.smile => '今月のOheyはにこにこ。いい夜が増えてきたね。',
    OheyFriendMood.fun => 'フレンズとの時間がきらきらしてる。今月いいペース！',
    OheyFriendMood.spark => '少しきらきらした気分。写真やメモも残しておこう。',
    OheyFriendMood.hype => '交流モード全開！Oheyもハイテンション。',
    OheyFriendMood.tired => 'たくさん遊んだね。今日はふわっと休もう。',
    OheyFriendMood.sleep => '夢の中でも楽しいゆるぼを整理中。おやすみ。',
  };
}

OheyFriendMood moodForMonthlyMemoryCount(int count) {
  if (count == 0) return OheyFriendMood.lonely;
  if (count <= 2) return OheyFriendMood.smile;
  if (count <= 5) return OheyFriendMood.fun;
  return OheyFriendMood.hype;
}
