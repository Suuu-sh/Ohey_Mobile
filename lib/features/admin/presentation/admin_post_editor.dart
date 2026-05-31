part of 'admin_screen.dart';

class _AdminPostEditorSheet extends ConsumerStatefulWidget {
  const _AdminPostEditorSheet({required this.memory, required this.users});

  final AdminMemory? memory;
  final List<AdminUserProfile> users;

  @override
  ConsumerState<_AdminPostEditorSheet> createState() =>
      _AdminPostEditorSheetState();
}

class _AdminPostEditorSheetState extends ConsumerState<_AdminPostEditorSheet> {
  late final TextEditingController _placeController;
  late final TextEditingController _memoController;
  late final TextEditingController _linkController;
  late final TextEditingController _ownerController;
  late String _ownerUserId;
  late bool _isOfficial;
  bool _saving = false;
  String? _error;

  AdminMemory? get _log => widget.memory;

  @override
  void initState() {
    super.initState();
    final memory = _log;
    _placeController = TextEditingController(text: memory?.placeName ?? '');
    _memoController = TextEditingController(text: memory?.memo ?? '');
    _linkController = TextEditingController(text: memory?.linkUrl ?? '');
    _ownerController = TextEditingController(text: memory?.ownerUserId ?? '');
    _ownerUserId = memory != null && !memory.isOfficial
        ? memory.ownerUserId
        : (widget.users.isNotEmpty ? widget.users.first.id : '');
    _isOfficial = memory?.isOfficial ?? false;
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _placeController.dispose();
    _memoController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final memory = _log;

    return _AdminSheet(
      title: memory == null ? '思い出作成' : '思い出編集',
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
                      title: 'Ohey公式として投稿します',
                      message: 'Ohey公式として届けるよ。',
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
              label: memory == null ? '作成する' : '保存する',
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
      final memory = _log;
      if (memory == null) {
        await ref
            .read(adminControllerProvider)
            .createMemory(
              ownerUserId: _isOfficial ? null : _ownerUserId,
              placeName: _placeController.text.trim(),
              memo: _memoController.text.trim(),
              linkUrl: _linkController.text.trim(),
              isOfficial: _isOfficial,
            );
      } else {
        await ref
            .read(adminControllerProvider)
            .updateMemory(
              id: memory.id,
              ownerUserId: _isOfficial ? null : _ownerUserId,
              placeName: _placeController.text.trim(),
              memo: _memoController.text.trim(),
              linkUrl: _linkController.text.trim(),
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
