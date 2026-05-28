enum NomoFriendMood { lonely, calm, smile, fun, spark, hype, tired, sleep }

extension NomoFriendMoodX on NomoFriendMood {
  String get label => switch (this) {
    NomoFriendMood.lonely => 'さみしい',
    NomoFriendMood.calm => 'ゆったり',
    NomoFriendMood.smile => 'にこにこ',
    NomoFriendMood.fun => 'たのしい',
    NomoFriendMood.spark => 'きらきら',
    NomoFriendMood.hype => 'ハイテンション',
    NomoFriendMood.tired => 'つかれた',
    NomoFriendMood.sleep => 'おやすみ',
  };

  String get message => switch (this) {
    NomoFriendMood.lonely => '今月はまだ静かなスタート。誰かに声をかけてみよ。',
    NomoFriendMood.calm => 'ゆったりいい感じ。無理せず思い出を増やそう。',
    NomoFriendMood.smile => '今月のTomoはにこにこ。いい夜が増えてきたね。',
    NomoFriendMood.fun => 'フレンズとの時間がきらきらしてる。今月いいペース！',
    NomoFriendMood.spark => '少しきらきらした気分。写真やメモも残しておこう。',
    NomoFriendMood.hype => '交流モード全開！Tomoもハイテンション。',
    NomoFriendMood.tired => 'たくさん遊んだね。今日はふわっと休もう。',
    NomoFriendMood.sleep => '夢の中でも楽しい思い出を整理中。おやすみ。',
  };
}

NomoFriendMood moodForMonthlyMemoryCount(int count) {
  if (count == 0) return NomoFriendMood.lonely;
  if (count <= 2) return NomoFriendMood.smile;
  if (count <= 5) return NomoFriendMood.fun;
  return NomoFriendMood.hype;
}
