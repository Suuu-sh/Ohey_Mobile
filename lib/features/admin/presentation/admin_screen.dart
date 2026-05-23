import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/supabase_config.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/models/nomo_gender.dart';
import '../../../core/models/nomo_user.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../application/admin_controller.dart';
import '../data/admin_repository.dart';

part 'admin_header_panes.dart';
part 'admin_cards.dart';
part 'admin_user_editor.dart';
part 'admin_post_editor.dart';
part 'admin_form_widgets.dart';
part 'admin_shared_widgets.dart';
part 'admin_screen_body.dart';

enum _AdminSection { users, posts, notifications }

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
