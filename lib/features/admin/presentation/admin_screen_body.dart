part of 'admin_screen.dart';

class _AdminBody extends StatelessWidget {
  const _AdminBody({required this.section, required this.onSectionChanged});

  final _AdminSection section;
  final ValueChanged<_AdminSection> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final access = ref.watch(adminAccessProvider);
        return Column(
          children: [
            _AdminHeader(onClose: () => Navigator.of(context).pop()),
            const SizedBox(height: 16),
            access.when(
              data: (allowed) => allowed
                  ? _AdminSegmentedControl(
                      section: section,
                      onChanged: onSectionChanged,
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _AdminAccessContent(access: access, section: section),
            ),
          ],
        );
      },
    );
  }
}

class _AdminAccessContent extends ConsumerWidget {
  const _AdminAccessContent({required this.access, required this.section});

  final AsyncValue<bool> access;
  final _AdminSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return access.when(
      data: (allowed) {
        if (!allowed) return const _AdminDeniedState();
        return switch (section) {
          _AdminSection.users => _AdminUsersPane(ref: ref),
          _AdminSection.yurubos => const _AdminYurubosPane(),
          _AdminSection.notifications => const _AdminNotificationsPane(),
        };
      },
      loading: () => const Center(
        child: CupertinoActivityIndicator(color: _AdminColors.lime),
      ),
      error: (error, _) => _AdminErrorState(
        message: '確認できなかったよ。あとでもう一度試してね',
        onRetry: () => ref.invalidate(adminAccessProvider),
      ),
    );
  }
}
