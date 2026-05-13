import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/calendar/presentation/calendar_screen.dart';
import '../../features/friends/presentation/friends_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/logs/presentation/add_log_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/onboarding/presentation/create_user_dialog.dart';
import '../application/nomo_user_controller.dart';
import '../data/supabase_client_provider.dart';
import '../theme/app_colors.dart';

class NomoTabShell extends ConsumerStatefulWidget {
  const NomoTabShell({super.key});

  @override
  ConsumerState<NomoTabShell> createState() => _NomoTabShellState();
}

class _NomoTabShellState extends ConsumerState<NomoTabShell> {
  int _selectedIndex = 0;
  bool _didScheduleOnboarding = false;

  static const _pages = [
    HomeScreen(),
    FriendsScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(nomoUserProvider);
    ref.watch(supabaseAuthStateProvider);
    if (user == null && !_didScheduleOnboarding) {
      _didScheduleOnboarding = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || ref.read(nomoUserProvider) != null) return;
        final hasSession =
            ref.read(supabaseClientProvider).auth.currentSession != null;
        if (hasSession) {
          try {
            final loaded = await ref
                .read(nomoUserProvider.notifier)
                .loadFromSupabaseProfile();
            if (!mounted || loaded) return;
          } catch (_) {
            // Fall through to onboarding so the user can repair the profile.
          }
        }
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => const CreateUserDialog(),
        );
        if (mounted && ref.read(nomoUserProvider) == null) {
          _didScheduleOnboarding = false;
          setState(() {});
        }
      });
    }

    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: .08),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              _TabItem(
                icon: CupertinoIcons.house,
                selectedIcon: CupertinoIcons.house_fill,
                label: 'ホーム',
                selected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _TabItem(
                icon: CupertinoIcons.person_2,
                selectedIcon: CupertinoIcons.person_2_fill,
                label: '友達',
                selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      CupertinoPageRoute<void>(
                        builder: (_) => const AddLogScreen(),
                      ),
                    ),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.navy, AppColors.deepNavy],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: .25),
                            blurRadius: 18,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.plus,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              _TabItem(
                icon: CupertinoIcons.calendar,
                selectedIcon: CupertinoIcons.calendar_today,
                label: 'カレンダー',
                selected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _TabItem(
                icon: CupertinoIcons.person,
                selectedIcon: CupertinoIcons.person_fill,
                label: 'マイページ',
                selected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.navy : const Color(0xFF9BA0B5);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 21),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
