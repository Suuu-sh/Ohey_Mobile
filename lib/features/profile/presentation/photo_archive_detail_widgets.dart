part of 'photo_archive_screen.dart';

class _ArchiveDetailSheet extends StatelessWidget {
  const _ArchiveDetailSheet({required this.memory});

  final Memory memory;

  @override
  Widget build(BuildContext context) {
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = isWhite
        ? const Color(0xFF7A8490)
        : Colors.white.withValues(alpha: .68);
    final comment = memory.memo.trim();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
        decoration: BoxDecoration(
          color: isWhite ? Colors.white : const Color(0xFF101B28),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(34)),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFE1E8EF)
                : Colors.white.withValues(alpha: .08),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: subColor.withValues(alpha: .45),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _ArchivePhotoFrame(
                memory: memory,
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _archiveTitle(memory),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w900,
                letterSpacing: -.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _archiveDate(memory.date),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: subColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (memory.friendNames.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _ArchiveInfoPill(
                icon: CupertinoIcons.person_2_fill,
                text: memory.friendNames.trim(),
              ),
            ],
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                comment,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: titleColor.withValues(alpha: .88),
                  fontWeight: FontWeight.w800,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArchiveInfoPill extends StatelessWidget {
  const _ArchiveInfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF26D9C7).withValues(alpha: .14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NomoGeneratedIcon(icon, color: const Color(0xFF26D9C7), size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF26D9C7),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArchivePhotoFrame extends StatelessWidget {
  const _ArchivePhotoFrame({
    required this.memory,
    required this.borderRadius,
    this.overlay,
  });

  final Memory memory;
  final BorderRadius borderRadius;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    final provider = _imageProviderFor(memory.photoAssetPath);
    return ClipRRect(
      borderRadius: borderRadius,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (provider == null)
            const _ArchivePhotoPlaceholder()
          else
            Image(
              image: provider,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  const _ArchivePhotoPlaceholder(),
            ),
          ?overlay,
        ],
      ),
    );
  }
}

class _ArchivePhotoPlaceholder extends StatelessWidget {
  const _ArchivePhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF182B44), Color(0xFF44203A)],
        ),
      ),
      child: const Center(
        child: NomoGeneratedIcon(
          CupertinoIcons.photo_fill_on_rectangle_fill,
          color: Colors.white70,
          size: 32,
        ),
      ),
    );
  }
}
