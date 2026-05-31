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

import '../../../core/application/ohey_user_controller.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_friend.dart';
import '../../../core/models/ohey_invite.dart';
import '../../../core/models/wish_item.dart';
import '../../../core/models/ohey_friend_request_status.dart';
import '../../../core/models/ohey_user.dart';
import '../../../core/models/yurubo.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ohey_theme_mode.dart';
import '../../../core/widgets/ohey_avatar.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_empty_state.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_action_tile.dart';
import '../../../core/widgets/ohey_page_header.dart';
import '../../../core/widgets/ohey_pop_icon.dart';
import '../../../core/widgets/ohey_post_action_pill.dart';
import '../../../core/widgets/ohey_scene_header_backdrop.dart';
import '../../../core/widgets/ohey_toast.dart';
import '../../../core/widgets/ohey_themed_panel.dart';
import '../../friends/application/invite_controller.dart';
import '../../friends/data/friend_repository.dart';
import '../../friends/presentation/friends_screen.dart';
import '../../memories/application/memory_controller.dart';
import '../../yurubos/application/yurubo_controller.dart';
import '../../yurubos/data/yurubo_repository.dart';
import '../../wish_items/application/wish_item_controller.dart';
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

class _FeedCreateYuruboFab extends StatelessWidget {
  const _FeedCreateYuruboFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 18,
      bottom: MediaQuery.paddingOf(context).bottom + 22,
      child: Semantics(
        button: true,
        label: 'ゆるぼする',
        child: Ohey3DButtonSurface(
          onTap: onTap,
          height: 58,
          radius: 29,
          color: _FeedColors.teal,
          bottomColor: _feedPrimaryActionShadowColor,
          padding: EdgeInsets.zero,
          outerShadows: [
            BoxShadow(
              color: _FeedColors.teal.withValues(alpha: .36),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
          child: const SizedBox(
            width: 58,
            height: 58,
            child: Icon(
              CupertinoIcons.plus,
              color: Color(0xFF101820),
              size: 30,
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _feedSwipeTutorialSeenKey = 'ohey_feed_swipe_tutorial_seen';
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
    final yurubosAsync = ref.watch(yuruboControllerProvider);
    final hasUnreadNotifications = ref.watch(hasUnreadNotificationsProvider);
    final incomingInvites =
        ref.watch(incomingInvitesProvider).asData?.value ??
        const <OheyInvite>[];
    final todayReservations =
        ref.watch(todayReservationsProvider).asData?.value ??
        const <OheyInvite>[];
    final isWhite = ref.watch(oheyThemeModeProvider).isWhite;
    final currentUserId = ref
        .watch(supabaseClientProvider)
        .auth
        .currentUser
        ?.id;
    final yurubos = yurubosAsync.asData?.value ?? const <Yurubo>[];
    final feedItems = _feedItemsFromYurubos(
      yurubos,
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
              isLoading: yurubosAsync.isLoading,
              onPageChanged: _handleFeedPageChanged,
              onCreateYuruboPressed: () => _showCreateYuruboSheet(context, ref),
              onLikePressed: (item) => ref
                  .read(yuruboControllerProvider.notifier)
                  .toggleParticipation(item.id),
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
            child: OheyPageHeader(
              title: 'ゆるぼ',
              titleColor: _FeedColors.teal,
              titleOffset: const Offset(0, -54),
              trailingOffset: const Offset(0, -54),
              trailing: OheyHeaderIconButton(
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
            ),
          ),
          _FeedCreateYuruboFab(
            onTap: () => _showCreateYuruboSheet(context, ref),
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
        ref.read(yuruboControllerProvider).asData?.value.length ?? 0;
    if (loadedCount > 0 && index >= loadedCount - 3) {
      ref.invalidate(yuruboControllerProvider);
    }
  }

  Future<void> _showFeedAuthorProfile(
    BuildContext context,
    _FeedItem item,
  ) async {
    HapticFeedback.selectionClick();
    final currentUser = ref.read(oheyUserProvider);
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
            handle: item.isOfficial ? 'Ohey公式' : item.place,
            avatar: item.avatar,
            accent: item.accent,
            statusKey: null,
          );
    await showOheyBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (context) => _FeedCompanionProfileSheet(
        friend: author,
        initialRelationship: item.ownedByMe
            ? const OheyFriendRelationshipStatus(
                alreadyFriend: true,
                requestState: OheyFriendRequestState.none,
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
      OheyToast.show(
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
          item.isOfficial ? 'ohey_official_post.png' : 'ohey_memory.png',
        ],
        title: item.isOfficial ? 'Ohey公式ゆるぼを共有' : 'ゆるぼを共有',
        subject: item.isOfficial ? 'Ohey公式のお知らせ' : 'Oheyのゆるぼ',
        sharePositionOrigin: shareOrigin,
      ),
    );
    if (!context.mounted) return;
    if (result.status == ShareResultStatus.unavailable) {
      OheyToast.show(
        context,
        '共有できるアプリが見つかりませんでした。',
        icon: CupertinoIcons.square_arrow_up,
      );
    }
  }
}
