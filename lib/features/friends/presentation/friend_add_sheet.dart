import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/application/ohey_user_controller.dart';
import '../../../core/config/auth_provider_config.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_avatar.dart';
import '../../../core/widgets/ohey_pop_icon.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_toast.dart';
import '../data/friend_repository.dart';
import 'package:ohey/core/theme/app_colors.dart';

String _friendQrPayload(String userId) {
  final scheme = AuthProviderConfig.redirectUrl.split('://').first;
  return '$scheme://friend/${Uri.encodeComponent(userId)}';
}

String _normalizedFriendInput(String value) {
  var input = value.trim();
  if (input.startsWith('@')) input = input.substring(1).trim();
  final uri = Uri.tryParse(input);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    input = uri.pathSegments.last.trim();
  }
  return Uri.decodeComponent(input);
}

Future<void> showFriendAddSheet(BuildContext context, WidgetRef ref) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '閉じる',
    barrierColor: AppColors.black.withValues(alpha: .70),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const _FriendQrDialog(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _FriendQrDialog extends ConsumerStatefulWidget {
  const _FriendQrDialog();

  @override
  ConsumerState<_FriendQrDialog> createState() => _FriendQrDialogState();
}

class _FriendQrDialogState extends ConsumerState<_FriendQrDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  OheyFriendProfile? _searchProfile;
  OheyFriendRelationshipStatus? _searchStatus;
  bool _isSearchExpanded = false;
  bool _isSearching = false;
  bool _isSending = false;
  String? _searchError;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _copyMyId(BuildContext context, String userId) async {
    await Clipboard.setData(ClipboardData(text: userId));
    if (!context.mounted) return;
    OheyToast.show(
      context,
      '@$userId をコピーしました',
      icon: CupertinoIcons.doc_on_clipboard_fill,
    );
  }

  Future<void> _copyFriendLink(BuildContext context, String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    OheyToast.show(context, 'リンクをコピーしました', icon: CupertinoIcons.link);
  }

  Future<void> _shareFriendLink(String userId, String payload) async {
    HapticFeedback.selectionClick();
    await SharePlus.instance.share(
      ShareParams(title: 'Oheyでつながろ', text: 'Oheyで@$userId とつながろう：$payload'),
    );
  }

  void _expandSearch() {
    HapticFeedback.selectionClick();
    setState(() => _isSearchExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  Future<void> _searchById() async {
    final friendId = _normalizedFriendInput(_searchController.text);
    _searchController.text = friendId;
    if (friendId.isEmpty) {
      setState(() => _searchError = 'IDを入力してください');
      return;
    }
    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchProfile = null;
      _searchStatus = null;
    });
    try {
      final repository = ref.read(friendRepositoryProvider);
      final profile = await repository.findProfileByUserId(friendId);
      final status = profile == null
          ? null
          : await repository.relationshipStatus(profile.id);
      if (!mounted) return;
      setState(() {
        _searchProfile = profile;
        _searchStatus = status;
        _searchError = profile == null ? 'このIDのユーザーが見つかりませんでした' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchError = '検索に失敗しました。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _sendSearchRequest() async {
    final profile = _searchProfile;
    if (profile == null) return;
    setState(() {
      _isSending = true;
      _searchError = null;
    });
    try {
      final repository = ref.read(friendRepositoryProvider);
      await repository.sendFriendRequest(profile.id);
      ref.invalidate(friendsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(
        context,
        '${profile.displayName}さんに申請を送りました',
        icon: CupertinoIcons.person_badge_plus_fill,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchError = '申請できませんでした。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _cancelSearchRequest() async {
    final profile = _searchProfile;
    final requestId = _searchStatus?.requestId;
    if (profile == null || requestId == null || requestId.isEmpty) return;
    setState(() {
      _isSending = true;
      _searchError = null;
    });
    try {
      final repository = ref.read(friendRepositoryProvider);
      await repository.cancelFriendRequest(requestId);
      final status = await repository.relationshipStatus(profile.id);
      if (!mounted) return;
      setState(() => _searchStatus = status);
      OheyToast.show(
        context,
        '申請を取り消しました',
        icon: CupertinoIcons.arrow_uturn_left_circle_fill,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchError = '申請を取り消せませんでした。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _scanFriendQr(BuildContext context) async {
    final scanned = await showOheyBottomSheet<String>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .70),
      builder: (_) => const _FriendQrScannerSheet(),
    );
    final friendId = scanned == null ? '' : _normalizedFriendInput(scanned);
    if (friendId.isEmpty || !context.mounted) return;
    try {
      final repository = ref.read(friendRepositoryProvider);
      final profile = await repository.findProfileByUserId(friendId);
      if (profile == null) {
        if (context.mounted) {
          OheyToast.show(context, 'このQRのユーザーが見つかりませんでした');
        }
        return;
      }
      await repository.sendFriendRequest(profile.id);
      ref.invalidate(friendsProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(
        context,
        '${profile.displayName}さんに申請を送りました',
        icon: CupertinoIcons.person_badge_plus_fill,
      );
    } catch (_) {
      if (!context.mounted) return;
      OheyToast.show(context, 'QRから申請できませんでした。あとでもう一度試してね');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(oheyUserProvider);
    final myUserId = user?.userId.trim() ?? '';
    final qrPayload = myUserId.isEmpty ? null : _friendQrPayload(myUserId);
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            child: Material(
              color: AppColors.transparent,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: _CuteQrCard(
                  name: user?.name.trim() ?? '',
                  userId: myUserId,
                  payload: qrPayload,
                  avatar: user?.avatar ?? OheyAvatar.defaultAvatar,
                  isWhite: false,
                  onClose: () => Navigator.of(context).pop(),
                  onCopyId: () => _copyMyId(context, myUserId),
                  onCopyLink: qrPayload == null
                      ? null
                      : () => _copyFriendLink(context, qrPayload),
                  onShare: qrPayload == null
                      ? null
                      : () => _shareFriendLink(myUserId, qrPayload),
                  onScan: () => _scanFriendQr(context),
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  isSearchExpanded: _isSearchExpanded,
                  isSearching: _isSearching,
                  searchError: _searchError,
                  searchProfile: _searchProfile,
                  searchStatus: _searchStatus,
                  isSendingSearchRequest: _isSending,
                  onExpandSearch: _expandSearch,
                  onSubmitSearch: _searchById,
                  onSendSearchRequest: _sendSearchRequest,
                  onCancelSearchRequest: _cancelSearchRequest,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendAddSheet extends StatefulWidget {
  const _FriendAddSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_FriendAddSheet> createState() => _FriendAddSheetState();
}

class _FriendAddSheetState extends State<_FriendAddSheet> {
  final TextEditingController _controller = TextEditingController();
  OheyFriendProfile? _profile;
  OheyFriendRelationshipStatus? _status;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _normalizedInput(String value) => _normalizedFriendInput(value);

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
    OheyToast.show(
      context,
      '@$userId をコピーしました',
      icon: CupertinoIcons.doc_on_clipboard_fill,
    );
  }

  Future<void> _copyFriendLink(String payload) async {
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    OheyToast.show(context, 'リンクをコピーしました', icon: CupertinoIcons.link);
  }

  Future<void> _shareFriendLink(String userId, String payload) async {
    HapticFeedback.selectionClick();
    await SharePlus.instance.share(
      ShareParams(title: 'Oheyでつながろ', text: 'Oheyで@$userId とつながろう：$payload'),
    );
  }

  Future<void> _scanFriendQr(BuildContext context) async {
    final scanned = await showOheyBottomSheet<String>(
      context: context,
      useSafeArea: true,
      barrierColor: AppColors.black.withValues(alpha: .70),
      builder: (_) => const _FriendQrScannerSheet(),
    );
    final friendId = scanned == null ? '' : _normalizedFriendInput(scanned);
    if (friendId.isEmpty || !context.mounted) return;
    try {
      final repository = widget.ref.read(friendRepositoryProvider);
      final profile = await repository.findProfileByUserId(friendId);
      if (profile == null) {
        if (context.mounted) {
          OheyToast.show(context, 'このQRのユーザーが見つかりませんでした');
        }
        return;
      }
      await repository.sendFriendRequest(profile.id);
      widget.ref.invalidate(friendsProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      OheyToast.show(
        context,
        '${profile.displayName}さんに申請を送りました',
        icon: CupertinoIcons.person_badge_plus_fill,
      );
    } catch (_) {
      if (!context.mounted) return;
      OheyToast.show(context, 'QRから申請できませんでした。あとでもう一度試してね');
    }
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
      OheyToast.show(
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

  Future<void> _cancelRequest() async {
    final profile = _profile;
    final requestId = _status?.requestId;
    if (profile == null || requestId == null || requestId.isEmpty) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      final repository = widget.ref.read(friendRepositoryProvider);
      await repository.cancelFriendRequest(requestId);
      final status = await repository.relationshipStatus(profile.id);
      if (!mounted) return;
      setState(() => _status = status);
      OheyToast.show(
        context,
        '申請を取り消しました',
        icon: CupertinoIcons.arrow_uturn_left_circle_fill,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = '申請を取り消せませんでした。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF18222E : AppColors.white;
    final sub = isWhite ? AppColors.cFF6C7480 : AppColors.white70;
    final profile = _profile;
    final status = _status;
    final user = widget.ref.watch(oheyUserProvider);
    final myUserId = user?.userId.trim() ?? '';
    final qrPayload = myUserId.isEmpty ? null : _friendQrPayload(myUserId);
    return OheyBottomSheetShell(
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
                      colors: [AppColors.cFFFF7AB8, AppColors.cFFC08BFF],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cFFFF7AB8.withValues(alpha: .26),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: OheyGeneratedIcon(
                      CupertinoIcons.person_2_fill,
                      color: AppColors.white,
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
                const SizedBox.shrink(),
              ],
            ),
            if (myUserId.isNotEmpty) ...[
              const SizedBox(height: 18),
              _CuteQrCard(
                name: user?.name.trim() ?? '',
                userId: myUserId,
                payload: qrPayload,
                avatar: user?.avatar ?? OheyAvatar.defaultAvatar,
                isWhite: isWhite,
                onCopyId: () => _copyMyId(myUserId),
                onCopyLink: qrPayload == null
                    ? null
                    : () => _copyFriendLink(qrPayload),
                onShare: qrPayload == null
                    ? null
                    : () => _shareFriendLink(myUserId, qrPayload),
                onScan: () => _scanFriendQr(context),
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
                color: AppColors.cFFFF7A9E,
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
                onCancel: _cancelRequest,
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
    required this.name,
    required this.userId,
    required this.payload,
    required this.avatar,
    required this.isWhite,
    required this.onCopyId,
    required this.onCopyLink,
    required this.onShare,
    this.onClose,
    this.onScan,
    this.searchController,
    this.searchFocusNode,
    this.isSearchExpanded = false,
    this.isSearching = false,
    this.searchError,
    this.searchProfile,
    this.searchStatus,
    this.isSendingSearchRequest = false,
    this.onExpandSearch,
    this.onSubmitSearch,
    this.onSendSearchRequest,
    this.onCancelSearchRequest,
  });

  final String name;
  final String userId;
  final String? payload;
  final OheyAvatar avatar;
  final bool isWhite;
  final VoidCallback onCopyId;
  final VoidCallback? onCopyLink;
  final VoidCallback? onShare;
  final VoidCallback? onClose;
  final VoidCallback? onScan;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final bool isSearchExpanded;
  final bool isSearching;
  final String? searchError;
  final OheyFriendProfile? searchProfile;
  final OheyFriendRelationshipStatus? searchStatus;
  final bool isSendingSearchRequest;
  final VoidCallback? onExpandSearch;
  final VoidCallback? onSubmitSearch;
  final VoidCallback? onSendSearchRequest;
  final VoidCallback? onCancelSearchRequest;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.cFF151515;
    const softInk = AppColors.cFF6D6D6D;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: AppColors.black.withValues(alpha: .08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isWhite ? .10 : .34),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: onClose == null
                    ? OheyGeneratedIcon(
                        CupertinoIcons.sparkles,
                        color: ink.withValues(alpha: .72),
                        size: 30,
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: const Text(
                  'Ohey',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.7,
                  ),
                ),
              ),
              const SizedBox(width: 30),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 196,
            height: 196,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.black.withValues(alpha: .05)),
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
                        width: 62,
                        height: 62,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.cFFF3F3F3,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.white.withValues(alpha: .96),
                              blurRadius: 0,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: OheyAvatarView(avatar: avatar, size: 50),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              Text(
                name.isEmpty ? 'ユーザー名未設定' : name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.4,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '@$userId',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: softInk,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _QrActionButton(
                icon: CupertinoIcons.square_arrow_up,
                label: 'リンクを共有',
                onTap: onShare,
              ),
              _QrActionButton(
                icon: CupertinoIcons.link,
                label: 'リンクをコピー',
                onTap: onCopyLink,
              ),
              _QrActionButton(
                icon: CupertinoIcons.doc_on_doc,
                label: 'IDをコピー',
                onTap: onCopyId,
              ),
              if (onScan != null) ...[
                _QrActionButton(
                  icon: CupertinoIcons.qrcode_viewfinder,
                  label: 'QRを読み取る',
                  onTap: onScan!,
                ),
              ],
            ],
          ),
          if (searchController != null &&
              searchFocusNode != null &&
              onExpandSearch != null &&
              onSubmitSearch != null) ...[
            const SizedBox(height: 8),
            Center(
              child: _QrIdSearchChip(
                controller: searchController!,
                focusNode: searchFocusNode!,
                isExpanded: isSearchExpanded,
                isLoading: isSearching,
                onExpand: onExpandSearch!,
                onSearch: onSubmitSearch!,
              ),
            ),
          ],
          if (searchError != null) ...[
            const SizedBox(height: 10),
            _CuteMessageBox(
              icon: CupertinoIcons.exclamationmark_bubble_fill,
              message: searchError!,
              color: AppColors.cFFFF7A9E,
            ),
          ],
          if (searchProfile != null && onSendSearchRequest != null) ...[
            const SizedBox(height: 10),
            _FriendSearchResultCard(
              profile: searchProfile!,
              status: searchStatus,
              isSending: isSendingSearchRequest,
              isWhite: true,
              onSend: onSendSearchRequest!,
              onCancel: onCancelSearchRequest,
            ),
          ],
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
    const ink = AppColors.cFF222222;
    return Semantics(
      button: true,
      label: label,
      child: Opacity(
        opacity: onTap == null ? .45 : 1,
        child: SizedBox(
          width: 138,
          child: Ohey3DButtonSurface(
            onTap: onTap,
            height: 48,
            radius: 18,
            color: AppColors.white,
            bottomColor: AppColors.cFFE1E1E1,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            useGradient: true,
            borderColor: AppColors.black.withValues(alpha: .09),
            borderWidth: 2,
            outerShadows: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: .06),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OheyGeneratedIcon(icon, color: ink, size: 20),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ink.withValues(alpha: .72),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrIdSearchChip extends StatelessWidget {
  const _QrIdSearchChip({
    required this.controller,
    required this.focusNode,
    required this.isExpanded,
    required this.isLoading,
    required this.onExpand,
    required this.onSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isExpanded;
  final bool isLoading;
  final VoidCallback onExpand;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    const ink = AppColors.cFF222222;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: isExpanded ? 270 : 130,
      child: Ohey3DButtonSurface(
        onTap: isExpanded ? null : onExpand,
        height: 34,
        radius: 17,
        color: AppColors.cFFF7F7F7,
        bottomColor: AppColors.cFFE1E1E1,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        useGradient: true,
        borderColor: AppColors.black.withValues(alpha: .08),
        outerShadows: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: .055),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isExpanded
              ? Row(
                  key: const ValueKey('search-input'),
                  children: [
                    OheyGeneratedIcon(
                      CupertinoIcons.search,
                      color: ink.withValues(alpha: .68),
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: CupertinoTextField(
                        controller: controller,
                        focusNode: focusNode,
                        placeholder: 'Ohey ID',
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => isLoading ? null : onSearch(),
                        padding: EdgeInsets.zero,
                        style: TextStyle(
                          color: ink.withValues(alpha: .86),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                        placeholderStyle: TextStyle(
                          color: ink.withValues(alpha: .36),
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: const BoxDecoration(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isLoading ? null : onSearch,
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: Center(
                          child: isLoading
                              ? const CupertinoActivityIndicator(radius: 7)
                              : OheyGeneratedIcon(
                                  CupertinoIcons.arrow_right_circle_fill,
                                  color: ink.withValues(alpha: .68),
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('search-chip'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OheyGeneratedIcon(
                      CupertinoIcons.search,
                      color: ink.withValues(alpha: .68),
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'ID検索',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ink.withValues(alpha: .62),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
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
        color: isWhite
            ? AppColors.white
            : AppColors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isWhite ? AppColors.cFFEADDEA : AppColors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            controller: controller,
            placeholder: 'Ohey ID',
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            prefix: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: OheyGeneratedIcon(
                CupertinoIcons.at,
                color: AppColors.cFFFF7AB8,
                size: 20,
              ),
            ),
            decoration: BoxDecoration(
              color: isWhite
                  ? AppColors.cFFFFF7FB
                  : AppColors.black.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isWhite ? AppColors.cFFFFC4DF : AppColors.white12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Ohey3DButton(
                  label: isLoading ? '探してる...' : 'IDで探す',
                  icon: CupertinoIcons.search,
                  onTap: isLoading ? null : onSearch,
                  height: 48,
                  radius: 24,
                  color: AppColors.cFFFF7AB8,
                  foregroundColor: AppColors.white,
                  shadowColor: AppColors.cFFC43D7C,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 104,
                child: Ohey3DButton.secondary(
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
          OheyGeneratedIcon(icon, color: color, size: 18),
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

class _FriendQrScannerSheet extends StatefulWidget {
  const _FriendQrScannerSheet();

  @override
  State<_FriendQrScannerSheet> createState() => _FriendQrScannerSheetState();
}

class _FriendQrScannerSheetState extends State<_FriendQrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _didScan = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDetect(BarcodeCapture capture) {
    if (_didScan) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (value == null) return;
    _didScan = true;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final ink = isWhite ? AppColors.cFF18222E : AppColors.white;
    final sub = isWhite ? AppColors.cFF6C7480 : AppColors.white70;
    return OheyBottomSheetShell(
      title: null,
      showHandle: true,
      radius: 34,
      maxHeightFactor: .82,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'QRを読み取る',
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '相手のOhey QRをカメラにかざしてね。',
            style: TextStyle(
              color: sub,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: SizedBox(
              height: 280,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: _handleDetect,
                  ),
                  Center(
                    child: Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: AppColors.cFFB7F15B,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
    this.onCancel,
  });

  final OheyFriendProfile profile;
  final OheyFriendRelationshipStatus? status;
  final bool isSending;
  final bool isWhite;
  final VoidCallback onSend;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final ink = isWhite ? AppColors.cFF18222E : AppColors.white;
    final sub = isWhite ? AppColors.cFF6C7480 : AppColors.white70;
    final alreadyFriend = status?.alreadyFriend == true;
    final alreadyRequested =
        status?.requestState == OheyFriendRequestState.outgoing;
    final incomingRequested =
        status?.requestState == OheyFriendRequestState.incoming;
    final canCancel =
        alreadyRequested && (status?.requestId?.isNotEmpty == true);
    final buttonLabel = alreadyFriend
        ? '追加済み'
        : alreadyRequested
        ? isSending
              ? '取消中'
              : '取消'
        : incomingRequested
        ? '申請あり'
        : isSending
        ? '送信中'
        : '申請';
    final buttonAction = alreadyFriend || incomingRequested || isSending
        ? null
        : alreadyRequested
        ? (canCancel ? onCancel : null)
        : onSend;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWhite ? AppColors.cFFF7FFF0 : AppColors.cFF162514,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.cFFB7F15B.withValues(alpha: .36)),
      ),
      child: Row(
        children: [
          OheyAvatarView(avatar: profile.avatar, size: 54),
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
            child: Ohey3DButton(
              label: buttonLabel,
              onTap: buttonAction,
              height: 42,
              radius: 20,
              color: alreadyRequested
                  ? AppColors.cFF415066
                  : AppColors.cFF8A62FF,
              foregroundColor: AppColors.white,
              shadowColor: alreadyRequested
                  ? AppColors.cFF253044
                  : AppColors.cFF4A2BBF,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
