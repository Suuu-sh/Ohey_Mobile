part of 'create_user_dialog.dart';

class _DarkMessageText extends StatelessWidget {
  const _DarkMessageText(this.text, {this.isError = false});

  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.coral : _authPink;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .24)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1.45,
        ),
      ),
    );
  }
}

bool _isValidUserId(String value) =>
    RegExp(r'^[a-zA-Z0-9_]{3,24}$').hasMatch(value);
