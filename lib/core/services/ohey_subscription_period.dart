/// Formats the ISO 8601 subscription periods returned by RevenueCat.
///
/// Returns null for missing or unsupported periods so the app can avoid
/// offering a purchase without first disclosing its renewal interval.
String? oheySubscriptionPeriodLabel(String? subscriptionPeriod) {
  final match = RegExp(
    r'^P([1-9][0-9]*)(W|M|Y)$',
  ).firstMatch(subscriptionPeriod?.trim() ?? '');
  if (match == null) return null;

  final count = match.group(1)!;
  final unit = switch (match.group(2)) {
    'W' => '週間',
    'M' => 'か月',
    'Y' => '年',
    _ => null,
  };
  if (unit == null) return null;
  return '$count$unitごと';
}
