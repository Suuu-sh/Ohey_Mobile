part of 'add_nomi_tomo_screen.dart';

class _DarkCard extends StatelessWidget {
  const _DarkCard({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: _ExchangeColors.card,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: Colors.white.withValues(alpha: .085)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .28),
          blurRadius: 24,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: child,
  );
}

class _DarkInput extends StatelessWidget {
  const _DarkInput({
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => Container(
    height: 58,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .06),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      children: [
        const NomoGeneratedIcon(
          CupertinoIcons.at,
          color: _ExchangeColors.blue,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: .35),
                fontWeight: FontWeight.w800,
              ),
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: .09)),
      ),
      child: const Center(
        child: NomoPopIcon(
          icon: CupertinoIcons.xmark,
          color: _ExchangeColors.lime,
          size: 34,
          iconSize: 20,
          shadow: false,
        ),
      ),
    ),
  );
}

class _PopBadge extends StatelessWidget {
  const _PopBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => NomoPopIcon(
    icon: icon,
    color: color,
    size: 44,
    iconSize: 25,
    shadow: true,
  );
}

class _MiniPopButton extends StatelessWidget {
  const _MiniPopButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: onTap == null ? .55 : 1,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: .38),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NomoGeneratedIcon(icon, color: _ExchangeColors.bg, size: 16),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: _ExchangeColors.bg,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BigPopButton extends StatelessWidget {
  const _BigPopButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 58,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _ExchangeColors.teal,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF079078),
            offset: Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          NomoGeneratedIcon(icon, color: _ExchangeColors.bg, size: 22),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: _ExchangeColors.bg,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ExchangeColors {
  const _ExchangeColors._();

  static const bg = AppColors.darkBackground;
  static const card = Color(0xFF101D29);
  static const lime = Color(0xFFB8FF00);
  static const teal = Color(0xFF17D1AE);
  static const blue = Color(0xFF27B7FF);
  static const purple = Color(0xFFA855F7);
}
