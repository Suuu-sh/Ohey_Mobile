part of 'create_user_dialog.dart';

class _SignupProgressHeader extends StatelessWidget {
  const _SignupProgressHeader({required this.progress, required this.onBack});

  final double progress;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF12222C),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .14),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: IconButton(
          onPressed: onBack,
          icon: Icon(
            CupertinoIcons.arrow_left,
            color: Colors.white.withValues(alpha: .76),
            size: 31,
          ),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 22,
            color: Colors.white.withValues(alpha: .18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0, 1),
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: _authPink,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: .22),
                        blurRadius: 0,
                        spreadRadius: -5,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _SignupInputBox extends StatelessWidget {
  const _SignupInputBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFF132630).withValues(alpha: .74),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withValues(alpha: .18), width: 2),
    ),
    child: child,
  );
}

class _SignupStepButton extends StatelessWidget {
  const _SignupStepButton({
    required this.label,
    required this.busy,
    required this.enabled,
    required this.onTap,
    this.height = 64,
  });

  final String label;
  final bool busy;
  final bool enabled;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) => Nomo3DButton(
    label: label,
    onTap: enabled ? onTap : null,
    isLoading: busy,
    enabled: enabled,
    height: height,
    radius: 18,
    color: _authPink,
    shadowColor: _authPinkShadow,
    disabledColor: _authPink,
    disabledOpacity: 1,
    foregroundColor: _authPinkInk,
    fontSize: 19,
  );
}
