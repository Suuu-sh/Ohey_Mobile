// ignore_for_file: invalid_use_of_protected_member

part of 'create_user_dialog.dart';

extension _CreateUserProfilePage on _CreateUserDialogState {
  Widget _buildProfile(BuildContext context) {
    final canSubmit =
        _userIdController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty &&
        !_isBusy;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 820;
        final extraCompact = constraints.maxHeight < 700;
        final fieldHeight = constraints.maxHeight < 640 ? 56.0 : 64.0;
        final buttonHeight = compact ? 54.0 : 64.0;
        final avatarSize = extraCompact ? 74.0 : (compact ? 104.0 : 144.0);
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
                  padding: EdgeInsets.only(
                    top: extraCompact ? 8 : (compact ? 14 : 34),
                    bottom: compact ? 8 : 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'プロフィールを作成して\nください',
                        style: TextStyle(
                          color: AppColors.cFF3C3C3C,
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
                          color: AppColors.cFF777777,
                          fontSize: compact ? 12 : 15,
                          fontWeight: FontWeight.w800,
                          height: 1.45,
                        ),
                      ),
                      SizedBox(height: extraCompact ? 8 : (compact ? 12 : 26)),
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
                                    color: AppColors.cFFE5E5E5,
                                    width: 2,
                                  ),
                                ),
                                child: OheyAvatarView(avatar: _avatar),
                              ),
                            ),
                            SizedBox(height: compact ? 2 : 12),
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                minimumSize: Size(0, compact ? 36 : 44),
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 8 : 12,
                                  vertical: 0,
                                ),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _isBusy ? null : _openAvatarBuilder,
                              icon: const OheyGeneratedIcon(
                                CupertinoIcons.pencil,
                                color: AppColors.cFF00CD9C,
                                size: 20,
                              ),
                              label: const Text(
                                'アバターを作る',
                                style: TextStyle(
                                  color: AppColors.cFF00CD9C,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: extraCompact ? 4 : (compact ? 10 : 22)),
                      _SignupInputBox(
                        child: _SignupProfileTextField(
                          controller: _nameController,
                          enabled: !_isBusy,
                          icon: CupertinoIcons.person_crop_circle_fill,
                          hintText: '名前（必須・日本語OK）',
                          height: fieldHeight,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 12),
                      _SignupInputBox(
                        child: _SignupProfileTextField(
                          controller: _userIdController,
                          enabled: !_isBusy,
                          icon: CupertinoIcons.at_circle_fill,
                          hintText: 'ユーザーID（半角英数字と_・3文字以上）',
                          height: fieldHeight,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) {
                            if (canSubmit) _submitProfile();
                          },
                        ),
                      ),
                      if (_error != null) ...[
                        SizedBox(height: compact ? 8 : 10),
                        _DarkMessageText(_error!, isError: true),
                      ],
                      if (_notice != null) ...[
                        SizedBox(height: compact ? 8 : 10),
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
