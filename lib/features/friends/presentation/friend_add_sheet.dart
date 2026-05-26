import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_bottom_sheet.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../logs/application/drink_log_controller.dart';
import '../data/friend_repository.dart';

Future<void> showFriendAddSheet(BuildContext context, WidgetRef ref) {
  return showNomoBottomSheet<void>(
    context: context,
    builder: (_) => _FriendAddSheet(ref: ref),
  );
}

class _FriendAddSheet extends StatefulWidget {
  const _FriendAddSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_FriendAddSheet> createState() => _FriendAddSheetState();
}

class _FriendAddSheetState extends State<_FriendAddSheet> {
  final TextEditingController _controller = TextEditingController();
  NomoFriendProfile? _profile;
  NomoFriendRelationshipStatus? _status;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizedInput(String value) {
    var input = value.trim();
    if (input.startsWith('@')) input = input.substring(1).trim();
    final uri = Uri.tryParse(input);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      input = uri.pathSegments.last.trim();
    }
    return input;
  }

  Future<void> _pasteAndSearch() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) {
      if (!mounted) return;
      setState(() => _error = 'コピーしたIDが見つかりませんでした');
      return;
    }
    _controller.text = _normalizedInput(text);
    await _search();
  }

  Future<void> _copyMyId(String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!mounted) return;
    NomoToast.show(
      context,
      '@$userId をコピーしました',
      icon: CupertinoIcons.doc_on_clipboard_fill,
    );
  }

  Future<void> _copyFriendLink(String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    NomoToast.show(context, 'リンクをコピーしました', icon: CupertinoIcons.link);
  }

  Future<void> _shareFriendLink(String userId, String payload) async {
    HapticFeedback.selectionClick();
    await SharePlus.instance.share(
      ShareParams(title: 'Nomoでつながろ', text: 'Nomoで@$userId とつながろう：$payload'),
    );
  }

  Future<void> _search() async {
    final userId = _normalizedInput(_controller.text);
    _controller.text = userId;
    if (userId.isEmpty) {
      setState(() => _error = 'IDを入力してください');
      return;
    }
    setState(() {
      _isLoading = true;
      _profile = null;
      _status = null;
      _error = null;
    });
    try {
      final repository = widget.ref.read(friendRepositoryProvider);
      final profile = await repository.findProfileByUserId(userId);
      final status = profile == null
          ? null
          : await repository.relationshipStatus(profile.id);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _status = status;
        _error = profile == null ? 'このIDのユーザーが見つかりませんでした' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '検索に失敗しました。時間をおいて再度お試しください');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendRequest() async {
    final profile = _profile;
    if (profile == null) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      final repository = widget.ref.read(friendRepositoryProvider);
      await repository.sendFriendRequest(profile.id);
      widget.ref.invalidate(friendsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      NomoToast.show(
        context,
        '${profile.displayName}さんに申請を送りました',
        icon: CupertinoIcons.person_badge_plus_fill,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '申請の送信に失敗しました。時間をおいて再度お試しください');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? const Color(0xFF18222E) : Colors.white;
    final sub = isWhite ? const Color(0xFF6C7480) : Colors.white70;
    final profile = _profile;
    final status = _status;
    final user = widget.ref.watch(nomoUserProvider);
    final myUserId = user?.userId.trim() ?? '';
    final qrPayload = myUserId.isEmpty ? null : 'tomola://friend/$myUserId';
    return NomoBottomSheetShell(
      title: null,
      showHandle: true,
      radius: 34,
      maxHeightFactor: .88,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF7AB8), Color(0xFFC08BFF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF7AB8).withValues(alpha: .26),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: NomoGeneratedIcon(
                      CupertinoIcons.person_2_fill,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'フレンズとつながろ',
                        style: TextStyle(
                          color: ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.8,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'QRを見せるか、IDで探してね。',
                        style: TextStyle(
                          color: sub,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: NomoGeneratedIcon(
                    CupertinoIcons.xmark,
                    color: ink.withValues(alpha: .86),
                    size: 30,
                  ),
                ),
              ],
            ),
            if (myUserId.isNotEmpty) ...[
              const SizedBox(height: 18),
              _CuteQrCard(
                userId: myUserId,
                payload: qrPayload,
                avatar: user?.avatar ?? NomoAvatar.defaultAvatar,
                isWhite: isWhite,
                onCopyId: () => _copyMyId(myUserId),
                onCopyLink: qrPayload == null
                    ? null
                    : () => _copyFriendLink(qrPayload),
                onShare: qrPayload == null
                    ? null
                    : () => _shareFriendLink(myUserId, qrPayload),
              ),
            ],
            const SizedBox(height: 18),
            _CuteIdSearchCard(
              controller: _controller,
              isWhite: isWhite,
              isLoading: _isLoading,
              onSearch: () {
                HapticFeedback.selectionClick();
                _search();
              },
              onPaste: _pasteAndSearch,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              _CuteMessageBox(
                icon: CupertinoIcons.exclamationmark_bubble_fill,
                message: _error!,
                color: const Color(0xFFFF7A9E),
              ),
            ],
            if (profile != null) ...[
              const SizedBox(height: 14),
              _FriendSearchResultCard(
                profile: profile,
                status: status,
                isSending: _isSending,
                isWhite: isWhite,
                onSend: _sendRequest,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CuteQrCard extends StatelessWidget {
  const _CuteQrCard({
    required this.userId,
    required this.payload,
    required this.avatar,
    required this.isWhite,
    required this.onCopyId,
    required this.onCopyLink,
    required this.onShare,
  });

  final String userId;
  final String? payload;
  final NomoAvatar avatar;
  final bool isWhite;
  final VoidCallback onCopyId;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF151515);
    const softInk = Color(0xFF6D6D6D);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.black.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWhite ? .10 : .34),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              NomoGeneratedIcon(
                CupertinoIcons.sparkles,
                color: ink.withValues(alpha: .72),
                size: 30,
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Nomo',
                      style: TextStyle(
                        color: ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.7,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@$userId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: softInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 30),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: 238,
            height: 238,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.black.withValues(alpha: .05)),
            ),
            child: payload == null
                ? const Center(child: Text('ログインしてね'))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      QrImageView(
                        data: payload!,
                        version: QrVersions.auto,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.circle,
                          color: ink,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.circle,
                          color: ink,
                        ),
                      ),
                      Container(
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: .96),
                              blurRadius: 0,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: NomoAvatarView(avatar: avatar, size: 62),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          const Text(
            'nomo',
            style: TextStyle(
              color: ink,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -.6,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QrActionButton(
                  icon: CupertinoIcons.square_arrow_up,
                  label: 'リンクをシェア',
                  onTap: onShare,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _QrActionButton(
                  icon: CupertinoIcons.link,
                  label: 'リンクをコピー',
                  onTap: onCopyLink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onCopyId,
            child: Text(
              'IDだけコピー',
              style: TextStyle(
                color: softInk.withValues(alpha: .82),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrActionButton extends StatelessWidget {
  const _QrActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF222222);
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .45 : 1,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withValues(alpha: .09),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: NomoGeneratedIcon(icon, color: ink, size: 32),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ink.withValues(alpha: .50),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuteIdSearchCard extends StatelessWidget {
  const _CuteIdSearchCard({
    required this.controller,
    required this.isWhite,
    required this.isLoading,
    required this.onSearch,
    required this.onPaste,
  });

  final TextEditingController controller;
  final bool isWhite;
  final bool isLoading;
  final VoidCallback onSearch;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWhite ? Colors.white : Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isWhite ? const Color(0xFFEADDEA) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            controller: controller,
            placeholder: 'Nomo ID',
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: NomoGeneratedIcon(
                CupertinoIcons.at,
                color: Color(0xFFFF7AB8),
                size: 20,
              ),
            ),
            decoration: BoxDecoration(
              color: isWhite
                  ? const Color(0xFFFFF7FB)
                  : Colors.black.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isWhite ? const Color(0xFFFFC4DF) : Colors.white12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Nomo3DButton(
                  label: isLoading ? '探してる...' : 'IDで探す',
                  icon: CupertinoIcons.search,
                  onTap: isLoading ? null : onSearch,
                  height: 48,
                  radius: 24,
                  color: const Color(0xFFFF7AB8),
                  foregroundColor: Colors.white,
                  shadowColor: const Color(0xFFC43D7C),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 104,
                child: Nomo3DButton.secondary(
                  label: '貼る',
                  icon: CupertinoIcons.doc_on_clipboard,
                  onTap: isLoading ? null : onPaste,
                  height: 48,
                  radius: 24,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CuteMessageBox extends StatelessWidget {
  const _CuteMessageBox({
    required this.icon,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Row(
        children: [
          NomoGeneratedIcon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendSearchResultCard extends StatelessWidget {
  const _FriendSearchResultCard({
    required this.profile,
    required this.status,
    required this.isSending,
    required this.isWhite,
    required this.onSend,
  });

  final NomoFriendProfile profile;
  final NomoFriendRelationshipStatus? status;
  final bool isSending;
  final bool isWhite;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final ink = isWhite ? const Color(0xFF18222E) : Colors.white;
    final sub = isWhite ? const Color(0xFF6C7480) : Colors.white70;
    final alreadyFriend = status?.alreadyFriend == true;
    final alreadyRequested =
        status?.requestState == NomoFriendRequestState.outgoing;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWhite ? const Color(0xFFF7FFF0) : const Color(0xFF162514),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFB7F15B).withValues(alpha: .36),
        ),
      ),
      child: Row(
        children: [
          NomoAvatarView(avatar: profile.avatar, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: TextStyle(
                    color: ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '@${profile.userId}',
                  style: TextStyle(color: sub, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 104,
            child: Nomo3DButton(
              label: alreadyFriend
                  ? '追加済み'
                  : alreadyRequested
                  ? '申請済み'
                  : isSending
                  ? '送信中'
                  : '申請',
              onTap: alreadyFriend || alreadyRequested || isSending
                  ? null
                  : onSend,
              height: 42,
              radius: 20,
              color: const Color(0xFF8A62FF),
              foregroundColor: Colors.white,
              shadowColor: const Color(0xFF4A2BBF),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
