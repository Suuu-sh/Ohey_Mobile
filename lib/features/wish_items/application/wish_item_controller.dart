import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/wish_item.dart';
import '../data/wish_item_repository.dart';

final wishItemControllerProvider =
    AsyncNotifierProvider<WishItemController, List<WishItem>>(
      WishItemController.new,
    );

class WishItemController extends AsyncNotifier<List<WishItem>> {
  @override
  Future<List<WishItem>> build() async {
    return ref.read(wishItemRepositoryProvider).fetchWishItems();
  }

  Future<void> createWishItem(WishItemCreateDraft draft) async {
    await ref.read(wishItemRepositoryProvider).createWishItem(draft);
    ref.invalidateSelf();
  }

  Future<void> updateWishItem(
    String wishItemId,
    WishItemCreateDraft draft,
  ) async {
    await ref
        .read(wishItemRepositoryProvider)
        .updateWishItem(wishItemId, draft);
    ref.invalidateSelf();
  }

  Future<void> deleteWishItem(String wishItemId) async {
    await ref.read(wishItemRepositoryProvider).deleteWishItem(wishItemId);
    ref.invalidateSelf();
  }
}

final profileWishItemsProvider = FutureProvider.autoDispose
    .family<List<WishItem>, String>((ref, profileId) async {
      if (profileId.trim().isEmpty) return const <WishItem>[];
      return ref
          .read(wishItemRepositoryProvider)
          .fetchProfileWishItems(profileId.trim());
    });
