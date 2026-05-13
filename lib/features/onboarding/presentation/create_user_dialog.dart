import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_character.dart';

enum _OnboardingStep { intro, auth, profile }

class CreateUserDialog extends ConsumerStatefulWidget {
  const CreateUserDialog({super.key});

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  NomoCharacterPose _selectedPose = NomoCharacterPose.memu;
  _OnboardingStep _step = _OnboardingStep.intro;
  bool _isLogin = true;
  bool _isBusy = false;
  bool _nameTouched = false;
  String? _error;
  String? _notice;

  static const _choices = [
    _CharacterChoice('memu', NomoCharacterPose.memu),
    _CharacterChoice('Saigou', NomoCharacterPose.saigou),
    _CharacterChoice('chi-', NomoCharacterPose.chi),
    _CharacterChoice('Uo', NomoCharacterPose.uo),
    _CharacterChoice('Aren', NomoCharacterPose.aren),
  ];
  @override
  void initState() {
    super.initState();
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _step = _OnboardingStep.profile;
      _emailController.text = session.user.email ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 22),
        backgroundColor: Colors.transparent,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink.withValues(alpha: .14),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: switch (_step) {
              _OnboardingStep.intro => _buildIntro(context),
              _OnboardingStep.auth => _buildAuth(context),
              _OnboardingStep.profile => _buildProfile(context),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        Container(
          width: 132,
          height: 132,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppColors.peach, AppColors.sky]),
          ),
          child: const NomoCharacter(pose: NomoCharacterPose.standingBeer),
        ),
        const SizedBox(height: 16),
        Text(
          'Nomoへようこそ',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '今月、誰と何回飲みに行ったかを\nかわいく残す飲み会ログSNSです。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.mutedInk,
            fontWeight: FontWeight.w800,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 18),
        const _IntroTile(icon: CupertinoIcons.person_2_fill, text: '飲み友と回数を共有'),
        const SizedBox(height: 8),
        const _IntroTile(icon: CupertinoIcons.calendar, text: '飲みログを月ごとに振り返り'),
        const SizedBox(height: 8),
        const _IntroTile(icon: CupertinoIcons.sparkles, text: 'キャラクターの表情が変化'),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: 'ログインしてはじめる',
          icon: CupertinoIcons.arrow_right_circle_fill,
          busy: false,
          onPressed: () => setState(() => _step = _OnboardingStep.auth),
        ),
      ],
    );
  }

  Widget _buildAuth(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: _isLogin ? 'ログイン' : '新規登録',
          subtitle: '飲みログを保存するためにアカウントが必要です。',
          onBack: _isBusy
              ? null
              : () => setState(() => _step = _OnboardingStep.intro),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _emailController,
          enabled: !_isBusy,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            hintText: 'メールアドレス',
            prefixIcon: Icon(CupertinoIcons.mail),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          enabled: !_isBusy,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(
            hintText: 'パスワード（6文字以上）',
            prefixIcon: Icon(CupertinoIcons.lock),
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
          label: _isLogin ? 'ログイン' : '新規登録して続ける',
          icon: _isLogin
              ? CupertinoIcons.person_crop_circle_badge_checkmark
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
    );
  }

  Widget _buildProfile(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          title: 'プロフィール作成',
          subtitle: '友達リストに表示する名前とキャラクターアイコンを選んでね。',
          onBack: _isBusy
              ? null
              : () => setState(() => _step = _OnboardingStep.auth),
        ),
        const SizedBox(height: 18),
        Container(
          width: 118,
          height: 118,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.peach, AppColors.sky],
            ),
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: NomoCharacter(pose: _selectedPose),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _nameController,
          enabled: !_isBusy,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (!_nameTouched) setState(() => _nameTouched = true);
          },
          decoration: InputDecoration(
            hintText: '名前（必須）',
            prefixIcon: const Icon(CupertinoIcons.person_crop_circle),
            errorText: _nameTouched && _nameController.text.trim().isEmpty
                ? '名前を入力してください'
                : null,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final choice in _choices)
              _CharacterChoiceTile(
                choice: choice,
                selected: choice.pose == _selectedPose,
                onTap: _isBusy
                    ? null
                    : () => setState(() => _selectedPose = choice.pose),
              ),
          ],
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
          Navigator.of(context).pop();
          return;
        }
      } else {
        final res = await supabase.auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: SupabaseConfig.authRedirectUrl,
        );
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
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _nameTouched = true;
        _error = 'プロフィールの名前を入力してください。';
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
      await ref
          .read(nomoUserProvider.notifier)
          .createUser(name: name, pose: _selectedPose);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'プロフィール作成に失敗しました: $e');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
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

class _IntroTile extends StatelessWidget {
  const _IntroTile({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.softGray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 19),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
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
            IconButton(
              onPressed: onBack,
              icon: const Icon(CupertinoIcons.chevron_left, size: 20),
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
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
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

class _CharacterChoiceTile extends StatelessWidget {
  const _CharacterChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  final _CharacterChoice choice;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: selected ? AppColors.peach : AppColors.softGray,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.coral : AppColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(child: NomoCharacter(pose: choice.pose)),
            Text(
              choice.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.navy,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterChoice {
  const _CharacterChoice(this.label, this.pose);

  final String label;
  final NomoCharacterPose pose;
}
