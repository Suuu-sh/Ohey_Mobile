import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
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
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../notifications/application/notification_controller.dart';
import '../../notifications/data/notification_repository.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _feedPageController;
  _FeedSection _selectedSection = _FeedSection.feed;
  bool _isRefreshingFeed = false;

  @override
  void initState() {
    super.initState();
    _feedPageController = PageController(initialPage: _selectedSection.index);
  }

  @override
  void dispose() {
    _feedPageController.dispose();
    super.dispose();
  }

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
    final sectionItems = {
      for (final section in _FeedSection.values)
        section: _itemsForSection(
          section,
          logs,
          user: user,
          currentUserId: currentUserId,
          friendUserIds: friendUserIds,
        ),
    };

    return const _FeedBackground(child: SizedBox.expand()).copyWith(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NomoPageHeader.horizontalPadding,
            NomoPageHeader.topPadding,
            NomoPageHeader.horizontalPadding,
            0,
          ),
          child: Column(
            children: [
              _FeedHeader(
                hasUnreadNotifications: hasUnreadNotifications,
                isRefreshing: _isRefreshingFeed,
                onRefresh: _refreshFeed,
                onNotifications: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => const _FeedNotificationsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _FeedTabs(
                selected: _selectedSection,
                onChanged: (section) => _onFeedSectionChanged(section),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: PageView(
                  controller: _feedPageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (page) {
                    final next = _FeedSection.values[page];
                    if (_selectedSection != next) {
                      setState(() => _selectedSection = next);
                    }
                  },
                  children: [
                    for (final section in _FeedSection.values)
                      _buildFeedSectionPage(
                        section: section,
                        items: sectionItems[section] ?? const <_FeedItem>[],
                        isWhite: isWhite,
                        logsAsync: logsAsync,
                        onLikePressed: (item) => ref
                            .read(drinkLogControllerProvider.notifier)
                            .toggleLike(item.id),
                        onSharePressed: (item) => _shareFeedItem(context, item),
                        onMorePressed: (item) =>
                            _showFeedPostActions(context, ref, item),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onFeedSectionChanged(_FeedSection section) {
    setState(() => _selectedSection = section);
    if (_feedPageController.hasClients) {
      _feedPageController.animateToPage(
        section.index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
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
          fileNameOverrides: const ['nomo_drink_log.png'],
          title: '飲みログを共有',
          subject: 'Nomoの飲みログ',
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

Widget _buildFeedSectionPage({
  required _FeedSection section,
  required List<_FeedItem> items,
  required bool isWhite,
  required AsyncValue<List<DrinkLog>> logsAsync,
  required ValueChanged<_FeedItem> onLikePressed,
  required ValueChanged<_FeedItem> onSharePressed,
  required ValueChanged<_FeedItem> onMorePressed,
}) => ListView(
  physics: const BouncingScrollPhysics(),
  padding: const EdgeInsets.only(bottom: 124),
  children: [
    if (logsAsync.isLoading && items.isEmpty)
      const Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CupertinoActivityIndicator()),
      )
    else if (items.isEmpty)
      _FeedSectionEmptyState(section: section, isWhite: isWhite)
    else
      ...items.map(
        (item) => _FeedPostCard(
          item: item,
          onLike: item.isLikeable ? () => onLikePressed(item) : null,
          onShare: item.id.isEmpty ? null : () => onSharePressed(item),
          onMore: item.id.isEmpty ? null : () => onMorePressed(item),
        ),
      ),
  ],
);

enum _FeedSection { feed, following, official }

extension _FeedSectionView on _FeedSection {
  String get label => switch (this) {
    _FeedSection.feed => 'おすすめ',
    _FeedSection.following => 'フレンズ',
    _FeedSection.official => '公式',
  };

  IconData get icon => switch (this) {
    _FeedSection.feed => Icons.sports_bar_rounded,
    _FeedSection.following => CupertinoIcons.person_2_fill,
    _FeedSection.official => CupertinoIcons.sparkles,
  };

  Color get accent => switch (this) {
    _FeedSection.feed => _FeedColors.teal,
    _FeedSection.following => const Color(0xFFFFD166),
    _FeedSection.official => const Color(0xFFFF7AB8),
  };
}

class _FeedBackground extends ConsumerWidget {
  const _FeedBackground({required this.child});
  final Widget child;

  _FeedBackground copyWith({Widget? child}) =>
      _FeedBackground(child: child ?? this.child);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWhite = ref.watch(nomoThemeModeProvider).isWhite;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isWhite
              ? const [Colors.white, Colors.white, Color(0xFFF7F9FB)]
              : const [Color(0xFF172637), Color(0xFF101B28), Color(0xFF0B1420)],
        ),
      ),
      child: child,
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.onRefresh,
    required this.onNotifications,
    required this.hasUnreadNotifications,
    required this.isRefreshing,
  });

  final VoidCallback onRefresh;
  final VoidCallback onNotifications;
  final bool hasUnreadNotifications;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return NomoPageHeader(
      title: 'フィード',
      titleColor: _FeedColors.teal,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NomoHeaderIconButton(
            icon: CupertinoIcons.arrow_clockwise,
            semanticLabel: 'フィードを更新',
            color: isRefreshing ? _FeedColors.sub : _FeedColors.teal,
            onTap: isRefreshing ? () {} : onRefresh,
          ),
          const SizedBox(width: 8),
          NomoHeaderIconButton(
            icon: CupertinoIcons.bell,
            semanticLabel: 'お知らせを開く',
            hasDot: hasUnreadNotifications,
            color: _FeedColors.teal,
            onTap: onNotifications,
          ),
        ],
      ),
    );
  }
}

class _FeedTabs extends StatelessWidget {
  const _FeedTabs({required this.selected, required this.onChanged});

  final _FeedSection selected;
  final ValueChanged<_FeedSection> onChanged;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWhite
              ? const [Colors.white, Color(0xFFF5FAFF)]
              : [
                  const Color(0xFF122334).withValues(alpha: .96),
                  const Color(0xFF081421).withValues(alpha: .96),
                ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFE2EAF2)
              : Colors.white.withValues(alpha: .10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .07 : .24),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: selected.accent.withValues(alpha: isWhite ? .10 : .12),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: SizedBox(
        height: 58,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sections = _FeedSection.values;
            final tabWidth = constraints.maxWidth / sections.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  left: selected.index * tabWidth + 3,
                  top: 3,
                  bottom: 3,
                  width: tabWidth - 6,
                  child: _FeedTabIndicator(
                    accent: selected.accent,
                    isWhite: isWhite,
                  ),
                ),
                Row(
                  children: [
                    for (final section in sections)
                      _FeedTab(
                        section: section,
                        selected: selected == section,
                        onTap: () => onChanged(section),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FeedTabIndicator extends StatelessWidget {
  const _FeedTabIndicator({required this.accent, required this.isWhite});

  final Color accent;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _FeedTabIndicatorPainter(accent: accent),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(Colors.white, accent, isWhite ? .32 : .24)!,
              accent,
              Color.lerp(accent, const Color(0xFFFFFFFF), .16)!,
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: Colors.white.withValues(alpha: isWhite ? .66 : .34),
            width: 1.3,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isWhite ? .26 : .34),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: isWhite ? .58 : .14),
              blurRadius: 0,
              offset: const Offset(0, -1),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedTabIndicatorPainter extends CustomPainter {
  const _FeedTabIndicatorPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()..color = Colors.white.withValues(alpha: .18);
    canvas.drawCircle(
      Offset(size.width * .18, size.height * .28),
      size.height * .22,
      glow,
    );
    canvas.drawCircle(
      Offset(size.width * .86, size.height * .70),
      size.height * .12,
      glow..color = Colors.white.withValues(alpha: .13),
    );

    final dot = Paint()..color = accent.withValues(alpha: .22);
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .26),
      size.height * .055,
      dot,
    );
    canvas.drawCircle(
      Offset(size.width * .33, size.height * .78),
      size.height * .04,
      dot..color = Colors.white.withValues(alpha: .16),
    );
  }

  @override
  bool shouldRepaint(covariant _FeedTabIndicatorPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _FeedSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final selectedColor = Color.lerp(
      const Color(0xFF031B22),
      section.accent,
      .10,
    )!;
    final idleColor = isWhite ? const Color(0xFF748291) : _FeedColors.sub;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Semantics(
          button: true,
          selected: selected,
          label: '${section.label}タブ',
          child: CupertinoButton(
            onPressed: selected ? null : onTap,
            minimumSize: const Size(0, 48),
            padding: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(25),
            child: SizedBox(
              width: double.infinity,
              height: 58,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                scale: selected ? 1 : .96,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: selected ? 27 : 22,
                      height: selected ? 27 : 22,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withValues(alpha: .38)
                            : Colors.white.withValues(
                                alpha: isWhite ? .74 : .06,
                              ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? Colors.white.withValues(alpha: .44)
                              : Colors.white.withValues(
                                  alpha: isWhite ? .55 : .06,
                                ),
                        ),
                      ),
                      child: Icon(
                        section.icon,
                        size: selected ? 15 : 13,
                        color: selected
                            ? selectedColor
                            : idleColor.withValues(alpha: isWhite ? .82 : .72),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: selected ? selectedColor : idleColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.45,
                            ) ??
                            TextStyle(
                              color: selected ? selectedColor : idleColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.45,
                            ),
                        child: Text(
                          section.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedSectionEmptyState extends StatelessWidget {
  const _FeedSectionEmptyState({required this.section, required this.isWhite});

  final _FeedSection section;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final title = switch (section) {
      _FeedSection.feed => 'まだ飲みログがありません',
      _FeedSection.following => 'フレンズの飲みログはまだありません',
      _FeedSection.official => '公式のお知らせはまだありません',
    };
    final message = switch (section) {
      _FeedSection.feed => '飲みログを追加するとフィードに表示されます。',
      _FeedSection.following => 'フレンズの飲みログが届くとここに表示されます。',
      _FeedSection.official => 'Nomoからのニュースやイベントをここで確認できます。',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: _FeedEmptyState(
        icon: section.icon,
        isWhite: isWhite,
        title: title,
        message: message,
        accent: section.accent,
      ),
    );
  }
}

Future<void> _showFeedPostActions(
  BuildContext context,
  WidgetRef ref,
  _FeedItem item,
) async {
  final body = item.body.trim();
  final action = await showCupertinoModalPopup<_FeedPostAction>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(item.userName),
      message: body.isEmpty ? null : Text(body),
      actions: [
        if (body.isNotEmpty)
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(_FeedPostAction.copy),
            child: const Text('コメントをコピー'),
          ),
        if (item.ownedByMe)
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(_FeedPostAction.delete),
            child: const Text('飲みログを削除'),
          )
        else
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(_FeedPostAction.report),
            child: const Text('飲みログを報告'),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('キャンセル'),
      ),
    ),
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case _FeedPostAction.copy:
      await Clipboard.setData(ClipboardData(text: body));
      if (context.mounted) NomoToast.show(context, 'コメントをコピーしました');
    case _FeedPostAction.delete:
      final confirmed = await _confirmDeleteFeedPost(context);
      if (!confirmed || !context.mounted) return;
      try {
        await ref.read(drinkLogControllerProvider.notifier).deleteLog(item.id);
        ref.invalidate(drinkLogControllerProvider);
        if (context.mounted) NomoToast.show(context, '飲みログを削除しました');
      } catch (error) {
        if (context.mounted) {
          NomoToast.show(context, '飲みログを削除できませんでした: $error');
        }
      }
    case _FeedPostAction.report:
      try {
        await ref.read(drinkLogControllerProvider.notifier).reportLog(item.id);
        if (context.mounted) NomoToast.show(context, '飲みログを報告しました');
      } catch (error) {
        if (context.mounted) {
          NomoToast.show(context, '飲みログを報告できませんでした: $error');
        }
      }
  }
}

Future<bool> _confirmDeleteFeedPost(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('飲みログを削除しますか？'),
      content: const Text('削除した飲みログは元に戻せません。'),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('削除'),
        ),
      ],
    ),
  );
  return result ?? false;
}

enum _FeedPostAction { copy, delete, report }

class _FeedPostCard extends StatelessWidget {
  const _FeedPostCard({
    required this.item,
    this.onLike,
    this.onShare,
    this.onMore,
  });

  final _FeedItem item;
  final VoidCallback? onLike;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  bool get _isOfficial => item.userName.contains('公式');

  @override
  Widget build(BuildContext context) {
    final photoPath = item.photoAssetPath;
    final hasPhoto = _isDisplayablePostPhoto(photoPath);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final line = isWhite
        ? Colors.black.withValues(alpha: .10)
        : Colors.white.withValues(alpha: .09);
    final body = _duoStyleBody(item).trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 22),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarBubble(
                avatar: item.avatar,
                size: 48,
                glowColor: item.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ink.withValues(alpha: .88),
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.2,
                    ),
                    children: [
                      TextSpan(text: item.userName),
                      if (_isOfficial)
                        TextSpan(
                          text: '  公式',
                          style: TextStyle(
                            color: item.accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onMore,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: NomoPopIcon(
                    icon: CupertinoIcons.ellipsis,
                    color: ink.withValues(alpha: .92),
                    size: 26,
                    showBubble: false,
                  ),
                ),
              ),
            ],
          ),
          if (hasPhoto) ...[
            const SizedBox(height: 12),
            _PostPhoto(path: photoPath!),
            if (body.isNotEmpty) const SizedBox(height: 12),
          ] else if (body.isNotEmpty)
            const SizedBox(height: 10),
          if (body.isNotEmpty)
            Text(
              body,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: ink.withValues(alpha: .88),
                fontWeight: FontWeight.w800,
                height: 1.35,
                letterSpacing: -.35,
              ),
            ),
          SizedBox(height: body.isEmpty ? 12 : 18),
          Row(
            children: [
              _DuoFeedButton(
                icon: item.liked
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                label: '${item.likes}',
                color: item.liked ? const Color(0xFFFF5EA8) : Colors.white,
                onTap: onLike,
              ),
              if (item.friends.isNotEmpty) ...[
                const SizedBox(width: 10),
                _WithFriendsPill(friends: item.friends),
              ],
              const SizedBox(width: 10),
              _DuoFeedButton(
                icon: CupertinoIcons.square_arrow_up,
                label: '',
                color: Colors.white,
                keepIconColor: true,
                useVectorShareIcon: true,
                onTap: onShare,
              ),
              const SizedBox(width: 10),
              if (_isOfficial)
                const _DuoFeedButton(
                  icon: CupertinoIcons.arrow_right_circle_fill,
                  label: '詳しく見る',
                  color: _FeedColors.teal,
                ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Text(
                  item.timeAgo,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: _FeedColors.sub,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DuoFeedButton extends StatelessWidget {
  const _DuoFeedButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.keepIconColor = false,
    this.useVectorShareIcon = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool keepIconColor;
  final bool useVectorShareIcon;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final effectiveIconColor = keepIconColor
        ? color
        : (color == Colors.white && isWhite ? const Color(0xFF101820) : color);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isWhite
                ? Colors.black.withValues(alpha: .18)
                : Colors.white.withValues(alpha: .20),
            width: 1.6,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            useVectorShareIcon
                ? _VectorShareIcon(color: effectiveIconColor, size: 27)
                : NomoPopIcon(
                    icon: icon,
                    color: effectiveIconColor,
                    size: 27,
                    showBubble: false,
                  ),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isWhite
                      ? const Color(0xFF101820)
                      : Colors.white.withValues(alpha: .90),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _VectorShareIcon extends StatelessWidget {
  const _VectorShareIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _VectorShareIconPainter(color)),
  );
}

class _VectorShareIconPainter extends CustomPainter {
  const _VectorShareIconPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = w * .105;

    final tray = Path()
      ..moveTo(w * .22, h * .62)
      ..lineTo(w * .22, h * .76)
      ..quadraticBezierTo(w * .22, h * .86, w * .32, h * .86)
      ..lineTo(w * .68, h * .86)
      ..quadraticBezierTo(w * .78, h * .86, w * .78, h * .76)
      ..lineTo(w * .78, h * .62);
    canvas.drawPath(tray, stroke);

    canvas.drawLine(Offset(w * .50, h * .66), Offset(w * .50, h * .16), stroke);
    canvas.drawLine(Offset(w * .34, h * .31), Offset(w * .50, h * .16), stroke);
    canvas.drawLine(Offset(w * .66, h * .31), Offset(w * .50, h * .16), stroke);
  }

  @override
  bool shouldRepaint(covariant _VectorShareIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

bool _isDisplayablePostPhoto(String? path) {
  if (path == null || path.isEmpty) return false;
  return !path.startsWith('nomo_memory_template_');
}

String _duoStyleBody(_FeedItem item) {
  if (item.userName.contains('公式')) {
    return switch (item.prop) {
      _PostProp.spark => 'Nomoで飲み友との思い出をもっと楽しく残せるようになったよ！',
      _PostProp.ticket => 'フレンズと一緒に今月の飲みログをふり返ろう。',
      _ => item.body,
    };
  }
  return item.body;
}

class _PostPhoto extends StatelessWidget {
  const _PostPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('http')
        ? Image.network(
            path,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : path.startsWith('/')
        ? Image.file(
            File(path),
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          )
        : Image.asset(
            path,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
          );
    return ClipRRect(borderRadius: BorderRadius.circular(22), child: image);
  }
}

class _FriendAvatarStack extends StatelessWidget {
  const _FriendAvatarStack({required this.friends});

  final List<_Companion> friends;

  @override
  Widget build(BuildContext context) {
    if (friends.isEmpty) return const SizedBox.shrink();
    final visible = friends.take(3).toList();
    return SizedBox(
      width: 28.0 + (visible.length - 1) * 18.0,
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < visible.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _FeedColors.card,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: NomoAvatarView(avatar: visible[i].avatar, size: 28),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WithFriendsPill extends StatelessWidget {
  const _WithFriendsPill({required this.friends});

  final List<_Companion> friends;

  @override
  Widget build(BuildContext context) => Container(
    height: 46,
    padding: const EdgeInsets.fromLTRB(12, 8, 13, 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .035),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.white.withValues(alpha: .20),
        width: 1.6,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'with',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: .90),
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
          ),
        ),
        const SizedBox(width: 8),
        _FriendAvatarStack(friends: friends),
      ],
    ),
  );
}

class _FeedNotificationsScreen extends ConsumerStatefulWidget {
  const _FeedNotificationsScreen();

  @override
  ConsumerState<_FeedNotificationsScreen> createState() =>
      _FeedNotificationsScreenState();
}

class _FeedNotificationsScreenState
    extends ConsumerState<_FeedNotificationsScreen> {
  bool _scheduledRead = false;

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationControllerProvider);
    final notifications = notificationsAsync.asData?.value
        .map(_FeedNotification.fromNotification)
        .toList(growable: false);

    if (!_scheduledRead &&
        (notificationsAsync.asData?.value.any(
              (notification) => notification.isUnread,
            ) ??
            false)) {
      _scheduledRead = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(notificationControllerProvider.notifier).markAllRead();
        }
      });
    }

    final isWhite = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isWhite ? Colors.white : const Color(0xFF07131F),
      body: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1.0)),
        child: _FeedBackground(
          child: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 124),
                  sliver: SliverList.list(
                    children: [
                      Stack(
                        children: [
                          CupertinoButton(
                            minimumSize: const Size(44, 44),
                            padding: EdgeInsets.zero,
                            borderRadius: BorderRadius.circular(16),
                            onPressed: () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isWhite
                                    ? const Color(0xFFF2F4F6)
                                    : Colors.white.withValues(alpha: .06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isWhite
                                      ? const Color(0xFFD7DEE7)
                                      : Colors.white.withValues(alpha: .09),
                                ),
                              ),
                              child: Center(
                                child: Transform.translate(
                                  offset: const Offset(-1, -1),
                                  child: Text(
                                    '＜',
                                    textAlign: TextAlign.center,
                                    strutStyle: const StrutStyle(
                                      fontSize: 23,
                                      height: 1,
                                      forceStrutHeight: true,
                                    ),
                                    style: TextStyle(
                                      color: isWhite
                                          ? const Color(0xFF27313B)
                                          : Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -2,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 56,
                                ),
                                child: Text(
                                  'お知らせ',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isWhite
                                        ? const Color(0xFF27313B)
                                        : Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (notificationsAsync.isLoading && notifications == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 42),
                          child: Center(child: CupertinoActivityIndicator()),
                        )
                      else if (notificationsAsync.hasError &&
                          notifications == null)
                        _FeedEmptyState(
                          icon: CupertinoIcons.exclamationmark_triangle,
                          isWhite: isWhite,
                          title: 'お知らせを読み込めませんでした',
                          message: '時間をおいてもう一度お試しください。',
                          accent: const Color(0xFFFF75B5),
                        )
                      else if ((notifications ?? const []).isEmpty)
                        _FeedEmptyState(
                          icon: CupertinoIcons.bell,
                          isWhite: isWhite,
                          title: 'まだお知らせはありません',
                          message: 'フレンズの反応がここに届きます。',
                        )
                      else
                        ...notifications!.map(
                          (notification) => _NotificationTile(
                            notification: notification,
                            isWhite: isWhite,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.isWhite});

  final _FeedNotification notification;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final cardColor = isWhite
        ? (notification.unread
              ? const Color(0xFFEBF5F5)
              : const Color(0xFFEEF3FA))
        : notification.unread
        ? _FeedColors.card.withValues(alpha: .86)
        : _FeedColors.card.withValues(alpha: .52);
    final cardBorderColor = isWhite
        ? const Color(0xFFE1E8F1)
        : Colors.white.withValues(alpha: .11);
    final messageColor = isWhite
        ? const Color(0xFF617281)
        : Colors.white.withValues(alpha: .64);
    final titleColor = isWhite ? const Color(0xFF27313B) : Colors.white;
    final timeColor = isWhite ? const Color(0xFF8B96A3) : _FeedColors.sub;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _feedCardDecoration(radius: 22).copyWith(
        color: cardColor,
        border: Border.all(color: cardBorderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NomoPopIcon(
            icon: notification.icon,
            color: notification.accent,
            size: 38,
            iconSize: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (notification.unread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _FeedColors.teal,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  notification.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: messageColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.timeAgo,
                  style: TextStyle(
                    color: timeColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.isWhite = false,
    this.accent = _FeedColors.teal,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool isWhite;
  final Color accent;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NomoPopIcon(icon: icon, color: accent, size: 58),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isWhite ? const Color(0xFF27313B) : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isWhite
                  ? const Color(0xFF6E7783)
                  : Colors.white.withValues(alpha: .55),
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
        ],
      ),
    ),
  );
}

class _AvatarBubble extends StatelessWidget {
  const _AvatarBubble({
    required this.avatar,
    required this.size,
    required this.glowColor,
  });

  final NomoAvatar avatar;
  final double size;
  final Color glowColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          glowColor.withValues(alpha: .36),
          glowColor.withValues(alpha: .10),
        ],
      ),
    ),
    child: NomoAvatarView(avatar: avatar, size: size * .96),
  );
}

BoxDecoration _feedCardDecoration({required double radius}) => BoxDecoration(
  color: _FeedColors.card.withValues(alpha: .74),
  borderRadius: BorderRadius.circular(radius),
  border: Border.all(color: Colors.white.withValues(alpha: .11), width: 1.2),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: .18),
      blurRadius: 26,
      offset: const Offset(0, 14),
    ),
  ],
);

List<_FeedItem> _itemsForSection(
  _FeedSection section,
  List<DrinkLog> logs, {
  NomoUser? user,
  String? currentUserId,
  Set<String> friendUserIds = const <String>{},
}) {
  final following = logs
      .map(
        (log) =>
            _FeedItem.fromLog(log, user: user, currentUserId: currentUserId),
      )
      .toList();
  return switch (section) {
    _FeedSection.feed => following,
    _FeedSection.following =>
      following
          .where((item) => friendUserIds.contains(item.ownerUserId))
          .toList(growable: false),
    _FeedSection.official => const <_FeedItem>[],
  };
}

class _FeedItem {
  const _FeedItem({
    this.id = '',
    required this.userName,
    required this.timeAgo,
    required this.body,
    required this.avatar,
    required this.accent,
    this.photoAssetPath,
    this.friends = const <_Companion>[],
    required this.likes,
    required this.saved,
    required this.liked,
    required this.prop,
    required this.tilt,
    this.ownerUserId = '',
    this.ownedByMe = false,
    required this.sparkles,
  });

  factory _FeedItem.fromLog(
    DrinkLog log, {
    NomoUser? user,
    String? currentUserId,
  }) {
    final accent = _accentForId(log.id);
    final ownerName = log.ownerDisplayName.trim();
    final authorName = ownerName.isNotEmpty
        ? ownerName
        : (log.ownerUserId == currentUserId &&
              user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : user?.userId ?? 'nomo_user';
    return _FeedItem(
      id: log.id,
      userName: authorName,
      timeAgo: _relativeTime(log.date),
      body: log.memo.trim(),
      avatar: log.ownerAvatar ?? user?.avatar ?? NomoAvatar.defaultAvatar,
      accent: accent,
      photoAssetPath: log.photoAssetPath,
      friends: log.friends.map(_Companion.fromFriend).toList(),
      likes: log.likeCount,
      saved: log.id.hashCode.isEven,
      liked: log.likedByMe,
      prop: _PostProp.beer,
      tilt: (log.id.hashCode.isEven ? -.08 : .08),
      ownerUserId: log.ownerUserId,
      ownedByMe: log.ownerUserId.isNotEmpty && log.ownerUserId == currentUserId,
      sparkles: const [
        Offset(12, 18),
        Offset(54, 2),
        Offset(118, 26),
        Offset(28, 66),
      ],
    );
  }

  bool matches(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final searchable = [userName, timeAgo, body].join(' ').toLowerCase();
    return searchable.contains(normalized);
  }

  bool get isLikeable => id.isNotEmpty && !userName.contains('公式');

  final String id;
  final String userName;
  final String timeAgo;
  final String body;
  final NomoAvatar avatar;
  final Color accent;
  final String? photoAssetPath;
  final List<_Companion> friends;
  final int likes;
  final bool saved;
  final bool liked;
  final String ownerUserId;
  final _PostProp prop;
  final double tilt;
  final bool ownedByMe;
  final List<Offset> sparkles;
}

enum _PostProp { beer, ticket, spark }

class _Companion {
  const _Companion({required this.name, required this.avatar});

  factory _Companion.fromFriend(NomoFriend friend) => _Companion(
    name: friend.name,
    avatar: friend.avatar ?? NomoAvatar.defaultAvatar,
  );

  final String name;
  final NomoAvatar avatar;
}

class _FeedNotification {
  const _FeedNotification({
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.accent,
    required this.unread,
  });

  factory _FeedNotification.fromNotification(NomoNotification notification) {
    return _FeedNotification(
      title: notification.title,
      message: notification.message,
      timeAgo: _relativeTimeText(notification.createdAt),
      icon: switch (notification.kind) {
        'drink_log_like' => CupertinoIcons.heart_fill,
        _ => CupertinoIcons.bell_fill,
      },
      accent: switch (notification.kind) {
        'drink_log_like' => const Color(0xFFFF75B5),
        _ => _FeedColors.teal,
      },
      unread: notification.isUnread,
    );
  }

  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color accent;
  final bool unread;
}

String _relativeTimeText(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inHours < 1) return '${diff.inMinutes}分前';
  if (diff.inDays < 1) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '$month/$day';
}

Future<String> _createStoryShareImage(_FeedItem item) async {
  const width = 1080.0;
  const height = 1920.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, width, height);

  final background = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF07131E), Color(0xFF112D3F), Color(0xFF21D6C4)],
    ).createShader(rect);
  canvas.drawRect(rect, background);

  final photoPath = item.photoAssetPath;
  if (photoPath != null && photoPath.startsWith('/')) {
    final file = File(photoPath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final source = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final imageAspect = image.width / image.height;
      final targetAspect = width / height;
      Rect target;
      if (imageAspect > targetAspect) {
        final targetWidth = height * imageAspect;
        target = Rect.fromLTWH(
          (width - targetWidth) / 2,
          0,
          targetWidth,
          height,
        );
      } else {
        final targetHeight = width / imageAspect;
        target = Rect.fromLTWH(
          0,
          (height - targetHeight) / 2,
          width,
          targetHeight,
        );
      }
      canvas.drawImageRect(image, source, target, Paint());
      canvas.drawRect(
        rect,
        Paint()..color = Colors.black.withValues(alpha: .38),
      );
      image.dispose();
    }
  }

  final cardRect = RRect.fromRectAndRadius(
    const Rect.fromLTWH(86, 1130, 908, 480),
    const Radius.circular(52),
  );
  canvas.drawRRect(
    cardRect,
    Paint()..color = const Color(0xFF07131E).withValues(alpha: .78),
  );
  canvas.drawRRect(
    cardRect,
    Paint()
      ..color = Colors.white.withValues(alpha: .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  void paintText(
    String text, {
    required double x,
    required double y,
    required double maxWidth,
    required double size,
    required FontWeight weight,
    Color color = Colors.white,
    int? maxLines,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: weight,
          height: 1.22,
          letterSpacing: -0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, Offset(x, y));
  }

  paintText(
    'Nomo',
    x: 116,
    y: 120,
    maxWidth: 500,
    size: 64,
    weight: FontWeight.w900,
    color: _FeedColors.teal,
  );
  paintText(
    '飲みログ',
    x: 116,
    y: 1212,
    maxWidth: 820,
    size: 44,
    weight: FontWeight.w900,
    color: _FeedColors.teal,
  );
  paintText(
    item.userName,
    x: 116,
    y: 1284,
    maxWidth: 820,
    size: 58,
    weight: FontWeight.w900,
  );
  final body = item.body.trim();
  if (body.isNotEmpty) {
    paintText(
      body,
      x: 116,
      y: 1390,
      maxWidth: 820,
      size: 54,
      weight: FontWeight.w900,
      maxLines: 3,
    );
  }
  paintText(
    item.timeAgo,
    x: 116,
    y: 1532,
    maxWidth: 820,
    size: 34,
    weight: FontWeight.w800,
    color: Colors.white.withValues(alpha: .68),
  );

  final picture = recorder.endRecording();
  final output = await picture.toImage(width.toInt(), height.toInt());
  final byteData = await output.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('共有画像を作成できませんでした。');
  }
  final path =
      '${Directory.systemTemp.path}/nomo_story_${DateTime.now().microsecondsSinceEpoch}.png';
  await File(path).writeAsBytes(byteData.buffer.asUint8List());
  output.dispose();
  picture.dispose();
  return path;
}

class _FeedColors {
  const _FeedColors._();
  static const teal = Color(0xFF21D6C4);
  static const card = Color(0xFF112332);
  static const sub = Color(0xFF9AA7B7);
}

Color _accentForId(String id) {
  const colors = [
    Color(0xFF12C9A4),
    Color(0xFFC08BFF),
    Color(0xFF9AF21A),
    Color(0xFFFF75B5),
    Color(0xFF58D6FF),
  ];
  return colors[id.hashCode.abs() % colors.length];
}

String _relativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  return '${diff.inDays}日前';
}
