import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/ohey_environment.dart';
import '../../../core/contracts/ohey_api_values.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/ohey_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_pop_icon.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_confirm_sheet.dart';
import '../../../core/widgets/ohey_toast.dart';
import '../../../core/widgets/ohey_empty_state.dart';
import '../../../core/widgets/ohey_state_view.dart';
import '../application/admin_controller.dart';
import '../data/admin_repository.dart';
import '../../friends/data/friend_repository.dart';

part 'admin_header_panes.dart';
part 'admin_cards.dart';
part 'admin_user_editor.dart';
part 'admin_yurubo_editor.dart';
part 'admin_form_widgets.dart';
part 'admin_shared_widgets.dart';
part 'admin_screen_body.dart';

enum _AdminSection { users, yurubos, notifications }

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  _AdminSection _section = _AdminSection.users;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: _AdminColors.bg,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _AdminBody(
            section: _section,
            onSectionChanged: (section) => setState(() => _section = section),
          ),
        ),
      ),
    );
  }
}
