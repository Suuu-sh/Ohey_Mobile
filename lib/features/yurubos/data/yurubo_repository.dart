import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/ohey_api_paths.dart';
import '../../../core/contracts/ohey_api_values.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_visibility.dart';
import '../../../core/models/yurubo.dart';

final yuruboRepositoryProvider = Provider<YuruboRepository>((ref) {
  return BackendYuruboRepository(ref.watch(backendApiClientProvider));
});

abstract interface class YuruboRepository {
  Future<List<Yurubo>> fetchYurubos({int limit = 50});
  Future<void> createYurubo(YuruboCreateDraft draft);
  Future<void> updateYurubo(String yuruboId, YuruboUpdateDraft draft);
  Future<void> deleteYurubo(String yuruboId);
  Future<void> setReaction(String yuruboId, {required bool reacted});
  Future<void> approveReaction(String yuruboId, String userId);
}

class YuruboCreateDraft {
  const YuruboCreateDraft({
    required this.title,
    this.category = OheyCategoryKeys.other,
    this.placeText = '',
    this.timeLabel = '',
    this.visibility = oheyFriendsVisibilityKey,
    this.startsAt,
    this.groupId,
    this.wishItemId,
  });

  final String title;
  final String category;
  final String placeText;
  final String timeLabel;
  final String visibility;
  final DateTime? startsAt;
  final String? groupId;
  final String? wishItemId;
}

class YuruboUpdateDraft {
  const YuruboUpdateDraft({
    required this.title,
    this.body = '',
    this.placeText = '',
    this.timeLabel = '',
    this.startsAt,
  });

  final String title;
  final String body;
  final String placeText;
  final String timeLabel;
  final DateTime? startsAt;
}

class BackendYuruboRepository implements YuruboRepository {
  const BackendYuruboRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<List<Yurubo>> fetchYurubos({int limit = 50}) async {
    final rows = await _client.getRows(
      OheyApiPaths.yurubos,
      query: {'limit': '$limit'},
    );
    return rows.map(_yuruboFromRow).toList(growable: false);
  }

  @override
  Future<void> createYurubo(YuruboCreateDraft draft) async {
    await _client.post(OheyApiPaths.yurubos, {
      'title': draft.title,
      'category': draft.category,
      'place_text': draft.placeText,
      'time_label': draft.timeLabel,
      'visibility': draft.visibility,
      if (draft.startsAt != null) 'starts_at': _dateOnlyString(draft.startsAt!),
      if (draft.groupId != null) 'group_id': draft.groupId,
      if (draft.wishItemId != null) 'wish_item_id': draft.wishItemId,
    });
  }

  @override
  Future<void> updateYurubo(String yuruboId, YuruboUpdateDraft draft) async {
    await _client.patch(OheyApiPaths.yurubo(yuruboId), {
      'title': draft.title,
      'body': draft.body,
      'place_text': draft.placeText,
      'time_label': draft.timeLabel,
      'starts_at': draft.startsAt == null
          ? null
          : _dateOnlyString(draft.startsAt!),
    });
  }

  @override
  Future<void> approveReaction(String yuruboId, String userId) async {
    await _client.patch(
      OheyApiPaths.yuruboReactionApproval(yuruboId, userId),
      const {},
    );
  }

  @override
  Future<void> deleteYurubo(String yuruboId) async {
    await _client.delete(OheyApiPaths.yurubo(yuruboId));
  }

  @override
  Future<void> setReaction(String yuruboId, {required bool reacted}) async {
    if (reacted) {
      await _client.put(OheyApiPaths.yuruboReaction(yuruboId), const {
        'reaction_type': oheyYuruboInterestedReactionKey,
      });
    } else {
      await _client.delete(OheyApiPaths.yuruboReaction(yuruboId));
    }
  }
}

String _dateOnlyString(DateTime value) {
  final normalized = DateTime(value.year, value.month, value.day);
  return '${normalized.year.toString().padLeft(4, '0')}-'
      '${normalized.month.toString().padLeft(2, '0')}-'
      '${normalized.day.toString().padLeft(2, '0')}';
}

Yurubo _yuruboFromRow(Map<String, dynamic> row) {
  final owner = row['owner'] is Map
      ? Map<String, dynamic>.from(row['owner'] as Map)
      : const <String, dynamic>{};
  final displayName = (owner['display_name'] as String?)?.trim();
  final handle = (owner['user_id'] as String?)?.trim();
  final avatar =
      OheyAvatar.decode(owner['avatar_url'] as String?) ??
      OheyAvatar.defaultAvatar;
  final createdAt =
      DateTime.tryParse((row['created_at'] as String?) ?? '') ?? DateTime.now();
  final startsAt = DateTime.tryParse((row['starts_at'] as String?) ?? '');
  return Yurubo(
    id: (row['id'] as String?) ?? '',
    ownerUserId: (row['owner_user_id'] as String?) ?? '',
    userName: displayName?.isNotEmpty == true
        ? displayName!
        : (handle?.isNotEmpty == true ? handle! : 'ohey_user'),
    avatar: avatar,
    title: ((row['title'] as String?) ?? '').trim(),
    body: ((row['body'] as String?) ?? '').trim(),
    category: ((row['category'] as String?) ?? OheyCategoryKeys.other).trim(),
    placeText: ((row['place_text'] as String?) ?? '').trim(),
    timeLabel: ((row['time_label'] as String?) ?? '').trim(),
    startsAt: startsAt,
    status: ((row['status'] as String?) ?? OheyStatusKeys.open).trim(),
    visibility: ((row['visibility'] as String?) ?? oheyFriendsVisibilityKey)
        .trim(),
    visibilityLabel: ((row['visibility_label'] as String?) ?? '全フレンズ').trim(),
    createdAt: createdAt,
    reactionCount: (row['reaction_count'] as num?)?.toInt() ?? 0,
    reactedByMe: (row['reacted_by_me'] as bool?) ?? false,
    myReactionType: ((row['my_reaction_type'] as String?) ?? '').trim(),
    participants: _participantsFromRow(row),
  );
}

List<YuruboParticipant> _participantsFromRow(Map<String, dynamic> row) {
  final raw = row['participants'];
  if (raw is! List) return const <YuruboParticipant>[];
  return raw
      .whereType<Map>()
      .map((entry) {
        final participant = Map<String, dynamic>.from(entry);
        final displayName = (participant['display_name'] as String?)?.trim();
        final handle = (participant['user_id'] as String?)?.trim();
        final id = ((participant['id'] as String?) ?? handle ?? '').trim();
        return YuruboParticipant(
          userId: id,
          name: displayName?.isNotEmpty == true
              ? displayName!
              : (handle?.isNotEmpty == true ? handle! : 'Oheyフレンズ'),
          handle: handle ?? '',
          avatar:
              OheyAvatar.decode(participant['avatar_url'] as String?) ??
              OheyAvatar.defaultAvatar,
          reactionType:
              ((participant['reaction_type'] as String?) ??
                      oheyApprovedYuruboReactionKey)
                  .trim(),
        );
      })
      .toList(growable: false);
}
