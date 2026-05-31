import 'ohey_avatar.dart';

class Yurubo {
  const Yurubo({
    required this.id,
    required this.ownerUserId,
    required this.userName,
    required this.avatar,
    required this.title,
    required this.body,
    required this.category,
    required this.placeText,
    required this.timeLabel,
    required this.status,
    required this.createdAt,
    required this.reactionCount,
    required this.reactedByMe,
  });

  final String id;
  final String ownerUserId;
  final String userName;
  final OheyAvatar avatar;
  final String title;
  final String body;
  final String category;
  final String placeText;
  final String timeLabel;
  final String status;
  final DateTime createdAt;
  final int reactionCount;
  final bool reactedByMe;

  Yurubo copyWith({int? reactionCount, bool? reactedByMe}) => Yurubo(
    id: id,
    ownerUserId: ownerUserId,
    userName: userName,
    avatar: avatar,
    title: title,
    body: body,
    category: category,
    placeText: placeText,
    timeLabel: timeLabel,
    status: status,
    createdAt: createdAt,
    reactionCount: reactionCount ?? this.reactionCount,
    reactedByMe: reactedByMe ?? this.reactedByMe,
  );
}
