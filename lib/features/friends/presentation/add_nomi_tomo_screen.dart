import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../logs/application/drink_log_controller.dart';

class AddNomiTomoScreen extends ConsumerStatefulWidget {
  const AddNomiTomoScreen({super.key});

  @override
  ConsumerState<AddNomiTomoScreen> createState() => _AddNomiTomoScreenState();
}

class _AddNomiTomoScreenState extends ConsumerState<AddNomiTomoScreen> {
  final _userIdController = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(nomoUserProvider);
    final qrPayload = _friendQrPayload(user?.userId ?? '');
    return Scaffold(
      backgroundColor: _ExchangeColors.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF142335), Color(0xFF08121D), Color(0xFF03080D)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 112),
            children: [
              _ExchangeHeader(onClose: () => Navigator.of(context).maybePop()),
              const SizedBox(height: 14),
              _MyQrCard(
                userId: user?.userId,
                payload: qrPayload,
                avatar: user?.avatar ?? NomoAvatar.defaultAvatar,
              ),
              const SizedBox(height: 16),
              _ScanQrCard(onScan: _scanQr),
              const SizedBox(height: 16),
              _UserIdSearchCard(
                controller: _userIdController,
                busy: _busy,
                onSubmitted: _searchByUserId,
              ),
              const SizedBox(height: 16),
              const _ExchangeHintCard(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _searchByUserId() async {
    final id = _userIdController.text.trim();
    if (id.isEmpty) {
      NomoToast.show(context, 'ユーザーIDを入力してください。');
      return;
    }
    await _openResult(id);
  }

  Future<void> _scanQr() async {
    final payload = await Navigator.of(context).push<String>(
      CupertinoPageRoute(builder: (_) => const NomiTomoQrScannerScreen()),
    );
    if (!mounted || payload == null) return;
    final userId = parseFriendQrPayload(payload);
    if (userId == null) {
      NomoToast.show(context, 'Nomoの友達QRではありません。');
      return;
    }
    await _openResult(userId);
  }

  Future<void> _openResult(String userId) async {
    setState(() => _busy = true);
    try {
      final profile = await _findProfileByUserId(userId);
      if (!mounted) return;
      if (profile == null) {
        NomoToast.show(context, '$userId は見つかりませんでした。');
        return;
      }
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: .62),
        isScrollControlled: true,
        builder: (context) => _UserSearchResultSheet(
          profile: profile,
          onAdd: () => _addFriend(profile),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      NomoToast.show(context, '検索できませんでした: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_FriendProfile?> _findProfileByUserId(String userId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      throw StateError('友達追加にはログインが必要です。');
    }
    final normalized = _normalizeFriendSearchId(userId);
    if (normalized.isEmpty) return null;
    final row = await Supabase.instance.client
        .from('profiles')
        .select('id, display_name, user_id, avatar_url')
        .eq('user_id', normalized)
        .maybeSingle();
    if (row == null) return null;
    return _FriendProfile.fromRow(Map<String, dynamic>.from(row));
  }

  Future<void> _addFriend(_FriendProfile profile) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      NomoToast.show(context, '友達追加にはログインが必要です。');
      return;
    }
    if (profile.id == currentUser.id) {
      NomoToast.show(context, '自分自身は追加できません。');
      return;
    }
    final ids = [currentUser.id, profile.id]..sort();
    try {
      await Supabase.instance.client.from('friendships').upsert({
        'user_a_id': ids[0],
        'user_b_id': ids[1],
      }, onConflict: 'user_a_id,user_b_id');
      ref.invalidate(friendsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      NomoToast.show(context, '${profile.displayName}を友達に追加しました。');
    } catch (e) {
      if (!mounted) return;
      NomoToast.show(context, '友達追加に失敗しました: $e');
    }
  }
}

String _friendQrPayload(String userId) => 'nomo://friend/$userId';

String _normalizeFriendSearchId(String raw) {
  final withoutAt = raw.trim().replaceFirst(RegExp(r'^@'), '');
  final localPart = withoutAt.contains('@')
      ? withoutAt.split('@').first
      : withoutAt;
  return localPart.replaceAll('-', '_').toLowerCase();
}

String? parseFriendQrPayload(String raw) {
  final value = raw.trim();
  final uri = Uri.tryParse(value);
  if (uri != null && uri.scheme == 'nomo' && uri.host == 'friend') {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    return id?.isEmpty == false ? id : null;
  }
  if (value.startsWith('@')) return value.substring(1);
  if (RegExp(r'^[A-Za-z0-9_\-]{3,}$').hasMatch(value)) return value;
  return null;
}

class _FriendProfile {
  const _FriendProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.avatar,
  });

  final String id;
  final String userId;
  final String displayName;
  final NomoAvatar avatar;

  factory _FriendProfile.fromRow(Map<String, dynamic> row) => _FriendProfile(
    id: row['id'] as String,
    userId: (row['user_id'] as String?) ?? '',
    displayName: (row['display_name'] as String?) ?? 'Nomo friend',
    avatar:
        NomoAvatar.decode(row['avatar_url'] as String?) ??
        NomoAvatar.defaultAvatar,
  );
}

class _ExchangeHeader extends StatelessWidget {
  const _ExchangeHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '飲み友交換',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'QRコードかユーザーIDで、Nomoのフレンズにつながろう。',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .56),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
      _RoundActionButton(icon: CupertinoIcons.xmark, onTap: onClose),
    ],
  );
}

class NomiTomoQrScannerScreen extends StatefulWidget {
  const NomiTomoQrScannerScreen({super.key});

  @override
  State<NomiTomoQrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<NomiTomoQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _returned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_returned) return;
    final code = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    _returned = true;
    Navigator.of(context).pop(code);
  }

  Future<void> _scanFromImage() async {
    if (kIsWeb) {
      NomoToast.show(context, 'Web では画像読み込みからのスキャンは未対応です。');
      return;
    }

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null || !mounted) return;

    try {
      final barcodes = await _controller.analyzeImage(image.path);
      if (!mounted || _returned) return;
      if (barcodes == null || barcodes.barcodes.isEmpty) {
        NomoToast.show(context, 'QRコードが見つかりませんでした');
        return;
      }
      final code = barcodes.barcodes.first.rawValue;
      if (code == null || code.isEmpty) {
        NomoToast.show(context, 'QRコードが見つかりませんでした');
        return;
      }
      _returned = true;
      Navigator.of(context).pop(code);
    } catch (_) {
      if (!mounted) return;
      NomoToast.show(context, '画像の読み込みに失敗しました');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('QRを読み取る'),
    ),
    body: Stack(
      children: [
        MobileScanner(controller: _controller, onDetect: _onDetect),
        Center(
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              border: Border.all(color: _ExchangeColors.lime, width: 4),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _ExchangeColors.lime.withValues(alpha: .28),
                  blurRadius: 28,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: SafeArea(
            top: false,
            child: _MiniPopButton(
              label: '画像から読み取り',
              icon: CupertinoIcons.photo,
              color: _ExchangeColors.teal,
              onTap: _scanFromImage,
            ),
          ),
        ),
      ],
    ),
  );
}

class _MyQrCard extends StatelessWidget {
  const _MyQrCard({
    required this.userId,
    required this.payload,
    required this.avatar,
  });

  final String? userId;
  final String payload;
  final NomoAvatar avatar;

  @override
  Widget build(BuildContext context) => _DarkCard(
    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: _ExchangeColors.teal.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _ExchangeColors.teal.withValues(alpha: .28),
                ),
              ),
              child: NomoAvatarView(avatar: avatar, size: 58),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'あなたのNomo QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '相手に見せて飲み友交換',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .48),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const _PopBadge(
              icon: CupertinoIcons.qrcode,
              color: _ExchangeColors.lime,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: 202,
          height: 202,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: _ExchangeColors.lime.withValues(alpha: .20),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: userId == null
              ? const Center(child: Text('ログインが必要です'))
              : QrImageView(data: payload, version: QrVersions.auto),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: .08)),
          ),
          child: Text(
            '@${userId ?? '-'}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: .2,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ScanQrCard extends StatelessWidget {
  const _ScanQrCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) => _ExchangeActionCard(
    icon: CupertinoIcons.qrcode_viewfinder,
    title: 'QRを読み取る',
    subtitle: 'カメラまたは画像から相手のNomo QRを読み取る',
    accent: _ExchangeColors.lime,
    onTap: onScan,
  );
}

class _UserIdSearchCard extends StatelessWidget {
  const _UserIdSearchCard({
    required this.controller,
    required this.busy,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final bool busy;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => _DarkCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _PopBadge(
              icon: CupertinoIcons.at,
              color: _ExchangeColors.blue,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'ユーザーIDで検索',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            _MiniPopButton(
              label: busy ? '検索中' : '探す',
              icon: busy ? CupertinoIcons.hourglass : CupertinoIcons.search,
              color: _ExchangeColors.blue,
              onTap: busy ? null : onSubmitted,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DarkInput(
          controller: controller,
          hintText: '例: nomo_yuta_2026',
          onSubmitted: (_) => onSubmitted(),
        ),
      ],
    ),
  );
}

class _ExchangeActionCard extends StatelessWidget {
  const _ExchangeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: _DarkCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _PopBadge(icon: icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .50),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          NomoGeneratedIcon(
            CupertinoIcons.chevron_right,
            color: accent,
            size: 22,
          ),
        ],
      ),
    ),
  );
}

class _UserSearchResultSheet extends StatelessWidget {
  const _UserSearchResultSheet({required this.profile, required this.onAdd});

  final _FriendProfile profile;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
        decoration: BoxDecoration(
          color: _ExchangeColors.card,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _ExchangeColors.teal.withValues(alpha: .14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: _ExchangeColors.teal.withValues(alpha: .35),
                ),
              ),
              child: NomoAvatarView(avatar: profile.avatar, size: 96),
            ),
            const SizedBox(height: 12),
            Text(
              profile.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${profile.userId} を飲み友に追加しますか？',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .52),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _BigPopButton(
              label: '飲み友に追加する',
              icon: CupertinoIcons.person_badge_plus_fill,
              onTap: onAdd,
            ),
          ],
        ),
      ),
    ),
  );
}

class _ExchangeHintCard extends StatelessWidget {
  const _ExchangeHintCard();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .045),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .07)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _PopBadge(
          icon: CupertinoIcons.lock_shield_fill,
          color: _ExchangeColors.purple,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            '交換後に相手のアバターと名前がフレンズに表示されます。',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .55),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: _ExchangeColors.card,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: .085)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .28),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );
}

class _DarkInput extends StatelessWidget {
  const _DarkInput({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      children: [
        const NomoGeneratedIcon(
          CupertinoIcons.at,
          color: _ExchangeColors.blue,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: .35),
                fontWeight: FontWeight.w800,
              ),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: const Center(
        child: NomoPopIcon(
          icon: CupertinoIcons.xmark,
          color: _ExchangeColors.lime,
          size: 34,
          iconSize: 20,
          shadow: false,
        ),
      ),
    ),
  );
}

class _PopBadge extends StatelessWidget {
  const _PopBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => NomoPopIcon(
    icon: icon,
    color: color,
    size: 44,
    iconSize: 25,
    shadow: true,
  );
}

class _MiniPopButton extends StatelessWidget {
  const _MiniPopButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? .55 : 1,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .38),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NomoGeneratedIcon(icon, color: _ExchangeColors.bg, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: _ExchangeColors.bg,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BigPopButton extends StatelessWidget {
  const _BigPopButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 58,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _ExchangeColors.teal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF079078),
            offset: Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NomoGeneratedIcon(icon, color: _ExchangeColors.bg, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _ExchangeColors.bg,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExchangeColors {
  const _ExchangeColors._();

  static const bg = Color(0xFF030B10);
  static const card = Color(0xFF101D29);
  static const lime = Color(0xFFB8FF00);
  static const teal = Color(0xFF17D1AE);
  static const blue = Color(0xFF27B7FF);
  static const purple = Color(0xFFA855F7);
}
