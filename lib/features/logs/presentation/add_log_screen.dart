import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_avatar.dart';
import '../../../core/models/nomo_friend.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_avatar.dart';
import '../../../core/widgets/nomo_3d_button.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_toast.dart';
import '../../../core/utils/nomo_photo_orientation.dart';
import '../../camera/presentation/nomo_camera_screen.dart';
import '../application/drink_log_controller.dart';
import '../data/nomo_place_search_service.dart';

part 'add_log_preview_widgets.dart';
part 'add_log_place_search.dart';
part 'add_log_form_widgets.dart';
part 'add_log_actions.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key, this.initialPhotoPath});

  final String? initialPhotoPath;

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedFriendIds = {};
  final _placeController = TextEditingController();
  final _memoController = TextEditingController();
  final _friendSearchController = TextEditingController();
  String _friendSearchQuery = '';
  String? _photoPath;
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
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final user = ref.watch(nomoUserProvider);
    final selectedFriends =
        friendsAsync.asData?.value
            .where((friend) => _selectedFriendIds.contains(friend.id))
            .toList(growable: false) ??
        const <NomoFriend>[];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: _AddLogColors.pageBackgroundFor(context),
      body: DecoratedBox(
        decoration: _AddLogColors.pageDecorationFor(context),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                child: _Header(onClose: () => Navigator.of(context).maybePop()),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 10, 0, 26),
                  children: [
                    if (_hasPhoto) ...[
                      _PostPreviewCard(
                        path: _photoPath!,
                        userName: _previewUserName(user?.name),
                        avatar: user?.avatar ?? NomoAvatar.defaultAvatar,
                        memoController: _memoController,
                        place: _placeController.text,
                        date: _selectedDate,
                        friends: selectedFriends,
                        onEditDateTime: _pickDateTime,
                        onMemoChanged: (_) => setState(() {}),
                        onRetake: _openNomoCamera,
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _PhotoCapturePrompt(onTap: _openNomoCamera),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _DateTimeBox(
                          icon: CupertinoIcons.calendar,
                          iconColor: _AddLogColors.calendarIcon,
                          label: _addLogDateTimeLabel(_selectedDate),
                          onTap: _pickDateTime,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _InputBox(
                          icon: CupertinoIcons.text_quote,
                          iconColor: _AddLogColors.impressionIcon,
                          hint: 'コメント（任意）',
                          controller: _memoController,
                          maxLines: 3,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _FriendSelectCard(
                        search: _InputBox(
                          icon: CupertinoIcons.search,
                          iconColor: _AddLogColors.searchIcon,
                          hint: '誰と？（任意）',
                          controller: _friendSearchController,
                          maxLines: 1,
                          borderless: true,
                          onChanged: (value) =>
                              setState(() => _friendSearchQuery = value),
                          suffix: _friendSearchQuery.isEmpty
                              ? null
                              : IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() {
                                    _friendSearchController.clear();
                                    _friendSearchQuery = '';
                                  }),
                                  icon: const NomoGeneratedIcon(
                                    CupertinoIcons.xmark_circle_fill,
                                    color: _AddLogColors.clearIcon,
                                  ),
                                ),
                        ),
                        chips: SizedBox(
                          height: 58,
                          child: friendsAsync.when(
                            data: (friends) => _FriendChips(
                              friends: _filteredFriends(friends),
                              selectedIds: _selectedFriendIds,
                              onChanged: _toggleFriend,
                              emptyMessage: _friendSearchQuery.trim().isEmpty
                                  ? 'まだフレンズがいません'
                                  : '該当するフレンズがいません',
                            ),
                            loading: () => const _LoadingBox(compact: true),
                            error: (error, stackTrace) => const _ErrorBox(
                              message: '読み込めなかったよ。あとでもう一度試してね',
                              compact: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _InputBox(
                        icon: CupertinoIcons.location_solid,
                        iconColor: _AddLogColors.placeIcon,
                        hint: 'どこで？（任意）',
                        controller: _placeController,
                        maxLines: 1,
                        onChanged: (_) => setState(() {}),
                        suffix: _PlaceSearchButton(onTap: _openPlaceSearch),
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: _SaveButton(
                    label: _hasPhoto ? '飲みログを投稿する' : '写真なしで保存する',
                    isSaving: _isSaving,
                    onPressed: () => _save(
                      friendsAsync.asData?.value ?? const <NomoFriend>[],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
