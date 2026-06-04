import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/ohey_api_paths.dart';
import '../../../core/contracts/ohey_api_values.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_visibility.dart';
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
    this.category = OheyCategoryKeys.other,
    this.placeText = '',
    this.placeUrl = '',
    this.visibility = oheyPrivateVisibilityKey,
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
      OheyApiPaths.wishItems,
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
      OheyApiPaths.profileWishItems(profileId),
      query: {'limit': '$limit'},
    );
    return rows.map(_wishItemFromRow).toList(growable: false);
  }

  @override
  Future<WishItem> createWishItem(WishItemCreateDraft draft) async {
    final row = await _client.postRow(OheyApiPaths.wishItems, {
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
    category: ((row['category'] as String?) ?? OheyCategoryKeys.other).trim(),
    placeText: ((row['place_text'] as String?) ?? '').trim(),
    placeUrl: ((row['place_url'] as String?) ?? '').trim(),
    visibility: ((row['visibility'] as String?) ?? oheyPrivateVisibilityKey)
        .trim(),
    createdAt:
        DateTime.tryParse((row['created_at'] as String?) ?? '') ??
        DateTime.now(),
  );
}
