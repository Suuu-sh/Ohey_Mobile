import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/application/tomo_user_controller.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/memory.dart';
import '../../../core/models/tomo_avatar.dart';
import '../../../core/models/tomo_invite.dart';
import '../../../core/models/tomo_friend.dart';
import '../../../core/models/tomo_friend_request_status.dart';
import '../../../core/models/tomo_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/tomo_theme_mode.dart';
import '../../../core/widgets/tomo_avatar.dart';
import '../../../core/widgets/tomo_3d_button.dart';
import '../../../core/widgets/tomo_empty_state.dart';
import '../../../core/widgets/tomo_bottom_sheet.dart';
import '../../../core/widgets/tomo_action_tile.dart';
import '../../../core/widgets/tomo_page_header.dart';
import '../../../core/widgets/tomo_pop_icon.dart';
import '../../../core/widgets/tomo_post_action_pill.dart';
import '../../../core/widgets/tomo_scene_header_backdrop.dart';
import '../../../core/widgets/tomo_toast.dart';
import '../../../core/widgets/tomo_themed_panel.dart';
import '../../friends/application/invite_controller.dart';
import '../../friends/data/friend_repository.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../memories/application/memory_controller.dart';
import '../../notifications/application/notification_controller.dart';
import '../../notifications/data/notification_repository.dart';
import '../../profile/data/user_safety_repository.dart';

part 'home_feed_layout.dart';
part 'home_feed_invite_banner.dart';
part 'home_feed_background.dart';
part 'home_feed_tutorial.dart';
part 'home_feed_actions.dart';
part 'home_feed_companions.dart';
part 'home_feed_post_card.dart';
part 'home_notifications.dart';
part 'home_feed_shared.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.onAddMemoryPressed});

  final VoidCallback? onAddMemoryPressed;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _feedSwipeTutorialSeenKey = 'tomo_feed_swipe_tutorial_seen';
  int _currentFeedPageIndex = 0;
  bool _isFeedSwipeTutorialSeen = true;

  @override
  void initState() {
    super.initState();
    _loadFeedSwipeTutorialSeen();
  }

  Future<void> _loadFeedSwipeTutorialSeen() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isFeedSwipeTutorialSeen =
          prefs.getBool(_feedSwipeTutorialSeenKey) ?? false;
    });
  }

  Future<void> _markFeedSwipeTutorialSeen() async {
    if (_isFeedSwipeTutorialSeen) return;
    setState(() => _isFeedSwipeTutorialSeen = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_feedSwipeTutorialSeenKey, true);
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(homeFeedControllerProvider);
    final hasUnreadNotifications = ref.watch(hasUnreadNotificationsProvider);
    final user = ref.watch(tomoUserProvider);
    final incomingInvites =
        ref.watch(incomingInvitesProvider).asData?.value ??
        const <TomoInvite>[];
    final todayReservations =
        ref.watch(todayReservationsProvider).asData?.value ??
        const <TomoInvite>[];
    final isWhite = ref.watch(tomoThemeModeProvider).isWhite;
    final currentUserId = ref
        .watch(supabaseClientProvider)
        .auth
        .currentUser
        ?.id;
    final memories = memoriesAsync.asData?.value ?? const <Memory>[];
    final feedItems = _feedItems(
      memories,
      user: user,
      currentUserId: currentUserId,
    );

    return const _FeedBackground(child: SizedBox.expand()).copyWith(
      child: Stack(
        children: [
          _FeedHeaderBackdropLayer(isWhite: isWhite),
          Positioned.fill(
            child: _buildFeedPage(
              topPadding: _feedHeaderScrollInset(context),
              items: feedItems,
              isWhite: isWhite,
              isLoading: memoriesAsync.isLoading,
              onPageChanged: _handleFeedPageChanged,
              onAddMemoryPressed: widget.onAddMemoryPressed ?? () {},
              onLikePressed: (item) => ref
                  .read(homeFeedControllerProvider.notifier)
                  .toggleLike(item.id),
              onSharePressed: (item) => _shareFeedItem(context, item),
              showSwipeTutorial:
                  !_isFeedSwipeTutorialSeen && feedItems.length > 1,
              onSwipeTutorialDismissed: _markFeedSwipeTutorialSeen,
              onMorePressed: (item) => _showFeedPostActions(context, ref, item),
              onAuthorPressed: (item) => _showFeedAuthorProfile(context, item),
            ),
          ),
          _FeedHeaderBackdropLayer(isWhite: isWhite),
          _FeedHeaderControlsLayer(
            child: TomoPageHeader(
              title: 'フィード',
              titleColor: _FeedColors.teal,
              titleOffset: const Offset(0, -54),
              trailingOffset: const Offset(0, -54),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TomoHeaderIconButton(
                    icon: CupertinoIcons.camera_fill,
                    semanticLabel: '投稿する',
                    color: _FeedColors.teal,
                    onTap: widget.onAddMemoryPressed ?? () {},
                  ),
                  const SizedBox(width: 8),
                  TomoHeaderIconButton(
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
          if (incomingInvites.isNotEmpty || todayReservations.isNotEmpty)
            _FeedInviteBanner(
              isWhite: isWhite,
              invite: incomingInvites.isNotEmpty ? incomingInvites.first : null,
              reservation:
                  incomingInvites.isEmpty && todayReservations.isNotEmpty
                  ? todayReservations.first
                  : null,
              currentUserId: currentUserId,
              onOpenNotifications: () => Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const _FeedNotificationsScreen(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _handleFeedPageChanged(int index) {
    if (_currentFeedPageIndex == index || !mounted) return;
    final isUpwardSwipe = index > _currentFeedPageIndex;
    if (isUpwardSwipe) {
      HapticFeedback.lightImpact();
    }
    setState(() => _currentFeedPageIndex = index);
    if (index > 0) {
      _markFeedSwipeTutorialSeen();
    }
    final loadedCount =
        ref.read(homeFeedControllerProvider).asData?.value.length ?? 0;
    if (loadedCount > 0 && index >= loadedCount - 3) {
      ref.read(homeFeedControllerProvider.notifier).loadMore();
    }
  }

  Future<void> _showFeedAuthorProfile(
    BuildContext context,
    _FeedItem item,
  ) async {
    HapticFeedback.selectionClick();
    final currentUser = ref.read(tomoUserProvider);
    final author = item.ownedByMe
        ? _Companion(
            userId: item.ownerUserId,
            name: currentUser?.name.trim().isNotEmpty == true
                ? currentUser!.name.trim()
                : item.userName,
            handle: currentUser?.userId.trim().isNotEmpty == true
                ? currentUser!.userId.trim()
                : item.place,
            avatar: currentUser?.avatar ?? item.avatar,
            accent: item.accent,
            statusKey: currentUser?.dailyStatus.key,
          )
        : _Companion(
            userId: item.ownerUserId,
            name: item.userName,
            handle: item.isOfficial ? 'Tomo公式' : item.place,
            avatar: item.avatar,
            accent: item.accent,
            statusKey: null,
          );
    await showTomoBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (context) => _FeedCompanionProfileSheet(
        friend: author,
        initialRelationship: item.ownedByMe
            ? const TomoFriendRelationshipStatus(
                alreadyFriend: true,
                requestState: TomoFriendRequestState.none,
              )
            : null,
      ),
    );
  }

  Future<void> _shareFeedItem(BuildContext context, _FeedItem item) async {
    try {
      final imagePath = await _createStoryShareImage(item);
      if (!mounted) return;
      await _shareFeedImageWithSystemSheet(this.context, item, imagePath);
    } catch (_) {
      if (!context.mounted) return;
      TomoToast.show(
        context,
        '共有を始められなかったよ。あとでもう一度試してね',
        icon: CupertinoIcons.square_arrow_up,
      );
    }
  }

  Future<void> _shareFeedImageWithSystemSheet(
    BuildContext context,
    _FeedItem item,
    String imagePath,
  ) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox == null
        ? null
        : renderBox.localToGlobal(Offset.zero) & renderBox.size;
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath, mimeType: 'image/png')],
        fileNameOverrides: [
          item.isOfficial ? 'tomo_official_post.png' : 'tomo_memory.png',
        ],
        title: item.isOfficial ? 'Tomo公式投稿を共有' : '思い出を共有',
        subject: item.isOfficial ? 'Tomo公式のお知らせ' : 'Tomoの思い出',
        sharePositionOrigin: shareOrigin,
      ),
    );
    if (!context.mounted) return;
    if (result.status == ShareResultStatus.unavailable) {
      TomoToast.show(
        context,
        '共有できるアプリが見つかりませんでした。',
        icon: CupertinoIcons.square_arrow_up,
      );
    }
  }
}
