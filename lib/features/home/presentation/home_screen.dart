import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/models/nomo_friend_mood.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_character.dart';
import '../../logs/application/drink_log_controller.dart';
import '../../logs/presentation/add_log_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(drinkLogControllerProvider);
    final logs = logsAsync.asData?.value ?? const <DrinkLog>[];
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final monthlyLogs = logs.where((log) => log.isInMonth(month)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final mood = moodForMonthlyDrinkCount(monthlyLogs.length);

    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 112),
            sliver: SliverList.list(
              children: [
                const _NomoHeader(),
                const SizedBox(height: 20),
                _HeroCountCard(count: monthlyLogs.length, mood: mood),
                const SizedBox(height: 14),
                _PrimaryNavyButton(
                  label: '飲みに行った！',
                  icon: CupertinoIcons.plus,
                  onPressed: () => Navigator.of(context).push(
                    CupertinoPageRoute<void>(
                      builder: (_) => const AddLogScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(title: '最近の飲みログ', trailing: 'すべて見る'),
                const SizedBox(height: 12),
                if (logsAsync.isLoading && logs.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CupertinoActivityIndicator(),
                    ),
                  )
                else if (monthlyLogs.isEmpty)
                  const _EmptyLogCard()
                else
                  ...monthlyLogs.take(3).map((log) => _RecentLogTile(log: log)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NomoHeader extends StatelessWidget {
  const _NomoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: AppColors.softBlue,
            shape: BoxShape.circle,
          ),
          child: const NomoCharacter(pose: NomoCharacterPose.standingSmile),
        ),
        Expanded(
          child: Text(
            'Nomo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
        ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: const Icon(
            CupertinoIcons.bell,
            size: 18,
            color: AppColors.navy,
          ),
        ),
      ],
    );
  }
}

class _HeroCountCard extends StatelessWidget {
  const _HeroCountCard({required this.count, required this.mood});

  final int count;
  final NomoFriendMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 184,
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF6F8FC), Color(0xFFEFF5FF)],
        ),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: .05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            left: 158,
            top: 38,
            child: _Sparkle(color: AppColors.beer),
          ),
          const Positioned(
            left: 184,
            top: 72,
            child: _Sparkle(color: AppColors.sky),
          ),
          const Positioned(
            left: 232,
            top: 30,
            child: _Sparkle(color: AppColors.peach),
          ),
          Positioned(
            right: 4,
            bottom: -3,
            child: NomoCharacter(
              pose: nomoPoseForDrinkCount(count),
              width: 138,
              height: 138,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '今月の飲みに行った回数',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      '$count',
                      key: ValueKey(count),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -3.6,
                        height: .88,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      '回',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '今月も楽しもう！',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrimaryNavyButton extends StatelessWidget {
  const _PrimaryNavyButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          elevation: 0,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        Text(
          trailing,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.mutedInk,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RecentLogTile extends StatelessWidget {
  const _RecentLogTile({required this.log});

  final DrinkLog log;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.softBlue,
              shape: BoxShape.circle,
            ),
            child: const NomoCharacter(pose: NomoCharacterPose.standingSmile),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${log.date.month}/${log.date.day} (${_weekday(log.date)}) ${_time(log.date)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.friendNames,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  log.place,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 86,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B261B), Color(0xFFC48949)],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.photo_fill,
                    color: AppColors.navy,
                    size: 30,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${log.friends.length}人',
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _weekday(DateTime date) {
    const labels = ['月', '火', '水', '木', '金', '土', '日'];
    return labels[date.weekday - 1];
  }

  static String _time(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _EmptyLogCard extends StatelessWidget {
  const _EmptyLogCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        'まだ今月の飲みログはありません。',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.mutedInk,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  const _Sparkle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(CupertinoIcons.sparkles, size: 16, color: color);
  }
}
