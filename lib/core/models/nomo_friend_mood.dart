enum NomoFriendMood { lonely, sober, smile, fun, tipsy, hype, tired, sleep }

extension NomoFriendMoodX on NomoFriendMood {
  String get label => switch (this) {
    NomoFriendMood.lonely => 'さみしい',
    NomoFriendMood.sober => 'シラフ',
    NomoFriendMood.smile => 'にこにこ',
    NomoFriendMood.fun => 'たのしい',
    NomoFriendMood.tipsy => 'ほろよい',
    NomoFriendMood.hype => 'ハイテンション',
    NomoFriendMood.tired => 'つかれた',
    NomoFriendMood.sleep => 'おやすみ',
  };

  String get message => switch (this) {
    NomoFriendMood.lonely => '今月はまだ静かなスタート。誰かに声をかけてみよ。',
    NomoFriendMood.sober => 'ゆったりいい感じ。無理せず思い出を増やそう。',
    NomoFriendMood.smile => '今月のNomo Friendはにこにこ。いい夜が増えてきたね。',
    NomoFriendMood.fun => '友達との時間がきらきらしてる。今月いいペース！',
    NomoFriendMood.tipsy => '少しほろよい気分。写真やメモも残しておこう。',
    NomoFriendMood.hype => '交流モード全開！Nomo Friendもハイテンション。',
    NomoFriendMood.tired => 'たくさん遊んだね。今日はふわっと休もう。',
    NomoFriendMood.sleep => '夢の中でも楽しい飲みログを整理中。おやすみ。',
  };
}

NomoFriendMood moodForMonthlyDrinkCount(int count) {
  if (count == 0) return NomoFriendMood.lonely;
  if (count <= 2) return NomoFriendMood.smile;
  if (count <= 5) return NomoFriendMood.fun;
  return NomoFriendMood.hype;
}
