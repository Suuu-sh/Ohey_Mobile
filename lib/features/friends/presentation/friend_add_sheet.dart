import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_bottom_sheet.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../../core/widgets/nomo_exchange_components.dart';
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
    final alreadyFriend = status?.alreadyFriend == true;
    final alreadyRequested =
        status?.requestState == NomoFriendRequestState.outgoing;

    return NomoBottomSheetShell(
      title: 'フレンズを追加',
      showHandle: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '相手のTomola IDを入力・ペーストしてすぐ申請できます。QRは自分のID交換用です。',
            style: TextStyle(
              color: sub,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          if (myUserId.isNotEmpty) ...[
            const SizedBox(height: 14),
            NomoQrDisplayCard(
              title: 'あなたのTomola ID',
              subtitle: '友達に見せるか、IDをコピーして送れます',
              handle: '@$myUserId',
              payload: qrPayload,
              avatar: user?.avatar ?? NomoAvatar.defaultAvatar,
              accentColor: const Color(0xFFB7F15B),
              textColor: ink,
              mutedTextColor: sub,
              qrSize: 154,
              qrPadding: 10,
            ),
            const SizedBox(height: 10),
            Nomo3DButton.secondary(
              label: '自分のIDをコピー',
              icon: CupertinoIcons.doc_on_clipboard,
              onTap: () => _copyMyId(myUserId),
              height: 42,
              radius: 20,
              fontSize: 13,
            ),
          ],
          const SizedBox(height: 14),
          CupertinoTextField(
            controller: _controller,
            placeholder: 'Tomola ID',
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isWhite
                  ? const Color(0xFFF4F7FB)
                  : Colors.white.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isWhite ? const Color(0xFFE0E6EF) : Colors.white12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Nomo3DButton(
                  label: _isLoading ? '検索中...' : 'IDで検索',
                  icon: CupertinoIcons.search,
                  onTap: _isLoading
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          _search();
                        },
                  height: 46,
                  radius: 22,
                  color: const Color(0xFFB7F15B),
                  foregroundColor: const Color(0xFF183018),
                  shadowColor: const Color(0xFF79A634),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 104,
                child: Nomo3DButton.secondary(
                  label: '貼り付け',
                  icon: CupertinoIcons.doc_on_clipboard,
                  onTap: _isLoading ? null : _pasteAndSearch,
                  height: 46,
                  radius: 22,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (profile != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isWhite
                    ? Colors.white
                    : Colors.white.withValues(alpha: .06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isWhite ? const Color(0xFFE4EAF2) : Colors.white12,
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
                          style: TextStyle(
                            color: sub,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 108,
                    child: Nomo3DButton(
                      label: alreadyFriend
                          ? '追加済み'
                          : alreadyRequested
                          ? '申請済み'
                          : _isSending
                          ? '送信中'
                          : '申請',
                      onTap: alreadyFriend || alreadyRequested || _isSending
                          ? null
                          : _sendRequest,
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
            ),
          ],
        ],
      ),
    );
  }
}
