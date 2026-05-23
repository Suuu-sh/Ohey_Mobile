part of 'admin_screen.dart';

class _AdminPostEditorSheet extends ConsumerStatefulWidget {
  const _AdminPostEditorSheet({required this.log, required this.users});

  final AdminDrinkLog? log;
  final List<AdminUserProfile> users;

  @override
  ConsumerState<_AdminPostEditorSheet> createState() =>
      _AdminPostEditorSheetState();
}

class _AdminPostEditorSheetState extends ConsumerState<_AdminPostEditorSheet> {
  late final TextEditingController _placeController;
  late final TextEditingController _memoController;
  late final TextEditingController _linkController;
  late final TextEditingController _photoController;
  late final TextEditingController _ownerController;
  late String _ownerUserId;
  late bool _isOfficial;
  bool _saving = false;
  String? _error;

  AdminDrinkLog? get _log => widget.log;

  @override
  void initState() {
    super.initState();
    final log = _log;
    _placeController = TextEditingController(text: log?.placeName ?? '');
    _memoController = TextEditingController(text: log?.memo ?? '');
    _linkController = TextEditingController(text: log?.linkUrl ?? '');
    _photoController = TextEditingController(text: log?.photoPath ?? '');
    _ownerController = TextEditingController(text: log?.ownerUserId ?? '');
    _ownerUserId = log != null && !log.isOfficial
        ? log.ownerUserId
        : (widget.users.isNotEmpty ? widget.users.first.id : '');
    _isOfficial = log?.isOfficial ?? false;
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _placeController.dispose();
    _memoController.dispose();
    _linkController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final log = _log;

    return _AdminSheet(
      title: log == null ? '飲みログ作成' : '飲みログ編集',
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AdminSwitchRow(
              label: '公式投稿として表示',
              value: _isOfficial,
              onChanged: (value) => setState(() => _isOfficial = value),
            ),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _isOfficial
                  ? const _AdminInfoBox(
                      key: ValueKey('official-info'),
                      title: 'Nomo公式として投稿します',
                      message: '公式アカウントとして全員に表示されます。',
                    )
                  : _AdminOwnerField(
                      key: const ValueKey('owner-field'),
                      users: widget.users,
                      ownerUserId: _ownerUserId,
                      ownerController: _ownerController,
                      onOwnerTextChanged: (value) => _ownerUserId = value,
                      onOwnerSelected: (value) {
                        if (value != null) {
                          setState(() => _ownerUserId = value);
                        }
                      },
                    ),
            ),
            const SizedBox(height: 10),
            _AdminInput(controller: _placeController, label: '場所'),
            const SizedBox(height: 10),
            _AdminInput(controller: _memoController, label: 'メモ', maxLines: 3),
            const SizedBox(height: 10),
            _AdminInput(
              controller: _linkController,
              label: 'リンクURL（任意・公式投稿の詳しく見る）',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            _AdminInput(
              controller: _photoController,
              label: '画像URL/アセットパス（任意・公式投稿の画像）',
              keyboardType: TextInputType.url,
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
            const SizedBox(height: 16),
            _AdminPrimaryButton(
              label: log == null ? '作成する' : '保存する',
              busy: _saving,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final log = _log;
      if (log == null) {
        await ref
            .read(adminControllerProvider)
            .createDrinkLog(
              ownerUserId: _isOfficial ? null : _ownerUserId,
              placeName: _placeController.text.trim(),
              memo: _memoController.text.trim(),
              linkUrl: _linkController.text.trim(),
              photoPath: _photoController.text.trim(),
              isOfficial: _isOfficial,
            );
      } else {
        await ref
            .read(adminControllerProvider)
            .updateDrinkLog(
              id: log.id,
              ownerUserId: _isOfficial ? null : _ownerUserId,
              placeName: _placeController.text.trim(),
              memo: _memoController.text.trim(),
              linkUrl: _linkController.text.trim(),
              photoPath: _photoController.text.trim(),
              isOfficial: _isOfficial,
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
}
