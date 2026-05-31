import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/backend_api_client.dart';
import '../../../core/models/wish_item.dart';

final wishItemRepositoryProvider = Provider<WishItemRepository>((ref) {
  return BackendWishItemRepository(ref.watch(backendApiClientProvider));
});

abstract interface class WishItemRepository {
  Future<List<WishItem>> fetchWishItems({int limit = 50});
  Future<List<WishItem>> fetchProfileWishItems(
    String profileId, {
    int limit = 30,
  });
  Future<WishItem> createWishItem(WishItemCreateDraft draft);
}

class WishItemCreateDraft {
  const WishItemCreateDraft({
    required this.title,
    this.note = '',
    this.category = 'other',
    this.placeText = '',
    this.placeUrl = '',
    this.visibility = 'private',
  });

  final String title;
  final String note;
  final String category;
  final String placeText;
  final String placeUrl;
  final String visibility;
}

class BackendWishItemRepository implements WishItemRepository {
  const BackendWishItemRepository(this._client);

  final BackendApiClient _client;

  @override
  Future<List<WishItem>> fetchWishItems({int limit = 50}) async {
    final rows = await _client.getRows(
      '/v1/wish-items',
      query: {'limit': '$limit'},
    );
    return rows.map(_wishItemFromRow).toList(growable: false);
  }

  @override
  Future<List<WishItem>> fetchProfileWishItems(
    String profileId, {
    int limit = 30,
  }) async {
    final rows = await _client.getRows(
      '/v1/wish-items/profile/${Uri.encodeComponent(profileId)}',
      query: {'limit': '$limit'},
    );
    return rows.map(_wishItemFromRow).toList(growable: false);
  }

  @override
  Future<WishItem> createWishItem(WishItemCreateDraft draft) async {
    final row = await _client.postRow('/v1/wish-items', {
      'title': draft.title,
      'note': draft.note,
      'category': draft.category,
      'place_text': draft.placeText,
      'place_url': draft.placeUrl,
      'visibility': draft.visibility,
    });
    return _wishItemFromRow(row);
  }
}

WishItem _wishItemFromRow(Map<String, dynamic> row) {
  return WishItem(
    id: (row['id'] as String?) ?? '',
    ownerUserId: (row['owner_user_id'] as String?) ?? '',
    title: ((row['title'] as String?) ?? '').trim(),
    note: ((row['note'] as String?) ?? '').trim(),
    category: ((row['category'] as String?) ?? 'other').trim(),
    placeText: ((row['place_text'] as String?) ?? '').trim(),
    placeUrl: ((row['place_url'] as String?) ?? '').trim(),
    visibility: ((row['visibility'] as String?) ?? 'private').trim(),
    createdAt:
        DateTime.tryParse((row['created_at'] as String?) ?? '') ??
        DateTime.now(),
  );
}
