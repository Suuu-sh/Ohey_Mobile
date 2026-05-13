import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/application/nomo_user_controller.dart';
import '../../../core/models/drink_log.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_character.dart';
import '../../../core/widgets/soft_card.dart';
import '../../logs/application/drink_log_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(drinkLogControllerProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final user = ref.watch(nomoUserProvider);
    final logs = logsAsync.asData?.value ?? const <DrinkLog>[];
    final monthlyLogs = logs
        .where((log) => log.isInMonth(DateTime.now()))
        .toList();
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 110),
            sliver: SliverList.list(
              children: [
                _Header(title: 'マイページ'),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 112,
                    height: 112,
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: AppColors.softBlue,
                      shape: BoxShape.circle,
                    ),
                    child: NomoCharacter(
                      pose: user?.characterPose ?? NomoCharacterPose.iconSmile,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'Nomo',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user == null ? 'ID: 未設定' : 'ID: local_preview',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                SoftCard(
                  borderRadius: 28,
                  padding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 8,
                  ),
                  child: Row(
                    children: [
                      _Stat(
                        icon: CupertinoIcons.flame_fill,
                        label: '今月の回数',
                        value: '${monthlyLogs.length}回',
                        color: AppColors.coral,
                      ),
                      _Divider(),
                      _Stat(
                        icon: CupertinoIcons.chart_bar_fill,
                        label: '今までの回数',
                        value: '${logs.length}回',
                        color: AppColors.beer,
                      ),
                      _Divider(),
                      friendsAsync.maybeWhen(
                        data: (friends) => _Stat(
                          icon: CupertinoIcons.person_2_fill,
                          label: '飲み友',
                          value: '${friends.length}人',
                          color: AppColors.green,
                        ),
                        orElse: () => const _Stat(
                          icon: CupertinoIcons.person_2_fill,
                          label: '飲み友',
                          value: '0人',
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _MonthlySummaryCard(count: monthlyLogs.length),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 42),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
        ),
        IconButton.filledTonal(
          onPressed: () {},
          icon: const Icon(CupertinoIcons.gear_alt_fill),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.mutedInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.navy,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 58, color: AppColors.line);
}

class _MonthlySummaryCard extends StatelessWidget {
  const _MonthlySummaryCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final title = count == 0 ? '今月はこれから' : '今月のふりかえり';
    final message = count == 0
        ? 'まだ飲みログがありません。最初の1杯を記録して、思い出を残しましょう。'
        : count < 4
        ? 'いいペースで記録できています。次の予定もNomoに残していきましょう。'
        : '今月はかなり充実しています。よく会う飲み友も増えてきました。';

    return SoftCard(
      borderRadius: 30,
      padding: const EdgeInsets.all(20),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF8E9), Color(0xFFF0F6FF)],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const NomoCharacter(pose: NomoCharacterPose.standingBeer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.mutedInk,
                    height: 1.45,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '今月 $count 回 記録中',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
