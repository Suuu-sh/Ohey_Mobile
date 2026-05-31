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
}
