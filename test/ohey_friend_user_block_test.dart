import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohey/core/models/ohey_avatar.dart';
import 'package:ohey/core/models/ohey_friend.dart';
import 'package:ohey/core/theme/app_colors.dart';
import 'package:ohey/core/widgets/ohey_friend_user_block.dart';

void main() {
  testWidgets('sent invite label fits inside the friend row action button', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 180));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          brightness: Brightness.dark,
          fontFamily: 'MPLUSRounded1c',
        ),
        home: const Scaffold(
          backgroundColor: AppColors.darkBackgroundBottom,
          body: Center(
            child: SizedBox(
              width: 360,
              child: OheyFriendUserBlock(
                friend: OheyFriend(
                  id: 'friend-1',
                  name: 'yisshiki391',
                  avatarEmoji: '🐶',
                  vibe: 'friendly',
                  characterAssetPath: '',
                  kind: OheyFriendKind.bunny,
                  palette: OheyFriendPalette.blush,
                  avatar: OheyAvatar.defaultAvatar,
                  isFavorite: false,
                ),
                statusLabel: '空いてる',
                statusReason: 'available',
                statusColor: AppColors.cFFFF4FA3,
                statusEnabled: true,
                fallbackAvatar: OheyAvatar.defaultAvatar,
                showFavorite: true,
                showInvite: true,
                inviteSent: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('招待済み'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
