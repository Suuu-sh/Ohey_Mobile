part of 'admin_screen.dart';

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({
    required this.user,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminUserProfile user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => _AdminCard(
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (user.isPlus) ...[
                    const SizedBox(width: 8),
                    const _AdminBadge(label: 'PLUS'),
                  ],
                ],
              ),
              const SizedBox(height: 5),
              Text(
                '@${user.userId}',
                style: const TextStyle(
                  color: _AdminColors.lime,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${_adminGenderLabel(user.gender)} / ${_adminStatusLabel(user.status)}',
                style: const TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                user.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        _AdminIconButton(icon: CupertinoIcons.pencil, onTap: onEdit),
        const SizedBox(width: 8),
        _AdminIconButton(
          icon: CupertinoIcons.trash,
          destructive: true,
          onTap: onDelete,
        ),
      ],
    ),
  );
}

class _AdminPostCard extends StatelessWidget {
  const _AdminPostCard({
    required this.memory,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminMemory memory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => _AdminCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                memory.placeName.isEmpty ? '場所未設定の思い出' : memory.placeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (memory.isOfficial) ...[
              const _AdminBadge(label: '公式'),
              const SizedBox(width: 8),
            ],
            _AdminIconButton(icon: CupertinoIcons.pencil, onTap: onEdit),
            const SizedBox(width: 8),
            _AdminIconButton(
              icon: CupertinoIcons.trash,
              destructive: true,
              onTap: onDelete,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '${memory.ownerDisplayName} @${memory.ownerHandle}',
          style: const TextStyle(
            color: _AdminColors.lime,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (memory.memo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            memory.memo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AdminColors.sub,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (memory.linkUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            memory.linkUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AdminColors.lime,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _dateLabel(memory.happenedAt),
          style: const TextStyle(
            color: _AdminColors.sub,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    ),
  );
}

Future<void> _showUserSheet(
  BuildContext context,
  WidgetRef ref, {
  AdminUserProfile? user,
}) async {
  final saved = await Navigator.of(context).push<bool>(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (_) => _AdminUserEditorScreen(user: user),
    ),
  );
  if (saved == true && context.mounted) {
    ref.invalidate(adminUsersProvider);
    ref.invalidate(friendsProvider);
    OheyToast.show(context, 'ユーザーを保存しました。');
  }
}
