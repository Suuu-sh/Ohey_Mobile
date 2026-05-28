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
          child: const NomoGeneratedIcon(
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
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  letterSpacing: -.8,
                ),
              ),
              Text(
                'Nomo ${SupabaseConfig.environment} admin',
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
          icon: const NomoGeneratedIcon(
            CupertinoIcons.xmark,
            color: Colors.white,
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
        color: Colors.white.withValues(alpha: .06),
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
            label: '思い出',
            selected: section == _AdminSection.posts,
            onTap: () => onChanged(_AdminSection.posts),
          ),
          _AdminSegmentButton(
            label: '通報',
            selected: section == _AdminSection.reports,
            onTap: () => onChanged(_AdminSection.reports),
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

class _AdminReportsPane extends StatelessWidget {
  const _AdminReportsPane({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(adminDrinkLogReportsProvider);
    return Column(
      children: [
        _AdminPaneToolbar(
          title: '通報・モデレーション',
          actionLabel: '更新',
          onAction: () => ref.invalidate(adminDrinkLogReportsProvider),
          onRefresh: () => ref.invalidate(adminDrinkLogReportsProvider),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: reportsAsync.when(
            data: (reports) {
              if (reports.isEmpty) {
                return const _AdminEmptyState(message: '未対応の通報はありません。');
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 120),
                itemBuilder: (context, index) => _AdminReportCard(
                  ref: ref,
                  report: reports[index],
                  onStatus: (status) => _showReportStatusSheet(
                    context,
                    ref,
                    reports[index],
                    status,
                  ),
                  onDeletePost: () =>
                      _confirmDeleteReportedPost(context, ref, reports[index]),
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: reports.length,
              );
            },
            loading: () => const Center(
              child: CupertinoActivityIndicator(color: _AdminColors.lime),
            ),
            error: (error, _) => _AdminErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(adminDrinkLogReportsProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  const _AdminReportCard({
    required this.ref,
    required this.report,
    required this.onStatus,
    required this.onDeletePost,
  });

  final WidgetRef ref;
  final AdminDrinkLogReport report;
  final ValueChanged<String> onStatus;
  final VoidCallback onDeletePost;

  @override
  Widget build(BuildContext context) => _AdminCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _AdminColors.lime.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _adminReportReasonLabel(report.reason),
                style: const TextStyle(
                  color: _AdminColors.lime,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _adminReportStatusLabel(report.status),
              style: const TextStyle(
                color: _AdminColors.sub,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          report.memo.isEmpty ? 'メモなし' : report.memo,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
        if (report.photoPath.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _AdminReportPhotoPreview(ref: ref, path: report.photoPath),
        ],
        const SizedBox(height: 8),
        Text(
          '投稿者: ${report.ownerDisplayName} @${report.ownerHandle}',
          style: const TextStyle(
            color: _AdminColors.sub,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '通報者: ${report.reporterDisplayName} @${report.reporterHandle}',
          style: const TextStyle(
            color: _AdminColors.sub,
            fontWeight: FontWeight.w800,
          ),
        ),
        if ((report.moderationNote ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'メモ: ${report.moderationNote!.trim()}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _AdminSmallActionButton(
              label: '対応中',
              onTap: () => onStatus('reviewing'),
            ),
            _AdminSmallActionButton(
              label: '解決',
              onTap: () => onStatus('resolved'),
            ),
            _AdminSmallActionButton(
              label: '却下',
              destructive: true,
              onTap: () => onStatus('dismissed'),
            ),
            _AdminSmallActionButton(
              label: '投稿削除',
              destructive: true,
              onTap: onDeletePost,
            ),
          ],
        ),
      ],
    ),
  );
}

class _AdminReportPhotoPreview extends StatelessWidget {
  const _AdminReportPhotoPreview({required this.ref, required this.path});

  final WidgetRef ref;
  final String path;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ref.read(adminControllerProvider).displayPhotoUrl(path),
      builder: (context, snapshot) {
        final url = snapshot.data;
        Widget child;
        if (snapshot.connectionState != ConnectionState.done) {
          child = const Center(
            child: CupertinoActivityIndicator(color: _AdminColors.lime),
          );
        } else if (url == null || url.isEmpty) {
          child = const Center(
            child: Text(
              '写真を表示できません',
              style: TextStyle(
                color: _AdminColors.sub,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        } else if (url.startsWith('assets/')) {
          child = Image.asset(url, fit: BoxFit.cover);
        } else if (url.startsWith('/')) {
          child = Image.file(File(url), fit: BoxFit.cover);
        } else {
          child = Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const Center(
              child: Text(
                '写真を表示できません',
                style: TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: .24),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class _AdminSmallActionButton extends StatelessWidget {
  const _AdminSmallActionButton({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: destructive
            ? const Color(0xFFFF5A72).withValues(alpha: .16)
            : _AdminColors.lime.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: destructive
              ? const Color(0xFFFF5A72).withValues(alpha: .35)
              : _AdminColors.lime.withValues(alpha: .35),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: destructive ? const Color(0xFFFF8EA0) : _AdminColors.lime,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    ),
  );
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
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? _AdminColors.lime : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF101820) : _AdminColors.sub,
            fontWeight: FontWeight.w900,
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

class _AdminPostsPane extends StatelessWidget {
  const _AdminPostsPane({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminDrinkLogsProvider);
    return Column(
      children: [
        _AdminPaneToolbar(
          title: '思い出管理',
          actionLabel: '作成',
          onAction: () => _showPostSheet(context, ref),
          onRefresh: () => ref.invalidate(adminDrinkLogsProvider),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const _AdminEmptyState(message: '思い出がまだありません。');
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 120),
                itemBuilder: (context, index) => _AdminPostCard(
                  log: logs[index],
                  onEdit: () => _showPostSheet(context, ref, log: logs[index]),
                  onDelete: () => _confirmDeletePost(context, ref, logs[index]),
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemCount: logs.length,
              );
            },
            loading: () => const Center(
              child: CupertinoActivityIndicator(color: _AdminColors.lime),
            ),
            error: (error, _) => _AdminErrorState(
              message: '$error',
              onRetry: () => ref.invalidate(adminDrinkLogsProvider),
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminNotificationsPane extends StatelessWidget {
  const _AdminNotificationsPane({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AdminPaneToolbar(
          title: 'System通知',
          actionLabel: '作成',
          onAction: () => _showNotificationSheet(context, ref),
          onRefresh: () => ref.invalidate(adminUsersProvider),
        ),
        const SizedBox(height: 12),
        const _AdminInfoBox(
          title: 'アプリ内のお知らせに出るよ',
          message: 'ユーザー全員、または選んだユーザーにお知らせを届けます。',
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ref
              .watch(adminUsersProvider)
              .when(
                data: (users) {
                  if (users.isEmpty) {
                    return const _AdminEmptyState(message: '送信先ユーザーがまだいません。');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemBuilder: (context, index) =>
                        _AdminRecipientPreview(user: users[index]),
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

class _AdminRecipientPreview extends StatelessWidget {
  const _AdminRecipientPreview({required this.user});

  final AdminUserProfile user;

  @override
  Widget build(BuildContext context) => _AdminCard(
    child: Row(
      children: [
        const NomoGeneratedIcon(
          CupertinoIcons.person_crop_circle,
          color: _AdminColors.lime,
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.userId}',
                style: const TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 20,
        ),
      ),
      const Spacer(),
      IconButton(
        onPressed: onRefresh,
        icon: const NomoGeneratedIcon(
          CupertinoIcons.arrow_clockwise,
          color: _AdminColors.sub,
          size: 22,
        ),
      ),
      _AdminSmallButton(label: actionLabel, onTap: onAction),
    ],
  );
}
