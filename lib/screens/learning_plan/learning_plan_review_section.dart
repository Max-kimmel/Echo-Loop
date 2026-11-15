part of '../learning_plan_screen.dart';

/// 单个复习轮次的数据模型
class _ReviewStageData {
  final String name;
  final LearningStage stage;

  const _ReviewStageData({required this.name, required this.stage});
}

/// 单个复习轮次区块（与首次学习同级）
///
/// 视觉与首次学习区块保持一致：标题行可独立折叠/展开，展开后显示子阶段。
class _ReviewRoundSection extends ConsumerWidget {
  final AppLocalizations l10n;
  final LearningProgress? progress;
  final _ReviewStageData review;
  final DateTime now;

  /// 合集 ID（导航用）
  final String? collectionId;

  /// 音频项 ID（导航用）
  final String audioItemId;
  final bool isExpanded;
  final VoidCallback onToggle;

  /// 点击当前进行中步骤的回调（效果同底部「开始学习」），不可启动时为 null
  final VoidCallback? onStartCurrentStage;

  const _ReviewRoundSection({
    required this.l10n,
    this.progress,
    required this.review,
    required this.now,
    required this.collectionId,
    required this.audioItemId,
    required this.isExpanded,
    required this.onToggle,
    this.onStartCurrentStage,
  });

  /// 使用统计与任务卡片共用的阶段展示定义，仅补充复习描述。
  _StepData _stepDataForStage(StudyStage stage, String description) {
    final visual = studyStageVisual(stage, l10n);
    return _StepData(
      icon: visual.icon,
      iconColor: visual.iconColor,
      name: visual.name,
      description: description,
    );
  }

  /// 计算本轮次「已完成」子步骤数（基于真实完成历史 [completedKeys]）。
  int _completedSubStageCount(Set<String> completedKeys) {
    int count = 0;
    for (final sub in review.stage.allSubStages) {
      if (completedKeys.contains('${review.stage.key}:${sub.key}')) count += 1;
    }
    return count;
  }

  /// 当前复习轮次时间文案（仅当前轮次显示）。
  ///
  /// 展示优先级：已有进度→"学习中" > 未到时间倒计时 > 逾期提示 > 可复习。
  String? _reviewTimingText(
    BuildContext context, {
    required Set<String> completedKeys,
  }) {
    if (progress == null) return null;
    if (!progress!.isCurrentStage(review.stage)) return null;

    // 已有进度（至少完成 1 个子阶段）→ 显示"学习中"
    if (_completedSubStageCount(completedKeys) > 0) {
      return l10n.learningInProgress;
    }

    final nextReview = progress!.nextReviewAt;
    if (nextReview == null) return null;

    // 与锁定判定同源（isReviewReadyAt 对手动解锁短路），避免手动解锁后
    // 按钮已消失、倒计时文案却仍显示的不一致。
    if (!progress!.isReviewReadyAt(now) && now.isBefore(nextReview)) {
      final diff = nextReview.difference(now);
      if (diff.inDays > 0) {
        return l10n.reviewUnlockIn(diff.inDays);
      }
      return l10n.reviewUnlockInHours(diff.inHours.clamp(1, 999));
    }

    if (progress!.isReviewOverdueAt(now)) {
      return _formatOverdueText(context, progress!.overdueDurationAt(now));
    }

    return l10n.reviewDue;
  }

  /// 逾期措辞：短期保留时间信息，长期只显示"待复习"。
  ///
  /// - 无时长 / >7天 → "待复习"
  /// - ≤7天 → "待复习 · X天前到期"
  /// - <1天 → "待复习 · X小时前到期"
  String _formatOverdueText(BuildContext context, Duration? overdue) {
    // 无时长信息或长期逾期（>7天）只显示"待复习"
    if (overdue == null || overdue.inDays > 7) {
      return l10n.reviewDue;
    }
    if (overdue.inDays > 0) {
      return l10n.overdueDays(overdue.inDays);
    }
    final hours = overdue.inHours.clamp(1, 999);
    return l10n.overdueHours(hours);
  }

  /// 复习子阶段名称与描述映射
  _StepData _subStageData(SubStageType subStage) {
    final retellSummaryVisual = studyRetellSummaryVisual(l10n);
    return switch (subStage) {
      SubStageType.blindListen => _stepDataForStage(
        StudyStage.blindListen,
        l10n.reviewBlindListenDesc,
      ),
      SubStageType.intensiveListen => _stepDataForStage(
        StudyStage.intensiveListen,
        l10n.stepIntensiveListeningDesc,
      ),
      SubStageType.listenAndRepeat => _stepDataForStage(
        StudyStage.listenAndRepeat,
        l10n.stepShadowingDesc,
      ),
      SubStageType.retell => _stepDataForStage(
        StudyStage.retell,
        l10n.stepRetellingDesc,
      ),
      SubStageType.reviewDifficultPractice => _stepDataForStage(
        StudyStage.reviewDifficultPractice,
        l10n.reviewDifficultPracticeDesc,
      ),
      SubStageType.reviewRetellParagraph => _stepDataForStage(
        StudyStage.retell,
        l10n.reviewRetellParagraphDesc,
      ),
      SubStageType.reviewRetellSummary => _StepData(
        icon: retellSummaryVisual.icon,
        iconColor: retellSummaryVisual.iconColor,
        name: retellSummaryVisual.name,
        description: l10n.reviewRetellSummaryDesc,
      ),
    };
  }

  /// 进入自由练习盲听模式（复习阶段的全文盲听）
  Future<void> _startFreePlayBlindListen(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final audioItem = ref
        .read(audioLibraryProvider.notifier)
        .getItemById(audioItemId);
    if (audioItem == null) return;
    final sentences = audioItem.isVideo
        ? await ref.read(audioSentencesProvider(audioItemId).future)
        : ref.read(listeningPracticeProvider).sentences;
    if (!context.mounted) return;
    if (sentences.isEmpty) return;

    // 按当前难句书签数实时重算难度，难度降低后速度随之回升
    final liveDifficulty = await ref
        .read(learningProgressProvider.notifier)
        .refreshDifficultyFromBookmarks(audioItemId, sentences.length);
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final estimatedDuration = estimateBlindListenSessionDuration(
      sentences: sentences,
      fullAudioDuration: ref.read(audioEngineProvider).totalDuration,
      skipSilenceEnabled: ref.read(appSettingsProvider).skipSilenceEnabled,
    );

    final smartSpeed = progress == null
        ? 1.0
        : defaultPlaybackSpeedFor(liveDifficulty, review.stage);
    final slot = stageSlotKey(StageSettingsSlots.blindListen, review.stage);
    final blindPrefs = ref.read(blindListenPrefsProvider.notifier);
    final defaults = blindPrefs.resolve(slot, smartSpeed: smartSpeed);
    final blindSeconds = blindPrefs.resolveTargetSeconds(
      slot,
      smartSeconds: -1,
    );
    showBlindListenParagraphSheet(
      context: context,
      sentences: sentences,
      estimatedDurationText: estimatedDuration != null
          ? formatEstimatedDuration(l10n, estimatedDuration)
          : null,
      defaultPlaybackSpeed: defaults.playbackSpeed,
      defaultSeconds: blindSeconds,
      defaultPause: blindPauseChoiceFromSettings(defaults),
      onSelectionChanged: blindPrefsRecorder(ref, slot, defaults, blindSeconds),
      onStartPractice: (targetDuration, pause, playbackSpeed) async {
        final settings = ref
            .read(blindListenPrefsProvider.notifier)
            .resolve(slot, smartSpeed: smartSpeed);
        final paragraphs = groupSentencesIntoParagraphs(
          sentences,
          targetDuration,
        );
        await _openBlindListenPractice(
          context: context,
          ref: ref,
          audioItem: audioItem,
          collectionId: collectionId,
          paragraphs: paragraphs,
          settings: settings,
          stage: review.stage,
          loadKey: '${audioItem.id}:blind-listen:${review.stage.key}:free-play',
          isFreePlay: true,
          catchUpStage: review.stage,
          catchUpSubStage: SubStageType.blindListen,
        );
      },
    );
  }

  /// 进入自由练习难句补练模式
  Future<void> _startFreePlayDifficultPractice(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final allowed = await ensureSpeechReadyForSubStage(
      context,
      ref,
      SubStageType.reviewDifficultPractice,
    );
    if (!allowed || !context.mounted) return;

    final audioItem = ref
        .read(audioLibraryProvider.notifier)
        .getItemById(audioItemId);
    if (audioItem == null) return;
    final sentences = audioItem.isVideo
        ? await ref.read(audioSentencesProvider(audioItemId).future)
        : ref.read(listeningPracticeProvider).sentences;
    if (sentences.isEmpty || !context.mounted) return;

    // 难句补练自由练习也按"先弹 briefing 含速度下拉"流程，与按计划学习对齐。
    final difficultDuration = sentences
        .where((s) => s.isBookmarked)
        .fold<Duration>(Duration.zero, (sum, s) => sum + s.duration);
    // 按当前难句书签数实时重算难度，难度降低后速度随之回升
    final liveDifficulty = await ref
        .read(learningProgressProvider.notifier)
        .refreshDifficultyFromBookmarks(audioItemId, sentences.length);
    if (!context.mounted) return;
    final smartSpeed = progress == null
        ? 1.0
        : defaultPlaybackSpeedFor(liveDifficulty, review.stage);
    final slot = stageSlotKey(
      StageSettingsSlots.reviewDifficultPractice,
      review.stage,
    );
    final dp = ref.read(difficultPracticePrefsProvider.notifier);
    final defaults = dp.resolve(slot, smartSpeed: smartSpeed);
    final estimated = estimateDifficultPracticeDuration(
      difficultSentenceDuration: difficultDuration,
      blindListenRepeatCount: defaults.isManualMode
          ? 1
          : defaults.blindListenRepeatCount,
      shadowReadingRepeatCount: defaults.isManualMode
          ? 1
          : defaults.shadowReadingRepeatCount,
    );
    showReviewBriefingSheet(
      context: context,
      stage: review.stage,
      subStage: SubStageType.reviewDifficultPractice,
      estimatedDuration: estimated,
      defaultPlaybackSpeed: defaults.playbackSpeed,
      defaultPause: difficultPauseChoiceFromSettings(defaults),
      onSelectionChanged: difficultPrefsRecorder(ref, slot, defaults),
      onStartPractice: (playbackSpeed, pause) async {
        final settings = ref
            .read(difficultPracticePrefsProvider.notifier)
            .resolve(slot, smartSpeed: smartSpeed);
        context.push(
          AppRoutes.reviewDifficultPractice(collectionId, audioItemId),
          extra: MediaLearningStartup(
            loadKey:
                '${audioItem.id}:review-difficult:${review.stage.key}:free-play',
            showVideoLoading: audioItem.isVideo,
            load: () async {
              final result = await ref
                  .read(learningSessionProvider.notifier)
                  .enterReviewDifficultPracticeMode(
                    audioItem,
                    sentences,
                    isFreePlay: true,
                    settings: settings,
                    stage: review.stage,
                  );
              if (result != MediaLoadResult.ready) return result;
              ref
                  .read(learningSessionProvider.notifier)
                  .setCatchUp(
                    review.stage,
                    SubStageType.reviewDifficultPractice,
                  );
              return result;
            },
            cancel: () => ref
                .read(learningSessionProvider.notifier)
                .cancelReviewDifficultPracticeEntry(),
          ),
        );
      },
    );
  }

  /// 进入自由练习复述模式（段落复述 / 全文复述）
  Future<void> _startFreePlayRetell(
    BuildContext context,
    WidgetRef ref, {
    required bool isSummary,
  }) async {
    final allowed = await ensureSpeechReadyForSubStage(
      context,
      ref,
      isSummary
          ? SubStageType.reviewRetellSummary
          : SubStageType.reviewRetellParagraph,
    );
    if (!allowed || !context.mounted) return;

    final audioItem = ref
        .read(audioLibraryProvider.notifier)
        .getItemById(audioItemId);
    if (audioItem == null) return;
    final sentences = audioItem.isVideo
        ? await ref.read(audioSentencesProvider(audioItemId).future)
        : ref.read(listeningPracticeProvider).sentences;
    if (!context.mounted || sentences.isEmpty) return;

    final catchUpSub = isSummary
        ? SubStageType.reviewRetellSummary
        : SubStageType.reviewRetellParagraph;

    if (isSummary) {
      // 全文复述：全文作为单个段落，无需选择时长
      await _openRetellPractice(
        context: context,
        ref: ref,
        audioItem: audioItem,
        collectionId: collectionId,
        paragraphs: [sentences],
        loadKey: '${audioItem.id}:retell-summary:${review.stage.key}:free-play',
        isFreePlay: true,
        catchUpStage: review.stage,
        catchUpSubStage: catchUpSub,
      );
      return;
    }

    // 段落复述：弹出简报面板让用户选择段落时长（预估时长由 sheet 内部按真实公式动态计算）
    final progressForRetell = ref
        .read(learningProgressProvider)
        .progressMap[audioItemId];
    // 按当前难句书签数实时重算难度，难度降低后速度/可见词比例随之调整
    final liveDifficulty = await ref
        .read(learningProgressProvider.notifier)
        .refreshDifficultyFromBookmarks(audioItemId, sentences.length);
    if (!context.mounted) return;
    final slot = stageSlotKey(StageSettingsSlots.retell, review.stage);
    final prefill = retellBriefingDefaults(
      ref,
      slot,
      smartSpeed: progressForRetell != null
          ? defaultPlaybackSpeedFor(liveDifficulty, review.stage)
          : 1.0,
      smartRatio: KeywordRatio.forDifficultyAndStage(
        liveDifficulty,
        review.stage,
      ),
      smartSeconds: retellDefaultSeconds(review.stage),
    );
    showRetellBriefingSheet(
      context: context,
      sentences: sentences,
      defaultSeconds: prefill.seconds,
      defaultKeywordRatio: progressForRetell != null ? prefill.ratio : null,
      defaultPlaybackSpeed: prefill.speed,
      repeatCount: prefill.settings.isManualMode
          ? 1
          : prefill.settings.repeatCount,
      defaultPause: prefill.pause,
      onSelectionChanged: retellPrefsRecorder(ref, slot, prefill.settings),
      onStartPractice: (targetDuration, pause, keywordRatio, playbackSpeed) async {
        final paragraphs = groupSentencesIntoParagraphs(
          sentences,
          targetDuration,
        );
        await _openRetellPractice(
          context: context,
          ref: ref,
          audioItem: audioItem,
          collectionId: collectionId,
          paragraphs: paragraphs,
          loadKey:
              '${audioItem.id}:retell-paragraph:${review.stage.key}:free-play',
          isFreePlay: true,
          catchUpStage: review.stage,
          catchUpSubStage: catchUpSub,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = ref.watch(learningPlanForAudioProvider(audioItemId));
    final stageCompletedAtMap =
        ref
            .watch(reviewStageCompletionTimesProvider(audioItemId))
            .value ??
        const <String, DateTime>{};
    final completedKeys = ref
        .watch(learningProgressProvider)
        .completionsFor(audioItemId);
    // 迭代顺序 = 当前 plan 顺序 + 历史外延项（已完成 / 已跳过但不在当前 plan 内）。
    // 例如 review28 v1 用户完成了 reviewRetellSummary 后切到 v2 不会发生（v1 用户
    // 该 stage 有 completion 仍走 v1 plan），但 helper 防御性兜底。
    final subStages = _orderedSubStagesForDisplay(
      plan: plan,
      stage: review.stage,
      completedKeys: completedKeys,
      skippedKeys: progress?.skippedSubStageKeys ?? const {},
    );
    final completedCount = _completedSubStageCount(completedKeys);
    final timingText = _reviewTimingText(context, completedKeys: completedKeys);
    final isCompleted = progress?.isStageCompleted(review.stage) ?? false;
    final isCurrent = progress?.isCurrentStage(review.stage) ?? false;
    final isFuture = !isCompleted && !isCurrent;
    final completedAt = stageCompletedAtMap[review.stage.key];
    // 标题行文案优先级：
    // 1. 已完成轮次显示相对完成时间
    // 2. 当前轮次显示真实倒计时 / 待复习 / 逾期
    // 3. 未来轮次不显示固定时间标签，避免误导为累计里程碑
    final statusText = isCompleted
        ? (completedAt == null
              ? null
              : formatCompletedStageTimeLabel(context, completedAt))
        : timingText;
    // 标题颜色：已完成→绿色，当前→默认，未来→弱化
    final titleColor = isCompleted
        ? Colors.green
        : isFuture
        ? theme.colorScheme.onSurfaceVariant
        : null;
    // 状态文案颜色：已完成→绿色，其余状态→弱化前景色。
    final statusColor = isCompleted
        ? Colors.green
        : theme.colorScheme.onSurfaceVariant;
    final reviewIconColor = isCompleted
        ? Colors.green
        : isFuture
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.onSurface;
    // 当前轮次锁定且未暂停 → 显示可点解锁药丸（倒计时并入药丸，不再挤在标题行）
    final showUnlockPill =
        isCurrent &&
        !(progress?.isPaused ?? false) &&
        (progress?.isReviewLockedAt(now) ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          // 未开始（锁定）轮次进一步弱化，避免抢夺当前/已完成轮次的注意力
          opacity: isFuture ? 0.45 : 1.0,
          child: _StageHeaderRow(
            keyPrefix: 'learning_plan_stage_${review.stage.key}',
            leadingIcon: SvgPicture.asset(
              _refreshIconAsset,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(reviewIconColor, BlendMode.srcIn),
            ),
            title: review.name,
            titleColor: titleColor,
            statusIcon: isCompleted
                ? SvgPicture.asset(
                    _checkCircleIconAsset,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      Colors.green,
                      BlendMode.srcIn,
                    ),
                  )
                : isCurrent
                ? SvgPicture.asset(_calendarIconAsset, width: 18, height: 18)
                : SvgPicture.asset(
                    _lockIconAsset,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                  ),
            // 状态文案内联到标题行：已完成显示完成时间，当前显示真实状态，
            // 未来轮次不显示固定“After X days”，但仍保留状态文案列宽。
            statusText: statusText,
            statusTextColor: statusColor,
            progressText: l10n.stepProgress(completedCount, subStages.length),
            progressColor: isCompleted
                ? Colors.green
                : theme.colorScheme.onSurfaceVariant,
            isExpanded: isExpanded,
            onTap: onToggle,
          ),
        ),
        // 当前轮次锁定且未暂停时显示「立即解锁」药丸按钮：倒计时是标题行的
        // 纯展示 label，解锁是独立按钮，两者分离避免歧义（解锁写 manualUnlockAt，
        // 不篡改完成时间，后续轮次仍按实际完成时间顺延）。
        if (showUnlockPill)
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.xl,
              top: AppSpacing.xs,
            ),
            child: Material(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => ref
                    .read(learningProgressProvider.notifier)
                    .unlockCurrentReview(audioItemId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(
                        _unlockIconAsset,
                        width: 14,
                        height: 14,
                        colorFilter: ColorFilter.mode(
                          theme.colorScheme.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        l10n.unlockReviewNow,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (isExpanded) ...[
          const SizedBox(height: AppSpacing.s),
          Column(
            children: List.generate(subStages.length, (index) {
              final subStage = subStages[index];
              final subStageData = _subStageData(subStage);
              final isCompleted =
                  progress?.isSubStageCompleted(
                    review.stage,
                    subStage,
                    completedKeys,
                  ) ??
                  false;
              final isCurrent =
                  progress?.isCurrentSubStage(review.stage, subStage) ?? false;
              final isSkipped =
                  progress?.isSubStageSkipped(review.stage, subStage) ?? false;

              // 难句补练步骤：显示难句数量或自动完成提示
              String? subtitle;
              if (subStage == SubStageType.reviewDifficultPractice) {
                final bookmarkCount =
                    ref
                        .watch(_bookmarkCountProvider(audioItemId))
                        .value ??
                    0;
                if (isCompleted && bookmarkCount == 0) {
                  subtitle = l10n.autoCompletedNoDifficultReview;
                } else if (bookmarkCount > 0) {
                  subtitle = l10n.difficultSentenceCount(bookmarkCount);
                }
              }

              // 已完成、已跳过（含当前阶段内跳过）或过去阶段的子步骤都支持点击进入自由练习。
              // （跳过的步骤用户随时可补做，不必等大阶段推进）
              final isPast =
                  progress != null &&
                  review.stage.index < progress!.currentStage.index;
              final canFreePlay = isCompleted || isSkipped || isPast;
              VoidCallback? onTap;
              if (canFreePlay) {
                // 无难句自动完成的补练步骤：点击只显示提示
                final bookmarkCount =
                    ref
                        .watch(_bookmarkCountProvider(audioItemId))
                        .value ??
                    0;
                if (subStage == SubStageType.reviewDifficultPractice &&
                    bookmarkCount == 0) {
                  onTap = () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.autoCompletedNoDifficultReview),
                      ),
                    );
                  };
                } else {
                  onTap = switch (subStage) {
                    SubStageType.blindListen => () => _startFreePlayBlindListen(
                      context,
                      ref,
                    ),
                    SubStageType.reviewDifficultPractice =>
                      () => _startFreePlayDifficultPractice(context, ref),
                    SubStageType.reviewRetellParagraph =>
                      () =>
                          _startFreePlayRetell(context, ref, isSummary: false),
                    SubStageType.reviewRetellSummary =>
                      () => _startFreePlayRetell(context, ref, isSummary: true),
                    _ => null,
                  };
                }
              }

              // 当前进行中的步骤：点击等同底部「开始学习」
              if (isCurrent) {
                onTap = onStartCurrentStage;
              }

              return _StepCard(
                stepNumber: index + 1,
                icon: subStageData.icon,
                iconColor: subStageData.iconColor,
                name: subStageData.name,
                description: subStageData.description,
                isCompleted: isCompleted,
                isCurrent: isCurrent,
                isSkipped: isSkipped,
                isFirst: index == 0,
                isLast: index == subStages.length - 1,
                subtitle: subtitle,
                onTap: onTap,
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// 音频信息行 — 显示时长、句子数、单词数
/// 单个信息标签
/// 无字幕提醒横幅 — 提示用户需要上传字幕，支持直接打开字幕管理
class _NoTranscriptBanner extends StatelessWidget {
  final AppLocalizations l10n;
  final AudioItem audioItem;
  final GuideStep addSubtitleStep;

  const _NoTranscriptBanner({
    required this.l10n,
    required this.audioItem,
    required this.addSubtitleStep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.onErrorContainer,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Text(
                l10n.noTranscriptWarning,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            GuideTarget(
              step: addSubtitleStep,
              child: FilledButton.icon(
                onPressed: () => _showManageSubtitlesSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.addSubtitle),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.onErrorContainer,
                  foregroundColor: theme.colorScheme.errorContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.m,
                    vertical: AppSpacing.xs,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageSubtitlesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => ManageSubtitlesSheet(audioItem: audioItem),
    );
  }
}

/// 底部固定按钮 — 根据进度显示不同形态：
///
/// - 未开始：单按钮「开始学习」（[onPressed] 为 null 时禁用）。
/// - 进行中（未暂停）：Row[Expanded 1:暂停学习 | Expanded 2:继续学习]，比例 1:2。
/// - 进行中（已暂停）：单按钮「恢复学习」，点击直接恢复（不弹窗），随后 UI 自动
///   回到 Row 形态。
/// - 已学完：单按钮「重置学习进度」，点击弹窗确认后清除全部进度。
class _BottomButton extends ConsumerWidget {
  final AppLocalizations l10n;
  final LearningProgress? progress;
  final String audioItemId;
  final String audioItemName;
  final VoidCallback? onPressed;
  final GuideStep? startLearningStep;
  final GuideStep? pauseLearningStep;

  const _BottomButton({
    required this.l10n,
    required this.audioItemId,
    required this.audioItemName,
    this.progress,
    required this.onPressed,
    this.startLearningStep,
    this.pauseLearningStep,
  });

  Future<void> _confirmAndPause(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pauseLearningConfirmTitle),
        content: Text(l10n.pauseLearningConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.pauseLearning),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(learningProgressProvider.notifier)
          .pauseProgress(audioItemId);
    }
  }

  Future<void> _resume(WidgetRef ref) {
    return ref
        .read(learningProgressProvider.notifier)
        .resumeProgress(audioItemId);
  }

  /// 已学完状态：重置学习进度（与音频列表菜单的「重置学习进度」逻辑一致）
  Future<void> _confirmAndReset(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetLearningProgressConfirmTitle),
        content: Text(l10n.resetLearningProgressConfirmMessage(audioItemName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref
          .read(learningProgressProvider.notifier)
          .resetProgress(audioItemId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resetLearningProgressDone)));
      }
    }
  }

  Widget _wrap(BuildContext context, Widget body) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.m),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(top: false, child: body),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasProgress = progress?.isStarted ?? false;
    final isPaused = progress?.isPaused ?? false;
    final isCompleted = progress?.isCompleted ?? false;

    // 已学完：只显示「重置学习进度」按钮，不再提供暂停/继续。
    if (isCompleted) {
      final theme = Theme.of(context);
      return _wrap(
        context,
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: () => _confirmAndReset(context, ref),
            icon: Icon(Icons.restart_alt, color: theme.colorScheme.error),
            label: Text(
              l10n.resetLearningProgress,
              style: TextStyle(color: theme.colorScheme.error),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ),
      );
    }

    // 暂停态：单按钮，文案合并「已暂停 · 恢复学习」，点击直接恢复。
    // 用 tonal 灰底突出当前是暂停态，与正常态的主色「继续学习」区分。
    if (hasProgress && isPaused) {
      final theme = Theme.of(context);
      return _wrap(
        context,
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: () => _resume(ref),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurfaceVariant,
            ),
            child: Text(
              '${l10n.pausedChipLabel} · ${l10n.resumeLearning}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }

    // 进行中（未暂停）：Row[暂停 | 继续] 1:2
    if (hasProgress) {
      final continueButton = FilledButton(
        onPressed: onPressed,
        child: Text(l10n.continueLearning),
      );
      final guidedContinue = startLearningStep != null
          ? GuideTarget(step: startLearningStep!, child: continueButton)
          : continueButton;
      final pauseButton = FilledButton.tonal(
        onPressed: () => _confirmAndPause(context, ref),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        child: Text(
          l10n.pauseLearning,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
      final guidedPause = pauseLearningStep != null
          ? GuideTarget(step: pauseLearningStep!, child: pauseButton)
          : pauseButton;
      return _wrap(
        context,
        Row(
          children: [
            Expanded(flex: 3, child: guidedPause),
            const SizedBox(width: AppSpacing.m),
            Expanded(flex: 5, child: guidedContinue),
          ],
        ),
      );
    }

    // 未开始：单按钮「开始学习」
    final startButton = FilledButton(
      onPressed: onPressed,
      child: Text(l10n.startLearning),
    );
    final guidedStart = startLearningStep != null
        ? GuideTarget(step: startLearningStep!, child: startButton)
        : startButton;
    return _wrap(context, SizedBox(width: double.infinity, child: guidedStart));
  }
}

/// 学习计划页子步骤显示顺序：当前 plan 顺序在前，历史外延项在后。
///
/// - [plan]：按 audio 版本派生的 plan（v1/v2）
/// - [stage]：当前渲染的大阶段
/// - [completedKeys]：该 audio 的 stage_completions 集合
/// - [skippedKeys]：该 audio 的用户跳过集合
///
/// 历史外延项 = `stage.allSubStages` ∖ plan，且属于 completed 或 skipped。
/// 用于保留 v1 已完成但 v2 已移除项（如 review28 v1→v2 中的 reviewRetellSummary）
/// 的 ✅ 历史显示。当用户走 v1 plan（该 stage 有 completion）时，
/// extras 通常为空（plan 已含历史项）。
List<SubStageType> _orderedSubStagesForDisplay({
  required LearningPlan plan,
  required LearningStage stage,
  required Set<String> completedKeys,
  required Set<String> skippedKeys,
}) {
  final planned = plan.subStagesFor(stage);
  final extras = stage.allSubStages
      .where((s) {
        if (planned.contains(s)) return false;
        final key = '${stage.key}:${s.key}';
        return completedKeys.contains(key) || skippedKeys.contains(key);
      })
      .toList(growable: false);
  return [...planned, ...extras];
}
