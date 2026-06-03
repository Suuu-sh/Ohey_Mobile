import '../contracts/ohey_api_values.dart';
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
    this.startsAt,
    required this.status,
    required this.visibility,
    required this.visibilityLabel,
    required this.createdAt,
    required this.reactionCount,
    required this.reactedByMe,
    this.myReactionType = '',
    this.participants = const <YuruboParticipant>[],
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
  final DateTime? startsAt;
  final String status;
  final String visibility;
  final String visibilityLabel;
  final DateTime createdAt;
  final int reactionCount;
  final bool reactedByMe;
  final String myReactionType;
  final List<YuruboParticipant> participants;

  Yurubo copyWith({
    int? reactionCount,
    bool? reactedByMe,
    String? myReactionType,
    DateTime? startsAt,
    bool clearStartsAt = false,
    List<YuruboParticipant>? participants,
  }) => Yurubo(
    id: id,
    ownerUserId: ownerUserId,
    userName: userName,
    avatar: avatar,
    title: title,
    body: body,
    category: category,
    placeText: placeText,
    timeLabel: timeLabel,
    startsAt: clearStartsAt ? null : (startsAt ?? this.startsAt),
    status: status,
    visibility: visibility,
    visibilityLabel: visibilityLabel,
    createdAt: createdAt,
    reactionCount: reactionCount ?? this.reactionCount,
    reactedByMe: reactedByMe ?? this.reactedByMe,
    myReactionType: myReactionType ?? this.myReactionType,
    participants: participants ?? this.participants,
  );
}

class YuruboParticipant {
  const YuruboParticipant({
    required this.userId,
    required this.name,
    required this.handle,
    required this.avatar,
    this.reactionType = OheyReactionTypeKeys.available,
  });

  final String userId;
  final String name;
  final String handle;
  final OheyAvatar avatar;
  final String reactionType;

  bool get isPending => reactionType != OheyReactionTypeKeys.available;

  YuruboParticipant copyWith({String? reactionType}) => YuruboParticipant(
    userId: userId,
    name: name,
    handle: handle,
    avatar: avatar,
    reactionType: reactionType ?? this.reactionType,
  );
}
