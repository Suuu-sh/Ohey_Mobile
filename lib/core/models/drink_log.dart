import 'nomo_friend.dart';

class DrinkLog {
  const DrinkLog({
    required this.id,
    required this.date,
    required this.friends,
    required this.place,
    required this.memo,
    this.photoAssetPath,
  });

  final String id;
  final DateTime date;
  final List<NomoFriend> friends;
  final String place;
  final String memo;
  final String? photoAssetPath;

  bool isInMonth(DateTime month) =>
      date.year == month.year && date.month == month.month;

  bool isSameDay(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;

  String get friendNames => friends.map((friend) => friend.name).join(', ');
}
