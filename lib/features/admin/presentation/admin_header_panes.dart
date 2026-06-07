part of 'admin_screen.dart';

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _AdminColors.lime.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const OheyGeneratedIcon(
            CupertinoIcons.lock_shield_fill,
            color: _AdminColors.lime,
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '管理画面',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -.8,
                ),
              ),
              Text(
                'Ohey ${SupabaseConfig.environment} admin',
                style: const TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onClose,
          icon: const OheyGeneratedIcon(
            CupertinoIcons.xmark,
            color: AppColors.white,
            size: 26,
          ),
        ),
      ],
    );
  }
}

class _AdminSegmentedControl extends StatelessWidget {
  const _AdminSegmentedControl({
    required this.section,
    required this.onChanged,
  });

  final _AdminSection section;
  final ValueChanged<_AdminSection> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _AdminColors.line),
      ),
      child: Row(
        children: [
          _AdminSegmentButton(
            label: 'ユーザー',
            selected: section == _AdminSection.users,
            onTap: () => onChanged(_AdminSection.users),
          ),
          _AdminSegmentButton(
            label: 'ゆるぼ',
            selected: section == _AdminSection.yurubos,
            onTap: () => onChanged(_AdminSection.yurubos),
          ),
          _AdminSegmentButton(
            label: '通知',
            selected: section == _AdminSection.notifications,
            onTap: () => onChanged(_AdminSection.notifications),
          ),
        ],
      ),
    );
  }
}


class _AdminSmallActionButton extends StatelessWidget {
  const _AdminSmallActionButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _AdminColors.lime.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(14),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: _AdminColors.lime,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _AdminSegmentButton extends StatelessWidget {
  const _AdminSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _AdminColors.lime : AppColors.transparent,
            borderRadius: BorderRadius.circular(17),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.cFF101820 : _AdminColors.sub,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    ),
  );
}

class _AdminUsersPane extends StatelessWidget {
  const _AdminUsersPane({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Column(
      children: [
        _AdminPaneToolbar(
          title: 'ユーザー管理',
          actionLabel: '追加',
          onAction: () => _showUserSheet(context, ref),
          onRefresh: () => ref.invalidate(adminUsersProvider),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: usersAsync.when(
            data: (users) {
              if (users.isEmpty) {
                return const _AdminEmptyState(message: 'ユーザーがまだいません。');
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 120),
                itemBuilder: (context, index) => _AdminUserCard(
                  user: users[index],
                  onEdit: () =>
                      _showUserSheet(context, ref, user: users[index]),
                  onDelete: () =>
                      _confirmDeleteUser(context, ref, users[index]),
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: users.length,
              );
            },
            loading: () => const Center(
              child: CupertinoActivityIndicator(color: _AdminColors.lime),
            ),
            error: (error, _) => _AdminErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(adminUsersProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminYurubosPane extends ConsumerStatefulWidget {
  const _AdminYurubosPane();

  @override
  ConsumerState<_AdminYurubosPane> createState() => _AdminYurubosPaneState();
}

class _AdminYurubosPaneState extends ConsumerState<_AdminYurubosPane> {
  String _status = OheyStatusKeys.open;

  @override
  Widget build(BuildContext context) {
    final yurubosAsync = ref.watch(adminYurubosProvider(_status));
    return Column(
      children: [
        _AdminPaneToolbar(
          title: 'ゆるぼ管理',
          actionLabel: '作成',
          onAction: () => _showYuruboSheet(context, ref),
          onRefresh: () => ref.invalidate(adminYurubosProvider(_status)),
        ),
        _AdminFilterChips(
          options: _adminYuruboStatusFilters,
          value: _status,
          onChanged: (value) => setState(() => _status = value),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: yurubosAsync.when(
            data: (yurubos) {
              if (yurubos.isEmpty) {
                return const _AdminEmptyState(message: 'ゆるぼがまだありません。');
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 120),
                itemBuilder: (context, index) => _AdminYuruboCard(
                  yurubo: yurubos[index],
                  onEdit: () =>
                      _showYuruboSheet(context, ref, yurubo: yurubos[index]),
                  onDelete: () =>
                      _confirmDeleteYurubo(context, ref, yurubos[index]),
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: yurubos.length,
              );
            },
            loading: () => const Center(
              child: CupertinoActivityIndicator(color: _AdminColors.lime),
            ),
            error: (error, _) => _AdminErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(adminYurubosProvider(_status)),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminNotificationsPane extends ConsumerStatefulWidget {
  const _AdminNotificationsPane();

  @override
  ConsumerState<_AdminNotificationsPane> createState() =>
      _AdminNotificationsPaneState();
}

class _AdminNotificationsPaneState
    extends ConsumerState<_AdminNotificationsPane> {
  String _status = OheyStatusKeys.failed;
  bool _processing = false;
  AdminNotificationOutboxProcessResult? _lastProcessResult;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final outboxAsync = ref.watch(adminNotificationOutboxProvider(_status));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdminPaneToolbar(
          title: '通知運用',
          actionLabel: '作成',
          onAction: () => _showNotificationSheet(context, ref),
          onRefresh: () {
            ref.invalidate(adminUsersProvider);
            ref.invalidate(adminNotificationOutboxProvider(_status));
          },
        ),
        const SizedBox(height: 12),
        _AdminInfoBox(
          title: usersAsync.maybeWhen(
            data: (users) => 'System通知と Outbox を管理',
            orElse: () => 'System通知と Outbox を管理',
          ),
          message: usersAsync.maybeWhen(
            data: (users) =>
                '送信対象 ${users.length} 人。失敗/待機中の push outbox はここから手動で再処理できます。',
            orElse: () => '全体・個別 System通知の作成と、push outbox の状態確認/再処理を行います。',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AdminFilterChips(
                options: _adminOutboxStatusFilters,
                value: _status,
                onChanged: (value) => setState(() => _status = value),
              ),
            ),
            const SizedBox(width: 10),
            _AdminSmallActionButton(
              label: _processing ? '処理中' : '再処理',
              onTap: _processOutbox,
            ),
          ],
        ),
        if (_lastProcessResult != null) ...[
          const SizedBox(height: 10),
          _AdminInfoBox(
            title: 'Outbox再処理結果',
            message:
                '成功 ${_lastProcessResult!.processedCount} 件 / 失敗 ${_lastProcessResult!.failedCount} 件 / スキップ ${_lastProcessResult!.skippedCount} 件',
          ),
        ],
        const SizedBox(height: 12),
        Expanded(
          child: outboxAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _AdminEmptyState(message: 'Outbox は空です。');
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 120),
                itemBuilder: (context, index) =>
                    _AdminOutboxCard(item: items[index]),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: items.length,
              );
            },
            loading: () => const Center(
              child: CupertinoActivityIndicator(color: _AdminColors.lime),
            ),
            error: (error, _) => _AdminErrorState(
              message: '$error',
              onRetry: () =>
                  ref.invalidate(adminNotificationOutboxProvider(_status)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _processOutbox() async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _lastProcessResult = null;
    });
    try {
      final result = await ref
          .read(adminControllerProvider)
          .processNotificationOutbox(limit: 50);
      _invalidateAdminOutboxProviders(ref);
      if (!mounted) return;
      setState(() {
        _processing = false;
        _lastProcessResult = result;
      });
      OheyToast.show(
        context,
        'Outboxを再処理しました（成功 ${result.processedCount} / 失敗 ${result.failedCount}）',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      OheyToast.show(context, 'Outboxを再処理できませんでした: $e');
    }
  }
}

class _AdminOutboxCard extends StatelessWidget {
  const _AdminOutboxCard({required this.item});

  final AdminNotificationOutboxItem item;

  @override
  Widget build(BuildContext context) {
    final payloadTitle = _adminOutboxPayloadTitle(item.payload);
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminBadge(label: _adminOutboxStatusLabel(item.status)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _adminOutboxEventLabel(item.eventKind),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (payloadTitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              payloadTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            [
              if (item.recipientUserId.isNotEmpty)
                'to ${_shortAdminId(item.recipientUserId)}',
              if (item.actorUserId.isNotEmpty)
                'actor ${_shortAdminId(item.actorUserId)}',
              'attempts ${item.attempts}',
            ].join(' / '),
            style: const TextStyle(
              color: _AdminColors.sub,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          if ((item.lastError ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item.lastError!.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AdminColors.pink,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ],
          if (item.createdAt != null || item.nextAttemptAt != null) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (item.createdAt != null) '作成 ${_dateLabel(item.createdAt!)}',
                if (item.nextAttemptAt != null)
                  '次回 ${_dateLabel(item.nextAttemptAt!)}',
              ].join(' / '),
              style: const TextStyle(
                color: _AdminColors.sub,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminPaneToolbar extends StatelessWidget {
  const _AdminPaneToolbar({
    required this.title,
    required this.actionLabel,
    required this.onAction,
    required this.onRefresh,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
      const Spacer(),
      IconButton(
        onPressed: onRefresh,
        icon: const OheyGeneratedIcon(
          CupertinoIcons.arrow_clockwise,
          color: _AdminColors.sub,
          size: 22,
        ),
      ),
      _AdminSmallButton(label: actionLabel, onTap: onAction),
    ],
  );
}
