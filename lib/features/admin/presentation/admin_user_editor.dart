part of 'admin_screen.dart';

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
    _gender = _adminNormalizeGender(user?.gender ?? OheyGender.unspecified.key);
    _status = _adminNormalizeStatus(
      user?.status ?? OheyDailyStatus.unselected.key,
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
                    icon: const OheyGeneratedIcon(
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
                label: 'Ohey Plus',
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
  AdminMemory? memory,
}) async {
  final users =
      ref.read(adminUsersProvider).asData?.value ?? const <AdminUserProfile>[];
  final didSave = await showOheyBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AdminPostEditorSheet(memory: memory, users: users),
  );

  if (didSave == true && context.mounted) {
    ref.invalidate(adminMemorysProvider);
    OheyToast.show(context, '思い出を保存しました。');
  }
}
