import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/data/nomo_last_account_store.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../profile/presentation/avatar_builder_screen.dart';

enum _OnboardingStep { intro, auth, profile }

class CreateUserDialog extends ConsumerStatefulWidget {
  const CreateUserDialog({super.key, this.startAtLogin = false});

  final bool startAtLogin;

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
  final _userIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _demoController = PageController();
  NomoAvatar _avatar = NomoAvatar.defaultAvatar;
  _OnboardingStep _step = _OnboardingStep.intro;
  int _demoPage = 0;
  bool _isLogin = true;
  bool _isBusy = false;
  bool _userIdTouched = false;
  bool _nameTouched = false;
  bool _isLastAccountLoaded = false;
  bool _showAuthForm = false;
  bool _obscurePlainLoginPassword = true;
  NomoLastAccount? _lastAccount;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _step = _OnboardingStep.profile;
      _emailController.text = session.user.email ?? '';
      _hydrateProfileFromAuthMetadata(session.user);
    } else if (widget.startAtLogin) {
      _step = _OnboardingStep.auth;
    }
    _showAuthForm = !widget.startAtLogin;
    _loadLastAccount();
  }

  Future<void> _loadLastAccount() async {
    final account = await NomoLastAccountStore.load();
    if (!mounted) return;
    setState(() {
      _lastAccount = account;
      _isLastAccountLoaded = true;
      if (widget.startAtLogin && account == null) {
        _showAuthForm = true;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _userIdController.dispose();
    _nameController.dispose();
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D1A22),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: KeyedSubtree(
              key: ValueKey('$_step-$_showAuthForm-$_isLogin'),
              child: switch (_step) {
                _OnboardingStep.intro => _FullScreenStep(
                  child: _IntroCard(child: _buildIntro(context)),
                ),
                _OnboardingStep.auth => _buildAuth(context),
                _OnboardingStep.profile => _FullScreenStep(
                  child: _AuthSurfaceCard(child: _buildProfile(context)),
                ),
              },
            ),
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
    if (widget.startAtLogin && !_showAuthForm && _isLogin) {
      if (!_isLastAccountLoaded) {
        return const _FullScreenStep(child: _ReLoginLoading());
      }
      final account = _lastAccount;
      if (account != null) {
        return _buildReLogin(context, account);
      }
    }

    if (_isLogin) {
      return _buildPlainLogin(context);
    }

    return _FullScreenStep(
      child: _AuthSurfaceCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Header(
              title: _isLogin ? 'おかえりログイン' : 'Nomoをはじめる',
              subtitle: _isLogin
                  ? '飲みログと飲み友リストの続きを開きましょう。'
                  : '飲みログを保存するためにアカウントが必要です。',
              showBackButton: !widget.startAtLogin || _lastAccount != null,
              onBack: _isBusy
                  ? null
                  : () => setState(() {
                      if (widget.startAtLogin && _lastAccount != null) {
                        _showAuthForm = false;
                        _isLogin = true;
                        _error = null;
                        _notice = null;
                        return;
                      }
                      _step = _OnboardingStep.intro;
                    }),
            ),
            const SizedBox(height: 16),
            _AuthHeroCard(isLogin: _isLogin),
            const SizedBox(height: 16),
            _AuthTextField(
              controller: _emailController,
              enabled: !_isBusy,
              icon: CupertinoIcons.mail,
              hintText: 'メールアドレス',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
            ),
            const SizedBox(height: 12),
            _AuthTextField(
              controller: _passwordController,
              enabled: !_isBusy,
              icon: CupertinoIcons.lock_fill,
              hintText: 'パスワード（6文字以上）',
              obscureText: true,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
            ),
            if (!_isLogin) ...[
              const SizedBox(height: 16),
              _RegistrationProfileFields(
                userIdController: _userIdController,
                nameController: _nameController,
                avatar: _avatar,
                enabled: !_isBusy,
                userIdTouched: _userIdTouched,
                nameTouched: _nameTouched,
                onUserIdChanged: (_) {
                  if (!_userIdTouched) setState(() => _userIdTouched = true);
                },
                onNameChanged: (_) {
                  if (!_nameTouched) setState(() => _nameTouched = true);
                },
                onAvatarTap: _openAvatarBuilder,
              ),
            ],
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
                  ? CupertinoIcons.arrow_right_circle_fill
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
        ),
      ),
    );
  }

  Widget _buildPlainLogin(BuildContext context) {
    final canGoBack = !widget.startAtLogin || _lastAccount != null;
    final canSubmit =
        _emailController.text.trim().isNotEmpty &&
        _passwordController.text.length >= 6 &&
        !_isBusy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
            child: Column(
              children: [
                _PlainLoginHeader(
                  canGoBack: canGoBack,
                  onBack: _isBusy ? null : _handleAuthBack,
                ),
                SizedBox(height: compact ? 24 : 30),
                _PlainLoginFields(
                  emailController: _emailController,
                  passwordController: _passwordController,
                  obscurePassword: _obscurePlainLoginPassword,
                  enabled: !_isBusy,
                  onChanged: (_) => setState(() {}),
                  onPasswordVisibilityTap: () => setState(
                    () => _obscurePlainLoginPassword =
                        !_obscurePlainLoginPassword,
                  ),
                  onSubmitted: canSubmit ? _submitAuth : null,
                ),
                const SizedBox(height: 28),
                _PlainLoginButton(
                  busy: _isBusy,
                  enabled: canSubmit,
                  onTap: canSubmit ? _submitAuth : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _DarkMessageText(_error!, isError: true),
                ],
                if (_notice != null) ...[
                  const SizedBox(height: 14),
                  _DarkMessageText(_notice!),
                ],
                const SizedBox(height: 28),
                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () => _showComingSoonSnack('パスワード再設定は今後対応予定です。'),
                  child: const Text(
                    'パスワードをお忘れですか？',
                    style: TextStyle(
                      color: Color(0xFF55D6FF),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 150 : 260),
                _SocialLoginButton(
                  label: 'GOOGLEでログイン',
                  mark: const _GoogleMark(),
                  onTap: () => _showComingSoonSnack('Googleログインは今後対応予定です。'),
                ),
                const SizedBox(height: 14),
                _SocialLoginButton(
                  label: 'FACEBOOKでログイン',
                  mark: const _FacebookMark(),
                  onTap: () => _showComingSoonSnack('Facebookログインは今後対応予定です。'),
                ),
                const SizedBox(height: 14),
                _SocialLoginButton(
                  label: 'APPLEでログイン',
                  mark: const _AppleMark(),
                  onTap: () => _showComingSoonSnack('Appleログインは今後対応予定です。'),
                ),
                const SizedBox(height: 28),
                Text(
                  'ログインするとNomoの利用規約とプライバシー\nポリシーに同意したことになります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleAuthBack() {
    setState(() {
      if (widget.startAtLogin && _lastAccount != null) {
        _showAuthForm = false;
        _isLogin = true;
        _error = null;
        _notice = null;
        return;
      }
      _step = _OnboardingStep.intro;
    });
  }

  void _showComingSoonSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildReLogin(BuildContext context, NomoLastAccount account) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 680;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 46),
            child: Column(
              children: [
                SizedBox(height: compact ? 12 : 42),
                _ReLoginMascot(size: compact ? 108 : 150),
                SizedBox(height: compact ? 16 : 28),
                Text(
                  '再ログイン',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 28 : 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                SizedBox(height: compact ? 24 : 42),
                _ReLoginAccountCard(
                  account: account,
                  onTap: () {
                    _emailController.text = account.email;
                    setState(() {
                      _showAuthForm = true;
                      _isLogin = true;
                      _error = null;
                      _notice = null;
                    });
                  },
                  onAddAccount: () {
                    _emailController.clear();
                    _passwordController.clear();
                    setState(() {
                      _showAuthForm = true;
                      _isLogin = true;
                      _error = null;
                      _notice = null;
                    });
                  },
                ),
                SizedBox(height: compact ? 22 : 46),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('アカウント管理は今後対応予定です。')),
                    );
                  },
                  child: Text(
                    'アカウント管理',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .42),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        _ProfileTextField(
          controller: _userIdController,
          enabled: !_isBusy,
          icon: CupertinoIcons.at,
          hintText: 'ユーザーID（必須・完全一致検索用）',
          errorText:
              _userIdTouched && !_isValidUserId(_userIdController.text.trim())
              ? '3〜24文字の英数字と_のみ使えます'
              : null,
          onChanged: (_) {
            if (!_userIdTouched) setState(() => _userIdTouched = true);
          },
        ),
        const SizedBox(height: 12),
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
            hintText: 'ユーザー名（必須）',
            hintStyle: const TextStyle(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
            prefixIcon: const NomoGeneratedIcon(
              CupertinoIcons.person_crop_circle,
              color: AppColors.ink,
            ),
            errorText: _nameTouched && _nameController.text.trim().isEmpty
                ? 'ユーザー名を入力してください'
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
      if (!_isLogin && !_validateRegistrationProfile()) return;

      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final loaded = await ref
            .read(nomoUserProvider.notifier)
            .loadFromSupabaseProfile();
        if (loaded && mounted) {
          await _saveLastAccount(email);
          return;
        }
        _hydrateProfileFromAuthMetadata(supabase.auth.currentUser);
      } else {
        final userId = _userIdController.text.trim();
        final name = _nameController.text.trim();
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: SupabaseConfig.authRedirectUrl,
          data: {
            'user_id': userId,
            'display_name': name,
            'character_key': 'avatar',
            'avatar_url': _avatar.encode(),
          },
        );
        if (res.session != null) {
          await ref
              .read(nomoUserProvider.notifier)
              .createUser(name: name, userId: userId, avatar: _avatar);
          await _saveLastAccount(email);
          return;
        }
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
    if (!_validateRegistrationProfile()) return;
    final userId = _userIdController.text.trim();
    final name = _nameController.text.trim();

    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref
          .read(nomoUserProvider.notifier)
          .createUser(name: name, userId: userId, avatar: _avatar);
      await _saveLastAccount(_emailController.text.trim());
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'プロフィール作成に失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  bool _validateRegistrationProfile() {
    final userId = _userIdController.text.trim();
    final name = _nameController.text.trim();
    if (!_isValidUserId(userId)) {
      setState(() {
        _userIdTouched = true;
        _error = 'ユーザーIDは3〜24文字の英数字と_のみ使えます。';
        _notice = null;
      });
      return false;
    }
    if (name.isEmpty) {
      setState(() {
        _nameTouched = true;
        _error = 'ユーザー名を入力してください。';
        _notice = null;
      });
      return false;
    }
    return true;
  }

  void _hydrateProfileFromAuthMetadata(User? user) {
    final metadata = user?.userMetadata;
    if (metadata == null) return;
    final userId = metadata['user_id'] as String?;
    final displayName = metadata['display_name'] as String?;
    final avatarUrl = metadata['avatar_url'] as String?;
    if (userId != null && _userIdController.text.trim().isEmpty) {
      _userIdController.text = userId;
    }
    if (displayName != null && _nameController.text.trim().isEmpty) {
      _nameController.text = displayName;
    }
    final avatar = NomoAvatar.decode(avatarUrl);
    if (avatar != null) _avatar = avatar;
  }

  Future<void> _saveLastAccount(String email) async {
    final user = ref.read(nomoUserProvider);
    await NomoLastAccountStore.save(
      name: user?.name ?? _nameController.text,
      email: email,
      avatar: user?.avatar ?? _avatar,
    );
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

class _FullScreenStep extends StatelessWidget {
  const _FullScreenStep({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 42),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _AuthSurfaceCard extends StatelessWidget {
  const _AuthSurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(32),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .24),
          blurRadius: 32,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: child,
  );
}

class _ReLoginLoading extends StatelessWidget {
  const _ReLoginLoading();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ReLoginMascot(size: 112),
        const SizedBox(height: 24),
        CircularProgressIndicator(
          color: const Color(0xFF8BDB00),
          backgroundColor: Colors.white.withValues(alpha: .10),
        ),
      ],
    ),
  );
}

class _ReLoginMascot extends StatelessWidget {
  const _ReLoginMascot({this.size = 150});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * 1.12,
    child: CustomPaint(painter: _ReLoginMascotPainter()),
  );
}

class _ReLoginMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final green = Paint()..color = const Color(0xFF7ED300);
    final light = Paint()..color = const Color(0xFF98EA12);
    final dark = Paint()..color = const Color(0xFF31424B);
    final white = Paint()..color = Colors.white;
    final orange = Paint()..color = const Color(0xFFFF9E1B);
    final shadow = Paint()
      ..color = Colors.white.withValues(alpha: .86)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * .05;

    final body = Path()
      ..moveTo(w * .30, h * .30)
      ..cubicTo(w * .18, h * .29, w * .14, h * .42, w * .21, h * .53)
      ..lineTo(w * .18, h * .75)
      ..cubicTo(w * .29, h * .70, w * .37, h * .67, w * .48, h * .70)
      ..cubicTo(w * .69, h * .75, w * .85, h * .58, w * .78, h * .36)
      ..cubicTo(w * .86, h * .20, w * .73, h * .08, w * .63, h * .27)
      ..cubicTo(w * .55, h * .20, w * .44, h * .28, w * .30, h * .30)
      ..close();
    canvas.drawPath(body, green);

    final belly = Path()
      ..moveTo(w * .34, h * .48)
      ..cubicTo(w * .45, h * .66, w * .65, h * .62, w * .67, h * .43)
      ..cubicTo(w * .58, h * .56, w * .45, h * .58, w * .34, h * .48)
      ..close();
    canvas.drawPath(belly, light);

    canvas.drawCircle(Offset(w * .37, h * .38), w * .13, white);
    canvas.drawCircle(Offset(w * .59, h * .34), w * .13, white);
    canvas.drawCircle(Offset(w * .40, h * .40), w * .055, dark);
    canvas.drawCircle(Offset(w * .57, h * .34), w * .055, dark);
    canvas.drawCircle(Offset(w * .43, h * .37), w * .022, white);
    canvas.drawCircle(Offset(w * .60, h * .31), w * .022, white);

    final beak = Path()
      ..moveTo(w * .47, h * .46)
      ..lineTo(w * .57, h * .42)
      ..lineTo(w * .52, h * .51)
      ..close();
    canvas.drawPath(beak, orange);

    for (final offset in [
      Offset(w * .47, h * .58),
      Offset(w * .56, h * .57),
      Offset(w * .53, h * .65),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: offset, width: w * .08, height: h * .035),
        light,
      );
    }

    canvas.drawOval(Rect.fromLTWH(w * .42, h * .77, w * .16, h * .07), orange);
    canvas.drawOval(Rect.fromLTWH(w * .65, h * .76, w * .16, h * .07), orange);
    canvas.drawLine(Offset(w * .30, h * .89), Offset(w * .82, h * .89), shadow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReLoginAccountCard extends StatelessWidget {
  const _ReLoginAccountCard({
    required this.account,
    required this.onTap,
    required this.onAddAccount,
  });

  final NomoLastAccount account;
  final VoidCallback onTap;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF101F28).withValues(alpha: .82),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .20), width: 2),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.peach, AppColors.lavender],
                    ),
                  ),
                  child: NomoAvatarView(
                    avatar: account.avatar ?? NomoAvatar.defaultAvatar,
                    size: 50,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.2,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        account.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .36),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                NomoGeneratedIcon(
                  CupertinoIcons.chevron_right,
                  color: Colors.white.withValues(alpha: .68),
                  size: 28,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: .16)),
        InkWell(
          onTap: onAddAccount,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .34),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: NomoGeneratedIcon(
                      CupertinoIcons.plus,
                      color: Colors.white.withValues(alpha: .44),
                      size: 27,
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Text(
                  '別のアカウントを追加',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .44),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlainLoginHeader extends StatelessWidget {
  const _PlainLoginHeader({required this.canGoBack, required this.onBack});

  final bool canGoBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: canGoBack
              ? IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    CupertinoIcons.arrow_left,
                    color: Colors.white.withValues(alpha: .72),
                    size: 31,
                  ),
                )
              : const SizedBox(width: 48),
        ),
        Text(
          'ログイン',
          style: TextStyle(
            color: Colors.white.withValues(alpha: .34),
            fontSize: 25,
            fontWeight: FontWeight.w900,
            letterSpacing: -.2,
          ),
        ),
      ],
    ),
  );
}

class _PlainLoginFields extends StatelessWidget {
  const _PlainLoginFields({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.enabled,
    required this.onChanged,
    required this.onPasswordVisibilityTap,
    required this.onSubmitted,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onPasswordVisibilityTap;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF132630).withValues(alpha: .74),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .18), width: 2),
    ),
    child: Column(
      children: [
        _PlainLoginTextField(
          controller: emailController,
          enabled: enabled,
          hintText: 'Eメール/電話番号/ユーザー名',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email, AutofillHints.username],
          onChanged: onChanged,
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: .14)),
        _PlainLoginTextField(
          controller: passwordController,
          enabled: enabled,
          hintText: 'パスワード',
          obscureText: obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onChanged: onChanged,
          onSubmitted: (_) => onSubmitted?.call(),
          trailing: IconButton(
            onPressed: enabled ? onPasswordVisibilityTap : null,
            icon: Icon(
              obscurePassword
                  ? CupertinoIcons.eye_slash_fill
                  : CupertinoIcons.eye_fill,
              color: const Color(0xFF18A7D5).withValues(alpha: .78),
              size: 28,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PlainLoginTextField extends StatelessWidget {
  const _PlainLoginTextField({
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.onSubmitted,
    this.trailing,
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: Row(
      children: [
        const SizedBox(width: 26),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
            cursorColor: const Color(0xFF55D6FF),
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: .29),
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
          const SizedBox(width: 14),
        ] else
          const SizedBox(width: 26),
      ],
    ),
  );
}

class _PlainLoginButton extends StatelessWidget {
  const _PlainLoginButton({
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? const Color(0xFF55D6FF)
            : const Color(0xFF526671).withValues(alpha: .62),
        borderRadius: BorderRadius.circular(17),
      ),
      child: busy
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.8,
                color: Colors.white,
              ),
            )
          : Text(
              'ログイン',
              style: TextStyle(
                color: enabled
                    ? const Color(0xFF0D1A22)
                    : Colors.white.withValues(alpha: .26),
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
    ),
  );
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.mark,
    required this.onTap,
  });

  final String label;
  final Widget mark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: .20),
          width: 2.4,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 34, child: Center(child: mark)),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    ),
  );
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => const Text(
    'G',
    style: TextStyle(
      color: Color(0xFF4285F4),
      fontSize: 27,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _FacebookMark extends StatelessWidget {
  const _FacebookMark();

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: const BoxDecoration(
      color: Color(0xFF2E89FF),
      shape: BoxShape.circle,
    ),
    alignment: Alignment.center,
    child: const Text(
      'f',
      style: TextStyle(
        color: Colors.white,
        fontSize: 25,
        height: .9,
        fontWeight: FontWeight.w900,
      ),
    ),
  );
}

class _AppleMark extends StatelessWidget {
  const _AppleMark();

  @override
  Widget build(BuildContext context) =>
      const Icon(Icons.apple, color: Colors.white, size: 35);
}

class _DarkMessageText extends StatelessWidget {
  const _DarkMessageText(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.coral : const Color(0xFF55D6FF);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1.45,
        ),
      ),
    );
  }
}

class _AuthHeroCard extends StatelessWidget {
  const _AuthHeroCard({required this.isLogin});

  final bool isLogin;

  @override
  Widget build(BuildContext context) {
    final height = isLogin ? 154.0 : 118.0;
    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEEF5), Color(0xFFE8F6FF), Color(0xFFEDE7FF)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: .86)),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withValues(alpha: .16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            right: -8,
            top: -10,
            child: _AuthDecorativeIcon(
              icon: CupertinoIcons.sparkles,
              color: AppColors.orange,
              size: 60,
              angle: .16,
            ),
          ),
          const Positioned(
            left: -10,
            bottom: -12,
            child: _AuthDecorativeIcon(
              icon: Icons.local_bar_rounded,
              color: AppColors.beer,
              size: 64,
              angle: -.12,
            ),
          ),
          Positioned(
            right: isLogin ? 14 : 18,
            bottom: isLogin ? 12 : 14,
            child: const _AuthDecorativeIcon(
              icon: CupertinoIcons.heart_fill,
              color: AppColors.rose,
              size: 42,
              angle: -.08,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
            child: Row(
              children: [
                _AuthAvatarBadge(size: isLogin ? 82 : 68),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLogin ? 'また乾杯を記録しよう' : '可愛いプロフィールで参加',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isLogin
                            ? 'アイコン・カレンダー・飲み友を、ログインして続きから。'
                            : '飲み友に見える名前とアイコンを一緒に作ります。',
                        maxLines: isLogin ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.mutedInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          height: 1.35,
                        ),
                      ),
                      if (isLogin) ...[
                        const SizedBox(height: 10),
                        const Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _AuthMiniBadge(
                              icon: Icons.local_bar_rounded,
                              label: '飲みログ',
                            ),
                            _AuthMiniBadge(
                              icon: CupertinoIcons.person_2_fill,
                              label: '飲み友',
                            ),
                            _AuthMiniBadge(
                              icon: CupertinoIcons.calendar,
                              label: '予定',
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthAvatarBadge extends StatelessWidget {
  const _AuthAvatarBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .075),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(colors: [AppColors.peach, AppColors.sky]),
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: .10),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: const NomoAvatarView(avatar: NomoAvatar.defaultAvatar),
  );
}

class _AuthDecorativeIcon extends StatelessWidget {
  const _AuthDecorativeIcon({
    required this.icon,
    required this.color,
    required this.size,
    this.angle = 0,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double angle;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: .28)),
      ),
      child: Center(
        child: NomoPopIcon(
          icon: icon,
          color: color,
          size: size * .58,
          showBubble: false,
        ),
      ),
    ),
  );
}

class _AuthMiniBadge extends StatelessWidget {
  const _AuthMiniBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: AppColors.navy.withValues(alpha: .08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NomoGeneratedIcon(icon, color: AppColors.navy, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.navy,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    this.onBack,
    this.showBackButton = true,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 48,
              child: showBackButton
                  ? IconButton(
                      onPressed: onBack,
                      icon: const NomoGeneratedIcon(
                        CupertinoIcons.chevron_left,
                        size: 20,
                      ),
                    )
                  : const SizedBox.shrink(),
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

bool _isValidUserId(String value) =>
    RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(value);

class _RegistrationProfileFields extends StatelessWidget {
  const _RegistrationProfileFields({
    required this.userIdController,
    required this.nameController,
    required this.avatar,
    required this.enabled,
    required this.userIdTouched,
    required this.nameTouched,
    required this.onUserIdChanged,
    required this.onNameChanged,
    required this.onAvatarTap,
  });

  final TextEditingController userIdController;
  final TextEditingController nameController;
  final NomoAvatar avatar;
  final bool enabled;
  final bool userIdTouched;
  final bool nameTouched;
  final ValueChanged<String> onUserIdChanged;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .78),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE4E8F0), width: 1.4),
    ),
    child: Column(
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: enabled ? onAvatarTap : null,
              child: Container(
                width: 64,
                height: 64,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.peach, AppColors.sky],
                  ),
                  border: Border.all(color: Colors.white, width: 2.5),
                ),
                child: NomoAvatarView(avatar: avatar),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'プロフィール',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '登録と同時に作成します',
                    style: TextStyle(
                      color: AppColors.mutedInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileTextField(
          controller: userIdController,
          enabled: enabled,
          icon: CupertinoIcons.at,
          hintText: 'ユーザーID（必須・完全一致検索用）',
          errorText:
              userIdTouched && !_isValidUserId(userIdController.text.trim())
              ? '3〜24文字の英数字と_のみ使えます'
              : null,
          onChanged: onUserIdChanged,
        ),
        const SizedBox(height: 10),
        _ProfileTextField(
          controller: nameController,
          enabled: enabled,
          icon: CupertinoIcons.person_crop_circle,
          hintText: 'ユーザー名（必須）',
          errorText: nameTouched && nameController.text.trim().isEmpty
              ? 'ユーザー名を入力してください'
              : null,
          onChanged: onNameChanged,
        ),
      ],
    ),
  );
}

class _ProfileTextField extends StatelessWidget {
  const _ProfileTextField({
    required this.controller,
    required this.enabled,
    required this.icon,
    required this.hintText,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final String hintText;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _AuthTextField(
        controller: controller,
        enabled: enabled,
        icon: icon,
        hintText: hintText,
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
      ),
      if (errorText != null) ...[
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            errorText!,
            style: const TextStyle(
              color: AppColors.coral,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ],
  );
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    required this.enabled,
    required this.icon,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.obscureText = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    decoration: BoxDecoration(
      color: const Color(0xFFF7F8FB),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE4E8F0), width: 1.6),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: .04),
          blurRadius: 16,
          offset: const Offset(0, 7),
        ),
      ],
    ),
    child: Row(
      children: [
        const SizedBox(width: 16),
        NomoGeneratedIcon(icon, color: AppColors.navy, size: 25),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
            cursorColor: AppColors.navy,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            obscureText: obscureText,
            onChanged: onChanged,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              hintText: hintText,
              hintStyle: const TextStyle(
                color: AppColors.mutedInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
      ],
    ),
  );
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
