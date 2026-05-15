import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PageController _feedPageController;
  _FeedSection _selectedSection = _FeedSection.feed;

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
                hasUnreadNotifications: false,
                onNotifications: () => Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (_) => _FeedNotificationsScreen(
                      notifications: const <_FeedNotification>[],
                    ),
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
}

Widget _buildFeedSectionPage({
  required _FeedSection section,
  required List<_FeedItem> items,
  required bool isWhite,
  required AsyncValue<List<DrinkLog>> logsAsync,
  required ValueChanged<_FeedItem> onLikePressed,
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
    required this.onNotifications,
    required this.hasUnreadNotifications,
  });

  final VoidCallback onNotifications;
  final bool hasUnreadNotifications;

  @override
  Widget build(BuildContext context) {
    return NomoPageHeader(
      title: 'フィード',
      titleColor: _FeedColors.teal,
      trailing: NomoHeaderIconButton(
        icon: CupertinoIcons.bell,
        semanticLabel: 'お知らせを開く',
        hasDot: hasUnreadNotifications,
        color: _FeedColors.teal,
        onTap: onNotifications,
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isWhite
            ? Colors.white
            : const Color(0xFF0C1724).withValues(alpha: .78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFDCE4EC)
              : Colors.white.withValues(alpha: .08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .06 : .18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SizedBox(
        height: 50,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final sections = _FeedSection.values;
            final tabWidth = constraints.maxWidth / sections.length;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  left: selected.index * tabWidth + 2,
                  top: 0,
                  bottom: 0,
                  width: tabWidth - 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          selected.accent,
                          selected.accent.withValues(alpha: .76),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(19),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected.accent.withValues(alpha: .30),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
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
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Semantics(
        button: true,
        selected: selected,
        label: '${section.label}タブ',
        child: CupertinoButton(
          onPressed: selected ? null : onTap,
          minimumSize: const Size(0, 44),
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            width: double.infinity,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    style:
                        Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: selected
                              ? const Color(0xFF062327)
                              : _FeedColors.sub,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.35,
                        ) ??
                        TextStyle(
                          color: selected
                              ? const Color(0xFF062327)
                              : _FeedColors.sub,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.35,
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
  );
}

class _FeedSectionEmptyState extends StatelessWidget {
  const _FeedSectionEmptyState({required this.section, required this.isWhite});

  final _FeedSection section;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final title = switch (section) {
      _FeedSection.feed => 'まだ投稿がありません',
      _FeedSection.following => 'フレンズの投稿はまだありません',
      _FeedSection.official => '公式のお知らせはまだありません',
    };
    final message = switch (section) {
      _FeedSection.feed => '乾杯ログを追加するとフィードに表示されます。',
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
  final action = await showCupertinoModalPopup<_FeedPostAction>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      title: Text(item.userName),
      message: Text(item.body),
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(_FeedPostAction.copy),
          child: const Text('投稿内容をコピー'),
        ),
        if (item.ownedByMe)
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(_FeedPostAction.delete),
            child: const Text('投稿を削除'),
          )
        else
          CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(_FeedPostAction.report),
            child: const Text('投稿を報告'),
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
      await Clipboard.setData(ClipboardData(text: item.body));
      if (context.mounted) NomoToast.show(context, '投稿内容をコピーしました');
    case _FeedPostAction.delete:
      final confirmed = await _confirmDeleteFeedPost(context);
      if (!confirmed || !context.mounted) return;
      await ref.read(drinkLogControllerProvider.notifier).deleteLog(item.id);
      if (context.mounted) NomoToast.show(context, '投稿を削除しました');
    case _FeedPostAction.report:
      await ref.read(drinkLogControllerProvider.notifier).reportLog(item.id);
      if (context.mounted) NomoToast.show(context, '投稿を報告しました');
  }
}

Future<bool> _confirmDeleteFeedPost(BuildContext context) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('投稿を削除しますか？'),
      content: const Text('削除した投稿は元に戻せません。'),
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
  const _FeedPostCard({required this.item, this.onLike, this.onMore});

  final _FeedItem item;
  final VoidCallback? onLike;
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
            const SizedBox(height: 12),
          ] else
            const SizedBox(height: 10),
          Text(
            _duoStyleBody(item),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: ink.withValues(alpha: .88),
              fontWeight: FontWeight.w800,
              height: 1.35,
              letterSpacing: -.35,
            ),
          ),
          const SizedBox(height: 18),
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
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

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
            NomoPopIcon(
              icon: icon,
              color: effectiveIconColor,
              size: 27,
              showBubble: false,
            ),
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
        ),
      ),
    );
  }
}

bool _isDisplayablePostPhoto(String? path) {
  if (path == null || path.isEmpty) return false;
  return !path.startsWith('nomo_memory_template_');
}

String _duoStyleBody(_FeedItem item) {
  if (item.userName.contains('公式')) {
    return switch (item.prop) {
      _PostProp.spark => 'Nomoで飲み友との思い出をもっと楽しく残せるようになったよ！',
      _PostProp.ticket => 'フレンズと一緒に今月の乾杯ログをふり返ろう。',
      _ => item.body,
    };
  }
  return '${item.userName}さんが「${item.body}」を記録したよ！';
}

class _PostPhoto extends StatelessWidget {
  const _PostPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: Image.asset(
      path,
      height: 150,
      width: double.infinity,
      fit: BoxFit.cover,
    ),
  );
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

class _FeedNotificationsScreen extends StatelessWidget {
  const _FeedNotificationsScreen({required this.notifications});

  final List<_FeedNotification> notifications;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final unreadCount = notifications.where((n) => n.unread).length;

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
                      Row(
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
                              child: NomoPopIcon(
                                icon: CupertinoIcons.chevron_left,
                                color: isWhite
                                    ? const Color(0xFF27313B)
                                    : Colors.white,
                                size: 24,
                                showBubble: false,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'お知らせ',
                            style: TextStyle(
                              color: isWhite
                                  ? const Color(0xFF27313B)
                                  : Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.8,
                            ),
                          ),
                          const Spacer(),
                          _UnreadPill(count: unreadCount, isWhite: isWhite),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (notifications.isEmpty)
                        _FeedEmptyState(
                          icon: CupertinoIcons.bell,
                          isWhite: isWhite,
                          title: 'まだお知らせはありません',
                          message: 'フレンズの反応がここに届きます。',
                        )
                      else
                        ...notifications.map(
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

class _UnreadPill extends StatelessWidget {
  const _UnreadPill({required this.count, required this.isWhite});

  final int count;
  final bool isWhite;

  @override
  Widget build(BuildContext context) {
    final bgColor = isWhite
        ? _FeedColors.teal.withValues(alpha: .16)
        : _FeedColors.teal.withValues(alpha: .16);
    final borderColor = isWhite
        ? _FeedColors.teal.withValues(alpha: .24)
        : _FeedColors.teal.withValues(alpha: .24);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        count == 0 ? '既読' : '未読 $count',
        style: const TextStyle(
          color: _FeedColors.teal,
          fontSize: 11,
          fontWeight: FontWeight.w900,
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

String _oneLineMemo(String memo, {required String fallback}) {
  final compact = memo.trim().replaceAll(RegExp(r'\s+'), '');
  final value = compact.isEmpty ? fallback.trim() : compact;
  if (value.characters.length <= 15) return value;
  return value.characters.take(15).toString();
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
      body: _oneLineMemo(
        log.memo,
        fallback: log.place.isEmpty ? '乾杯したよ' : log.place,
      ),
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

  final String title;
  final String message;
  final String timeAgo;
  final IconData icon;
  final Color accent;
  final bool unread;
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
