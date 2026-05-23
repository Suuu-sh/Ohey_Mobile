import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/models/nomo_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_empty_state.dart';
import '../../../core/widgets/nomo_bottom_sheet.dart';
import '../../../core/widgets/nomo_action_tile.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_scene_header_backdrop.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../friends/application/drink_invite_controller.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../notifications/application/notification_controller.dart';
import '../../notifications/data/notification_repository.dart';

part 'home_feed_layout.dart';
part 'home_feed_actions.dart';
part 'home_feed_companions.dart';
part 'home_feed_post_card.dart';
part 'home_notifications.dart';
part 'home_feed_shared.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isRefreshingFeed = false;
  bool _isFeedHeaderTransparent = false;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(drinkLogControllerProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final hasUnreadNotifications = ref.watch(hasUnreadNotificationsProvider);
    final user = ref.watch(nomoUserProvider);
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    final currentUserId = ref
        .watch(supabaseClientProvider)
        .auth
        .currentUser
        ?.id;
    final logs = logsAsync.asData?.value ?? const <DrinkLog>[];
    final friendUserIds =
        friendsAsync.asData?.value
            .map((friend) => friend.id)
            .where((id) => id.isNotEmpty)
            .toSet() ??
        const <String>{};
    final feedItems = _feedItems(
      logs,
      user: user,
      currentUserId: currentUserId,
      friendUserIds: friendUserIds,
    );

    return const _FeedBackground(child: SizedBox.expand()).copyWith(
      child: Stack(
        children: [
          Positioned.fill(
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleFeedScrollNotification,
              child: _buildFeedPage(
                topPadding: _feedHeaderScrollInset(context),
                items: feedItems,
                isWhite: isWhite,
                isLoading: logsAsync.isLoading || friendsAsync.isLoading,
                onLikePressed: (item) => ref
                    .read(drinkLogControllerProvider.notifier)
                    .toggleLike(item.id),
                onSharePressed: (item) => _shareFeedItem(context, item),
                onMorePressed: (item) =>
                    _showFeedPostActions(context, ref, item),
              ),
            ),
          ),
          _FeedHeaderOverlay(
            isWhite: isWhite,
            isTransparent: _isFeedHeaderTransparent,
            child: NomoPageHeader(
              title: 'フィード',
              titleColor: _FeedColors.teal,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NomoHeaderIconButton(
                    icon: CupertinoIcons.arrow_clockwise,
                    semanticLabel: 'フィードを更新',
                    color: _isRefreshingFeed
                        ? _FeedColors.sub
                        : _FeedColors.teal,
                    onTap: _isRefreshingFeed ? () {} : _refreshFeed,
                  ),
                  const SizedBox(width: 8),
                  NomoHeaderIconButton(
                    icon: CupertinoIcons.bell,
                    semanticLabel: 'お知らせを開く',
                    hasDot: hasUnreadNotifications,
                    color: _FeedColors.teal,
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const _FeedNotificationsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _handleFeedScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification is ScrollUpdateNotification) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > .5) {
        _setFeedHeaderTransparent(true);
      } else if (delta < -.5) {
        _setFeedHeaderTransparent(false);
      }
    } else if (notification is ScrollEndNotification) {
      _setFeedHeaderTransparent(false);
    }
    return false;
  }

  void _setFeedHeaderTransparent(bool value) {
    if (_isFeedHeaderTransparent == value || !mounted) return;
    setState(() => _isFeedHeaderTransparent = value);
  }

  Future<void> _refreshFeed() async {
    if (_isRefreshingFeed) return;
    HapticFeedback.selectionClick();
    setState(() => _isRefreshingFeed = true);
    try {
      await Future.wait([
        ref.refresh(drinkLogControllerProvider.future),
        ref.refresh(friendsProvider.future),
        ref.refresh(notificationControllerProvider.future),
      ]);
      if (!mounted) return;
      NomoToast.show(
        context,
        'フィードを更新しました',
        icon: CupertinoIcons.arrow_clockwise,
      );
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        'フィードを更新できませんでした',
        icon: CupertinoIcons.arrow_clockwise,
      );
    } finally {
      if (mounted) setState(() => _isRefreshingFeed = false);
    }
  }

  Future<void> _shareFeedItem(BuildContext context, _FeedItem item) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    try {
      final imagePath = await _createStoryShareImage(item);
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath, mimeType: 'image/png')],
          fileNameOverrides: [
            item.isOfficial ? 'nomo_official_post.png' : 'nomo_drink_log.png',
          ],
          title: item.isOfficial ? 'Nomo公式投稿を共有' : '飲みログを共有',
          subject: item.isOfficial ? 'Nomo公式のお知らせ' : 'Nomoの飲みログ',
          sharePositionOrigin: shareOrigin,
        ),
      );
      if (!context.mounted) return;
      if (result.status == ShareResultStatus.unavailable) {
        NomoToast.show(
          context,
          '共有できるアプリが見つかりませんでした。',
          icon: CupertinoIcons.square_arrow_up,
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      NomoToast.show(
        context,
        '共有を開始できませんでした: $error',
        icon: CupertinoIcons.square_arrow_up,
      );
    }
  }
}
