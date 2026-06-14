// ignore_for_file: invalid_use_of_protected_member

part of 'create_user_dialog.dart';

extension _CreateUserAuthPages on _CreateUserDialogState {
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
    final password = _passwordController.text;
    final passwordConfirmation = _passwordConfirmationController.text;
    final canContinue = _emailController.text.trim().isNotEmpty && !_isBusy;
    final canTapPasswordContinue =
        password.isNotEmpty && passwordConfirmation.isNotEmpty && !_isBusy;
    final signupPasswordError = !isEmailStep && password.isNotEmpty
        ? _signupPasswordValidationMessage(password)
        : null;
    final showPasswordMismatch =
        !isEmailStep &&
        signupPasswordError == null &&
        passwordConfirmation.isNotEmpty &&
        !_hasMatchingPasswords(password, passwordConfirmation);

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
                  color: AppColors.white,
                  fontSize: compact ? 27 : 28,
                  fontWeight: FontWeight.w900,
                  height: 1.18,
                  letterSpacing: -.8,
                ),
              ),
              SizedBox(height: compact ? 28 : 42),
              if (isEmailStep)
                _SignupInputBox(
                  child: _PlainLoginTextField(
                    controller: _emailController,
                    enabled: !_isBusy,
                    hintText: 'メールアドレス',
                    height: textFieldHeight,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (canContinue) _goToSignupPasswordStep();
                    },
                  ),
                )
              else ...[
                _SignupInputBox(
                  child: _PlainLoginTextField(
                    controller: _passwordController,
                    enabled: !_isBusy,
                    hintText: 'パスワード',
                    height: textFieldHeight,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    obscureText: _obscureSignupPassword,
                    onChanged: (_) => setState(() {}),
                    trailing: _signupPasswordVisibilityButton(
                      obscureText: _obscureSignupPassword,
                      onTap: () => setState(
                        () => _obscureSignupPassword = !_obscureSignupPassword,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 10 : 14),
                _SignupInputBox(
                  child: _PlainLoginTextField(
                    controller: _passwordConfirmationController,
                    enabled: !_isBusy,
                    hintText: 'パスワード（確認）',
                    height: textFieldHeight,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    obscureText: _obscureSignupPasswordConfirmation,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (canTapPasswordContinue) _goToSignupProfileStep();
                    },
                    trailing: _signupPasswordVisibilityButton(
                      obscureText: _obscureSignupPasswordConfirmation,
                      onTap: () => setState(
                        () => _obscureSignupPasswordConfirmation =
                            !_obscureSignupPasswordConfirmation,
                      ),
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                _DarkMessageText(_error!, isError: true),
              ] else if (signupPasswordError != null) ...[
                const SizedBox(height: 10),
                _DarkMessageText(signupPasswordError, isError: true),
              ] else if (showPasswordMismatch) ...[
                const SizedBox(height: 10),
                const _DarkMessageText(
                  _passwordConfirmationRequirementMessage,
                  isError: true,
                ),
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
                enabled: isEmailStep ? canContinue : canTapPasswordContinue,
                onTap: isEmailStep
                    ? (canContinue ? _goToSignupPasswordStep : null)
                    : (canTapPasswordContinue ? _goToSignupProfileStep : null),
              ),
              if (!isEmailStep) ...[
                const SizedBox(height: 20),
                Text(
                  '登録するとOheyの利用規約とプライバシー\nポリシーに同意したことになります。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: .82),
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

  Widget _signupPasswordVisibilityButton({
    required bool obscureText,
    required VoidCallback onTap,
  }) {
    return IconButton(
      onPressed: _isBusy ? null : onTap,
      icon: Icon(
        obscureText ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill,
        color: _authPink.withValues(alpha: .78),
        size: 28,
      ),
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
                  color: AppColors.white,
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
                  keyboardType: isEmailStep
                      ? TextInputType.emailAddress
                      : TextInputType.visiblePassword,
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
                'ログインするとOheyの利用規約とプライバシー\nポリシーに同意したことになります。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: .82),
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

  Widget _buildReLogin(BuildContext context, List<OheyLastAccount> accounts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 720 ||
            accounts.length >= OheyLastAccountStore.maxAccounts;
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
                  color: AppColors.white,
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
                  unawaited(_switchToSavedAccount(account));
                },
                onAddAccount: () {
                  _emailController.clear();
                  _passwordController.clear();
                  _passwordConfirmationController.clear();
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
                      color: AppColors.white.withValues(alpha: .42),
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
}
