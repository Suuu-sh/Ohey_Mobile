// ignore_for_file: invalid_use_of_protected_member

part of 'create_user_dialog.dart';

extension _CreateUserAccountChoicePage on _CreateUserDialogState {
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
                'まずはアカウントを作って\n今日を1枚残そう',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
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
                color: AppColors.white.withValues(alpha: .18),
              ),
              SizedBox(height: compact ? 30 : 54),
              Text(
                '30秒で始められます',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: compact ? 23 : 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.6,
                ),
              ),
              SizedBox(height: compact ? 28 : 40),
              _AccountChoiceOutlineButton(
                label: '新しくはじめる',
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
}
