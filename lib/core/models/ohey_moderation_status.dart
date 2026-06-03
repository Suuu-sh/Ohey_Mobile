import '../contracts/ohey_api_values.dart';

const oheyModerationPendingKey = OheyStatusKeys.pending;
const oheyModerationReviewingKey = OheyStatusKeys.reviewing;
const oheyModerationResolvedKey = OheyStatusKeys.resolved;
const oheyModerationDismissedKey = OheyStatusKeys.dismissed;

enum OheyModerationStatus {
  pending(oheyModerationPendingKey),
  reviewing(oheyModerationReviewingKey),
  resolved(oheyModerationResolvedKey),
  dismissed(oheyModerationDismissedKey);

  const OheyModerationStatus(this.key);

  final String key;

  static const actions = <OheyModerationStatus>[
    OheyModerationStatus.reviewing,
    OheyModerationStatus.resolved,
    OheyModerationStatus.dismissed,
  ];
}

extension OheyModerationStatusX on OheyModerationStatus {
  String get label => switch (this) {
    OheyModerationStatus.pending => '未対応',
    OheyModerationStatus.reviewing => '対応中',
    OheyModerationStatus.resolved => '解決済み',
    OheyModerationStatus.dismissed => '却下',
  };

  String get actionLabel => switch (this) {
    OheyModerationStatus.pending => label,
    OheyModerationStatus.reviewing => '対応中',
    OheyModerationStatus.resolved => '解決',
    OheyModerationStatus.dismissed => '却下',
  };

  bool get isDestructiveAction => this == OheyModerationStatus.dismissed;
}

OheyModerationStatus oheyModerationStatusFromKey(String? key) {
  return switch (key?.trim()) {
    oheyModerationReviewingKey => OheyModerationStatus.reviewing,
    oheyModerationResolvedKey => OheyModerationStatus.resolved,
    oheyModerationDismissedKey => OheyModerationStatus.dismissed,
    _ => OheyModerationStatus.pending,
  };
}
