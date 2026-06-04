part of 'admin_screen.dart';

class _AdminSheet extends StatelessWidget {
  const _AdminSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: AppColors.cFF071622,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _AdminColors.line),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                  },
                  icon: const OheyGeneratedIcon(
                    CupertinoIcons.xmark,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    ),
  );
}

class _AdminInput extends StatelessWidget {
  const _AdminInput({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscureText,
    maxLines: maxLines,
    onChanged: onChanged,
    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: _AdminColors.sub,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: AppColors.white.withValues(alpha: .06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _AdminColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _AdminColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _AdminColors.lime),
      ),
    ),
  );
}

class _AdminDropdown extends StatelessWidget {
  const _AdminDropdown({
    required this.value,
    required this.users,
    required this.onChanged,
  });

  final String value;
  final List<AdminUserProfile> users;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final values = users.map((user) => user.id).toSet();
    final selectedValue = values.contains(value) ? value : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '思い出のユーザー',
            style: TextStyle(
              color: _AdminColors.sub,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              dropdownColor: AppColors.cFF101B28,
              iconEnabledColor: _AdminColors.lime,
              hint: const Text(
                '投稿者を選択',
                style: TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w800,
                ),
              ),
              items: [
                for (final user in users)
                  DropdownMenuItem(
                    value: user.id,
                    child: Text(
                      '${user.displayName} @${user.userId}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatusDropdown extends StatelessWidget {
  const _AdminStatusDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _adminNormalizeStatus(value);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AdminColors.sub,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in OheyDailyStatus.adminSelectable)
                _AdminStatusChip(
                  label: status.label,
                  selected: status.key == selected,
                  onTap: () => onChanged(status.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminGenderDropdown extends StatelessWidget {
  const _AdminGenderDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = _adminNormalizeGender(value);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _AdminColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _AdminColors.sub,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final gender in _adminSelectableGenders)
                _AdminStatusChip(
                  label: gender.label,
                  selected: gender.key == selected,
                  onTap: () => onChanged(gender.key),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminReadOnlyInfoRow extends StatelessWidget {
  const _AdminReadOnlyInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _AdminColors.line),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _AdminColors.sub,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

class _AdminStatusChip extends StatelessWidget {
  const _AdminStatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? _AdminColors.lime : AppColors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? _AdminColors.lime
                  : AppColors.white.withValues(alpha: .18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.cFF101820 : AppColors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminFilterOption {
  const _AdminFilterOption({required this.key, required this.label});

  final String key;
  final String label;
}

class _AdminFilterChips extends StatelessWidget {
  const _AdminFilterChips({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<_AdminFilterOption> options;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final option in options) ...[
          _AdminStatusChip(
            label: option.label,
            selected: option.key == value,
            onTap: () => onChanged(option.key),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

const _adminReportStatusFilters = <_AdminFilterOption>[
  _AdminFilterOption(key: OheyStatusKeys.pending, label: '未対応'),
  _AdminFilterOption(key: OheyStatusKeys.reviewing, label: '対応中'),
  _AdminFilterOption(key: OheyStatusKeys.resolved, label: '解決済み'),
  _AdminFilterOption(key: OheyStatusKeys.dismissed, label: '却下'),
  _AdminFilterOption(key: OheyStatusKeys.all, label: 'すべて'),
];

const _adminOutboxStatusFilters = <_AdminFilterOption>[
  _AdminFilterOption(key: OheyStatusKeys.failed, label: '失敗'),
  _AdminFilterOption(key: OheyStatusKeys.pending, label: '待機中'),
  _AdminFilterOption(key: OheyStatusKeys.processed, label: '処理済み'),
  _AdminFilterOption(key: OheyStatusKeys.all, label: 'すべて'),
];

void _invalidateAdminOutboxProviders(WidgetRef ref) {
  for (final option in _adminOutboxStatusFilters) {
    ref.invalidate(adminNotificationOutboxProvider(option.key));
  }
}

const _adminSelectableGenders = <OheyGender>[
  OheyGender.unspecified,
  OheyGender.male,
  OheyGender.female,
];

String _adminStatusLabel(String status) {
  return oheyDailyStatusFromKey(status).label;
}

String _adminGenderLabel(String gender) {
  return oheyGenderFromKey(gender).label;
}

String _adminReportReasonLabel(String reason) {
  return switch (reason) {
    OheyReportReasonKeys.spam => 'スパム',
    OheyReportReasonKeys.harassment => '嫌がらせ',
    OheyReportReasonKeys.inappropriate => '不適切',
    OheyReportReasonKeys.violence => '暴力・危険',
    OheyReportReasonKeys.minorSafety => '未成年安全',
    _ => 'その他',
  };
}

String _adminReportStatusLabel(String status) {
  return oheyModerationStatusFromKey(status).label;
}

String _adminOutboxStatusLabel(String status) {
  return switch (status.trim()) {
    OheyStatusKeys.failed => '失敗',
    OheyStatusKeys.processed => '処理済み',
    OheyStatusKeys.pending => '待機中',
    _ => status.trim().isEmpty ? '不明' : status.trim(),
  };
}

String _adminOutboxEventLabel(String eventKind) {
  return switch (eventKind.trim()) {
    'invite.created' => 'お誘い作成',
    'invite.accepted' => 'お誘い承認',
    'friend_request.created' => 'フレンド申請',
    'friend_request.accepted' => 'フレンド承認',
    'memory.tagged' => '思い出タグ付け',
    'memory.liked' => '思い出いいね',
    'memory.reported' => '思い出通報',
    'system_notification.created' => 'System通知',
    _ => eventKind.trim().isEmpty ? '通知イベント' : eventKind.trim(),
  };
}

String _adminOutboxPayloadTitle(Map<String, dynamic> payload) {
  final title = payload['title'] as String?;
  final message = payload['message'] as String?;
  if ((title ?? '').trim().isNotEmpty && (message ?? '').trim().isNotEmpty) {
    return '${title!.trim()} / ${message!.trim()}';
  }
  if ((title ?? '').trim().isNotEmpty) return title!.trim();
  if ((message ?? '').trim().isNotEmpty) return message!.trim();
  final notificationTitle = payload['notification_title'] as String?;
  if ((notificationTitle ?? '').trim().isNotEmpty) {
    return notificationTitle!.trim();
  }
  return '';
}

String _shortAdminId(String id) {
  final trimmed = id.trim();
  if (trimmed.length <= 8) return trimmed;
  return trimmed.substring(0, 8);
}

String _adminNormalizeStatus(String status) {
  return oheyDailyStatusFromKey(status).key;
}

String _adminNormalizeGender(String gender) {
  return oheyGenderFromKey(gender).key;
}

class _AdminSwitchRow extends StatelessWidget {
  const _AdminSwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _AdminColors.line),
    ),
    child: Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Spacer(),
        CupertinoSwitch(
          value: value,
          activeTrackColor: _AdminColors.lime,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _AdminInfoBox extends StatelessWidget {
  const _AdminInfoBox({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _AdminColors.lime.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _AdminColors.lime.withValues(alpha: .28)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          CupertinoIcons.checkmark_seal_fill,
          color: _AdminColors.lime,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: _AdminColors.sub,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _AdminCard extends StatelessWidget {
  const _AdminCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _AdminColors.panel,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: _AdminColors.line),
    ),
    child: child,
  );
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: _AdminColors.lime.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: _AdminColors.lime,
        fontWeight: FontWeight.w900,
        fontSize: 10,
      ),
    ),
  );
}

class _AdminSmallButton extends StatelessWidget {
  const _AdminSmallButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 96,
    child: Ohey3DButtonSurface(
      onTap: onTap,
      height: 36,
      radius: 16,
      color: _AdminColors.lime,
      bottomColor: AppColors.cFF5D8B00,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      borderColor: AppColors.white.withValues(alpha: .14),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.cFF101820,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _AdminIconButton extends StatelessWidget {
  const _AdminIconButton({
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? _AdminColors.pink : _AdminColors.lime;
    return SizedBox(
      width: 39,
      child: Ohey3DButtonSurface(
        onTap: onTap,
        height: 32,
        radius: 14,
        color: color.withValues(alpha: .18),
        bottomColor: ohey3DShadowColorFor(color, lightnessScale: .56),
        padding: EdgeInsets.zero,
        borderColor: color.withValues(alpha: .28),
        outerShadows: [
          BoxShadow(
            color: color.withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        child: OheyGeneratedIcon(icon, color: color, size: 22),
      ),
    );
  }
}

class _AdminPrimaryButton extends StatelessWidget {
  const _AdminPrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Ohey3DButton(
    label: label,
    onTap: busy ? null : onTap,
    isLoading: busy,
    enabled: !busy,
    height: 54,
    radius: 22,
    color: _AdminColors.lime,
    foregroundColor: AppColors.cFF101820,
    shadowColor: AppColors.cFF5D8B00,
    fontSize: 16,
  );
}

class _AdminDeniedState extends StatelessWidget {
  const _AdminDeniedState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'このアカウントでは管理画面を開けません。',
      textAlign: TextAlign.center,
      style: TextStyle(color: _AdminColors.sub, fontWeight: FontWeight.w800),
    ),
  );
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => OheyEmptyState(
    visual: const OheyGeneratedIcon(
      CupertinoIcons.tray,
      color: _AdminColors.lime,
      size: 46,
    ),
    title: message,
    message: '条件を変えるか、あとでもう一度確認してください。',
    titleColor: AppColors.white,
    messageColor: _AdminColors.sub,
  );
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      OheyStateView.error(message: message, compact: false);
}

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.year}/${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _AdminColors {
  const _AdminColors._();

  static const bg = AppColors.darkBackground;
  static const panel = AppColors.cFF101B28;
  static const line = AppColors.c1EFFFFFF;
  static const sub = AppColors.cFF8F9BAB;
  static const lime = AppColors.cFFB8FF00;
  static const pink = AppColors.cFFFF5EA8;
}
