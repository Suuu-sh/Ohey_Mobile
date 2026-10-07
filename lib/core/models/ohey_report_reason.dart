import '../contracts/ohey_api_values.dart';

enum OheyReportReason {
  spam(OheyReportReasonKeys.spam, 'スパム・宣伝', '宣伝、詐欺、迷惑な勧誘'),
  harassment(OheyReportReasonKeys.harassment, '不快・いやがらせ', '攻撃的、差別的、嫌がらせに感じる内容'),
  inappropriate(OheyReportReasonKeys.inappropriate, '不適切な内容', '性的・過度に不快な表現'),
  violence(OheyReportReasonKeys.violence, '暴力・危険行為', '暴力、危険行為、自傷を助長する内容'),
  minorSafety(OheyReportReasonKeys.minorSafety, '未成年・危険', '未成年の安全に関わる懸念'),
  other(OheyReportReasonKeys.other, 'その他', '上記に当てはまらない問題');

  const OheyReportReason(this.value, this.label, this.description);

  final String value;
  final String label;
  final String description;
}
