import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../../core/widgets/nomo_exchange_components.dart';
import '../../logs/application/drink_log_controller.dart';
import '../data/friend_repository.dart';

part 'add_nomi_tomo_scanner.dart';
part 'add_nomi_tomo_cards.dart';
part 'add_nomi_tomo_shared.dart';

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
      resizeToAvoidBottomInset: false,
      backgroundColor: _ExchangeColors.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.darkBackgroundGradient,
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
      NomoToast.show(context, 'NomoのフレンズQRではありません。');
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
      NomoToast.show(context, '検索できなかったよ。あとでもう一度試してね');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<NomoFriendProfile?> _findProfileByUserId(String userId) async {
    final repository = ref.read(friendRepositoryProvider);
    if (repository.currentUserId == null) {
      throw StateError('フレンズ追加にはログインが必要です。');
    }
    return repository.findProfileByUserId(userId);
  }

  Future<void> _addFriend(NomoFriendProfile profile) async {
    final repository = ref.read(friendRepositoryProvider);
    final currentUserId = repository.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      NomoToast.show(context, 'フレンズ追加にはログインが必要です。');
      return;
    }
    if (profile.id == currentUserId) {
      NomoToast.show(context, '自分自身は追加できません。');
      return;
    }
    try {
      await repository.addFriend(profile.id);
      ref.invalidate(friendsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      NomoToast.show(context, '${profile.displayName}をフレンズに追加しました。');
    } catch (e) {
      if (!mounted) return;
      NomoToast.show(context, '追加できなかったよ。あとでもう一度試してね');
    }
  }
}

String _friendQrPayload(String userId) => 'nomo://friend/$userId';

String? parseFriendQrPayload(String raw) {
  final value = raw.trim();
  final uri = Uri.tryParse(value);
  if (uri != null && uri.scheme == 'nomo' && uri.host == 'friend') {
    final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    return id?.isEmpty == false ? id : null;
  }
  if (RegExp(r'^[A-Za-z0-9_]{3,24}$').hasMatch(value)) return value;
  return null;
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
              '飲みとも交換',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'QRコードかIDでフレンズにつながろう。',
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
