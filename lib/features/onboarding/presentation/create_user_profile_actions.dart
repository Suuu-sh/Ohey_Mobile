// ignore_for_file: invalid_use_of_protected_member

part of 'create_user_dialog.dart';

extension _CreateUserProfileActions on _CreateUserDialogState {
  Future<void> _submitAuth() async {
    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      final authRepository = ref.read(authRepositoryProvider);
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      if (!_hasValidEmailAddress(email)) {
        throw const AuthException(_emailInputRequirementMessage);
      }
      if (!_hasValidPassword(password)) {
        throw const AuthException(_emailPasswordRequirementMessage);
      }

      if (_isLogin) {
        // Do not let a stale saved Clerk session carry the user past the
        // password page. The password attempt below must be the only session
        // that can advance the login flow.
        await authRepository.suspendCurrentSessionLocally();
        if (!mounted) return;
        await authRepository.signInWithPassword(
          email: email,
          password: password,
        );
        final loaded = await ref
            .read(oheyUserProvider.notifier)
            .loadFromBackendProfile();
        if (loaded && mounted) {
          await _saveLastAccount(email);
          return;
        }
      } else {
        _goToSignupProfileStep();
        return;
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
        setState(() => _error = _friendlyUnexpectedAuthError(e));
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
      final authRepository = ref.read(authRepositoryProvider);
      final isBackendSignup = OheyAuthFlowPolicy.shouldUseBackendSignup(
        isLoginFlow: _isLogin,
        hasActiveSession: authRepository.isSignedIn,
      );
      if (isBackendSignup) {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        if (!_hasValidEmailAddress(email)) {
          throw const AuthException(_emailInputRequirementMessage);
        }
        final passwordError = _signupPasswordValidationMessage(password);
        if (passwordError != null) {
          throw AuthException(passwordError);
        }
        if (!_hasMatchingPasswords(
          password,
          _passwordConfirmationController.text,
        )) {
          throw const AuthException(_passwordConfirmationRequirementMessage);
        }
        await authRepository.signUpWithProfileMetadata(
          email: email,
          password: password,
          userId: userId,
          displayName: name,
          avatar: _avatar,
        );
      }
      if (isBackendSignup) {
        await ref
            .read(oheyUserProvider.notifier)
            .useLocallyCreatedUser(name: name, userId: userId, avatar: _avatar);
      } else {
        await ref
            .read(oheyUserProvider.notifier)
            .createUser(name: name, userId: userId, avatar: _avatar);
      }
      await _saveLastAccount(_emailController.text.trim());
    } on AuthException catch (e) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(e.message));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '作成できなかったよ。あとでもう一度試してね');
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
        _error = 'ユーザーIDは3〜24文字の英数字と_のみ使えます。';
        _notice = null;
      });
      return false;
    }
    if (name.isEmpty) {
      setState(() {
        _error = 'ユーザー名を入力してください。';
        _notice = null;
      });
      return false;
    }
    return true;
  }

  Future<void> _saveLastAccount(String email) async {
    final user = ref.read(oheyUserProvider);
    final displayName = await _latestDisplayName(user?.name);
    await OheyLastAccountStore.save(
      name: displayName,
      email: email,
      avatar: user?.avatar ?? _avatar,
    );
    await OheyLastAccountStore.setSessionRestoreSuppressed(false);
  }

  Future<String?> _latestDisplayName(String? fallback) {
    return ref.read(oheyUserProvider.notifier).latestDisplayName(fallback);
  }

  Future<void> _openAvatarBuilder() async {
    final result = await Navigator.of(context).push<OheyAvatar>(
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
