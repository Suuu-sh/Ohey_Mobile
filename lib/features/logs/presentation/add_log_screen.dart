import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/nomo_friend.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_character.dart';
import '../../camera/presentation/nomo_camera_screen.dart';
import '../application/drink_log_controller.dart';

class AddLogScreen extends ConsumerStatefulWidget {
  const AddLogScreen({super.key});

  @override
  ConsumerState<AddLogScreen> createState() => _AddLogScreenState();
}

class _AddLogScreenState extends ConsumerState<AddLogScreen> {
  DateTime _selectedDate = DateTime.now();
  final Set<String> _selectedFriendIds = {};
  final _placeController = TextEditingController();
  final _memoController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _placeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
              sliver: SliverList.list(
                children: [
                  _Header(onBack: () => Navigator.of(context).maybePop()),
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      height: 116,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const NomoCharacter(
                            pose: NomoCharacterPose.standingBeer,
                            width: 126,
                            height: 126,
                          ),
                          const Positioned(
                            left: 80,
                            top: 6,
                            child: _Sparkle(color: AppColors.beer),
                          ),
                          const Positioned(
                            right: 72,
                            top: 24,
                            child: _Sparkle(color: AppColors.peach),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FormRow(
                    icon: CupertinoIcons.calendar,
                    title: '日付',
                    trailing: _dateText(_selectedDate),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 10),
                  friendsAsync.when(
                    data: (friends) {
                      if (_selectedFriendIds.isEmpty) {
                        _selectedFriendIds.addAll(
                          friends.take(3).map((friend) => friend.id),
                        );
                      }
                      return _FriendsBox(
                        friends: friends,
                        selectedIds: _selectedFriendIds,
                        onChanged: _toggleFriend,
                      );
                    },
                    loading: () => const _LoadingBox(),
                    error: (error, stackTrace) =>
                        _ErrorBox(message: '友達を読み込めませんでした'),
                  ),
                  const SizedBox(height: 10),
                  _InputBox(
                    icon: CupertinoIcons.location_solid,
                    title: '場所',
                    controller: _placeController,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 10),
                  _InputBox(
                    icon: CupertinoIcons.pencil,
                    title: 'メモ（任意）',
                    controller: _memoController,
                    maxLines: 3,
                    counter: '15 / 100',
                  ),
                  const SizedBox(height: 10),
                  const _PhotoBox(),
                  const SizedBox(height: 24),
                  friendsAsync.maybeWhen(
                    data: (friends) => _SaveButton(
                      isSaving: _isSaving,
                      onPressed: () => _save(friends),
                    ),
                    orElse: () =>
                        const _SaveButton(isSaving: true, onPressed: null),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleFriend(String id) {
    setState(() {
      if (_selectedFriendIds.contains(id)) {
        _selectedFriendIds.remove(id);
      } else {
        _selectedFriendIds.add(id);
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.navy,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(
        () => _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        ),
      );
    }
  }

  Future<void> _save(List<NomoFriend> friends) async {
    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('一緒に飲んだ友達を1人以上選んでください。')));
      return;
    }
    setState(() => _isSaving = true);
    final selectedFriends = friends
        .where((friend) => _selectedFriendIds.contains(friend.id))
        .toList(growable: false);
    try {
      await ref
          .read(drinkLogControllerProvider.notifier)
          .addLog(
            date: _selectedDate,
            friends: selectedFriends,
            place: _placeController.text,
            memo: _memoController.text,
          );
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('飲みログを保存できませんでした: $error')));
    }
  }

  static String _dateText(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} (${_weekday(date)}) 20:00';
  static String _weekday(DateTime date) =>
      const ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        onPressed: onBack,
        icon: const Icon(CupertinoIcons.chevron_left, color: AppColors.navy),
      ),
      Expanded(
        child: Text(
          '飲みログを追加',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 48),
    ],
  );
}

class _FormRow extends StatelessWidget {
  const _FormRow({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: _FormShell(
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 21),
          const SizedBox(width: 13),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          Text(
            trailing,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class _FriendsBox extends StatelessWidget {
  const _FriendsBox({
    required this.friends,
    required this.selectedIds,
    required this.onChanged,
  });
  final List<NomoFriend> friends;
  final Set<String> selectedIds;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => _FormShell(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(CupertinoIcons.person_2, color: AppColors.navy, size: 21),
            SizedBox(width: 13),
            Text(
              '一緒に飲んだ友達',
              style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w900,
              ),
            ),
            Spacer(),
            _PlusCircle(),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: friends
              .take(4)
              .map(
                (friend) => Expanded(
                  child: GestureDetector(
                    onTap: () => onChanged(friend.id),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: friend.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedIds.contains(friend.id)
                                  ? AppColors.navy
                                  : AppColors.line,
                              width: selectedIds.contains(friend.id) ? 2.5 : 1,
                            ),
                          ),
                          child: const NomoCharacter(
                            pose: NomoCharacterPose.standingSmile,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          friend.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

class _InputBox extends StatelessWidget {
  const _InputBox({
    required this.icon,
    required this.title,
    required this.controller,
    required this.maxLines,
    this.counter,
  });
  final IconData icon;
  final String title;
  final TextEditingController controller;
  final int maxLines;
  final String? counter;
  @override
  Widget build(BuildContext context) => _FormShell(
    child: Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.navy, size: 21),
        const SizedBox(width: 13),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (counter != null)
          Text(
            counter!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    ),
  );
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox();

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => Navigator.of(
      context,
    ).push(CupertinoPageRoute<void>(builder: (_) => const NomoCameraScreen())),
    child: _FormShell(
      child: Column(
        children: [
          Row(
            children: const [
              Icon(CupertinoIcons.camera, color: AppColors.navy, size: 21),
              SizedBox(width: 13),
              Text(
                'Nomoカメラで撮る',
                style: TextStyle(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Spacer(),
              Icon(
                CupertinoIcons.chevron_right,
                color: AppColors.mutedInk,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF6E8), Color(0xFFEFF6FF)],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.sparkles,
                  color: AppColors.beer,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'フィルター付き写真をInstagramにシェア',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _FormShell extends StatelessWidget {
  const _FormShell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.line),
      boxShadow: [
        BoxShadow(
          color: AppColors.ink.withValues(alpha: .025),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: child,
  );
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.isSaving, required this.onPressed});
  final bool isSaving;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    width: double.infinity,
    child: FilledButton(
      onPressed: isSaving ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      ),
      child: isSaving
          ? const CupertinoActivityIndicator(color: Colors.white)
          : const Text('保存する'),
    ),
  );
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();
  @override
  Widget build(BuildContext context) =>
      const _FormShell(child: Center(child: CupertinoActivityIndicator()));
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => _FormShell(child: Text(message));
}

class _PlusCircle extends StatelessWidget {
  const _PlusCircle();
  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.line),
    ),
    child: const Icon(CupertinoIcons.plus, color: AppColors.navy, size: 19),
  );
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) =>
      Icon(CupertinoIcons.sparkles, color: color, size: 17);
}
