import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/yurubo.dart';

final yuruboRepositoryProvider = Provider<YuruboRepository>((ref) {
  return BackendYuruboRepository(ref.watch(backendApiClientProvider));
});

abstract interface class YuruboRepository {
  Future<List<Yurubo>> fetchYurubos({int limit = 50});
  Future<void> setReaction(String yuruboId, {required bool reacted});
}

class BackendYuruboRepository implements YuruboRepository {
  const BackendYuruboRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<List<Yurubo>> fetchYurubos({int limit = 50}) async {
    final rows = await _client.getRows(
      '/v1/yurubos',
      query: {'limit': '$limit'},
    );
    return rows.map(_yuruboFromRow).toList(growable: false);
  }

  @override
  Future<void> setReaction(String yuruboId, {required bool reacted}) async {
    if (reacted) {
      await _client.put('/v1/yurubos/$yuruboId/reaction', const {
        'reaction_type': 'interested',
      });
    } else {
      await _client.delete('/v1/yurubos/$yuruboId/reaction');
    }
  }
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
  return Yurubo(
    id: (row['id'] as String?) ?? '',
    ownerUserId: (row['owner_user_id'] as String?) ?? '',
    userName: displayName?.isNotEmpty == true
        ? displayName!
        : (handle?.isNotEmpty == true ? handle! : 'ohey_user'),
    avatar: avatar,
    title: ((row['title'] as String?) ?? '').trim(),
    body: ((row['body'] as String?) ?? '').trim(),
    category: ((row['category'] as String?) ?? 'other').trim(),
    placeText: ((row['place_text'] as String?) ?? '').trim(),
    timeLabel: ((row['time_label'] as String?) ?? '').trim(),
    status: ((row['status'] as String?) ?? 'open').trim(),
    createdAt: createdAt,
    reactionCount: (row['reaction_count'] as num?)?.toInt() ?? 0,
    reactedByMe: (row['reacted_by_me'] as bool?) ?? false,
  );
}
