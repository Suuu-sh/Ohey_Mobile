part of 'admin_screen.dart';

class _AdminYuruboEditorSheet extends ConsumerStatefulWidget {
  const _AdminYuruboEditorSheet({required this.yurubo, required this.users});

  final AdminYurubo? yurubo;
  final List<AdminUserProfile> users;

  @override
  ConsumerState<_AdminYuruboEditorSheet> createState() =>
      _AdminYuruboEditorSheetState();
}

class _AdminYuruboEditorSheetState
    extends ConsumerState<_AdminYuruboEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late final TextEditingController _placeController;
  late final TextEditingController _timeController;
  late final TextEditingController _startsAtController;
  late final TextEditingController _ownerController;
  late String _ownerUserId;
  late String _status;
  late String _visibility;
  bool _saving = false;
  String? _error;

  AdminYurubo? get _log => widget.yurubo;

  @override
  void initState() {
    super.initState();
    final yurubo = _log;
    _titleController = TextEditingController(text: yurubo?.title ?? '');
    _bodyController = TextEditingController(text: yurubo?.body ?? '');
    _placeController = TextEditingController(text: yurubo?.placeText ?? '');
    _timeController = TextEditingController(text: yurubo?.timeLabel ?? '');
    _startsAtController = TextEditingController(
      text: yurubo?.startsAt == null ? '' : _adminDateInput(yurubo!.startsAt!),
    );
    _ownerController = TextEditingController(text: yurubo?.ownerUserId ?? '');
    _ownerUserId =
        yurubo?.ownerUserId ??
        (widget.users.isNotEmpty ? widget.users.first.id : '');
    _status = _adminNormalizeYuruboStatus(
      yurubo?.status ?? OheyStatusKeys.open,
    );
    _visibility = _adminNormalizeYuruboVisibility(
      yurubo?.visibility ?? OheyVisibilityKeys.friends,
    );
  }

  @override
  void dispose() {
    _ownerController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _placeController.dispose();
    _timeController.dispose();
    _startsAtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final yurubo = _log;

    return _AdminSheet(
      title: yurubo == null ? 'ゆるぼ作成' : 'ゆるぼ編集',
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AdminOwnerField(
              users: widget.users,
              ownerUserId: _ownerUserId,
              ownerController: _ownerController,
              onOwnerTextChanged: (value) => _ownerUserId = value,
              onOwnerSelected: (value) {
                if (value != null) setState(() => _ownerUserId = value);
              },
            ),
            const SizedBox(height: 10),
            _AdminInput(controller: _titleController, label: 'タイトル'),
            const SizedBox(height: 10),
            _AdminInput(controller: _bodyController, label: '本文', maxLines: 3),
            const SizedBox(height: 10),
            _AdminInput(controller: _placeController, label: '場所'),
            const SizedBox(height: 10),
            _AdminInput(controller: _timeController, label: '時間ラベル'),
            const SizedBox(height: 10),
            _AdminInput(
              controller: _startsAtController,
              label: '開始日（任意・YYYY-MM-DD）',
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: 10),
            _AdminOptionChips(
              label: 'ステータス',
              options: _adminYuruboEditableStatusOptions,
              value: _status,
              onChanged: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 10),
            _AdminOptionChips(
              label: '公開範囲',
              options: _adminYuruboVisibilityOptions,
              value: _visibility,
              onChanged: (value) => setState(() => _visibility = value),
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
              label: yurubo == null ? '作成する' : '保存する',
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
      final yurubo = _log;
      if (yurubo == null) {
        await ref
            .read(adminControllerProvider)
            .createYurubo(
              ownerUserId: _ownerUserId.trim(),
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
              placeText: _placeController.text.trim(),
              timeLabel: _timeController.text.trim(),
              startsAt: _startsAtController.text.trim(),
              status: _status,
              visibility: _visibility,
            );
      } else {
        await ref
            .read(adminControllerProvider)
            .updateYurubo(
              id: yurubo.id,
              ownerUserId: _ownerUserId.trim(),
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
              placeText: _placeController.text.trim(),
              timeLabel: _timeController.text.trim(),
              startsAt: _startsAtController.text.trim(),
              status: _status,
              visibility: _visibility,
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
