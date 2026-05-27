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
      title: log == null ? '思い出作成' : '思い出編集',
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
                      message: 'Nomo公式として届けるよ。',
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
            _AdminPhotoPickerField(
              photoPath: _photoController.text.trim(),
              onPick: _pickPhoto,
              onClear: _clearPhoto,
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

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _photoController.text = picked.path;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '写真を選択できませんでした: $error');
    }
  }

  void _clearPhoto() {
    setState(() {
      _photoController.clear();
      _error = null;
    });
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

class _AdminPhotoPickerField extends StatelessWidget {
  const _AdminPhotoPickerField({
    required this.photoPath,
    required this.onPick,
    required this.onClear,
  });

  final String photoPath;
  final VoidCallback onPick;
  final VoidCallback onClear;

  bool get _hasPhoto => photoPath.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final normalized = photoPath.trim();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '写真（選択式）',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
              if (_hasPhoto)
                SizedBox(
                  width: 62,
                  child: Nomo3DButtonSurface(
                    onTap: onClear,
                    height: 30,
                    radius: 14,
                    color: _AdminColors.pink.withValues(alpha: .16),
                    bottomColor: nomo3DShadowColorFor(
                      _AdminColors.pink,
                      lightnessScale: .56,
                    ),
                    padding: EdgeInsets.zero,
                    borderColor: _AdminColors.pink.withValues(alpha: .28),
                    child: const Text(
                      '削除',
                      style: TextStyle(
                        color: _AdminColors.pink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_hasPhoto) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 1.65,
                child: _AdminSelectedPhotoPreview(path: normalized),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Nomo3DButton(
            label: _hasPhoto ? '写真を変更する' : '写真を選択する',
            icon: CupertinoIcons.photo_on_rectangle,
            onTap: onPick,
            height: 48,
            radius: 18,
            color: _AdminColors.lime,
            foregroundColor: const Color(0xFF101820),
            shadowColor: const Color(0xFF5D8B00),
            fontSize: 14,
          ),
          if (_hasPhoto) ...[
            const SizedBox(height: 8),
            Text(
              normalized.startsWith('/')
                  ? '選択済みの写真を保存時にアップロードします'
                  : '既存の写真が設定されています',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _AdminColors.sub,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminSelectedPhotoPreview extends StatelessWidget {
  const _AdminSelectedPhotoPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('http://') || path.startsWith('https://')
        ? Image.network(path, fit: BoxFit.cover)
        : path.startsWith('assets/')
        ? Image.asset(path, fit: BoxFit.cover)
        : path.startsWith('/')
        ? Image.file(File(path), fit: BoxFit.cover)
        : null;

    if (image == null) {
      return Container(
        color: Colors.black.withValues(alpha: .24),
        alignment: Alignment.center,
        child: const Text(
          '保存済み写真',
          style: TextStyle(
            color: _AdminColors.sub,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }
    return image;
  }
}
