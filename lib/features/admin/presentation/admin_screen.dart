import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/nomo_gender.dart';
import '../../../core/models/nomo_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../application/admin_controller.dart';

enum _AdminSection { users, posts, notifications }

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  _AdminSection _section = _AdminSection.users;

  @override
  Widget build(BuildContext context) {
    final access = ref.watch(adminAccessProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _AdminColors.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(
            children: [
              _AdminHeader(onClose: () => Navigator.of(context).pop()),
              const SizedBox(height: 16),
              access.when(
                data: (allowed) => allowed
                    ? _AdminSegmentedControl(
                        section: _section,
                        onChanged: (section) =>
                            setState(() => _section = section),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: access.when(
                  data: (allowed) {
                    if (!allowed) return const _AdminDeniedState();
                    return switch (_section) {
                      _AdminSection.users => _AdminUsersPane(ref: ref),
                      _AdminSection.posts => _AdminPostsPane(ref: ref),
                      _AdminSection.notifications => _AdminNotificationsPane(
                        ref: ref,
                      ),
                    };
                  },
                  loading: () => const Center(
                    child: CupertinoActivityIndicator(color: _AdminColors.lime),
                  ),
                  error: (error, _) => _AdminErrorState(
                    message: '管理者確認に失敗しました: $error',
                    onRetry: () => ref.invalidate(adminAccessProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            label: '飲みログ',
            selected: section == _AdminSection.posts,
            onTap: () => onChanged(_AdminSection.posts),
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
          title: '飲みログ管理',
          actionLabel: '作成',
          onAction: () => _showPostSheet(context, ref),
          onRefresh: () => ref.invalidate(adminDrinkLogsProvider),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return const _AdminEmptyState(message: '飲みログがまだありません。');
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
          title: '通常通知画面に表示されます',
          message:
              'POST /v1/admin/notifications を使って kind=system の通知を作成します。送信先は全ユーザー、または個別ユーザーを選べます。',
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
                        color: Colors.white,
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
    required this.log,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminDrinkLog log;
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
                log.placeName.isEmpty ? '場所未設定の飲みログ' : log.placeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (log.isOfficial) ...[
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
          '${log.ownerDisplayName} @${log.ownerHandle}',
          style: const TextStyle(
            color: _AdminColors.lime,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (log.memo.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            log.memo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AdminColors.sub,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (log.linkUrl.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            log.linkUrl,
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
          _dateLabel(log.drankAt),
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
    NomoToast.show(context, 'ユーザーを保存しました。');
  }
}

class _AdminUserEditorScreen extends ConsumerStatefulWidget {
  const _AdminUserEditorScreen({this.user});

  final AdminUserProfile? user;

  @override
  ConsumerState<_AdminUserEditorScreen> createState() =>
      _AdminUserEditorScreenState();
}

class _AdminUserEditorScreenState
    extends ConsumerState<_AdminUserEditorScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _userIdController;
  late final TextEditingController _displayNameController;
  late bool _isPlus;
  late String _gender;
  late String _status;
  bool _saving = false;
  String? _error;

  AdminUserProfile? get _user => widget.user;

  @override
  void initState() {
    super.initState();
    final user = _user;
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _userIdController = TextEditingController(text: user?.userId ?? '');
    _displayNameController = TextEditingController(
      text: user?.displayName ?? '',
    );
    _isPlus = user?.isPlus ?? false;
    _gender = _adminNormalizeGender(user?.gender ?? NomoGender.unspecified.key);
    _status = _adminNormalizeStatus(
      user?.status ?? NomoDailyStatus.unselected.key,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _userIdController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final user = _user;
      if (user == null) {
        await ref
            .read(adminControllerProvider)
            .createUser(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
              userId: _userIdController.text.trim(),
              displayName: _displayNameController.text.trim(),
              gender: _gender,
              status: _status,
              isPlus: _isPlus,
            );
      } else {
        await ref
            .read(adminControllerProvider)
            .updateUser(
              id: user.id,
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              password: _passwordController.text.trim().isEmpty
                  ? null
                  : _passwordController.text.trim(),
              userId: _userIdController.text.trim(),
              displayName: _displayNameController.text.trim(),
              status: _status,
              isPlus: _isPlus,
            );
      }
      if (!mounted) return;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pop(true);
    } on BackendApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _AdminColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      user == null ? 'ユーザー追加' : 'ユーザー編集',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 26,
                        letterSpacing: -.8,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _saving
                        ? null
                        : () => Navigator.of(context).pop(false),
                    icon: const NomoGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AdminInput(
                controller: _emailController,
                label: user == null ? 'メールアドレス' : 'メールアドレス（変更時のみ）',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              _AdminInput(
                controller: _passwordController,
                label: user == null ? '初期パスワード' : '新しいパスワード（任意）',
                obscureText: true,
              ),
              const SizedBox(height: 10),
              _AdminInput(controller: _userIdController, label: 'ユーザーID'),
              const SizedBox(height: 10),
              _AdminInput(controller: _displayNameController, label: '表示名'),
              const SizedBox(height: 10),
              if (user == null)
                _AdminGenderDropdown(
                  label: '性別',
                  value: _gender,
                  onChanged: (value) {
                    if (value != null) setState(() => _gender = value);
                  },
                )
              else
                _AdminReadOnlyInfoRow(
                  label: '性別',
                  value: _adminGenderLabel(user.gender),
                ),
              const SizedBox(height: 10),
              _AdminStatusDropdown(
                label: 'ステータス',
                value: _status,
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 10),
              _AdminSwitchRow(
                label: 'Nomo Plus',
                value: _isPlus,
                onChanged: (value) => setState(() => _isPlus = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: _AdminColors.pink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _AdminPrimaryButton(
                label: user == null ? '追加する' : '保存する',
                busy: _saving,
                onTap: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showPostSheet(
  BuildContext context,
  WidgetRef ref, {
  AdminDrinkLog? log,
}) async {
  final users =
      ref.read(adminUsersProvider).asData?.value ?? const <AdminUserProfile>[];
  final placeController = TextEditingController(text: log?.placeName ?? '');
  final memoController = TextEditingController(text: log?.memo ?? '');
  final linkController = TextEditingController(text: log?.linkUrl ?? '');
  final photoController = TextEditingController(text: log?.photoPath ?? '');
  final ownerController = TextEditingController(text: log?.ownerUserId ?? '');
  var ownerUserId = log != null && !log.isOfficial
      ? log.ownerUserId
      : (users.isNotEmpty ? users.first.id : '');
  var isOfficial = log?.isOfficial ?? false;
  var saving = false;
  var didSave = false;
  String? error;

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => _AdminSheet(
          title: log == null ? '飲みログ作成' : '飲みログ編集',
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminSwitchRow(
                  label: '公式投稿として表示',
                  value: isOfficial,
                  onChanged: (value) => setState(() => isOfficial = value),
                ),
                const SizedBox(height: 10),
                if (isOfficial)
                  const _AdminInfoBox(
                    title: 'Nomo公式として投稿します',
                    message: '投稿者は自動で公式アカウントになります。全ユーザーのフィードに表示されます。',
                  )
                else if (users.isEmpty)
                  _AdminInput(
                    label: 'owner_user_id',
                    controller: ownerController,
                    onChanged: (value) => ownerUserId = value,
                  )
                else
                  _AdminDropdown(
                    value: ownerUserId,
                    users: users,
                    onChanged: (value) {
                      if (value != null) setState(() => ownerUserId = value);
                    },
                  ),
                const SizedBox(height: 10),
                _AdminInput(controller: placeController, label: '場所'),
                const SizedBox(height: 10),
                _AdminInput(
                  controller: memoController,
                  label: 'メモ',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                _AdminInput(
                  controller: linkController,
                  label: 'リンクURL（任意・公式投稿の詳しく見る）',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 10),
                _AdminInput(
                  controller: photoController,
                  label: '画像URL/アセットパス（任意・公式投稿の画像）',
                  keyboardType: TextInputType.url,
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: _AdminColors.pink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _AdminPrimaryButton(
                  label: log == null ? '作成する' : '保存する',
                  busy: saving,
                  onTap: () async {
                    setState(() {
                      saving = true;
                      error = null;
                    });
                    try {
                      if (log == null) {
                        await ref
                            .read(adminControllerProvider)
                            .createDrinkLog(
                              ownerUserId: isOfficial ? null : ownerUserId,
                              placeName: placeController.text.trim(),
                              memo: memoController.text.trim(),
                              linkUrl: linkController.text.trim(),
                              photoPath: photoController.text.trim(),
                              isOfficial: isOfficial,
                            );
                      } else {
                        await ref
                            .read(adminControllerProvider)
                            .updateDrinkLog(
                              id: log.id,
                              ownerUserId: isOfficial ? null : ownerUserId,
                              placeName: placeController.text.trim(),
                              memo: memoController.text.trim(),
                              linkUrl: linkController.text.trim(),
                              photoPath: photoController.text.trim(),
                              isOfficial: isOfficial,
                            );
                      }
                      didSave = true;
                      if (sheetContext.mounted) {
                        FocusScope.of(sheetContext).unfocus();
                        Navigator.of(sheetContext).pop();
                      }
                    } on BackendApiException catch (e) {
                      setState(() {
                        saving = false;
                        error = e.message;
                      });
                    } catch (e) {
                      setState(() {
                        saving = false;
                        error = '$e';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } finally {
    await WidgetsBinding.instance.endOfFrame;
    ownerController.dispose();
    placeController.dispose();
    memoController.dispose();
    linkController.dispose();
    photoController.dispose();
  }
  if (didSave && context.mounted) {
    ref.invalidate(adminDrinkLogsProvider);
    NomoToast.show(context, '飲みログを保存しました。');
  }
}

Future<void> _showNotificationSheet(BuildContext context, WidgetRef ref) async {
  final users =
      ref.read(adminUsersProvider).asData?.value ?? const <AdminUserProfile>[];
  final titleController = TextEditingController();
  final messageController = TextEditingController();
  final keyController = TextEditingController();
  var sendToAll = true;
  final selectedUserIds = <String>{};
  var saving = false;
  var didSave = false;
  AdminNotificationResult? result;
  String? error;

  try {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setState) => _AdminSheet(
          title: 'System通知作成',
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminInput(controller: titleController, label: 'タイトル'),
                const SizedBox(height: 10),
                _AdminInput(
                  controller: messageController,
                  label: '本文',
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                _AdminInput(
                  controller: keyController,
                  label: 'system_key（任意・重複防止キー）',
                ),
                const SizedBox(height: 10),
                _AdminSwitchRow(
                  label: '全ユーザーに送る',
                  value: sendToAll,
                  onChanged: (value) => setState(() => sendToAll = value),
                ),
                if (!sendToAll) ...[
                  const SizedBox(height: 10),
                  _AdminRecipientSelector(
                    users: users,
                    selectedUserIds: selectedUserIds,
                    onChanged: () => setState(() {}),
                  ),
                ],
                if (result != null) ...[
                  const SizedBox(height: 10),
                  _AdminInfoBox(
                    title: '送信しました',
                    message:
                        '${result!.createdCount}/${result!.recipientCount} 件の通知を作成しました。',
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    error!,
                    style: const TextStyle(
                      color: _AdminColors.pink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _AdminPrimaryButton(
                  label: '通知を送る',
                  busy: saving,
                  onTap: () async {
                    setState(() {
                      saving = true;
                      error = null;
                      result = null;
                    });
                    try {
                      final sent = await ref
                          .read(adminControllerProvider)
                          .createSystemNotification(
                            title: titleController.text.trim(),
                            message: messageController.text.trim(),
                            sendToAll: sendToAll,
                            recipientUserIds: selectedUserIds.toList(),
                            systemKey: keyController.text.trim(),
                          );
                      didSave = true;
                      setState(() {
                        saving = false;
                        result = sent;
                      });
                    } on BackendApiException catch (e) {
                      setState(() {
                        saving = false;
                        error = e.message;
                      });
                    } catch (e) {
                      setState(() {
                        saving = false;
                        error = '$e';
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } finally {
    await WidgetsBinding.instance.endOfFrame;
    titleController.dispose();
    messageController.dispose();
    keyController.dispose();
  }
  if (didSave && context.mounted) {
    NomoToast.show(context, 'System通知を送信しました。');
  }
}

class _AdminRecipientSelector extends StatelessWidget {
  const _AdminRecipientSelector({
    required this.users,
    required this.selectedUserIds,
    required this.onChanged,
  });

  final List<AdminUserProfile> users;
  final Set<String> selectedUserIds;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _AdminColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '送信先ユーザー',
          style: TextStyle(
            color: _AdminColors.sub,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 10),
        if (users.isEmpty)
          const Text(
            'ユーザー一覧を取得できていません。',
            style: TextStyle(color: _AdminColors.sub),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final user in users)
                _AdminStatusChip(
                  label: user.displayName,
                  selected: selectedUserIds.contains(user.id),
                  onTap: () {
                    if (!selectedUserIds.remove(user.id)) {
                      selectedUserIds.add(user.id);
                    }
                    onChanged();
                  },
                ),
            ],
          ),
      ],
    ),
  );
}

Future<void> _confirmDeleteUser(
  BuildContext context,
  WidgetRef ref,
  AdminUserProfile user,
) async {
  final ok = await _confirmDestructive(
    context,
    title: 'ユーザーを削除しますか？',
    message: '${user.displayName} と関連データが削除されます。',
  );
  if (ok != true) return;
  try {
    await ref.read(adminControllerProvider).deleteUser(user.id);
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminDrinkLogsProvider);
    if (context.mounted) NomoToast.show(context, 'ユーザーを削除しました。');
  } catch (e) {
    if (context.mounted) NomoToast.show(context, '削除できませんでした: $e');
  }
}

Future<void> _confirmDeletePost(
  BuildContext context,
  WidgetRef ref,
  AdminDrinkLog log,
) async {
  final ok = await _confirmDestructive(
    context,
    title: '飲みログを削除しますか？',
    message: log.placeName.isEmpty ? log.id : log.placeName,
  );
  if (ok != true) return;
  try {
    await ref.read(adminControllerProvider).deleteDrinkLog(log.id);
    ref.invalidate(adminDrinkLogsProvider);
    if (context.mounted) NomoToast.show(context, '飲みログを削除しました。');
  } catch (e) {
    if (context.mounted) NomoToast.show(context, '削除できませんでした: $e');
  }
}

Future<bool?> _confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF101B28),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: Text(message, style: const TextStyle(color: _AdminColors.sub)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('削除', style: TextStyle(color: _AdminColors.pink)),
        ),
      ],
    ),
  );
}

class _AdminSheet extends StatelessWidget {
  const _AdminSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF071622),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _AdminColors.line),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
                  icon: const NomoGeneratedIcon(
                    CupertinoIcons.xmark,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );
}

class _AdminInput extends StatelessWidget {
  const _AdminInput({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    maxLines: maxLines,
    onChanged: onChanged,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _AdminColors.sub,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _AdminColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _AdminColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _AdminColors.lime),
      ),
    ),
  );
}

class _AdminDropdown extends StatelessWidget {
  const _AdminDropdown({
    required this.value,
    required this.users,
    required this.onChanged,
  });

  final String value;
  final List<AdminUserProfile> users;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = users.map((user) => user.id).toSet();
    final selectedValue = values.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '飲みログのユーザー',
            style: TextStyle(
              color: _AdminColors.sub,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: const Color(0xFF101B28),
              iconEnabledColor: _AdminColors.lime,
              hint: const Text(
                '投稿者を選択',
                style: TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w800,
                ),
              ),
              items: [
                for (final user in users)
                  DropdownMenuItem(
                    value: user.id,
                    child: Text(
                      '${user.displayName} @${user.userId}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatusDropdown extends StatelessWidget {
  const _AdminStatusDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _adminNormalizeStatus(value);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AdminColors.sub,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in _adminSelectableStatusKeys)
                _AdminStatusChip(
                  label: status.label,
                  selected: status.key == selected,
                  onTap: () => onChanged(status.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminGenderDropdown extends StatelessWidget {
  const _AdminGenderDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _adminNormalizeGender(value);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AdminColors.sub,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final gender in _adminSelectableGenders)
                _AdminStatusChip(
                  label: gender.label,
                  selected: gender.key == selected,
                  onTap: () => onChanged(gender.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminReadOnlyInfoRow extends StatelessWidget {
  const _AdminReadOnlyInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _AdminColors.line),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _AdminColors.sub,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

class _AdminStatusChip extends StatelessWidget {
  const _AdminStatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _AdminColors.lime : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _AdminColors.lime
                  : Colors.white.withValues(alpha: .18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF101820) : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

const _adminSelectableStatusKeys = <NomoDailyStatus>[
  NomoDailyStatus.unselected,
  NomoDailyStatus.canDrinkToday,
  NomoDailyStatus.nonAlcohol,
  NomoDailyStatus.liverRest,
  NomoDailyStatus.hasPlans,
];

const _adminSelectableGenders = <NomoGender>[
  NomoGender.unspecified,
  NomoGender.male,
  NomoGender.female,
];

String _adminStatusLabel(String status) {
  return nomoDailyStatusFromKey(status).label;
}

String _adminGenderLabel(String gender) {
  return nomoGenderFromKey(gender).label;
}

String _adminNormalizeStatus(String status) {
  return nomoDailyStatusFromKey(status).key;
}

String _adminNormalizeGender(String gender) {
  return nomoGenderFromKey(gender).key;
}

class _AdminSwitchRow extends StatelessWidget {
  const _AdminSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _AdminColors.line),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        CupertinoSwitch(
          value: value,
          activeTrackColor: _AdminColors.lime,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _AdminInfoBox extends StatelessWidget {
  const _AdminInfoBox({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _AdminColors.lime.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _AdminColors.lime.withValues(alpha: .28)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          CupertinoIcons.checkmark_seal_fill,
          color: _AdminColors.lime,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _AdminColors.panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _AdminColors.line),
    ),
    child: child,
  );
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _AdminColors.lime.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _AdminColors.lime,
        fontWeight: FontWeight.w900,
        fontSize: 10,
      ),
    ),
  );
}

class _AdminSmallButton extends StatelessWidget {
  const _AdminSmallButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _AdminColors.lime,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF101820),
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _AdminIconButton extends StatelessWidget {
  const _AdminIconButton({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: (destructive ? _AdminColors.pink : _AdminColors.lime).withValues(
          alpha: .14,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: NomoGeneratedIcon(
        icon,
        color: destructive ? _AdminColors.pink : _AdminColors.lime,
        size: 22,
      ),
    ),
  );
}

class _AdminPrimaryButton extends StatelessWidget {
  const _AdminPrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: busy ? null : onTap,
    child: Container(
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _AdminColors.lime,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF5D8B00),
            offset: Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: busy
          ? const CupertinoActivityIndicator(color: Color(0xFF101820))
          : Text(
              label,
              style: const TextStyle(
                color: Color(0xFF101820),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
    ),
  );
}

class _AdminDeniedState extends StatelessWidget {
  const _AdminDeniedState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'このアカウントでは管理画面を開けません。',
      textAlign: TextAlign.center,
      style: TextStyle(color: _AdminColors.sub, fontWeight: FontWeight.w800),
    ),
  );
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      message,
      style: const TextStyle(
        color: _AdminColors.sub,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _AdminColors.pink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _AdminSmallButton(label: '再読み込み', onTap: onRetry),
      ],
    ),
  );
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _AdminColors {
  const _AdminColors._();

  static const bg = AppColors.darkBackground;
  static const panel = Color(0xFF101B28);
  static const line = Color(0x1EFFFFFF);
  static const sub = Color(0xFF8F9BAB);
  static const lime = Color(0xFFB8FF00);
  static const pink = Color(0xFFFF5EA8);
}
