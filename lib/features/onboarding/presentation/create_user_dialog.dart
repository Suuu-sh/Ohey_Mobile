import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/data/nomo_last_account_store.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_gender.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../profile/presentation/avatar_builder_screen.dart';

part 'create_user_auth_helpers.dart';
part 'create_user_demo.dart';
part 'create_user_demo_screen.dart';
part 'create_user_shell_widgets.dart';
part 'create_user_form_widgets.dart';
part 'create_user_profile_actions.dart';
part 'create_user_auth_actions.dart';

enum _OnboardingStep { intro, accountChoice, auth, profile }

enum _RegistrationStep { email, password }

enum _SocialAuthIntent { signup, login }

const _authPink = AppColors.coral;
const _authPinkShadow = Color(0xFFE05F83);
const _authPinkInk = Color(0xFF2B1320);
const _minPasswordLength = 6;
const _emailPasswordRequirementMessage =
    'メールアドレスと$_minPasswordLength文字以上のパスワードを入力してください。';

class CreateUserDialog extends ConsumerStatefulWidget {
  const CreateUserDialog({super.key, this.startAtLogin = false});

  final bool startAtLogin;

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _userIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _demoController = PageController();
  NomoAvatar _avatar = NomoAvatar.defaultAvatar;
  NomoGender _gender = NomoGender.unspecified;
  _OnboardingStep _step = _OnboardingStep.intro;
  int _demoPage = 0;
  bool _isLogin = true;
  bool _isBusy = false;
  bool _isLastAccountLoaded = false;
  bool _showAuthForm = false;
  bool _obscurePlainLoginPassword = true;
  bool _obscureSignupPassword = true;
  _RegistrationStep _loginStep = _RegistrationStep.email;
  _RegistrationStep _registrationStep = _RegistrationStep.email;
  List<NomoLastAccount> _lastAccounts = const <NomoLastAccount>[];
  String? _error;
  String? _notice;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    final session = ref.read(authRepositoryProvider).currentSession;
    if (session != null) {
      _step = _OnboardingStep.profile;
      _emailController.text = session.user.email ?? '';
      _hydrateProfileFromAuthMetadata(session.user);
    } else if (widget.startAtLogin) {
      _step = _OnboardingStep.auth;
    }
    _showAuthForm = !widget.startAtLogin;
    _authSubscription = ref
        .read(authRepositoryProvider)
        .onAuthStateChange
        .listen((event) {
          if (!mounted) return;
          final session = event.session;
          if (session != null &&
              (event.event == AuthChangeEvent.signedIn ||
                  event.event == AuthChangeEvent.tokenRefreshed ||
                  event.event == AuthChangeEvent.initialSession)) {
            unawaited(_handleOAuthSession(session));
          }
        });
    _loadLastAccount();
  }

  Future<void> _loadLastAccount() async {
    final accounts = await NomoLastAccountStore.loadAccounts();
    if (!mounted) return;
    setState(() {
      _lastAccounts = accounts;
      _isLastAccountLoaded = true;
      if (widget.startAtLogin && accounts.isEmpty) {
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
    _authSubscription?.cancel();
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.darkBackground,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeOutCubic,
            child: KeyedSubtree(
              key: ValueKey(
                '$_step-$_showAuthForm-$_isLogin-$_loginStep-$_registrationStep',
              ),
              child: switch (_step) {
                _OnboardingStep.intro => _FullScreenStep(
                  child: _IntroCard(child: _buildIntro(context)),
                ),
                _OnboardingStep.accountChoice => _buildAccountChoice(context),
                _OnboardingStep.auth => _buildAuth(context),
                _OnboardingStep.profile => _buildProfile(context),
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
                        if (widget.startAtLogin && _lastAccounts.isNotEmpty) {
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
      if (_lastAccounts.isNotEmpty) {
        return _buildReLogin(context, _lastAccounts);
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
    final canRegister = _hasValidPassword(_passwordController.text) && !_isBusy;

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
                      _goToSignupProfileStep();
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
                label: isEmailStep ? '次へ' : '次へ',
                height: buttonHeight,
                busy: _isBusy,
                enabled: isEmailStep ? canContinue : canRegister,
                onTap: isEmailStep
                    ? (canContinue ? _goToSignupPasswordStep : null)
                    : (canRegister ? _goToSignupProfileStep : null),
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
                _SocialAuthButtons(
                  intent: _SocialAuthIntent.signup,
                  height: socialHeight,
                  gap: compact ? 10 : 14,
                  onTap: _startOAuthAuth,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlainLogin(BuildContext context) {
    final isEmailStep = _loginStep == _RegistrationStep.email;
    final canContinue = _emailController.text.trim().isNotEmpty && !_isBusy;
    final canSubmit = _hasValidPassword(_passwordController.text) && !_isBusy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasMessage = _error != null || _notice != null;
        final compact = constraints.maxHeight < 760 || hasMessage;
        final fieldHeight = compact ? 56.0 : 64.0;
        final buttonHeight = compact ? 56.0 : 64.0;
        final socialHeight = compact ? 48.0 : 64.0;
        final headingGap = compact ? 24.0 : 64.0;
        final inputGap = compact ? 24.0 : 42.0;
        final buttonGap = compact ? 22.0 : 42.0;
        final forgotGap = compact ? 8.0 : 22.0;
        final socialGap = compact ? 8.0 : 14.0;
        final termsGap = compact ? 8.0 : 24.0;
        return _fixedAuthPage(
          constraints: constraints,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignupProgressHeader(
                progress: isEmailStep ? .48 : .76,
                onBack: _isBusy ? null : _handleLoginBack,
              ),
              SizedBox(height: headingGap),
              Text(
                isEmailStep ? 'メールアドレスを入力して\nください' : 'パスワードを入力してください',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 26 : 28,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                  letterSpacing: -.8,
                ),
              ),
              SizedBox(height: inputGap),
              _SignupInputBox(
                child: _PlainLoginTextField(
                  controller: isEmailStep
                      ? _emailController
                      : _passwordController,
                  enabled: !_isBusy,
                  hintText: isEmailStep ? 'メールアドレス' : 'パスワード',
                  height: fieldHeight,
                  keyboardType: isEmailStep ? TextInputType.emailAddress : null,
                  textInputAction: isEmailStep
                      ? TextInputAction.next
                      : TextInputAction.done,
                  autofillHints: isEmailStep
                      ? const [AutofillHints.email, AutofillHints.username]
                      : const [AutofillHints.password],
                  obscureText: !isEmailStep && _obscurePlainLoginPassword,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) {
                    if (isEmailStep && canContinue) {
                      _goToLoginPasswordStep();
                    } else if (!isEmailStep && canSubmit) {
                      _submitAuth();
                    }
                  },
                  trailing: isEmailStep
                      ? null
                      : IconButton(
                          onPressed: _isBusy
                              ? null
                              : () => setState(
                                  () => _obscurePlainLoginPassword =
                                      !_obscurePlainLoginPassword,
                                ),
                          icon: Icon(
                            _obscurePlainLoginPassword
                                ? CupertinoIcons.eye_slash_fill
                                : CupertinoIcons.eye_fill,
                            color: _authPink.withValues(alpha: .78),
                            size: 28,
                          ),
                        ),
                ),
              ),
              SizedBox(height: buttonGap),
              _SignupStepButton(
                label: isEmailStep ? '次へ' : 'ログイン',
                height: buttonHeight,
                busy: _isBusy,
                enabled: isEmailStep ? canContinue : canSubmit,
                onTap: isEmailStep
                    ? (canContinue ? _goToLoginPasswordStep : null)
                    : (canSubmit ? _submitAuth : null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                _DarkMessageText(_error!, isError: true),
              ],
              if (_notice != null) ...[
                const SizedBox(height: 10),
                _DarkMessageText(_notice!),
              ],
              if (!isEmailStep) ...[
                SizedBox(height: forgotGap),
                SizedBox(
                  height: compact ? 34 : 44,
                  child: TextButton(
                    onPressed: _isBusy ? null : _sendPasswordResetEmail,
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
              ],
              const Spacer(),
              _SocialAuthButtons(
                intent: _SocialAuthIntent.login,
                height: socialHeight,
                gap: socialGap,
                onTap: _startOAuthAuth,
              ),
              SizedBox(height: termsGap),
              Text(
                'ログインするとNomoの利用規約とプライバシー\nポリシーに同意したことになります。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .82),
                  fontSize: compact ? 12 : 14,
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

  Widget _buildReLogin(BuildContext context, List<NomoLastAccount> accounts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 720 ||
            accounts.length >= NomoLastAccountStore.maxAccounts;
        return _fixedAuthPage(
          constraints: constraints,
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
          child: Column(
            children: [
              Spacer(flex: compact ? 1 : 2),
              _ReLoginMascot(size: compact ? 92 : 150),
              SizedBox(height: compact ? 10 : 28),
              Text(
                '再ログイン',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 28 : 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              SizedBox(height: compact ? 16 : 42),
              _ReLoginAccountCard(
                accounts: accounts,
                compact: compact,
                onAccountTap: (account) {
                  _emailController.text = account.email;
                  _passwordController.clear();
                  setState(() {
                    _showAuthForm = true;
                    _isLogin = true;
                    _loginStep = _RegistrationStep.password;
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
              SizedBox(height: compact ? 8 : 34),
              SizedBox(
                height: compact ? 40 : 48,
                child: TextButton(
                  onPressed: () {
                    _showAccountManagementSheet();
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
              Spacer(flex: compact ? 2 : 3),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfile(BuildContext context) {
    final canSubmit =
        _isValidUserId(_userIdController.text.trim()) &&
        _nameController.text.trim().isNotEmpty &&
        _gender != NomoGender.unspecified &&
        !_isBusy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 700;
        final fieldHeight = compact ? 50.0 : 64.0;
        final buttonHeight = compact ? 54.0 : 64.0;
        final avatarSize = compact ? 74.0 : 144.0;
        return _fixedAuthPage(
          constraints: constraints,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SignupProgressHeader(
                progress: 1,
                onBack: _isBusy
                    ? null
                    : () => setState(() => _step = _OnboardingStep.auth),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(top: compact ? 8 : 34, bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'プロフィールを作成して\nください',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 24 : 28,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                          letterSpacing: -.8,
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 12),
                      Text(
                        '名前とアバターを作ってね。',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .66),
                          fontSize: compact ? 12 : 15,
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 26),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _isBusy ? null : _openAvatarBuilder,
                              child: Container(
                                width: avatarSize,
                                height: avatarSize,
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [AppColors.peach, AppColors.sky],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .20),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF12C9A4,
                                      ).withValues(alpha: .16),
                                      blurRadius: 28,
                                      offset: const Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: NomoAvatarView(avatar: _avatar),
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 12),
                            TextButton.icon(
                              onPressed: _isBusy ? null : _openAvatarBuilder,
                              icon: const NomoGeneratedIcon(
                                CupertinoIcons.pencil,
                                color: Color(0xFF12C9A4),
                                size: 20,
                              ),
                              label: const Text(
                                'アバターを作る',
                                style: TextStyle(
                                  color: Color(0xFF12C9A4),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 4 : 22),
                      _SignupInputBox(
                        child: _SignupProfileTextField(
                          controller: _userIdController,
                          enabled: !_isBusy,
                          icon: CupertinoIcons.at_circle_fill,
                          hintText: 'ユーザーID（必須・完全一致検索用）',
                          height: fieldHeight,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SignupInputBox(
                        child: _SignupProfileTextField(
                          controller: _nameController,
                          enabled: !_isBusy,
                          icon: CupertinoIcons.person_crop_circle_fill,
                          hintText: 'ユーザー名（必須）',
                          height: fieldHeight,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) {
                            if (canSubmit) _submitProfile();
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SignupGenderSelector(
                        selectedGender: _gender,
                        enabled: !_isBusy,
                        compact: compact,
                        onChanged: (gender) {
                          setState(() {
                            _gender = gender;
                            _avatar = _avatar.normalizedForGender(gender);
                            _error = null;
                            _notice = null;
                          });
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        _DarkMessageText(_error!, isError: true),
                      ],
                      if (_notice != null) ...[
                        const SizedBox(height: 10),
                        _DarkMessageText(_notice!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SignupStepButton(
                label: 'ユーザー作成',
                height: buttonHeight,
                busy: _isBusy,
                enabled: canSubmit,
                onTap: canSubmit ? _submitProfile : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
