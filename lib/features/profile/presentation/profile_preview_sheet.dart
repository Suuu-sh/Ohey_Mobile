part of 'profile_screen.dart';

class _NomoProfilePreviewSheet extends StatefulWidget {
  const _NomoProfilePreviewSheet({
    required this.profile,
    required this.alreadyFriend,
    required this.requestState,
    required this.onRequest,
  });

  final NomoFriendProfile profile;
  final bool alreadyFriend;
  final NomoFriendRequestState requestState;
  final Future<void> Function() onRequest;

  @override
  State<_NomoProfilePreviewSheet> createState() =>
      _NomoProfilePreviewSheetState();
}

class _NomoProfilePreviewSheetState extends State<_NomoProfilePreviewSheet> {
  bool _busy = false;

  bool get _canRequest =>
      !widget.alreadyFriend &&
      widget.requestState == NomoFriendRequestState.none;

  String get _statusMessage {
    if (widget.alreadyFriend) {
      return 'すでにフレンズです。飲みログに一緒に残せます。';
    }
    return switch (widget.requestState) {
      NomoFriendRequestState.outgoing => 'フレンズ申請を送信済みです。相手の承認を待っています。',
      NomoFriendRequestState.incoming => 'フレンズ申請が届いています。',
      NomoFriendRequestState.none => '申請して、飲みログでつながろう。',
    };
  }

  String get _buttonLabel {
    if (widget.alreadyFriend) return 'フレンズです';
    return switch (widget.requestState) {
      NomoFriendRequestState.outgoing => '申請済み',
      NomoFriendRequestState.incoming => '申請が届いています',
      NomoFriendRequestState.none => 'フレンズ申請を送る',
    };
  }

  IconData get _statusIcon {
    if (widget.alreadyFriend) return CupertinoIcons.checkmark_seal_fill;
    return switch (widget.requestState) {
      NomoFriendRequestState.none => CupertinoIcons.paperplane_fill,
      NomoFriendRequestState.outgoing => CupertinoIcons.clock_fill,
      NomoFriendRequestState.incoming =>
        CupertinoIcons.person_crop_circle_badge_checkmark,
    };
  }

  Color get _statusColor {
    if (widget.alreadyFriend) return const Color(0xFF9AF21A);
    return switch (widget.requestState) {
      NomoFriendRequestState.none => const Color(0xFF22D7C5),
      NomoFriendRequestState.outgoing => const Color(0xFFFFD166),
      NomoFriendRequestState.incoming => const Color(0xFFC08BFF),
    };
  }

  Future<void> _sendRequest() async {
    if (_busy || !_canRequest) return;
    setState(() => _busy = true);
    try {
      await widget.onRequest();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => NomoProfileResultSheet(
    avatar: widget.profile.avatar,
    displayName: widget.profile.displayName,
    subtitle: '@${widget.profile.userId}',
    statusMessage: _statusMessage,
    statusIcon: _statusIcon,
    statusColor: _statusColor,
    actionLabel: _buttonLabel,
    actionIcon: _canRequest ? CupertinoIcons.paperplane_fill : _statusIcon,
    onAction: _canRequest ? _sendRequest : () {},
    backgroundColor: const Color(0xFF071622),
    accentColor: _canRequest ? AppColors.primaryAction : _statusColor,
    onClose: () => Navigator.of(context).pop(),
  );
}

class _MyQrCard extends StatelessWidget {
  const _MyQrCard({
    required this.name,
    required this.handle,
    required this.avatar,
    required this.payload,
    required this.onClose,
    required this.onCopyUserId,
    required this.onSaveQr,
    required this.onScan,
    required this.onSearchUserId,
  });

  final String name;
  final String handle;
  final NomoAvatar? avatar;
  final String payload;
  final VoidCallback onClose;
  final VoidCallback onCopyUserId;
  final VoidCallback onSaveQr;
  final VoidCallback onScan;
  final Future<void> Function(String value) onSearchUserId;

  @override
  Widget build(BuildContext context) {
    const cardColor = Colors.white;
    const titleColor = Color(0xFF33373C);
    const subColor = Color(0xFF7D858E);
    const qrColor = Color(0xFF4B5056);
    const logoBg = Color(0xFFF4F2EE);
    const logoBorder = Colors.white;

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(parent: ClampingScrollPhysics()),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: NomoGeneratedIcon(
                        CupertinoIcons.xmark,
                        color: Color(0xFF4B5056),
                        size: 30,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: subColor,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Stack(
              alignment: Alignment.center,
              children: [
                QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 284,
                  padding: EdgeInsets.zero,
                  backgroundColor: Colors.white,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: qrColor,
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.circle,
                    color: qrColor,
                  ),
                ),
                Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: logoBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: logoBorder, width: 6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .10),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: NomoAvatarView(
                      avatar: avatar ?? NomoAvatar.defaultAvatar,
                      size: 78,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'nomo',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF22D7C5),
                fontWeight: FontWeight.w900,
                letterSpacing: -.8,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _QrActionButton(
                  icon: CupertinoIcons.arrow_down_to_line_alt,
                  label: 'QR保存',
                  color: const Color(0xFF22D7C5),
                  onTap: onSaveQr,
                ),
                _QrActionButton(
                  icon: CupertinoIcons.qrcode_viewfinder,
                  label: 'QR読取',
                  color: const Color(0xFFB188FF),
                  onTap: onScan,
                ),
                _QrActionButton(
                  icon: CupertinoIcons.at,
                  label: 'IDコピー',
                  color: const Color(0xFFFF8A3D),
                  onTap: onCopyUserId,
                ),
              ],
            ),
            const SizedBox(height: 18),
            _QrIdSearchInput(onSearch: onSearchUserId),
          ],
        ),
      ),
    );
  }
}

class _QrActionButton extends StatelessWidget {
  const _QrActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color.lerp(color, Colors.white, .88)!],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE3E4E6), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 12,
                    top: 11,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .95),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  NomoPopIcon(
                    icon: icon,
                    color: color,
                    size: 39,
                    showBubble: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF9BA1A8),
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrIdSearchInput extends StatefulWidget {
  const _QrIdSearchInput({required this.onSearch});

  final Future<void> Function(String value) onSearch;

  @override
  State<_QrIdSearchInput> createState() => _QrIdSearchInputState();
}

class _QrIdSearchInputState extends State<_QrIdSearchInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_scrollIntoViewWhenFocused);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_scrollIntoViewWhenFocused)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _scrollIntoViewWhenFocused() {
    if (!_focusNode.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureInputVisible();
      Future<void>.delayed(
        const Duration(milliseconds: 280),
        _ensureInputVisible,
      );
    });
  }

  void _ensureInputVisible() {
    if (!mounted) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: .86,
    );
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSearch(_controller.text);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE0E4E8), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          NomoGeneratedIcon(
            CupertinoIcons.at,
            color: Color(0xFF5F6872),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                hintText: 'ユーザーIDで検索',
                hintStyle: const TextStyle(
                  color: Color(0xFF8D97A2),
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: const TextStyle(
                color: Color(0xFF202832),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          GestureDetector(
            onTap: _busy ? null : _submit,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF22D7C5),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22D7C5).withValues(alpha: .25),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _busy ? '検索中' : '検索',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
