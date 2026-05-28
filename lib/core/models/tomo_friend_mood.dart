enum TomoFriendMood { lonely, calm, smile, fun, spark, hype, tired, sleep }

extension TomoFriendMoodX on TomoFriendMood {
  String get label => switch (this) {
    TomoFriendMood.lonely => 'さみしい',
    TomoFriendMood.calm => 'ゆったり',
    TomoFriendMood.smile => 'にこにこ',
    TomoFriendMood.fun => 'たのしい',
    TomoFriendMood.spark => 'きらきら',
    TomoFriendMood.hype => 'ハイテンション',
    TomoFriendMood.tired => 'つかれた',
    TomoFriendMood.sleep => 'おやすみ',
  };

  String get message => switch (this) {
    TomoFriendMood.lonely => '今月はまだ静かなスタート。誰かに声をかけてみよ。',
    TomoFriendMood.calm => 'ゆったりいい感じ。無理せず思い出を増やそう。',
    TomoFriendMood.smile => '今月のTomoはにこにこ。いい夜が増えてきたね。',
    TomoFriendMood.fun => 'フレンズとの時間がきらきらしてる。今月いいペース！',
    TomoFriendMood.spark => '少しきらきらした気分。写真やメモも残しておこう。',
    TomoFriendMood.hype => '交流モード全開！Tomoもハイテンション。',
    TomoFriendMood.tired => 'たくさん遊んだね。今日はふわっと休もう。',
    TomoFriendMood.sleep => '夢の中でも楽しい思い出を整理中。おやすみ。',
  };
}

TomoFriendMood moodForMonthlyMemoryCount(int count) {
  if (count == 0) return TomoFriendMood.lonely;
  if (count <= 2) return TomoFriendMood.smile;
  if (count <= 5) return TomoFriendMood.fun;
  return TomoFriendMood.hype;
}
