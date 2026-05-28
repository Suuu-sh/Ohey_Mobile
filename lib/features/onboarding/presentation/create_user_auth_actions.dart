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
      _userIdController.clear();
      _nameController.clear();
      _avatar = NomoAvatar.defaultAvatar;
      _gender = NomoGender.unspecified;
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
    if (email.isEmpty) {
      setState(() => _error = 'メールアドレスを入力してください。');
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

  void _goToSignupProfileStep() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || !_hasValidPassword(password)) {
      setState(() => _error = _emailPasswordRequirementMessage);
      return;
    }
    setState(() {
      _userIdController.clear();
      _nameController.clear();
      _avatar = NomoAvatar.defaultAvatar;
      _gender = NomoGender.unspecified;
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
        _notice = '$providerLabel認証を完了するとNomoに戻ります。';
      });
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _friendlyAuthError(e.message));
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyUnexpectedAuthError(e));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleOAuthSession(Session session) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      final loaded = await ref
          .read(nomoUserProvider.notifier)
          .loadFromBackendProfile();
      if (loaded) {
        await _saveLastAccount(session.user.email ?? '');
        return;
      }
      _emailController.text = session.user.email ?? _emailController.text;
      _hydrateProfileFromAuthMetadata(session.user);
      if (_nameController.text.trim().isEmpty) {
        _nameController.text = _displayNameFromOAuth(session.user) ?? '';
      }
      if (mounted) {
        setState(() {
          _step = _OnboardingStep.profile;
          _showAuthForm = true;
          _notice = 'プロフィールを作成すると登録が完了します。';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = _friendlyUnexpectedAuthError(e));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _showAccountManagementSheet() async {
    final accounts = await NomoLastAccountStore.loadAccounts();
    if (!mounted) return;
    await showNomoBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'アカウント管理',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              if (accounts.isEmpty)
                Text(
                  '保存済みアカウントはありません。',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .68),
                    fontWeight: FontWeight.w800,
                  ),
                )
              else
                for (final account in accounts)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      account.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      account.email,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .58),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        CupertinoIcons.trash,
                        color: AppColors.coral,
                      ),
                      onPressed: () async {
                        await NomoLastAccountStore.remove(account.email);
                        if (context.mounted) Navigator.of(context).pop();
                        await _loadLastAccount();
                      },
                    ),
                  ),
              const SizedBox(height: 8),
              Nomo3DButton.secondary(
                label: '閉じる',
                icon: CupertinoIcons.xmark_circle_fill,
                onTap: () => Navigator.of(context).pop(),
                height: 48,
                radius: 21,
                color: Colors.white.withValues(alpha: .07),
                foregroundColor: Colors.white.withValues(alpha: .76),
                shadowColor: const Color(0xFF6E3E5D).withValues(alpha: .72),
                fontSize: 14,
                useGradient: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
