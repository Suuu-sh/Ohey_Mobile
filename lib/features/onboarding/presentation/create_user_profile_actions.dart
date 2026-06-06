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
        _hydrateProfileFromAuthMetadata(authRepository.currentUser);
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
    final gender = _gender;

    setState(() {
      _isBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      final authRepository = ref.read(authRepositoryProvider);
      if (authRepository.currentSession == null) {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        if (!_hasValidEmailAddress(email)) {
          throw const AuthException(_emailInputRequirementMessage);
        }
        if (!_hasValidPassword(password)) {
          throw const AuthException(_emailPasswordRequirementMessage);
        }
        if (!_hasMatchingPasswords(
          password,
          _passwordConfirmationController.text,
        )) {
          throw const AuthException(_passwordConfirmationRequirementMessage);
        }
        final res = await authRepository.signUpWithProfileMetadata(
          email: email,
          password: password,
          userId: userId,
          displayName: name,
          gender: gender,
          avatar: _avatar,
        );
        if (res.session == null) {
          if (mounted) {
            setState(() {
              _notice = '確認メールを送ったよ。リンクを開いてね。';
            });
          }
          return;
        }
      }
      await ref
          .read(oheyUserProvider.notifier)
          .createUser(
            name: name,
            userId: userId,
            gender: gender,
            avatar: _avatar,
          );
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
    if (_gender == OheyGender.unspecified) {
      setState(() {
        _error = '性別を選択してください。';
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
    final gender = oheyGenderFromKey(metadata['gender'] as String?);
    if (userId != null && _userIdController.text.trim().isEmpty) {
      _userIdController.text = userId;
    }
    if (displayName != null && _nameController.text.trim().isEmpty) {
      _nameController.text = displayName;
    }
    final avatar = OheyAvatar.decode(avatarUrl);
    if (avatar != null) _avatar = avatar;
    if (gender != OheyGender.unspecified) _gender = gender;
  }

  Future<void> _saveLastAccount(String email) async {
    final user = ref.read(oheyUserProvider);
    final displayName = await _latestDisplayName(user?.name);
    await OheyLastAccountStore.save(
      name: displayName,
      email: email,
      avatar: user?.avatar ?? _avatar,
    );
  }

  Future<String?> _latestDisplayName(String? fallback) {
    return ref.read(oheyUserProvider.notifier).latestDisplayName(fallback);
  }

  Future<void> _openAvatarBuilder() async {
    if (_gender == OheyGender.unspecified) {
      setState(() {
        _error = '先に性別を選択してください。';
        _notice = null;
      });
      return;
    }
    final result = await Navigator.of(context).push<OheyAvatar>(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            AvatarBuilderScreen(initialAvatar: _avatar, gender: _gender),
      ),
    );
    if (result != null && mounted) {
      setState(() => _avatar = result);
    }
  }
}
