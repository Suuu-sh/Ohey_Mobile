import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/drink_log.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/nomo_page_header.dart';
import '../../../core/widgets/nomo_bottom_sheet.dart';
import '../../../core/widgets/nomo_pop_icon.dart';
import '../../../core/widgets/nomo_empty_state.dart';

part 'photo_archive_visuals.dart';
part 'photo_archive_detail_widgets.dart';
part 'photo_archive_empty_widgets.dart';

class PhotoArchivePreview extends StatelessWidget {
  const PhotoArchivePreview({
    super.key,
    required this.logs,
    required this.isWhite,
    required this.onTap,
  });

  final List<DrinkLog> logs;
  final bool isWhite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedPhotoLogs(logs);
    final memoryLog = _randomMemoryLog(sorted);
    final previewLogs = _archivePreviewLogs(sorted);
    final titleColor = isWhite ? const Color(0xFF101820) : Colors.white;
    final subColor = isWhite
        ? const Color(0xFF7A8490)
        : Colors.white.withValues(alpha: .66);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isWhite
                ? const [Color(0xFFFFFFFF), Color(0xFFF2F7FB)]
                : const [Color(0xFF15273C), Color(0xFF0E1825)],
          ),
          border: Border.all(
            color: isWhite
                ? const Color(0xFFE1E8EF)
                : Colors.white.withValues(alpha: .09),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isWhite ? .07 : .22),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6FA8), Color(0xFFFFC46B)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6FA8).withValues(alpha: .30),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const NomoGeneratedIcon(
                    CupertinoIcons.photo_on_rectangle,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'フォトアーカイブ',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: titleColor,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -.3,
                            ),
                      ),
                      Text(
                        memoryLog == null
                            ? '自分の投稿写真をおしゃれに見返す'
                            : '${_memoryAgoLabel(memoryLog.date)}の思い出',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: subColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '開く',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFFF6FA8),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                const NomoGeneratedIcon(
                  CupertinoIcons.chevron_forward,
                  color: Color(0xFFFF6FA8),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (sorted.isEmpty)
              _ArchiveEmptyPreview(isWhite: isWhite)
            else
              _ArchivePreviewCollage(
                logs: previewLogs,
                totalCount: sorted.length,
              ),
          ],
        ),
      ),
    );
  }
}

class PhotoArchiveScreen extends StatefulWidget {
  const PhotoArchiveScreen({super.key, required this.logs});

  final List<DrinkLog> logs;

  @override
  State<PhotoArchiveScreen> createState() => _PhotoArchiveScreenState();
}

enum _ArchiveViewMode { grid, places }

class _PhotoArchiveScreenState extends State<PhotoArchiveScreen> {
  _ArchiveViewMode _viewMode = _ArchiveViewMode.grid;

  @override
  Widget build(BuildContext context) {
    final sorted = _sortedPhotoLogs(widget.logs);
    final memoryLog = _randomMemoryLog(sorted);
    final isWhite = Theme.of(context).brightness == Brightness.light;
    final background = isWhite
        ? const Color(0xFFF7F9FC)
        : AppColors.darkBackgroundBottom;

    return Scaffold(
      backgroundColor: background,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWhite
                ? const [Colors.white, Color(0xFFF7F9FC)]
                : AppColors.darkBackgroundGradient,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NomoPageHeader.horizontalPadding,
                  NomoPageHeader.topPadding,
                  NomoPageHeader.horizontalPadding,
                  0,
                ),
                child: NomoPageHeader(
                  title: 'アーカイブ',
                  trailing: NomoHeaderIconButton(
                    icon: CupertinoIcons.xmark,
                    color: isWhite ? const Color(0xFF101820) : Colors.white,
                    semanticLabel: '閉じる',
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              if (sorted.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 6),
                  child: _ArchiveViewModeSelector(
                    value: _viewMode,
                    isWhite: isWhite,
                    onChanged: (value) => setState(() => _viewMode = value),
                  ),
                ),
              Expanded(
                child: sorted.isEmpty
                    ? _ArchiveEmptyState(isWhite: isWhite)
                    : _viewMode == _ArchiveViewMode.places
                    ? _ArchivePlacesView(
                        logs: sorted,
                        isWhite: isWhite,
                        onLogTap: (log) => _showArchiveDetail(context, log),
                      )
                    : _ArchiveStoriesView(
                        logs: sorted,
                        memoryLog: memoryLog,
                        isWhite: isWhite,
                        onLogTap: (log) => _showArchiveDetail(context, log),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showArchiveDetail(BuildContext context, DrinkLog log) {
    showNomoBottomSheet<void>(
      context: context,
      builder: (context) => _ArchiveDetailSheet(log: log),
    );
  }
}
