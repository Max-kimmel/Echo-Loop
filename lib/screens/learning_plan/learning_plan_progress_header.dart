part of '../learning_plan_screen.dart';

/// 顶部进度卡片 — 圆环进度 + 状态文字 + 逾期徽章 + 音频元信息
class _ProgressCard extends ConsumerWidget {
  final AppLocalizations l10n;
  final LearningProgress? progress;
  final AudioItem? audioItem;

  const _ProgressCard({required this.l10n, this.progress, this.audioItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // 没有 audioItem 时（理论不出现，因 progress 同源）退化到全局默认 plan。
    final plan = audioItem == null
        ? ref.watch(learningPlanProvider)
        : ref.watch(learningPlanForAudioProvider(audioItem!.id));
    final completedKeys = audioItem == null
        ? const <String>{}
        : ref
              .watch(learningProgressProvider)
              .completionsFor(audioItem!.id);
    final percent = progress?.progressPercent(plan, completedKeys) ?? 0.0;
    final percentText = '${(percent * 100).round()}%';

    final canOpenDetail = audioItem != null;
    return Card(
      child: Semantics(
        button: canOpenDetail,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canOpenDetail ? () => _openAudioDetail(context) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.m,
              vertical: AppSpacing.m,
            ),
            child: Row(
              children: [
                // 左侧：圆环进度
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(
                    painter: _ProgressRingPainter(
                      progress: percent,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      progressColor: theme.colorScheme.primary,
                    ),
                    child: Center(
                      child: Text(
                        percentText,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                // 右侧：三行信息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 第一行：文件标题
                      if (audioItem case final item?)
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      // 第二行：文件描述，最多两行，超出省略
                      if (_getDescription() case final description?) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                      // 第三行：音频元信息
                      if (audioItem != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        _buildAudioInfo(theme),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 点击卡片进入音频详情页（嵌套子路由，见 app_router.dart 的 _audioDetailRoute）
  void _openAudioDetail(BuildContext context) {
    unawaited(
      AppRoutes.pushNested(
        context,
        AppRoutes.audioDetailSegment,
        extra: audioItem,
      ),
    );
  }

  /// 构建音频元信息行
  Widget _buildAudioInfo(ThemeData theme) {
    final item = audioItem!;
    final chips = <Widget>[];

    // 内容异常警告（损坏 / 静音）放在首位，最醒目。
    final contentWarningLabel = _contentWarningLabel(item.contentStatus);
    if (contentWarningLabel != null) {
      chips.add(_buildContentWarningChip(theme, contentWarningLabel));
    }
    // 难度（CEFR）放在元信息行最前，与时长/句数/词数同一行展示。
    final difficulty = CommunityDifficulty.fromCode(item.difficulty);
    if (difficulty != null) {
      chips.add(CommunityDifficultyBadge(difficulty: difficulty));
    }
    if (item.totalDuration > 0) {
      chips.add(
        AudioInfoChip(
          icon: Icons.timer_outlined,
          label: SubtitleParser.formatDuration(
            Duration(seconds: item.totalDuration),
          ),
        ),
      );
    }
    if (item.sentenceCount > 0) {
      chips.add(
        AudioInfoChip(
          icon: Icons.format_list_numbered,
          label: l10n.sentenceCountLabel(item.sentenceCount),
        ),
      );
    }
    if (item.wordCount > 0) {
      chips.add(
        AudioInfoChip(
          icon: Icons.text_fields,
          label: l10n.wordCountLabel(item.wordCount),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }

  /// 内容异常警告徽章，与音频列表项的警告徽章风格一致。
  Widget _buildContentWarningChip(ThemeData theme, String label) {
    final color = theme.colorScheme.error;
    return Container(
      key: const Key('learning_plan_content_warning_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  String? _contentWarningLabel(AudioContentStatus? status) {
    return switch (status) {
      AudioContentStatus.damaged => l10n.audioContentDamagedWarning,
      AudioContentStatus.silent => l10n.audioContentSilentWarning,
      AudioContentStatus.ok || null => null,
    };
  }

  /// 第二行：文件描述（去除首尾空白，为空时返回 null，整行不显示）
  String? _getDescription() {
    final description = audioItem?.description?.trim();
    return description == null || description.isEmpty ? null : description;
  }
}

/// 学习计划页 AppBar 的「自由练习」入口。
///
/// 这里不用普通文字按钮，而是做成轻量 CTA 胶囊，提升可发现性，
/// 同时控制横向占用，避免在移动端把标题进一步挤压。
class _FreePlayAppBarButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FreePlayAppBarButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = colorScheme.primaryContainer.withValues(
      alpha: isDark ? 0.34 : 0.72,
    );
    final borderColor = colorScheme.primary.withValues(
      alpha: isDark ? 0.18 : 0.24,
    );
    final iconColor = colorScheme.primary;
    final labelColor = colorScheme.onPrimaryContainer;

    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        shadowColor: colorScheme.primary.withValues(alpha: 0.12),
        child: InkWell(
          key: const Key('learning_plan_free_play_button'),
          onTap: onPressed,
          borderRadius: BorderRadius.circular(28),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: surfaceColor,
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.headphones_rounded, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                    color: labelColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆环进度绘制器
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const strokeWidth = 6.0;

    // 背景圆环
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // 进度圆弧
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// 学习计划阶段标题行。
///
/// 固定关键列宽，避免某一行缺少状态文案时影响后续进度计数和展开箭头的列对齐。
class _StageHeaderRow extends StatelessWidget {
  final String keyPrefix;
  final Widget leadingIcon;
  final String title;
  final Color? titleColor;
  final Widget statusIcon;
  final String? statusText;
  final Color statusTextColor;
  final String progressText;
  final Color progressColor;
  final bool isExpanded;
  final VoidCallback onTap;

  const _StageHeaderRow({
    required this.keyPrefix,
    required this.leadingIcon,
    required this.title,
    this.titleColor,
    required this.statusIcon,
    this.statusText,
    required this.statusTextColor,
    required this.progressText,
    required this.progressColor,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZh = Localizations.localeOf(context).languageCode == 'zh';
    final titleColumnWidth = isZh
        ? _stageHeaderZhTitleColumnWidth
        : _stageHeaderTitleColumnWidth;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xs,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalGaps =
                AppSpacing.s +
                AppSpacing.xs +
                AppSpacing.s +
                AppSpacing.s +
                AppSpacing.xs;
            final fixedWidth =
                20 +
                titleColumnWidth +
                18 +
                _stageHeaderProgressColumnWidth +
                24 +
                horizontalGaps;
            final statusTextWidth = math
                .max(0, constraints.maxWidth - fixedWidth)
                .clamp(0, _stageHeaderStatusTextMaxWidth)
                .toDouble();

            return Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(child: leadingIcon),
                ),
                const SizedBox(width: AppSpacing.s),
                SizedBox(
                  key: Key('${keyPrefix}_title_column'),
                  width: titleColumnWidth,
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  key: Key('${keyPrefix}_status_icon_column'),
                  width: 18,
                  height: 18,
                  child: Center(child: statusIcon),
                ),
                const SizedBox(width: AppSpacing.s),
                SizedBox(
                  key: Key('${keyPrefix}_status_text_column'),
                  width: statusTextWidth,
                  child: Text(
                    statusText ?? '',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: statusTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: AppSpacing.s),
                SizedBox(
                  key: Key('${keyPrefix}_progress_column'),
                  width: _stageHeaderProgressColumnWidth,
                  child: Text(
                    progressText,
                    textAlign: TextAlign.right,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: progressColor,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                SizedBox(
                  key: Key('${keyPrefix}_expand_column'),
                  width: 24,
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

