import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../profile/presentation/avatar_builder_screen.dart';

enum _OnboardingStep { intro, auth, profile }

class CreateUserDialog extends ConsumerStatefulWidget {
  const CreateUserDialog({super.key});

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class NomoDemoScreen extends StatefulWidget {
  const NomoDemoScreen({super.key});

  @override
  State<NomoDemoScreen> createState() => _NomoDemoScreenState();
}

class _NomoDemoScreenState extends State<NomoDemoScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _demoSlides;
    return Scaffold(
      backgroundColor: const Color(0xFF07131F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const NomoGeneratedIcon(
                      CupertinoIcons.xmark,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemCount: slides.length,
                  itemBuilder: (context, index) =>
                      _DemoSlide(slide: slides[index]),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _DemoDots(count: slides.length, selectedIndex: _page),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_page < slides.length - 1) {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                        );
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Color(0xFF12C9A4),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF079078),
                            offset: Offset(0, 6),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: NomoPopIcon(
                          icon: _page == slides.length - 1
                              ? CupertinoIcons.checkmark
                              : CupertinoIcons.arrow_right,
                          color: Colors.white,
                          foregroundColor: Colors.white,
                          showBubble: false,
                          size: 30,
                          iconSize: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _demoController = PageController();
  NomoAvatar _avatar = NomoAvatar.defaultAvatar;
  _OnboardingStep _step = _OnboardingStep.intro;
  int _demoPage = 0;
  bool _isLogin = true;
  bool _isBusy = false;
  bool _nameTouched = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _step = _OnboardingStep.profile;
      _emailController.text = session.user.email ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: Colors.transparent,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: .14),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: switch (_step) {
              _OnboardingStep.intro => _buildIntro(context),
              _OnboardingStep.auth => _buildAuth(context),
              _OnboardingStep.profile => _buildProfile(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    final slides = _demoSlides;
    return SizedBox(
      height: 620,
      width: double.infinity,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _demoController,
              onPageChanged: (index) => setState(() => _demoPage = index),
              itemCount: slides.length,
              itemBuilder: (context, index) => _DemoSlide(slide: slides[index]),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _DemoDots(count: slides.length, selectedIndex: _demoPage),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (_demoPage < slides.length - 1) {
                    _demoController.nextPage(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOutCubic,
                    );
                    return;
                  }
                  setState(() => _step = _OnboardingStep.auth);
                },
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFF12C9A4),
                    shape: BoxShape.circle,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF079078),
                        offset: Offset(0, 6),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: NomoPopIcon(
                      icon: CupertinoIcons.arrow_right,
                      color: Colors.white,
                      foregroundColor: Colors.white,
                      showBubble: false,
                      size: 30,
                      iconSize: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => setState(() => _step = _OnboardingStep.auth),
            child: Text(_demoPage == slides.length - 1 ? 'ログインへ進む' : 'スキップ'),
          ),
        ],
      ),
    );
  }

  Widget _buildAuth(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: _isLogin ? 'ログイン' : '新規登録',
          subtitle: '飲みログを保存するためにアカウントが必要です。',
          onBack: _isBusy
              ? null
              : () => setState(() => _step = _OnboardingStep.intro),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _emailController,
          enabled: !_isBusy,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
          cursorColor: AppColors.ink,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            hintText: 'メールアドレス',
            hintStyle: const TextStyle(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
            prefixIcon: const NomoGeneratedIcon(
              CupertinoIcons.mail,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: !_isBusy,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
          cursorColor: AppColors.ink,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            hintText: 'パスワード（6文字以上）',
            hintStyle: const TextStyle(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
            prefixIcon: const NomoGeneratedIcon(
              CupertinoIcons.lock,
              color: AppColors.ink,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _MessageText(_error!, isError: true),
        ],
        if (_notice != null) ...[
          const SizedBox(height: 12),
          _MessageText(_notice!),
        ],
        const SizedBox(height: 18),
        _PrimaryButton(
          label: _isLogin ? 'ログイン' : '新規登録して続ける',
          icon: _isLogin
              ? CupertinoIcons.person_crop_circle_badge_checkmark
              : CupertinoIcons.person_add_solid,
          busy: _isBusy,
          onPressed: _submitAuth,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isBusy
              ? null
              : () => setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                  _notice = null;
                }),
          child: Text(_isLogin ? 'アカウントがない方はこちら' : 'すでにアカウントがある方はこちら'),
        ),
      ],
    );
  }

  Widget _buildProfile(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: 'プロフィール作成',
          subtitle: '友達リストに表示する名前と自分だけのアバターを作ってね。',
          onBack: _isBusy
              ? null
              : () => setState(() => _step = _OnboardingStep.auth),
        ),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _isBusy ? null : _openAvatarBuilder,
          child: Container(
            width: 128,
            height: 128,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.peach, AppColors.sky],
              ),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: NomoAvatarView(avatar: _avatar),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _isBusy ? null : _openAvatarBuilder,
          icon: const NomoGeneratedIcon(CupertinoIcons.pencil),
          label: const Text('アバターを作る'),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _nameController,
          enabled: !_isBusy,
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
          cursorColor: AppColors.ink,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (!_nameTouched) setState(() => _nameTouched = true);
          },
          decoration: InputDecoration(
            hintText: '名前（必須）',
            hintStyle: const TextStyle(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
            prefixIcon: const NomoGeneratedIcon(
              CupertinoIcons.person_crop_circle,
              color: AppColors.ink,
            ),
            errorText: _nameTouched && _nameController.text.trim().isEmpty
                ? '名前を入力してください'
                : null,
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          _MessageText(_error!, isError: true),
        ],
        if (_notice != null) ...[
          const SizedBox(height: 12),
          _MessageText(_notice!),
        ],
        const SizedBox(height: 18),
        _PrimaryButton(
          label: 'ユーザー作成',
          icon: CupertinoIcons.sparkles,
          busy: _isBusy,
          onPressed: _submitProfile,
        ),
      ],
    );
  }

  Future<void> _submitAuth() async {
    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      final supabase = ref.read(supabaseClientProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (email.isEmpty || password.length < 6) {
        throw const AuthException('メールアドレスと6文字以上のパスワードを入力してください。');
      }

      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final loaded = await ref
            .read(nomoUserProvider.notifier)
            .loadFromSupabaseProfile();
        if (loaded && mounted) {
          Navigator.of(context).pop();
          return;
        }
      } else {
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: SupabaseConfig.authRedirectUrl,
        );
        if (res.session == null) {
          if (mounted) {
            setState(() {
              _notice = '確認メールを送信しました。メール内のリンクを開いてからログインしてください。';
            });
          }
          return;
        }
      }
      if (mounted) {
        setState(() => _step = _OnboardingStep.profile);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(e.message));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'ログインに失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _submitProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameTouched = true;
        _error = 'プロフィールの名前を入力してください。';
        _notice = null;
      });
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref
          .read(nomoUserProvider.notifier)
          .createUser(name: name, avatar: _avatar);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'プロフィール作成に失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _openAvatarBuilder() async {
    final result = await Navigator.of(context).push<NomoAvatar>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) => AvatarBuilderScreen(initialAvatar: _avatar),
      ),
    );
    if (result != null && mounted) {
      setState(() => _avatar = result);
    }
  }
}

String _friendlyAuthError(String message) {
  final lower = message.toLowerCase();
  if (lower.contains('invalid login credentials')) {
    return 'メールアドレスまたはパスワードが違います。dev環境は本番アカウントとは別なので、初回は「アカウントがない方はこちら」から新規登録してください。';
  }
  if (lower.contains('email not confirmed')) {
    return 'メール確認がまだです。確認メールのリンクを開いてからログインしてください。';
  }
  return message;
}

const _demoSlides = [
  _DemoSlideData(
    step: '1 / 4',
    title: 'Nomoで飲みログを\nかわいく残そう',
    subtitle: '今月、誰と何回飲みに行ったかをゆるく記録。健康管理ではなく、友達との思い出を楽しく残すSNSです。',
    kind: _DemoKind.hero,
  ),
  _DemoSlideData(
    step: '2 / 4',
    title: 'プロフィールと\nアバターを作ろう',
    subtitle: '名前と自分らしいアバターを設定。飲み友リストやログにあなたのアイコンとして表示されます。',
    kind: _DemoKind.profile,
  ),
  _DemoSlideData(
    step: '3 / 4',
    title: '飲み会の思い出を\nさっと記録',
    subtitle: '場所、飲み友、日付、メモを残して、カレンダーで今月の交流を振り返れます。',
    kind: _DemoKind.log,
  ),
  _DemoSlideData(
    step: '4 / 4',
    title: '飲み友とつながって\nまた誘おう',
    subtitle: 'QRやユーザーIDで飲み友を追加。今月よく飲んだ友達や、今日誘える友達が見つかります。',
    kind: _DemoKind.friends,
  ),
];

enum _DemoKind { hero, profile, log, friends }

class _DemoSlideData {
  const _DemoSlideData({
    required this.step,
    required this.title,
    required this.subtitle,
    required this.kind,
  });

  final String step;
  final String title;
  final String subtitle;
  final _DemoKind kind;
}

class _DemoSlide extends StatelessWidget {
  const _DemoSlide({required this.slide});

  final _DemoSlideData slide;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF132637), Color(0xFF07131F)],
      ),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withValues(alpha: .10)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          slide.step,
          style: const TextStyle(
            color: Color(0xFF12C9A4),
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          slide.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.25,
            letterSpacing: -.9,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          slide.subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .62),
            fontSize: 14,
            fontWeight: FontWeight.w800,
            height: 1.6,
          ),
        ),
        const Spacer(),
        _DemoVisual(kind: slide.kind),
      ],
    ),
  );
}

class _DemoVisual extends StatelessWidget {
  const _DemoVisual({required this.kind});

  final _DemoKind kind;

  @override
  Widget build(BuildContext context) => switch (kind) {
    _DemoKind.hero => const _HeroDemoVisual(),
    _DemoKind.profile => const _ProfileDemoVisual(),
    _DemoKind.log => const _LogDemoVisual(),
    _DemoKind.friends => const _FriendsDemoVisual(),
  };
}

class _HeroDemoVisual extends StatelessWidget {
  const _HeroDemoVisual();

  @override
  Widget build(BuildContext context) => Center(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 190,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .06),
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        const Positioned(
          left: 30,
          bottom: 8,
          child: NomoAvatarView(avatar: NomoAvatar.defaultAvatar, size: 132),
        ),
        const Positioned(
          right: 20,
          top: 18,
          child: NomoPopIcon(
            icon: CupertinoIcons.sparkles,
            color: Color(0xFFFFC857),
            size: 42,
          ),
        ),
        const Positioned(
          left: -14,
          top: 48,
          child: NomoPopIcon(
            icon: CupertinoIcons.calendar,
            color: Color(0xFF16A8FF),
            size: 48,
          ),
        ),
      ],
    ),
  );
}

class _ProfileDemoVisual extends StatelessWidget {
  const _ProfileDemoVisual();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      children: [
        const NomoAvatarView(avatar: NomoAvatar.defaultAvatar, size: 86),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .24),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 80,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  NomoPopIcon(icon: CupertinoIcons.person_fill, size: 34),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '@nomo_friend',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LogDemoVisual extends StatelessWidget {
  const _LogDemoVisual();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: const Column(
      children: [
        _DemoRow(icon: Icons.local_bar_rounded, label: '今月の飲み', value: '3回'),
        SizedBox(height: 14),
        _DemoRow(
          icon: CupertinoIcons.person_2_fill,
          label: '一緒に飲んだ友達',
          value: '5人',
        ),
        SizedBox(height: 14),
        _DemoRow(icon: CupertinoIcons.calendar, label: 'カレンダーに記録', value: 'OK'),
      ],
    ),
  );
}

class _FriendsDemoVisual extends StatelessWidget {
  const _FriendsDemoVisual();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const NomoAvatarView(avatar: NomoAvatar.defaultAvatar, size: 86),
          const SizedBox(width: 12),
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFC08BFF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: NomoPopIcon(
                icon: CupertinoIcons.heart_fill,
                color: Colors.white,
                foregroundColor: Colors.white,
                showBubble: false,
                size: 42,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF12C9A4),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          '飲み友を追加する',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text(
          'QRコードで交換',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
      ),
    ],
  );
}

class _DemoRow extends StatelessWidget {
  const _DemoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      NomoPopIcon(icon: icon, color: const Color(0xFF12C9A4), size: 42),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .72),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

class _DemoDots extends StatelessWidget {
  const _DemoDots({required this.count, required this.selectedIndex});

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (var i = 0; i < count; i++) ...[
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: i == selectedIndex ? 18 : 9,
          height: 9,
          decoration: BoxDecoration(
            color: i == selectedIndex
                ? const Color(0xFF12C9A4)
                : Colors.white.withValues(alpha: .22),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        if (i != count - 1) const SizedBox(width: 8),
      ],
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle, this.onBack});
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const NomoGeneratedIcon(
                CupertinoIcons.chevron_left,
                size: 20,
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedInk,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Nomo3DButton(
      label: label,
      icon: icon,
      isLoading: busy,
      enabled: onPressed != null,
      onTap: onPressed,
      height: 54,
      radius: 22,
      color: const Color(0xFF12C9A4),
      shadowColor: const Color(0xFF079078),
      fontSize: 15,
    );
  }
}

class _MessageText extends StatelessWidget {
  const _MessageText(this.text, {this.isError = false});
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.coral : AppColors.navy;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          height: 1.45,
        ),
      ),
    );
  }
}
