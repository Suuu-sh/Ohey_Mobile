import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/ohey_user_controller.dart';
import '../../../core/data/clerk_auth_service.dart';
import '../../../core/data/ohey_last_account_store.dart';
import '../../../core/data/auth_repository.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ohey_avatar.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_pop_icon.dart';
import '../../../core/widgets/ohey_themed_panel.dart';
import '../../profile/presentation/avatar_builder_screen.dart';

part 'create_user_auth_helpers.dart';
part 'create_user_demo.dart';
part 'create_user_demo_screen.dart';
part 'create_user_step_shell_widgets.dart';
part 'create_user_relogin_widgets.dart';
part 'create_user_signup_shell_widgets.dart';
part 'create_user_account_choice_widgets.dart';
part 'create_user_profile_form_widgets.dart';
part 'create_user_text_field_widgets.dart';
part 'create_user_social_auth_widgets.dart';
part 'create_user_message_widgets.dart';
part 'create_user_profile_actions.dart';
part 'create_user_intro_page.dart';
part 'create_user_account_choice_page.dart';
part 'create_user_auth_pages.dart';
part 'create_user_profile_page.dart';
part 'create_user_auth_actions.dart';

enum _OnboardingStep { intro, accountChoice, auth, profile }

enum _RegistrationStep { email, password }

enum _SocialAuthIntent { signup, login }

const _authPink = AppColors.coral;
const _authPinkShadow = AppColors.cFFE05F83;
const _authPinkInk = AppColors.cFF2B1320;
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
  final _passwordConfirmationController = TextEditingController();
  final _userIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _demoController = PageController();
  OheyAvatar _avatar = OheyAvatar.defaultAvatar;
  _OnboardingStep _step = _OnboardingStep.intro;
  int _demoPage = 0;
  bool _isLogin = true;
  bool _isBusy = false;
  bool _isLastAccountLoaded = false;
  bool _showAuthForm = false;
  bool _obscurePlainLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureSignupPasswordConfirmation = true;
  _RegistrationStep _loginStep = _RegistrationStep.email;
  _RegistrationStep _registrationStep = _RegistrationStep.email;
  List<OheyLastAccount> _lastAccounts = const <OheyLastAccount>[];
  String? _error;
  String? _notice;
  StreamSubscription<void>? _clerkAuthSubscription;

  @override
  void initState() {
    super.initState();
    final authRepository = ref.read(authRepositoryProvider);
    if (authRepository.isSignedIn) {
      _step = _OnboardingStep.profile;
      _emailController.text = authRepository.currentEmail ?? '';
    } else if (widget.startAtLogin) {
      _step = _OnboardingStep.auth;
    }
    _showAuthForm = !widget.startAtLogin;
    _clerkAuthSubscription = ref
        .read(clerkAuthServiceProvider)
        .authChanges
        .listen((_) => unawaited(_handleClerkAuthSession()));
    _loadLastAccount();
  }

  Future<void> _loadLastAccount() async {
    final accounts = await OheyLastAccountStore.loadAccounts();
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
    _passwordConfirmationController.dispose();
    _userIdController.dispose();
    _nameController.dispose();
    _clerkAuthSubscription?.cancel();
    _demoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
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
}
