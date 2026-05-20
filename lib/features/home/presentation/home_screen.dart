import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/models/nomo_user.dart';
import '../../../core/theme/nomo_theme_mode.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../friends/application/drink_invite_controller.dart';
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
    _FeedSection.official => CupertinoIcons.bolt_fill,
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
                    AnimatedScale(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      scale: selected ? 1.08 : 1,
                      child: NomoPopIcon(
                        icon: section.icon,
                        size: selected ? 28 : 24,
                        iconSize: selected ? 27 : 23,
                        showBubble: false,
                        shadow: false,
                        color: selected
                            ? selectedColor
                            : idleColor.withValues(alpha: isWhite ? .86 : .78),
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
  HapticFeedback.selectionClick();
  final action = await showModalBottomSheet<_FeedPostAction>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (context) => _FeedPostActionsSheet(item: item, body: body),
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
  final result = await showModalBottomSheet<bool>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => const _FeedDeleteConfirmSheet(),
  );
  return result ?? false;
}

enum _FeedPostAction { copy, delete, report }

class _FeedPostActionsSheet extends StatelessWidget {
  const _FeedPostActionsSheet({required this.item, required this.body});

  final _FeedItem item;
  final String body;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
    return _FeedModalShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FeedModalHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              _AvatarBubble(
                avatar: item.avatar,
                size: 46,
                glowColor: item.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body.isEmpty ? '飲みログメニュー' : body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: NomoPopIcon(
                  icon: CupertinoIcons.xmark,
                  color: subtitleColor,
                  size: 34,
                  iconSize: 18,
                  shadow: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (body.isNotEmpty) ...[
            _FeedActionTile(
              icon: CupertinoIcons.doc_on_clipboard_fill,
              title: 'コメントをコピー',
              subtitle: 'クリップボードに保存',
              accent: _FeedColors.teal,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.copy),
            ),
            const SizedBox(height: 10),
          ],
          if (item.ownedByMe)
            _FeedActionTile(
              icon: CupertinoIcons.trash_fill,
              title: '飲みログを削除',
              subtitle: 'この投稿をフィードから消す',
              accent: const Color(0xFFFF5F8F),
              destructive: true,
              onTap: () => Navigator.of(context).pop(_FeedPostAction.delete),
            )
          else
            _FeedActionTile(
              icon: CupertinoIcons.exclamationmark_bubble_fill,
              title: '飲みログを報告',
              subtitle: '気になる投稿を運営に送る',
              accent: const Color(0xFFFFD166),
              onTap: () => Navigator.of(context).pop(_FeedPostAction.report),
            ),
          const SizedBox(height: 12),
          _FeedModalTextButton(
            label: 'キャンセル',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _FeedDeleteConfirmSheet extends StatelessWidget {
  const _FeedDeleteConfirmSheet();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
    return _FeedModalShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FeedModalHandle(),
          const SizedBox(height: 20),
          Center(
            child: NomoPopIcon(
              icon: CupertinoIcons.trash_fill,
              color: const Color(0xFFFF5F8F),
              size: 64,
              iconSize: 34,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '飲みログを削除しますか？',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: titleColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '削除した飲みログは元に戻せません。',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _FeedModalTextButton(
                  label: 'やめる',
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FeedModalTextButton(
                  label: '削除する',
                  color: const Color(0xFFFF5F8F),
                  onTap: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeedModalShell extends StatelessWidget {
  const _FeedModalShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              decoration: BoxDecoration(
                color: isWhite ? Colors.white : null,
                gradient: isWhite
                    ? null
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF172737), Color(0xFF0B1722)],
                      ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isWhite
                      ? const Color(0xFFE1E8F1)
                      : Colors.white.withValues(alpha: .12),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isWhite ? .16 : .36),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedModalHandle extends StatelessWidget {
  const _FeedModalHandle();

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return Center(
      child: Container(
        width: 42,
        height: 5,
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFD7E0EA)
              : Colors.white.withValues(alpha: .20),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _FeedActionTile extends StatelessWidget {
  const _FeedActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = destructive
        ? const Color(0xFFFF5F8F)
        : isWhite
        ? const Color(0xFF101820)
        : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .55);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFF7FAFC)
              : Colors.white.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: destructive
                ? const Color(0xFFFF5F8F).withValues(alpha: .32)
                : isWhite
                ? const Color(0xFFE1E8F1)
                : Colors.white.withValues(alpha: .10),
          ),
        ),
        child: Row(
          children: [
            NomoPopIcon(icon: icon, color: accent, size: 44, iconSize: 23),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            NomoPopIcon(
              icon: CupertinoIcons.chevron_forward,
              color: subtitleColor,
              size: 30,
              iconSize: 16,
              shadow: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedModalTextButton extends StatelessWidget {
  const _FeedModalTextButton({
    required this.label,
    required this.onTap,
    this.color = _FeedColors.teal,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: isWhite ? .13 : .10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .30)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: -.35,
          ),
        ),
      ),
    );
  }
}

Future<void> _showFeedCompanionList(
  BuildContext context,
  List<_Companion> friends,
) async {
  if (friends.isEmpty) return;
  HapticFeedback.selectionClick();
  final selected = await showModalBottomSheet<_Companion>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .58),
    builder: (context) => _FeedCompanionListSheet(friends: friends),
  );
  if (!context.mounted || selected == null) return;
  HapticFeedback.selectionClick();
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .62),
    builder: (context) => _FeedCompanionProfileSheet(friend: selected),
  );
}

class _FeedCompanionListSheet extends StatelessWidget {
  const _FeedCompanionListSheet({required this.friends});

  final List<_Companion> friends;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
    final listHeight = (friends.length * 78.0).clamp(
      78.0,
      MediaQuery.sizeOf(context).height * .44,
    );
    return _FeedModalShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FeedModalHandle(),
          const SizedBox(height: 18),
          Row(
            children: [
              NomoPopIcon(
                icon: CupertinoIcons.person_2_fill,
                color: _FeedColors.teal,
                size: 46,
                iconSize: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '一緒に飲んだフレンズ',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'タップしてプロフィールを見る',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: NomoPopIcon(
                  icon: CupertinoIcons.xmark,
                  color: subtitleColor,
                  size: 34,
                  iconSize: 18,
                  shadow: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: listHeight,
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: friends.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _FeedCompanionTile(
                friend: friends[index],
                onTap: () => Navigator.of(context).pop(friends[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCompanionTile extends StatelessWidget {
  const _FeedCompanionTile({required this.friend, required this.onTap});

  final _Companion friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .56);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isWhite
              ? const Color(0xFFF7FAFC)
              : Colors.white.withValues(alpha: .055),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFE1E8F1)
                : Colors.white.withValues(alpha: .10),
          ),
        ),
        child: Row(
          children: [
            _AvatarBubble(
              avatar: friend.avatar,
              size: 44,
              glowColor: friend.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friend.handleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _companionStatusColor(
                  friend.statusKey,
                ).withValues(alpha: isWhite ? .13 : .11),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _companionStatusLabel(friend.statusKey),
                style: TextStyle(
                  color: _companionStatusColor(friend.statusKey),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            NomoPopIcon(
              icon: CupertinoIcons.chevron_forward,
              color: subtitleColor,
              size: 28,
              iconSize: 15,
              shadow: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedCompanionProfileSheet extends StatelessWidget {
  const _FeedCompanionProfileSheet({required this.friend});

  final _Companion friend;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subtitleColor = isWhite
        ? const Color(0xFF697684)
        : Colors.white.withValues(alpha: .58);
    final statusColor = _companionStatusColor(friend.statusKey);
    return _FeedModalShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FeedModalHandle(),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: NomoPopIcon(
                icon: CupertinoIcons.xmark,
                color: subtitleColor,
                size: 34,
                iconSize: 18,
                shadow: false,
              ),
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 142,
                  height: 142,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [friend.accent, _FeedColors.teal],
                    ),
                  ),
                ),
                Container(
                  width: 130,
                  height: 130,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: isWhite ? Colors.white : const Color(0xFFF4F2EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 5),
                  ),
                  child: ClipOval(
                    child: NomoAvatarView(avatar: friend.avatar, size: 112),
                  ),
                ),
                const Positioned(
                  right: 12,
                  top: 14,
                  child: NomoPopIcon(
                    icon: CupertinoIcons.sparkles,
                    color: Color(0xFFFFD166),
                    size: 32,
                    iconSize: 19,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            friend.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isWhite
                    ? const Color(0xFFF2F6F8)
                    : Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isWhite
                      ? const Color(0xFFE1E8F1)
                      : Colors.white.withValues(alpha: .10),
                ),
              ),
              child: Text(
                friend.handleLabel,
                style: TextStyle(
                  color: subtitleColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isWhite
                  ? const Color(0xFFF7FAFC)
                  : Colors.white.withValues(alpha: .045),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isWhite
                    ? const Color(0xFFE1E8F1)
                    : Colors.white.withValues(alpha: .08),
              ),
            ),
            child: Row(
              children: [
                NomoPopIcon(
                  icon: _companionStatusIcon(friend.statusKey),
                  color: statusColor,
                  size: 40,
                  iconSize: 22,
                  showBubble: false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _companionStatusLabel(friend.statusKey),
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _companionStatusMessage(friend.statusKey),
                        style: TextStyle(
                          color: subtitleColor,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FeedModalTextButton(
            label: '閉じる',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

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

  bool get _isOfficial => item.isOfficial;

  @override
  Widget build(BuildContext context) {
    final photoPath = item.photoAssetPath;
    final hasPhoto = _isDisplayablePostPhoto(photoPath);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    final line = isWhite
        ? Colors.black.withValues(alpha: .10)
        : Colors.white.withValues(alpha: .09);
    final rawBody = _duoStyleBody(item).trim();

    final body = hasPhoto ? '' : rawBody;

    final decoration = _isOfficial
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: isWhite
                  ? const [Color(0xFFFFF5FA), Color(0xFFFFFBF0)]
                  : const [Color(0xFF251424), Color(0xFF241C10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFF9DCA), width: 1.4),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF5EA8).withValues(alpha: .13),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          )
        : BoxDecoration(
            border: Border(bottom: BorderSide(color: line)),
          );

    return Container(
      margin: EdgeInsets.only(
        left: _isOfficial ? 4 : 0,
        right: _isOfficial ? 4 : 0,
        bottom: _isOfficial ? 14 : 0,
      ),
      padding: EdgeInsets.fromLTRB(
        _isOfficial ? 16 : 0,
        20,
        _isOfficial ? 16 : 0,
        22,
      ),
      decoration: decoration,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: ink.withValues(alpha: .88),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.25,
                        ),
                      ),
                    ),
                    if (_isOfficial) const _OfficialVerifiedBadge(),
                  ],
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
                useVectorShareIcon: true,
                onTap: onShare,
              ),
              const SizedBox(width: 10),
              if (_isOfficial && item.linkUrl.trim().isNotEmpty)
                _DuoFeedButton(
                  icon: CupertinoIcons.arrow_right_circle_fill,
                  label: '詳しく見る',
                  color: _FeedColors.teal,
                  onTap: () => _openOfficialLink(context, item.linkUrl),
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

  Future<void> _openOfficialLink(BuildContext context, String rawUrl) async {
    final normalized = rawUrl.trim();
    final candidate = normalized.startsWith(RegExp(r'https?://'))
        ? normalized
        : 'https://$normalized';
    final uri = Uri.tryParse(candidate);
    if (uri == null || !uri.hasScheme || uri.host.trim().isEmpty) {
      NomoToast.show(context, 'リンクを開けませんでした。');
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      NomoToast.show(context, 'リンクを開けませんでした。');
    }
  }
}

class _OfficialVerifiedBadge extends StatelessWidget {
  const _OfficialVerifiedBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 7),
      child: Semantics(
        label: '公式アカウント',
        child: SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: const [
              Positioned.fill(
                child: CustomPaint(painter: _VerifiedBadgeSeal()),
              ),
              Icon(
                CupertinoIcons.checkmark_alt,
                color: Colors.white,
                size: 14,
                weight: 900,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerifiedBadgeSeal extends CustomPainter {
  const _VerifiedBadgeSeal();

  static const _pink = Color(0xFFFF5EA8);
  static const _pinkLight = Color(0xFFFF83C0);
  static const _rim = Color(0xFFFFC1DC);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final seal = _sealPath(size, inset: size.shortestSide * .14);
    final shadow = Paint()
      ..color = _pink.withValues(alpha: .34)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(seal.shift(Offset(0, size.height * .10)), shadow);

    final outer = Paint()
      ..color = Colors.white.withValues(alpha: .95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .10
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(seal, outer);

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_pinkLight, _pink],
      ).createShader(bounds);
    canvas.drawPath(seal, fill);

    final innerRim = Paint()
      ..color = _rim.withValues(alpha: .65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .045
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(seal, innerRim);

    canvas.drawCircle(
      Offset(size.width * .36, size.height * .31),
      size.shortestSide * .095,
      Paint()..color = Colors.white.withValues(alpha: .24),
    );
  }

  Path _sealPath(Size size, {required double inset}) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2 - inset;
    final path = Path();
    const samples = 48;
    for (var i = 0; i <= samples; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / samples);
      final wave = math.cos(angle * 8);
      final r = radius * (1 + wave * .065);
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant _VerifiedBadgeSeal oldDelegate) => false;
}

class _DuoFeedButton extends StatelessWidget {
  const _DuoFeedButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
    this.useVectorShareIcon = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool useVectorShareIcon;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final effectiveIconColor = color == Colors.white && isWhite
        ? const Color(0xFF101820)
        : color;
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
  final normalized = path?.trim();
  if (normalized == null || normalized.isEmpty) return false;
  if (normalized.startsWith('nomo_memory_template_')) return false;
  if (normalized.startsWith('/')) return File(normalized).existsSync();
  if (normalized.startsWith('http://') ||
      normalized.startsWith('https://') ||
      normalized.startsWith('assets/')) {
    return true;
  }
  return false;
}

String _duoStyleBody(_FeedItem item) {
  if (item.isOfficial) {
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
    final provider = _imageProviderFor(path);
    if (provider == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image(
          image: provider,
          width: double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  ImageProvider? _imageProviderFor(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return NetworkImage(normalized);
    }
    if (normalized.startsWith('/')) {
      final file = File(normalized);
      if (!file.existsSync()) return null;
      return FileImage(file);
    }
    if (normalized.startsWith('assets/')) return AssetImage(normalized);
    return null;
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
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF101820) : Colors.white;
    return Semantics(
      button: true,
      label: '一緒に飲んだフレンズを表示',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showFeedCompanionList(context, friends),
        child: Container(
          height: 46,
          padding: const EdgeInsets.fromLTRB(12, 8, 13, 8),
          decoration: BoxDecoration(
            color: isWhite
                ? Colors.black.withValues(alpha: .025)
                : Colors.white.withValues(alpha: .035),
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
              Text(
                'with',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ink.withValues(alpha: .90),
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
              const SizedBox(width: 8),
              _FriendAvatarStack(friends: friends),
            ],
          ),
        ),
      ),
    );
  }
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
      resizeToAvoidBottomInset: false,
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
                            onTap: notification.canOpen
                                ? () => _openNotification(notification)
                                : null,
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

  Future<void> _openNotification(_FeedNotification notification) async {
    if (notification.kind == 'friend_request_received') {
      await _openFriendRequestNotification(notification);
      return;
    }
    if (notification.kind == 'drink_invite_received') {
      await _openDrinkInviteNotification(notification);
    }
  }

  Future<void> _openFriendRequestNotification(
    _FeedNotification notification,
  ) async {
    final friendRequestId = notification.friendRequestId;
    if (friendRequestId == null || friendRequestId.isEmpty) {
      NomoToast.show(context, 'この申請を開けませんでした。もう一度お試しください。');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (sheetContext) => _FriendRequestNotificationSheet(
        notification: notification,
        onAccept: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .acceptFriendRequest(friendRequestId);
          ref.invalidate(friendsProvider);
          ref.invalidate(drinkLogControllerProvider);
        },
        onReject: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .rejectFriendRequest(friendRequestId);
          ref.invalidate(notificationControllerProvider);
        },
      ),
    );
  }

  Future<void> _openDrinkInviteNotification(
    _FeedNotification notification,
  ) async {
    final drinkInviteId = notification.drinkInviteId;
    if (drinkInviteId == null || drinkInviteId.isEmpty) {
      NomoToast.show(context, 'この飲み誘いを開けませんでした。もう一度お試しください。');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .62),
      builder: (sheetContext) => _DrinkInviteNotificationSheet(
        notification: notification,
        onAccept: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .acceptDrinkInvite(drinkInviteId);
          ref.invalidate(todayReservationsProvider);
          ref.invalidate(incomingDrinkInvitesProvider);
        },
        onReject: () async {
          await ref
              .read(notificationControllerProvider.notifier)
              .rejectDrinkInvite(drinkInviteId);
          ref.invalidate(incomingDrinkInvitesProvider);
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isWhite,
    this.onTap,
  });

  final _FeedNotification notification;
  final bool isWhite;
  final VoidCallback? onTap;

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

    final tile = Container(
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
                Row(
                  children: [
                    Text(
                      notification.timeAgo,
                      style: TextStyle(
                        color: timeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (notification.actionLabel != null) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: notification.accent.withValues(
                                alpha: isWhite ? .14 : .18,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: notification.accent.withValues(
                                  alpha: isWhite ? .24 : .30,
                                ),
                              ),
                            ),
                            child: Text(
                              notification.actionLabel!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: notification.accent,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return Semantics(
      button: true,
      label: '${notification.title}を開く',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: tile,
      ),
    );
  }
}

class _FriendRequestNotificationSheet extends StatefulWidget {
  const _FriendRequestNotificationSheet({
    required this.notification,
    required this.onAccept,
    required this.onReject,
  });

  final _FeedNotification notification;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  State<_FriendRequestNotificationSheet> createState() =>
      _FriendRequestNotificationSheetState();
}

class _FriendRequestNotificationSheetState
    extends State<_FriendRequestNotificationSheet> {
  String? _busyAction;

  bool get _isPending =>
      widget.notification.friendRequestStatus == null ||
      widget.notification.friendRequestStatus == 'pending';

  Future<void> _submit({required bool accept}) async {
    if (_busyAction != null || !_isPending) return;
    final action = accept ? 'accept' : 'reject';
    setState(() => _busyAction = action);
    try {
      if (accept) {
        await widget.onAccept();
      } else {
        await widget.onReject();
      }
      if (!mounted) return;
      NomoToast.show(context, accept ? 'フレンズ申請を承認しました' : '申請を見送りました');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        accept
            ? '承認できませんでした。時間をおいてもう一度お試しください。'
            : '見送りできませんでした。時間をおいてもう一度お試しください。',
      );
      setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (widget.notification.friendRequestStatus) {
      'accepted' => '承認済み',
      'rejected' => '見送り済み',
      'cancelled' => '取り消し済み',
      _ => '承認待ち',
    };

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF071622),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .32),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NomoPopIcon(
                  icon: CupertinoIcons.person_badge_plus_fill,
                  color: const Color(0xFF58D6FF),
                  size: 54,
                  iconSize: 29,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF58D6FF).withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFF58D6FF,
                            ).withValues(alpha: .26),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Color(0xFF58D6FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  minimumSize: const Size(42, 42),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                    child: const NomoGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Text(
                _isPending
                    ? '${widget.notification.message}\n承認するとフレンズになり、飲みログや飲み予約でつながれます。'
                    : widget.notification.message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_isPending) ...[
              Nomo3DButton(
                label: '承認してフレンズになる',
                icon: CupertinoIcons.checkmark_seal_fill,
                onTap: () => _submit(accept: true),
                isLoading: _busyAction == 'accept',
                enabled: _busyAction == null,
                height: 54,
                radius: 22,
                color: const Color(0xFF9AF21A),
                shadowColor: const Color(0xFF5BB716),
                fontSize: 15,
              ),
              const SizedBox(height: 10),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _busyAction == null
                    ? () => _submit(accept: false)
                    : null,
                child: Text(
                  _busyAction == 'reject' ? '見送り中...' : '今回は見送る',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .60),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ] else
              Nomo3DButton(
                label: '閉じる',
                icon: CupertinoIcons.checkmark_circle_fill,
                onTap: () => Navigator.of(context).pop(),
                height: 52,
                radius: 22,
                color: const Color(0xFF22D7C5),
                shadowColor: const Color(0xFF109F91),
                fontSize: 15,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrinkInviteNotificationSheet extends StatefulWidget {
  const _DrinkInviteNotificationSheet({
    required this.notification,
    required this.onAccept,
    required this.onReject,
  });

  final _FeedNotification notification;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  @override
  State<_DrinkInviteNotificationSheet> createState() =>
      _DrinkInviteNotificationSheetState();
}

class _DrinkInviteNotificationSheetState
    extends State<_DrinkInviteNotificationSheet> {
  String? _busyAction;

  bool get _isPending =>
      widget.notification.drinkInviteStatus == null ||
      widget.notification.drinkInviteStatus == 'pending';

  Future<void> _submit({required bool accept}) async {
    if (_busyAction != null || !_isPending) return;
    final action = accept ? 'accept' : 'reject';
    setState(() => _busyAction = action);
    try {
      if (accept) {
        await widget.onAccept();
      } else {
        await widget.onReject();
      }
      if (!mounted) return;
      NomoToast.show(context, accept ? '飲み誘いを承認しました' : '飲み誘いを見送りました');
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(
        context,
        accept
            ? '承認できませんでした。時間をおいてもう一度お試しください。'
            : '見送りできませんでした。時間をおいてもう一度お試しください。',
      );
      setState(() => _busyAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = switch (widget.notification.drinkInviteStatus) {
      'accepted' => '参加予定',
      'rejected' => '見送り済み',
      'cancelled' => '取り消し済み',
      _ => '返信待ち',
    };

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF071622),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .32),
              blurRadius: 30,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                NomoPopIcon(
                  icon: CupertinoIcons.calendar_badge_plus,
                  color: const Color(0xFFC08BFF),
                  size: 54,
                  iconSize: 29,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC08BFF).withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(
                              0xFFC08BFF,
                            ).withValues(alpha: .26),
                          ),
                        ),
                        child: Text(
                          statusLabel,
                          style: const TextStyle(
                            color: Color(0xFFC08BFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  minimumSize: const Size(42, 42),
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .08),
                      shape: BoxShape.circle,
                    ),
                    child: const NomoGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .045),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withValues(alpha: .08)),
              ),
              child: Text(
                _isPending
                    ? '${widget.notification.message}\n承認すると今日の飲み予定に追加されます。'
                    : widget.notification.message,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .78),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_isPending) ...[
              Nomo3DButton(
                label: '承認して飲みに行く',
                icon: CupertinoIcons.checkmark_circle_fill,
                onTap: () => _submit(accept: true),
                isLoading: _busyAction == 'accept',
                enabled: _busyAction == null,
                height: 54,
                radius: 22,
                color: const Color(0xFF9AF21A),
                shadowColor: const Color(0xFF5BB716),
                fontSize: 15,
              ),
              const SizedBox(height: 10),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _busyAction == null
                    ? () => _submit(accept: false)
                    : null,
                child: Text(
                  _busyAction == 'reject' ? '見送り中...' : '今回は見送る',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .60),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ] else
              Nomo3DButton(
                label: '閉じる',
                icon: CupertinoIcons.checkmark_circle_fill,
                onTap: () => Navigator.of(context).pop(),
                height: 52,
                radius: 22,
                color: const Color(0xFF22D7C5),
                shadowColor: const Color(0xFF109F91),
                fontSize: 15,
              ),
          ],
        ),
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
          .where(
            (item) =>
                !item.isOfficial && friendUserIds.contains(item.ownerUserId),
          )
          .toList(growable: false),
    _FeedSection.official =>
      following.where((item) => item.isOfficial).toList(growable: false),
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
    this.linkUrl = '',
    this.friends = const <_Companion>[],
    required this.likes,
    required this.saved,
    required this.liked,
    required this.prop,
    required this.tilt,
    this.ownerUserId = '',
    this.ownedByMe = false,
    this.isOfficial = false,
    required this.sparkles,
  });

  factory _FeedItem.fromLog(
    DrinkLog log, {
    NomoUser? user,
    String? currentUserId,
  }) {
    final accent = _accentForId(log.id);
    final ownerName = log.ownerDisplayName.trim();
    final isOwnedByCurrentUser =
        currentUserId?.isNotEmpty == true && log.ownerUserId == currentUserId;
    final authorName = ownerName.isNotEmpty
        ? ownerName
        : (isOwnedByCurrentUser && user?.name.trim().isNotEmpty == true)
        ? user!.name.trim()
        : user?.userId ?? 'nomo_user';
    final avatar = log.isOfficial
        ? NomoAvatar.adminAvatar
        : log.ownerAvatar ??
              (isOwnedByCurrentUser ? user?.avatar : null) ??
              NomoAvatar.defaultAvatar;
    return _FeedItem(
      id: log.id,
      userName: log.isOfficial ? 'Nomo' : authorName,
      timeAgo: _relativeTime(log.date),
      body: log.memo.trim(),
      avatar: avatar,
      accent: accent,
      photoAssetPath: log.photoAssetPath,
      linkUrl: log.linkUrl ?? '',
      friends: log.friends.map(_Companion.fromFriend).toList(),
      likes: log.likeCount,
      saved: log.id.hashCode.isEven,
      liked: log.likedByMe,
      prop: _PostProp.beer,
      tilt: (log.id.hashCode.isEven ? -.08 : .08),
      ownerUserId: log.ownerUserId,
      ownedByMe: isOwnedByCurrentUser,
      isOfficial: log.isOfficial,
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

  bool get isLikeable => id.isNotEmpty;

  final String id;
  final String userName;
  final String timeAgo;
  final String body;
  final NomoAvatar avatar;
  final Color accent;
  final String? photoAssetPath;
  final String linkUrl;
  final List<_Companion> friends;
  final int likes;
  final bool saved;
  final bool liked;
  final String ownerUserId;
  final _PostProp prop;
  final double tilt;
  final bool ownedByMe;
  final bool isOfficial;
  final List<Offset> sparkles;
}

enum _PostProp { beer, ticket, spark }

class _Companion {
  const _Companion({
    required this.name,
    required this.handle,
    required this.avatar,
    required this.accent,
    required this.statusKey,
  });

  factory _Companion.fromFriend(NomoFriend friend) => _Companion(
    name: friend.name,
    handle: friend.vibe,
    avatar: friend.avatar ?? NomoAvatar.defaultAvatar,
    accent: friend.accentColor,
    statusKey: friend.statusKey,
  );

  final String name;
  final String handle;
  final NomoAvatar avatar;
  final Color accent;
  final String? statusKey;

  String get handleLabel => handle.trim().isEmpty ? 'Nomoフレンズ' : '@$handle';
}

String _companionStatusLabel(String? statusKey) {
  final legacy = switch (statusKey) {
    'available' => '今ヒマ',
    'last_train' => '終電までなら',
    'want_drink' => '飲みたい気分',
    'busy' => '休肝日',
    'unset' => '未設定',
    _ => null,
  };
  if (legacy != null) return legacy;
  return nomoDailyStatusFromKey(statusKey).label;
}

String _companionStatusMessage(String? statusKey) {
  final legacy = switch (statusKey) {
    'available' => '今日なら行けるよ〜！',
    'last_train' => '軽く飲めるかも！',
    'want_drink' => '誰か誘って〜！',
    'busy' => '今日はお休み中...',
    'unset' => 'ステータス未設定',
    _ => null,
  };
  if (legacy != null) return legacy;
  return nomoDailyStatusFromKey(statusKey).description;
}

IconData _companionStatusIcon(String? statusKey) {
  final legacy = switch (statusKey) {
    'available' => CupertinoIcons.hand_thumbsup_fill,
    'last_train' => CupertinoIcons.clock_fill,
    'want_drink' => Icons.local_bar_rounded,
    'busy' => CupertinoIcons.moon_fill,
    _ => null,
  };
  if (legacy != null) return legacy;
  final status = nomoDailyStatusFromKey(statusKey);
  return switch (status) {
    NomoDailyStatus.canDrinkToday => CupertinoIcons.checkmark_circle_fill,
    NomoDailyStatus.lightDrink => CupertinoIcons.clock_fill,
    NomoDailyStatus.wantDrinkHard => Icons.local_bar_rounded,
    NomoDailyStatus.nonAlcohol => CupertinoIcons.drop_fill,
    NomoDailyStatus.liverRest => CupertinoIcons.moon_fill,
    NomoDailyStatus.waitingInvite => CupertinoIcons.bell_fill,
    NomoDailyStatus.hasPlans => CupertinoIcons.calendar_today,
    NomoDailyStatus.unselected => CupertinoIcons.circle,
  };
}

Color _companionStatusColor(String? statusKey) {
  final legacy = switch (statusKey) {
    'available' => const Color(0xFF9AF21A),
    'last_train' => const Color(0xFF58D6FF),
    'want_drink' => const Color(0xFFFFC857),
    'busy' => const Color(0xFFFF5EA8),
    _ => null,
  };
  if (legacy != null) return legacy;
  final status = nomoDailyStatusFromKey(statusKey);
  return switch (status) {
    NomoDailyStatus.canDrinkToday => const Color(0xFF9AF21A),
    NomoDailyStatus.lightDrink => const Color(0xFF58D6FF),
    NomoDailyStatus.wantDrinkHard => const Color(0xFFFFC857),
    NomoDailyStatus.nonAlcohol => const Color(0xFF5DEBD3),
    NomoDailyStatus.liverRest => const Color(0xFFFF5EA8),
    NomoDailyStatus.waitingInvite => const Color(0xFFC08BFF),
    NomoDailyStatus.hasPlans => const Color(0xFFB8C1CD),
    NomoDailyStatus.unselected => _FeedColors.sub,
  };
}

class _FeedNotification {
  const _FeedNotification({
    required this.kind,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.icon,
    required this.accent,
    required this.unread,
    this.friendRequestId,
    this.friendRequestStatus,
    this.drinkInviteId,
    this.drinkInviteStatus,
  });

  factory _FeedNotification.fromNotification(NomoNotification notification) {
    return _FeedNotification(
      kind: notification.kind,
      title: notification.title,
      message: notification.message,
      timeAgo: _relativeTimeText(notification.createdAt),
      icon: switch (notification.kind) {
        'drink_log_like' => CupertinoIcons.heart_fill,
        'friend_request_received' => CupertinoIcons.person_badge_plus_fill,
        'friend_request_accepted' => CupertinoIcons.checkmark_seal_fill,
        'drink_invite_received' => CupertinoIcons.calendar_badge_plus,
        'drink_invite_accepted' => CupertinoIcons.checkmark_circle_fill,
        'today_reservation_reminder' => CupertinoIcons.calendar_today,
        'drink_log_tagged' => CupertinoIcons.person_2_fill,
        'system' => CupertinoIcons.bell_fill,
        _ => CupertinoIcons.bell_fill,
      },
      accent: switch (notification.kind) {
        'drink_log_like' => const Color(0xFFFF75B5),
        'friend_request_received' => const Color(0xFF58D6FF),
        'friend_request_accepted' => const Color(0xFF9AF21A),
        'drink_invite_received' => const Color(0xFFC08BFF),
        'drink_invite_accepted' => _FeedColors.teal,
        'today_reservation_reminder' => const Color(0xFFFFD166),
        'drink_log_tagged' => const Color(0xFF58D6FF),
        'system' => const Color(0xFFFFD166),
        _ => _FeedColors.teal,
      },
      unread: notification.isUnread,
      friendRequestId: notification.friendRequestId,
      friendRequestStatus: notification.friendRequestStatus,
      drinkInviteId: notification.drinkInviteId,
      drinkInviteStatus: notification.drinkInviteStatus,
    );
  }

  final String kind;
  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color accent;
  final bool unread;
  final String? friendRequestId;
  final String? friendRequestStatus;
  final String? drinkInviteId;
  final String? drinkInviteStatus;

  bool get canOpen {
    if (kind == 'friend_request_received') {
      return friendRequestId != null && friendRequestId!.isNotEmpty;
    }
    if (kind == 'drink_invite_received') {
      return drinkInviteId != null && drinkInviteId!.isNotEmpty;
    }
    return false;
  }

  String? get actionLabel {
    if (kind == 'friend_request_received') {
      return switch (friendRequestStatus) {
        'accepted' => '承認済み',
        'rejected' => '見送り済み',
        'cancelled' => '取り消し済み',
        _ => 'タップして承認',
      };
    }
    if (kind == 'drink_invite_received') {
      return switch (drinkInviteStatus) {
        'accepted' => '参加予定',
        'rejected' => '見送り済み',
        'cancelled' => '取り消し済み',
        _ => 'タップして返信',
      };
    }
    return null;
  }
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
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF05080D), Color(0xFF111821), Color(0xFF05080D)],
      stops: [0, .48, 1],
    ).createShader(rect);
  canvas.drawRect(rect, background);

  final photo = await _loadSharePhoto(item.photoAssetPath);
  if (photo != null) {
    final blurredBackdropRect = Rect.fromLTWH(-160, 0, width + 320, height);
    _paintCoverImage(
      canvas,
      image: photo,
      target: blurredBackdropRect,
      opacity: .20,
    );
    canvas.drawRect(
      rect,
      Paint()..color = const Color(0xFF05080D).withValues(alpha: .70),
    );
  }

  const cardWidth = 930.0;
  const cardHorizontalPadding = 42.0;
  const cardTopPadding = 42.0;
  const photoWidth = cardWidth - cardHorizontalPadding * 2;
  const photoHeight = photoWidth * 9 / 16;
  const textTopGap = 38.0;
  const captionFontSize = 54.0;
  const metaFontSize = 34.0;
  const metaGap = 16.0;
  const cardBottomPadding = 44.0;
  const cardHeight =
      cardTopPadding +
      photoHeight +
      textTopGap +
      captionFontSize * 1.20 +
      metaGap +
      metaFontSize * 1.18 +
      cardBottomPadding;
  const cardLeft = (width - cardWidth) / 2;
  const cardTop = (height - cardHeight) / 2;
  final cardRect = Rect.fromLTWH(cardLeft, cardTop, cardWidth, cardHeight);
  final cardRRect = RRect.fromRectAndRadius(cardRect, const Radius.circular(4));

  canvas.drawRRect(
    cardRRect.shift(const Offset(0, 18)),
    Paint()
      ..color = Colors.black.withValues(alpha: .26)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
  );
  canvas.drawRRect(cardRRect, Paint()..color = Colors.white);

  final photoRect = Rect.fromLTWH(
    cardLeft + cardHorizontalPadding,
    cardTop + cardTopPadding,
    photoWidth,
    photoHeight,
  );
  final photoRRect = RRect.fromRectAndRadius(
    photoRect,
    const Radius.circular(2),
  );
  if (photo != null) {
    canvas.save();
    canvas.clipRRect(photoRRect);
    _paintCoverImage(canvas, image: photo, target: photoRect);
    canvas.restore();
    photo.dispose();
  } else {
    canvas.drawRRect(
      photoRRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF0A8D), Color(0xFF21D6C4)],
        ).createShader(photoRect),
    );
  }

  final title = item.body.trim().isNotEmpty ? item.body.trim() : item.userName;
  final captionTop = photoRect.bottom + textTopGap;
  _paintShareText(
    canvas,
    title,
    x: photoRect.left,
    y: captionTop,
    maxWidth: photoRect.width,
    size: captionFontSize,
    weight: FontWeight.w700,
    color: const Color(0xFF111111),
    maxLines: 1,
  );
  _paintShareText(
    canvas,
    item.timeAgo,
    x: photoRect.left,
    y: captionTop + captionFontSize * 1.20 + metaGap,
    maxWidth: photoRect.width,
    size: metaFontSize,
    weight: FontWeight.w700,
    color: const Color(0xFF8D8D8D),
    maxLines: 1,
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

Future<ui.Image?> _loadSharePhoto(String? path) async {
  final normalized = path?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  try {
    late final Uint8List bytes;
    if (normalized.startsWith('/')) {
      final file = File(normalized);
      if (!await file.exists()) return null;
      bytes = await file.readAsBytes();
    } else if (normalized.startsWith('http://') ||
        normalized.startsWith('https://')) {
      final uri = Uri.tryParse(normalized);
      if (uri == null) return null;
      final request = await HttpClient().getUrl(uri);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      bytes = await consolidateHttpClientResponseBytes(response);
    } else if (normalized.startsWith('assets/')) {
      final data = await rootBundle.load(normalized);
      bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } else {
      return null;
    }
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

void _paintCoverImage(
  Canvas canvas, {
  required ui.Image image,
  required Rect target,
  double opacity = 1,
}) {
  final source = Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    image.height.toDouble(),
  );
  final imageAspect = image.width / image.height;
  final targetAspect = target.width / target.height;
  Rect sourceCrop;
  if (imageAspect > targetAspect) {
    final cropWidth = image.height * targetAspect;
    sourceCrop = Rect.fromLTWH(
      (image.width - cropWidth) / 2,
      0,
      cropWidth,
      image.height.toDouble(),
    );
  } else {
    final cropHeight = image.width / targetAspect;
    sourceCrop = Rect.fromLTWH(
      0,
      (image.height - cropHeight) / 2,
      image.width.toDouble(),
      cropHeight,
    );
  }
  final paint = Paint()..filterQuality = ui.FilterQuality.high;
  if (opacity < 1) {
    paint.colorFilter = ColorFilter.mode(
      Colors.white.withValues(alpha: opacity),
      BlendMode.modulate,
    );
  }
  canvas.drawImageRect(image, sourceCrop.intersect(source), target, paint);
}

void _paintShareText(
  Canvas canvas,
  String text, {
  required double x,
  required double y,
  required double maxWidth,
  required double size,
  required FontWeight weight,
  required Color color,
  int? maxLines,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: 1.18,
        letterSpacing: -0.8,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);
  painter.paint(canvas, Offset(x, y));
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
