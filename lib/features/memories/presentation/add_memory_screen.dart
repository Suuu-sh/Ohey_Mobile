import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/application/ohey_user_controller.dart';
import '../../../core/data/backend_api_client.dart';
import '../../../core/data/supabase_client_provider.dart';
import '../../../core/models/memory.dart';
import '../../../core/models/ohey_avatar.dart';
import '../../../core/models/ohey_friend.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ohey_avatar.dart';
import '../../../core/widgets/ohey_3d_button.dart';
import '../../../core/widgets/ohey_bottom_sheet.dart';
import '../../../core/widgets/ohey_pop_icon.dart';
import '../../../core/widgets/ohey_post_action_pill.dart';
import '../../../core/widgets/ohey_toast.dart';
import '../../../core/widgets/ohey_state_view.dart';
import '../../../core/widgets/ohey_themed_panel.dart';
import '../../../core/utils/ohey_photo_orientation.dart';
import '../../camera/presentation/ohey_camera_screen.dart';
import '../application/memory_controller.dart';
import '../application/memory_daily_limit.dart';
import '../data/ohey_place_search_service.dart';
import 'memory_daily_limit_dialog.dart';

part 'add_memory_preview_widgets.dart';
part 'add_memory_place_search.dart';
part 'add_memory_form_widgets.dart';
part 'add_memory_layout.dart';
part 'add_memory_actions.dart';

const _memoryCommentMaxLength = 15;

class AddMemoryScreen extends ConsumerStatefulWidget {
  const AddMemoryScreen({super.key, this.initialPhotoPath});

  final String? initialPhotoPath;

  @override
  ConsumerState<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends ConsumerState<AddMemoryScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedFriendIds = {};
  final _placeController = TextEditingController();
  final _memoController = TextEditingController();
  final _friendSearchController = TextEditingController();
  String _friendSearchQuery = '';
  String? _selectedPlaceName;
  double? _selectedPlaceLatitude;
  double? _selectedPlaceLongitude;
  String? _photoPath;
  double _captionY = .5;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _photoPath = widget.initialPhotoPath;
  }

  @override
  void dispose() {
    _placeController.dispose();
    _memoController.dispose();
    _friendSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildAddMemoryScreen(context);
}
