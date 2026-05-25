import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
                onCopy: () => _copyMyId(myUserId),
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
    required this.onCopy,
  });

  final String userId;
  final String? payload;
  final NomoAvatar avatar;
  final bool isWhite;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final ink = isWhite ? const Color(0xFF18222E) : Colors.white;
    final sub = isWhite ? const Color(0xFF6C7480) : Colors.white70;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isWhite
              ? const [Color(0xFFFFF3FA), Color(0xFFF3EEFF)]
              : const [Color(0xFF1B1830), Color(0xFF102225)],
        ),
        border: Border.all(
          color: isWhite
              ? const Color(0xFFFFC4DF)
              : Colors.white.withValues(alpha: .10),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFFF7AB8,
            ).withValues(alpha: isWhite ? .18 : .12),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              NomoAvatarView(avatar: avatar, size: 56),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '見せるだけでOK',
                      style: TextStyle(
                        color: ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@$userId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: sub, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const NomoPopIcon(
                icon: CupertinoIcons.sparkles,
                color: Color(0xFFFFC857),
                size: 38,
                iconSize: 20,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: 184,
            height: 184,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(34),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF21D6C4).withValues(alpha: .20),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: payload == null
                ? const Center(child: Text('ログインしてね'))
                : QrImageView(data: payload!, version: QrVersions.auto),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 220,
            child: Nomo3DButton.secondary(
              label: 'IDをコピー',
              icon: CupertinoIcons.doc_on_clipboard,
              onTap: onCopy,
              height: 44,
              radius: 22,
              fontSize: 13,
            ),
          ),
        ],
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
            placeholder: 'Tomola ID',
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
