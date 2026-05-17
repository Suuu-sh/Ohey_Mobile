import 'dart:math' as math;

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

enum _OnboardingStep { intro, accountChoice, auth, profile }

enum _RegistrationStep { email, password }

const _authPink = AppColors.coral;
const _authPinkShadow = Color(0xFFE05F83);
const _authPinkInk = Color(0xFF2B1320);

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
  bool _obscureSignupPassword = true;
  _RegistrationStep _registrationStep = _RegistrationStep.email;
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
              key: ValueKey(
                '$_step-$_showAuthForm-$_isLogin-$_registrationStep',
              ),
              child: switch (_step) {
                _OnboardingStep.intro => _FullScreenStep(
                  child: _IntroCard(child: _buildIntro(context)),
                ),
                _OnboardingStep.accountChoice => _buildAccountChoice(context),
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
                  setState(() => _step = _OnboardingStep.accountChoice);
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
            onPressed: () =>
                setState(() => _step = _OnboardingStep.accountChoice),
            child: Text(_demoPage == slides.length - 1 ? 'はじめる' : 'スキップ'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountChoice(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 640;
        return _fixedAuthPage(
          constraints: constraints,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            children: [
              _AccountChoiceHeader(
                onBack: _isBusy
                    ? null
                    : () => setState(() {
                        if (widget.startAtLogin && _lastAccount != null) {
                          _step = _OnboardingStep.auth;
                          _showAuthForm = false;
                          _isLogin = true;
                        } else {
                          _step = _OnboardingStep.intro;
                        }
                        _error = null;
                        _notice = null;
                      }),
              ),
              const Spacer(flex: 5),
              Text(
                'すでにアカウントをお持ち\nですか？',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 24 : 27,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                  letterSpacing: -.8,
                ),
              ),
              SizedBox(height: compact ? 26 : 44),
              _AccountChoicePrimaryButton(
                label: 'ログイン',
                height: compact ? 58 : 64,
                onTap: _showLoginForm,
              ),
              SizedBox(height: compact ? 30 : 54),
              Divider(
                height: 1,
                thickness: 2,
                color: Colors.white.withValues(alpha: .18),
              ),
              SizedBox(height: compact ? 30 : 54),
              Text(
                'Nomoは初めてですか',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 23 : 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              SizedBox(height: compact ? 28 : 40),
              _AccountChoiceOutlineButton(
                label: 'サインアップ',
                height: compact ? 58 : 64,
                onTap: _showRegistrationForm,
              ),
              const Spacer(flex: 6),
            ],
          ),
        );
      },
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

    return _buildSignupStep(context);
  }

  Widget _buildSignupStep(BuildContext context) {
    final isEmailStep = _registrationStep == _RegistrationStep.email;
    final canContinue = _emailController.text.trim().isNotEmpty && !_isBusy;
    final canRegister = _passwordController.text.length >= 6 && !_isBusy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 640;
        final textFieldHeight = compact ? 56.0 : 64.0;
        final buttonHeight = compact ? 56.0 : 64.0;
        final socialHeight = compact ? 52.0 : 64.0;
        return _fixedAuthPage(
          constraints: constraints,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignupProgressHeader(
                progress: isEmailStep ? .48 : .76,
                onBack: _isBusy ? null : _handleSignupBack,
              ),
              SizedBox(height: compact ? 34 : 64),
              Text(
                isEmailStep ? 'メールアドレスを入力して\nください' : 'パスワードを入力してください',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 27 : 28,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                  letterSpacing: -.8,
                ),
              ),
              SizedBox(height: compact ? 28 : 42),
              _SignupInputBox(
                child: _PlainLoginTextField(
                  controller: isEmailStep
                      ? _emailController
                      : _passwordController,
                  enabled: !_isBusy,
                  hintText: isEmailStep ? 'メールアドレス' : 'パスワード',
                  height: textFieldHeight,
                  keyboardType: isEmailStep ? TextInputType.emailAddress : null,
                  textInputAction: isEmailStep
                      ? TextInputAction.next
                      : TextInputAction.done,
                  autofillHints: isEmailStep
                      ? const [AutofillHints.email]
                      : const [AutofillHints.newPassword],
                  obscureText: !isEmailStep && _obscureSignupPassword,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (isEmailStep && canContinue) {
                      _goToSignupPasswordStep();
                    } else if (!isEmailStep && canRegister) {
                      _submitAuth();
                    }
                  },
                  trailing: isEmailStep
                      ? null
                      : IconButton(
                          onPressed: _isBusy
                              ? null
                              : () => setState(
                                  () => _obscureSignupPassword =
                                      !_obscureSignupPassword,
                                ),
                          icon: Icon(
                            _obscureSignupPassword
                                ? CupertinoIcons.eye_slash_fill
                                : CupertinoIcons.eye_fill,
                            color: _authPink.withValues(alpha: .78),
                            size: 28,
                          ),
                        ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _DarkMessageText(_error!, isError: true),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 10),
                _DarkMessageText(_notice!),
              ],
              SizedBox(height: compact ? 24 : 42),
              _SignupStepButton(
                label: isEmailStep ? '次へ' : 'アカウントを登録（無料）',
                height: buttonHeight,
                busy: _isBusy,
                enabled: isEmailStep ? canContinue : canRegister,
                onTap: isEmailStep
                    ? (canContinue ? _goToSignupPasswordStep : null)
                    : (canRegister ? _submitAuth : null),
              ),
              if (!isEmailStep) ...[
                const SizedBox(height: 20),
                Text(
                  '登録するとNomoの利用規約とプライバシー\nポリシーに同意したことになります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .82),
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w800,
                    height: 1.45,
                  ),
                ),
                const Spacer(),
              ],
              if (isEmailStep) ...[
                const Spacer(),
                _SocialLoginButton(
                  label: 'GOOGLEで登録',
                  height: socialHeight,
                  mark: const _GoogleMark(),
                  onTap: () => _showComingSoonSnack('Google登録は今後対応予定です。'),
                ),
                SizedBox(height: compact ? 10 : 14),
                _SocialLoginButton(
                  label: 'APPLEで登録',
                  height: socialHeight,
                  mark: const _AppleMark(),
                  onTap: () => _showComingSoonSnack('Apple登録は今後対応予定です。'),
                ),
              ],
            ],
          ),
        );
      },
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
        final compact = constraints.maxHeight < 640;
        final fieldHeight = compact ? 52.0 : 64.0;
        final loginHeight = compact ? 52.0 : 60.0;
        final socialHeight = compact ? 50.0 : 64.0;
        return _fixedAuthPage(
          constraints: constraints,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            children: [
              _PlainLoginHeader(
                canGoBack: canGoBack,
                onBack: _isBusy ? null : _handleAuthBack,
              ),
              SizedBox(height: compact ? 16 : 30),
              _PlainLoginFields(
                emailController: _emailController,
                passwordController: _passwordController,
                obscurePassword: _obscurePlainLoginPassword,
                enabled: !_isBusy,
                fieldHeight: fieldHeight,
                onChanged: (_) => setState(() {}),
                onPasswordVisibilityTap: () => setState(
                  () =>
                      _obscurePlainLoginPassword = !_obscurePlainLoginPassword,
                ),
                onSubmitted: canSubmit ? _submitAuth : null,
              ),
              SizedBox(height: compact ? 18 : 28),
              _PlainLoginButton(
                height: loginHeight,
                busy: _isBusy,
                enabled: canSubmit,
                onTap: canSubmit ? _submitAuth : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _DarkMessageText(_error!, isError: true),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 10),
                _DarkMessageText(_notice!),
              ],
              SizedBox(height: compact ? 10 : 22),
              SizedBox(
                height: compact ? 38 : 44,
                child: TextButton(
                  onPressed: _isBusy
                      ? null
                      : () => _showComingSoonSnack('パスワード再設定は今後対応予定です。'),
                  child: const Text(
                    'パスワードをお忘れですか？',
                    style: TextStyle(
                      color: _authPink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _SocialLoginButton(
                label: 'GOOGLEでログイン',
                height: socialHeight,
                mark: const _GoogleMark(),
                onTap: () => _showComingSoonSnack('Googleログインは今後対応予定です。'),
              ),
              SizedBox(height: compact ? 10 : 14),
              _SocialLoginButton(
                label: 'APPLEでログイン',
                height: socialHeight,
                mark: const _AppleMark(),
                onTap: () => _showComingSoonSnack('Appleログインは今後対応予定です。'),
              ),
              SizedBox(height: compact ? 12 : 24),
              Text(
                'ログインするとNomoの利用規約とプライバシー\nポリシーに同意したことになります。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ],
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
      _step = _OnboardingStep.accountChoice;
      _isLogin = true;
      _error = null;
      _notice = null;
    });
  }

  void _showLoginForm() {
    setState(() {
      _step = _OnboardingStep.auth;
      _isLogin = true;
      _showAuthForm = true;
      _registrationStep = _RegistrationStep.email;
      _error = null;
      _notice = null;
    });
  }

  void _showRegistrationForm() {
    setState(() {
      _step = _OnboardingStep.auth;
      _isLogin = false;
      _showAuthForm = true;
      _registrationStep = _RegistrationStep.email;
      _passwordController.clear();
      _error = null;
      _notice = null;
    });
  }

  void _handleSignupBack() {
    setState(() {
      if (_registrationStep == _RegistrationStep.password) {
        _registrationStep = _RegistrationStep.email;
        _error = null;
        _notice = null;
        return;
      }
      _step = _OnboardingStep.accountChoice;
      _isLogin = true;
      _error = null;
      _notice = null;
    });
  }

  void _goToSignupPasswordStep() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'メールアドレスを入力してください。');
      return;
    }
    setState(() {
      _registrationStep = _RegistrationStep.password;
      _error = null;
      _notice = null;
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
        final compact = constraints.maxHeight < 640;
        return _fixedAuthPage(
          constraints: constraints,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              _ReLoginMascot(size: compact ? 104 : 150),
              SizedBox(height: compact ? 14 : 28),
              Text(
                '再ログイン',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 28 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              SizedBox(height: compact ? 22 : 42),
              _ReLoginAccountCard(
                account: account,
                compact: compact,
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
                    _step = _OnboardingStep.accountChoice;
                    _showAuthForm = false;
                    _isLogin = true;
                    _error = null;
                    _notice = null;
                  });
                },
              ),
              SizedBox(height: compact ? 12 : 34),
              SizedBox(
                height: compact ? 40 : 48,
                child: TextButton(
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
              ),
              const Spacer(flex: 3),
            ],
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
        final userId = _signupUserId(email);
        final name = _signupDisplayName(email);
        if (_userIdController.text.trim().isEmpty) {
          _userIdController.text = userId;
        }
        if (_nameController.text.trim().isEmpty) {
          _nameController.text = name;
        }
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
    final displayName = await _latestDisplayName(user?.name);
    await NomoLastAccountStore.save(
      name: displayName,
      email: email,
      avatar: user?.avatar ?? _avatar,
    );
  }

  Future<String?> _latestDisplayName(String? fallback) async {
    final authUserId = ref.read(supabaseClientProvider).auth.currentUser?.id;
    if (authUserId == null || authUserId.isEmpty) return fallback;

    try {
      final row = await ref
          .read(supabaseClientProvider)
          .from('profiles')
          .select('display_name')
          .eq('id', authUserId)
          .maybeSingle();
      final displayName = (row?['display_name'] as String?)?.trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }
    } catch (_) {
      // Re-login can still proceed even if refreshing the cached label fails.
    }
    return fallback;
  }

  String _signupDisplayName(String email) {
    final entered = _nameController.text.trim();
    if (entered.isNotEmpty) return entered;
    final localPart = email.split('@').first.trim();
    return localPart.isEmpty ? 'Nomoユーザー' : localPart;
  }

  String _signupUserId(String email) {
    final entered = _userIdController.text.trim();
    if (_isValidUserId(entered)) return entered;

    final localPart = email.split('@').first.toLowerCase();
    final base = localPart
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final suffix = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final prefix = (base.isEmpty ? 'nomo' : base);
    final maxPrefixLength = 24 - suffix.length - 1;
    final compactPrefix = prefix.length > maxPrefixLength
        ? prefix.substring(0, maxPrefixLength)
        : prefix;
    return '${compactPrefix}_$suffix';
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

Widget _fixedAuthPage({
  required BoxConstraints constraints,
  required EdgeInsets padding,
  required Widget child,
}) {
  final availableHeight = constraints.maxHeight.isFinite
      ? constraints.maxHeight - padding.vertical
      : 720.0;
  return Padding(
    padding: padding,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SizedBox(
          height: availableHeight > 0 ? availableHeight : 0,
          child: child,
        ),
      ),
    ),
  );
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
      builder: (context, constraints) => _fixedAuthPage(
        constraints: constraints,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Center(child: child),
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
          color: _authPink,
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
    height: size * 1.06,
    child: CustomPaint(painter: _ReLoginMascotPainter()),
  );
}

class _ReLoginMascotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final body = Paint()..color = const Color(0xFFFF4FA3);
    final bodyDark = Paint()..color = const Color(0xFFE52B83);
    final bodyLight = Paint()..color = const Color(0xFFFF86C7);
    final outline = Paint()
      ..color = const Color(0xFFFFA4D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .018
      ..strokeCap = StrokeCap.round;
    final eye = Paint()..color = const Color(0xFF101827);
    final white = Paint()..color = Colors.white;
    final mouth = Paint()..color = const Color(0xFF251225);
    final tongue = Paint()..color = const Color(0xFFFF6AAE);
    final leaf = Paint()..color = const Color(0xFF84E817);
    final leafDark = Paint()..color = const Color(0xFF58C80A);
    final sparkle = Paint()..color = const Color(0xFFFF4FAB);

    void rotatedOval(
      Offset center,
      double width,
      double height,
      double radians,
      Paint paint,
    ) {
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(radians)
        ..drawOval(
          Rect.fromCenter(center: Offset.zero, width: width, height: height),
          paint,
        )
        ..restore();
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .50, h * .86),
        width: w * .48,
        height: h * .075,
      ),
      Paint()..color = const Color(0xFFFF4FAB).withValues(alpha: .16),
    );

    rotatedOval(Offset(w * .33, h * .76), w * .20, h * .17, -.58, bodyDark);
    rotatedOval(Offset(w * .57, h * .79), w * .18, h * .22, -.12, bodyDark);
    rotatedOval(Offset(w * .18, h * .49), w * .18, h * .27, -.58, bodyDark);
    rotatedOval(Offset(w * .82, h * .56), w * .18, h * .24, .18, bodyDark);

    final bodyRect = Rect.fromCenter(
      center: Offset(w * .50, h * .54),
      width: w * .66,
      height: h * .58,
    );
    canvas.drawOval(bodyRect, body);
    canvas.drawOval(bodyRect, outline);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .38, h * .39),
        width: w * .30,
        height: h * .13,
      ),
      bodyLight..color = const Color(0xFFFF86C7).withValues(alpha: .36),
    );

    final stem = Path()
      ..moveTo(w * .50, h * .26)
      ..cubicTo(w * .52, h * .20, w * .58, h * .21, w * .59, h * .29)
      ..cubicTo(w * .56, h * .31, w * .52, h * .31, w * .49, h * .29)
      ..close();
    canvas.drawPath(stem, leafDark);

    final leafPath = Path()
      ..moveTo(w * .52, h * .20)
      ..cubicTo(w * .58, h * .07, w * .83, h * .08, w * .83, h * .23)
      ..cubicTo(w * .81, h * .36, w * .60, h * .36, w * .52, h * .20)
      ..close();
    canvas.drawPath(leafPath, leaf);
    canvas.drawPath(
      leafPath,
      Paint()
        ..color = Colors.white.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .012,
    );

    rotatedOval(Offset(w * .38, h * .48), w * .17, h * .27, .17, eye);
    rotatedOval(Offset(w * .60, h * .50), w * .17, h * .27, -.08, eye);
    canvas.drawCircle(Offset(w * .41, h * .42), w * .035, white);
    canvas.drawCircle(Offset(w * .62, h * .44), w * .035, white);

    final smile = Path()
      ..moveTo(w * .43, h * .61)
      ..cubicTo(w * .46, h * .70, w * .58, h * .70, w * .61, h * .61)
      ..cubicTo(w * .57, h * .64, w * .48, h * .64, w * .43, h * .61)
      ..close();
    canvas.drawPath(smile, mouth);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .52, h * .66),
        width: w * .11,
        height: h * .045,
      ),
      tongue,
    );

    final starCenter = Offset(w * .88, h * .33);
    final star = Path();
    for (var i = 0; i < 8; i++) {
      final radius = i.isEven ? w * .08 : w * .028;
      final angle = -math.pi / 2 + i * math.pi / 4;
      final point = Offset(
        starCenter.dx + math.cos(angle) * radius,
        starCenter.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        star.moveTo(point.dx, point.dy);
      } else {
        star.lineTo(point.dx, point.dy);
      }
    }
    star.close();
    canvas.drawPath(star, sparkle);
    canvas.drawPath(
      star,
      Paint()
        ..color = const Color(0xFFFF9BD0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .012,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReLoginAccountCard extends StatelessWidget {
  const _ReLoginAccountCard({
    required this.account,
    required this.onTap,
    required this.onAddAccount,
    this.compact = false,
  });

  final NomoLastAccount account;
  final VoidCallback onTap;
  final VoidCallback onAddAccount;
  final bool compact;

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
            padding: compact
                ? const EdgeInsets.fromLTRB(18, 14, 16, 12)
                : const EdgeInsets.fromLTRB(20, 18, 18, 16),
            child: Row(
              children: [
                Container(
                  width: compact ? 52 : 58,
                  height: compact ? 52 : 58,
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.peach, AppColors.lavender],
                    ),
                  ),
                  child: NomoAvatarView(
                    avatar: account.avatar ?? NomoAvatar.defaultAvatar,
                    size: compact ? 44 : 50,
                  ),
                ),
                SizedBox(width: compact ? 14 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 18 : 19,
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
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                NomoGeneratedIcon(
                  CupertinoIcons.chevron_right,
                  color: Colors.white.withValues(alpha: .68),
                  size: compact ? 26 : 28,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: Colors.white.withValues(alpha: .16)),
        InkWell(
          onTap: onAddAccount,
          child: Padding(
            padding: compact
                ? const EdgeInsets.fromLTRB(18, 16, 18, 16)
                : const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Row(
              children: [
                Container(
                  width: compact ? 50 : 56,
                  height: compact ? 50 : 56,
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
                      size: compact ? 25 : 27,
                    ),
                  ),
                ),
                SizedBox(width: compact ? 16 : 18),
                Text(
                  '別のアカウントを追加',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .44),
                    fontSize: compact ? 16 : 17,
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

class _SignupProgressHeader extends StatelessWidget {
  const _SignupProgressHeader({required this.progress, required this.onBack});

  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF12222C),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onBack,
          icon: Icon(
            CupertinoIcons.arrow_left,
            color: Colors.white.withValues(alpha: .76),
            size: 31,
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 22,
            color: Colors.white.withValues(alpha: .18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0, 1),
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: _authPink,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: .22),
                        blurRadius: 0,
                        spreadRadius: -5,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _SignupInputBox extends StatelessWidget {
  const _SignupInputBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF132630).withValues(alpha: .74),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .18), width: 2),
    ),
    child: child,
  );
}

class _SignupStepButton extends StatelessWidget {
  const _SignupStepButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled
            ? _authPink
            : const Color(0xFF526671).withValues(alpha: .62),
        borderRadius: BorderRadius.circular(17),
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: _authPinkShadow,
                  blurRadius: 0,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
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
              label,
              style: TextStyle(
                color: enabled
                    ? _authPinkInk
                    : Colors.white.withValues(alpha: .26),
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -.2,
              ),
            ),
    ),
  );
}

class _AccountChoiceHeader extends StatelessWidget {
  const _AccountChoiceHeader({required this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: onBack,
        icon: Icon(
          CupertinoIcons.arrow_left,
          color: Colors.white.withValues(alpha: .72),
          size: 31,
        ),
      ),
    ),
  );
}

class _AccountChoicePrimaryButton extends StatelessWidget {
  const _AccountChoicePrimaryButton({
    required this.label,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _authPink,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: _authPinkShadow,
            blurRadius: 0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _authPinkInk,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -.3,
        ),
      ),
    ),
  );
}

class _AccountChoiceOutlineButton extends StatelessWidget {
  const _AccountChoiceOutlineButton({
    required this.label,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: .20),
          width: 2.4,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _authPink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -.2,
        ),
      ),
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
    this.fieldHeight = 64,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onPasswordVisibilityTap;
  final VoidCallback? onSubmitted;
  final double fieldHeight;

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
          height: fieldHeight,
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
          height: fieldHeight,
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
              color: _authPink.withValues(alpha: .78),
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
    this.height = 64,
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
  final double height;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
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
            cursorColor: _authPink,
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
    this.height = 60,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null && !busy;
    return GestureDetector(
      onTap: canTap ? onTap : null,
      child: Opacity(
        opacity: enabled || busy ? 1 : .78,
        child: Container(
          width: double.infinity,
          height: height + 7,
          decoration: BoxDecoration(
            color: _authPinkShadow,
            borderRadius: BorderRadius.circular(19),
            boxShadow: [
              BoxShadow(
                color: _authPink.withValues(alpha: .22),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: double.infinity,
              height: height,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _authPink,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .18)),
              ),
              child: busy
                  ? const CupertinoActivityIndicator(color: _authPinkInk)
                  : Text(
                      'ログイン',
                      style: TextStyle(
                        color: _authPinkInk.withValues(
                          alpha: enabled ? 1 : .58,
                        ),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialLoginButton extends StatelessWidget {
  const _SocialLoginButton({
    required this.label,
    required this.mark,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final Widget mark;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      height: height,
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
    final color = isError ? AppColors.coral : _authPink;
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
            SizedBox(
              width: 48,
              child: IconButton(
                onPressed: onBack,
                icon: const NomoGeneratedIcon(
                  CupertinoIcons.chevron_left,
                  size: 20,
                ),
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

bool _isValidUserId(String value) =>
    RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(value);

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
    this.textInputAction,
    this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final String hintText;
  final TextInputAction? textInputAction;
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
            textInputAction: textInputAction,
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
