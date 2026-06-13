// ignore_for_file: invalid_use_of_protected_member

part of 'create_user_dialog.dart';

extension _CreateUserAuthActions on _CreateUserDialogState {
  void _showLoginForm() {
    setState(() {
      _step = _OnboardingStep.auth;
      _isLogin = true;
      _showAuthForm = true;
      _loginStep = _RegistrationStep.email;
      _registrationStep = _RegistrationStep.email;
      _passwordConfirmationController.clear();
      _error = null;
      _notice = null;
    });
  }

  void _showRegistrationForm() {
    setState(() {
      _step = _OnboardingStep.auth;
      _isLogin = false;
      _showAuthForm = true;
      _loginStep = _RegistrationStep.email;
      _registrationStep = _RegistrationStep.email;
      _passwordController.clear();
      _passwordConfirmationController.clear();
      _userIdController.clear();
      _nameController.clear();
      _avatar = OheyAvatar.defaultAvatar;
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

  void _handleLoginBack() {
    setState(() {
      if (_loginStep == _RegistrationStep.password) {
        _loginStep = _RegistrationStep.email;
        _passwordController.clear();
        _passwordConfirmationController.clear();
        _error = null;
        _notice = null;
        return;
      }
      if (widget.startAtLogin && _lastAccounts.isNotEmpty) {
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

  void _goToLoginPasswordStep() {
    final email = _emailController.text.trim();
    if (!_hasValidEmailAddress(email)) {
      setState(
        () => _error = email.isEmpty
            ? 'メールアドレスを入力してください。'
            : _emailInputRequirementMessage,
      );
      return;
    }
    setState(() {
      _loginStep = _RegistrationStep.password;
      _error = null;
      _notice = null;
    });
  }

  void _goToSignupPasswordStep() {
    final email = _emailController.text.trim();
    if (!_hasValidEmailAddress(email)) {
      setState(
        () => _error = email.isEmpty
            ? 'メールアドレスを入力してください。'
            : _emailInputRequirementMessage,
      );
      return;
    }
    setState(() {
      _registrationStep = _RegistrationStep.password;
      _error = null;
      _notice = null;
    });
  }

  void _goToSignupProfileStep() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final passwordConfirmation = _passwordConfirmationController.text;
    if (email.isEmpty || !_hasValidPassword(password)) {
      setState(() => _error = _emailPasswordRequirementMessage);
      return;
    }
    if (!_hasMatchingPasswords(password, passwordConfirmation)) {
      setState(() => _error = _passwordConfirmationRequirementMessage);
      return;
    }
    setState(() {
      _userIdController.clear();
      _nameController.clear();
      _avatar = OheyAvatar.defaultAvatar;
      _step = _OnboardingStep.profile;
      _error = null;
      _notice = null;
    });
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'パスワード再設定メールを送るメールアドレスを入力してください。';
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
      await ref.read(authRepositoryProvider).resetPasswordForEmail(email);
      if (!mounted) return;
      setState(() {
        _notice = '再設定メールを送ったよ。リンクを開いてね。';
      });
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyAuthError(e.message));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyUnexpectedAuthError(e));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _switchToSavedAccount(OheyLastAccount account) async {
    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      final switched = await ref
          .read(authRepositoryProvider)
          .switchToSavedAccount(account.email);
      if (!switched) {
        if (!mounted) return;
        setState(() {
          _emailController.text = account.email;
          _showAuthForm = true;
          _isLogin = true;
          _loginStep = _RegistrationStep.email;
          _passwordController.clear();
          _passwordConfirmationController.clear();
          _notice = 'この端末の保存済みセッションが切れています。メール、Google、またはAppleで再ログインしてね。';
        });
        return;
      }
      await OheyLastAccountStore.setSessionRestoreSuppressed(false);
      await ref
          .read(oheyUserProvider.notifier)
          .ensureProfileForAuthenticatedUser();
      if (mounted) {
        await _saveLastAccount(account.email);
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyUnexpectedAuthError(e));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _startOAuthAuth(
    OAuthProvider provider,
    String providerLabel,
  ) async {
    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithOAuth(provider);
      if (!mounted) return;
      setState(() {
        _notice = '$providerLabel認証を完了するとOheyに戻ります。';
      });
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e.message));
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyUnexpectedAuthError(e));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleClerkAuthSession() async {
    if (_isBusy || !ref.read(authRepositoryProvider).isSignedIn) return;
    if (widget.startAtLogin && !_showAuthForm && _isLogin) return;
    if (_step == _OnboardingStep.profile && !_isLogin) return;
    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      await ref
          .read(oheyUserProvider.notifier)
          .ensureProfileForAuthenticatedUser();
      await _saveLastAccount(
        ref.read(authRepositoryProvider).currentEmail ?? '',
      );
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyUnexpectedAuthError(e));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showAccountManagementSheet() async {
    final accounts = await OheyLastAccountStore.loadAccounts();
    if (!mounted) return;
    await showOheyBottomSheet<void>(
      context: context,
      builder: (context) => _AccountManagementSheet(
        accounts: accounts,
        onRemove: (account) async {
          await OheyLastAccountStore.remove(account.email);
          if (context.mounted) Navigator.of(context).pop();
          await _loadLastAccount();
        },
      ),
    );
  }
}

class _AccountManagementSheet extends StatelessWidget {
  const _AccountManagementSheet({
    required this.accounts,
    required this.onRemove,
  });

  final List<OheyLastAccount> accounts;
  final Future<void> Function(OheyLastAccount account) onRemove;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? AppColors.cFF101820 : AppColors.white;
    final subtitleColor = titleColor.withValues(alpha: .58);
    return OheyBottomSheetShell(
      title: 'アカウント管理',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (accounts.isEmpty)
            Text(
              '保存済みアカウントはありません。',
              style: TextStyle(
                color: subtitleColor,
                fontWeight: FontWeight.w800,
              ),
            )
          else
            for (final account in accounts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  account.name,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: Text(
                  account.email,
                  style: TextStyle(
                    color: subtitleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    CupertinoIcons.trash,
                    color: AppColors.coral,
                  ),
                  onPressed: () => onRemove(account),
                ),
              ),
        ],
      ),
    );
  }
}
