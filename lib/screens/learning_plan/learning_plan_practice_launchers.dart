part of '../learning_plan_screen.dart';

/// 学习计划复习轮次标题左侧图标。
///
/// 使用固定 SVG，避免 `🔁` emoji 在不同平台被系统字体渲染成不一致的蓝色方块。
const String _refreshIconAsset = 'assets/icon/refresh.svg';
const _durationDebugLogTag = 'MediaDuration';

/// 统一打开音频或视频盲听任务，避免首次学习与复习入口各自维护媒体分流。
///
/// 自由练习的补做目标只在媒体加载成功后写入，加载失败和取消不会提前改变学习进度语义。
Future<void> _openBlindListenPractice({
  required BuildContext context,
  required WidgetRef ref,
  required AudioItem audioItem,
  required String? collectionId,
  required List<List<Sentence>> paragraphs,
  required BlindListenSettings settings,
  required LearningStage stage,
  required String loadKey,
  bool isFreePlay = false,
  LearningStage? catchUpStage,
  SubStageType? catchUpSubStage,
}) async {
  final session = ref.read(learningSessionProvider.notifier);
  final route = AppRoutes.blindListenPlayer(collectionId, audioItem.id);
  if (!context.mounted) return;
  context.push(
    route,
    extra: MediaLearningStartup(
      loadKey: loadKey,
      showVideoLoading: audioItem.isVideo,
      load: () async {
        final result = await session.enterBlindListenMode(
          audioItem,
          paragraphs: paragraphs,
          settings: settings,
          stage: stage,
          isFreePlay: isFreePlay,
        );
        if (result == MediaLoadResult.ready &&
            catchUpStage != null &&
            catchUpSubStage != null) {
          session.setCatchUp(catchUpStage, catchUpSubStage);
        }
        return result;
      },
      cancel: session.cancelBlindListenEntry,
    ),
  );
}

/// 通过统一媒体启动链路打开音频或视频复述任务。
Future<void> _openRetellPractice({
  required BuildContext context,
  required WidgetRef ref,
  required AudioItem audioItem,
  required String? collectionId,
  required List<List<Sentence>> paragraphs,
  required String loadKey,
  bool isFreePlay = false,
  LearningStage? catchUpStage,
  SubStageType? catchUpSubStage,
}) async {
  final session = ref.read(learningSessionProvider.notifier);
  if (!context.mounted) return;
  await _pushPracticeAndWaitForTransition(
    context,
    AppRoutes.retellPlayer(collectionId, audioItem.id),
    ref: ref,
    event: RatingPromptEvent.retellCompleted,
    extra: MediaLearningStartup(
      loadKey: loadKey,
      showVideoLoading: audioItem.isVideo,
      load: () => session.enterRetellMode(
        audioItem,
        paragraphs,
        isFreePlay: isFreePlay,
        catchUpStage: catchUpStage,
        catchUpSubStage: catchUpSubStage,
      ),
      cancel: session.cancelRetellEntry,
    ),
  );
}

/// 推入练习页，等待 root 退场完成后在原计划页仍可见时检查评分资格。
Future<void> _pushPracticeAndWaitForTransition(
  BuildContext context,
  String route, {
  Object? extra,
  required WidgetRef ref,
  required RatingPromptEvent event,
}) async {
  final transition = rootRouteObserver.watchNextPop();
  final presentation = RatingPromptPresentationGuard(
    context: context,
    isRootRouteCurrent: () => transition.returnedToPreviousRoute,
  );
  try {
    final result = await context.push<PracticeCompletionResult>(
      route,
      extra: extra,
    );
    if (result == PracticeCompletionResult.completed) {
      await transition.completed;
      if (!context.mounted) return;
      await _requestRatingAfterPractice(
        ref,
        event,
        canPresent: () => presentation.canPresent,
      );
    }
  } finally {
    transition.cancel();
  }
}

/// 评分邀请失败由独立协调器处理，不改变练习完成后的导航行为。
Future<void> _requestRatingAfterPractice(
  WidgetRef ref,
  RatingPromptEvent event, {
  required bool Function() canPresent,
}) async {
  try {
    await ref
        .read(ratingPromptCoordinatorProvider)
        .maybeRequest(event, canPresent: canPresent);
  } catch (error, stackTrace) {
    AppLogger.log(
      'RatingPrompt',
      'coordinator unavailable error=$error\n$stackTrace',
    );
  }
}

/// 学习计划大阶段完成标记图标。
///
/// 使用固定 SVG，避免 `✅` emoji 在不同平台呈现不一致。
const String _checkCircleIconAsset = 'assets/icon/check-circle-3.svg';

/// 学习计划大阶段当前到期标记图标。
///
/// 使用固定 SVG，避免 `📖` emoji 在不同平台呈现不一致。
const String _calendarIconAsset = 'assets/icon/calendar-2.svg';

/// 学习计划大阶段锁定标记图标。
///
/// 使用固定 SVG，避免 `🔒` emoji 在不同平台呈现不一致。
const String _lockIconAsset = 'assets/icon/lock.svg';

/// 学习计划复习轮次提前解锁按钮图标。
const String _unlockIconAsset = 'assets/icon/unlock.svg';

/// 学习计划首次学习标题左侧图标。
const String _readingIconAsset = 'assets/icon/reading.svg';

/// 学习计划阶段标题行标题列宽。
///
/// 首次学习与各复习轮次共用固定列宽，保证状态图标、状态文案和进度计数
/// 在不同行之间垂直对齐。
const double _stageHeaderTitleColumnWidth = 132;

/// 学习计划阶段标题行中文标题列宽。
const double _stageHeaderZhTitleColumnWidth = 112;

/// 学习计划阶段标题行状态文案列最大宽度。
const double _stageHeaderStatusTextMaxWidth = 180;

/// 学习计划阶段标题行进度计数列宽。
const double _stageHeaderProgressColumnWidth = 48;

/// 实时查询指定音频的书签数量（难句数）
///
/// 使用 StreamProvider 监听 bookmarks 表变化，确保难句数实时更新。
final _bookmarkCountProvider = StreamProvider.family.autoDispose<int, String>((
  ref,
  audioItemId,
) {
  final bookmarkDao = ref.watch(bookmarkDaoProvider);
  return bookmarkDao
      .watchByAudioId(audioItemId)
      .map((bookmarks) => bookmarks.length);
});

/// 查询指定音频各复习大阶段的最终完成时间。
///
/// 学习计划页据此为已完成的大阶段显示“X 天前”一类相对完成时间。
final reviewStageCompletionTimesProvider =
    StreamProvider.family<Map<String, DateTime>, String>((ref, audioItemId) {
      final dao = ref.watch(stageCompletionDaoProvider);
      return dao.watchStageCompletedAtByAudioId(audioItemId);
    });

/// 已完成大阶段标题文案。
///
/// 使用相对时间，但显式带上“完成于 / Completed”前缀，避免误读成逾期时间。
String formatCompletedStageTimeLabel(
  BuildContext context,
  DateTime completedAt,
) {
  final ago = formatTimeAgo(context, completedAt);
  final isZh = Localizations.localeOf(context).languageCode == 'zh';
  return isZh ? '完成于$ago' : 'Completed $ago';
}

/// 逐句精听入口弹窗的「停顿下拉显示值」← 已解析设置。
///
/// 仅作下拉的 UI 显示值,不承担持久化/传输(真相源是 [intensiveListenPrefsProvider])。
BriefingPauseChoice intensivePauseChoiceFromSettings(
  IntensiveListenSettings s,
) => switch (s.pauseMode) {
  PauseMode.smart => const BriefingPauseChoice.smart(),
  PauseMode.fixed => BriefingPauseChoice.fixed(s.fixedPauseSeconds),
  PauseMode.multiplier => BriefingPauseChoice.multiplier(s.pauseMultiplier),
};

/// 生成逐句精听入口弹窗的「改完即记」回调:用户在弹窗改速度/停顿时即时写入
/// [intensiveListenPrefsProvider](与 🔧 面板同一份 store,改完即持久,无需开始练习)。
///
/// 闭包跟踪上次值,仅写**真正变化的那个字段**:既支持来回改,又不会因改一个字段而
/// 把另一个未碰过的字段(智能默认)冻结。两个入口(按计划/自由练习)共用,行为一致。
void Function(double, BriefingPauseChoice) intensivePrefsRecorder(
  IntensiveListenPrefsNotifier notifier,
  String slot,
  IntensiveListenSettings resolved,
) {
  var lastSpeed = resolved.playbackSpeed;
  var lastPause = intensivePauseChoiceFromSettings(resolved);
  return (speed, pause) {
    if (speed != lastSpeed) {
      notifier.setPlaybackSpeed(slot, speed);
      lastSpeed = speed;
    }
    if (pause != lastPause) {
      switch (pause.mode) {
        case PauseMode.smart:
          notifier.setPauseMode(slot, PauseMode.smart);
        case PauseMode.fixed:
          notifier.setPauseMode(slot, PauseMode.fixed);
          notifier.setFixedPauseSeconds(slot, pause.fixedSeconds);
        case PauseMode.multiplier:
          notifier.setPauseMode(slot, PauseMode.multiplier);
          notifier.setPauseMultiplier(slot, pause.multiplier);
      }
      lastPause = pause;
    }
  };
}

/// 盲听入口弹窗的「停顿下拉显示值」← 已解析设置。
BriefingPauseChoice blindPauseChoiceFromSettings(BlindListenSettings s) =>
    switch (s.pauseMode) {
      PauseMode.smart => const BriefingPauseChoice.smart(),
      PauseMode.fixed => BriefingPauseChoice.fixed(s.fixedPauseSeconds),
      PauseMode.multiplier => BriefingPauseChoice.multiplier(s.pauseMultiplier),
    };

/// 难句补练 / 收藏句复习 入口的「停顿下拉显示值」← 已解析设置。
BriefingPauseChoice difficultPauseChoiceFromSettings(
  DifficultPracticeSettings s,
) => switch (s.pauseMode) {
  PauseMode.smart => const BriefingPauseChoice.smart(),
  PauseMode.fixed => BriefingPauseChoice.fixed(s.fixedPauseSeconds),
  PauseMode.multiplier => BriefingPauseChoice.multiplier(s.pauseMultiplier),
};

/// 段落复述 入口的「停顿下拉显示值」← 已解析设置。
BriefingPauseChoice retellPauseChoiceFromSettings(RetellSettings s) =>
    switch (s.pauseMode) {
      PauseMode.smart => const BriefingPauseChoice.smart(),
      PauseMode.fixed => BriefingPauseChoice.fixed(s.fixedPauseSeconds),
      PauseMode.multiplier => BriefingPauseChoice.multiplier(s.pauseMultiplier),
    };

/// 复述段落入口弹窗的预填:从按槽位偏好 resolve 出 速度/停顿/可见词比例/目标段长。
({
  int seconds,
  KeywordRatio ratio,
  double speed,
  BriefingPauseChoice pause,
  RetellSettings settings,
})
retellBriefingDefaults(
  WidgetRef ref,
  String slot, {
  required double smartSpeed,
  required KeywordRatio smartRatio,
  required int smartSeconds,
}) {
  final rp = ref.read(retellPrefsProvider.notifier);
  final settings = rp.resolve(
    slot,
    smartSpeed: smartSpeed,
    smartRatio: smartRatio,
  );
  final rawSeconds = rp.resolveTargetSeconds(slot, smartSeconds: smartSeconds);
  // 目标段长须落在合法档位内,否则下拉 value 不在 items 会断言。
  final seconds = paragraphDurationOptions.contains(rawSeconds)
      ? rawSeconds
      : smartSeconds;
  return (
    seconds: seconds,
    ratio: settings.keywordRatio,
    speed: settings.playbackSpeed,
    pause: retellPauseChoiceFromSettings(settings),
    settings: settings,
  );
}

/// 盲听入口「改完即记」回调:改速度/停顿即时写按槽位偏好(跟踪上次值,仅写变化字段,
/// 支持回退到默认)。供按计划/自由练习各入口共用。
void Function(Duration, BriefingPauseChoice, double) blindPrefsRecorder(
  WidgetRef ref,
  String slot,
  BlindListenSettings defaults,
  int defaultSeconds,
) {
  final n = ref.read(blindListenPrefsProvider.notifier);
  var lastPause = blindPauseChoiceFromSettings(defaults);
  var lastSpeed = defaults.playbackSpeed;
  var lastSeconds = defaultSeconds;
  return (duration, pause, speed) {
    if (speed != lastSpeed) {
      n.setPlaybackSpeed(slot, speed);
      lastSpeed = speed;
    }
    if (pause != lastPause) {
      switch (pause.mode) {
        case PauseMode.smart:
          n.setPauseMode(slot, PauseMode.smart);
        case PauseMode.fixed:
          n.setPauseMode(slot, PauseMode.fixed);
          n.setFixedPauseSeconds(slot, pause.fixedSeconds);
        case PauseMode.multiplier:
          n.setPauseMode(slot, PauseMode.multiplier);
          n.setPauseMultiplier(slot, pause.multiplier);
      }
      lastPause = pause;
    }
    final seconds = duration.inHours >= 24 ? -1 : duration.inSeconds;
    if (seconds != lastSeconds && paragraphDurationOptions.contains(seconds)) {
      n.setTargetSeconds(slot, seconds);
      lastSeconds = seconds;
    }
  };
}

/// 难句补练入口「改完即记」回调(速度/停顿)。
void Function(double, BriefingPauseChoice) difficultPrefsRecorder(
  WidgetRef ref,
  String slot,
  DifficultPracticeSettings defaults,
) {
  final n = ref.read(difficultPracticePrefsProvider.notifier);
  var lastPause = difficultPauseChoiceFromSettings(defaults);
  var lastSpeed = defaults.playbackSpeed;
  return (speed, pause) {
    if (speed != lastSpeed) {
      n.setPlaybackSpeed(slot, speed);
      lastSpeed = speed;
    }
    if (pause != lastPause) {
      switch (pause.mode) {
        case PauseMode.smart:
          n.setPauseMode(slot, PauseMode.smart);
        case PauseMode.fixed:
          n.setPauseMode(slot, PauseMode.fixed);
          n.setFixedPauseSeconds(slot, pause.fixedSeconds);
        case PauseMode.multiplier:
          n.setPauseMode(slot, PauseMode.multiplier);
          n.setPauseMultiplier(slot, pause.multiplier);
      }
      lastPause = pause;
    }
  };
}

/// 全文复述(复习简报)「改完即记」回调(仅速度/停顿)。
void Function(double, BriefingPauseChoice) retellPauseSpeedRecorder(
  WidgetRef ref,
  String slot,
  RetellSettings defaults,
) {
  final n = ref.read(retellPrefsProvider.notifier);
  var lastPause = retellPauseChoiceFromSettings(defaults);
  var lastSpeed = defaults.playbackSpeed;
  return (speed, pause) {
    if (speed != lastSpeed) {
      n.setPlaybackSpeed(slot, speed);
      lastSpeed = speed;
    }
    if (pause != lastPause) {
      switch (pause.mode) {
        case PauseMode.smart:
          n.setPauseMode(slot, PauseMode.smart);
        case PauseMode.fixed:
          n.setPauseMode(slot, PauseMode.fixed);
          n.setFixedPauseSeconds(slot, pause.fixedSeconds);
        case PauseMode.multiplier:
          n.setPauseMode(slot, PauseMode.multiplier);
          n.setPauseMultiplier(slot, pause.multiplier);
      }
      lastPause = pause;
    }
  };
}

/// 复述入口「改完即记」回调(目标段长/停顿/可见词比例/速度)。
void Function(Duration, BriefingPauseChoice, KeywordRatio?, double)
retellPrefsRecorder(WidgetRef ref, String slot, RetellSettings defaults) {
  final n = ref.read(retellPrefsProvider.notifier);
  var lastPause = retellPauseChoiceFromSettings(defaults);
  var lastSpeed = defaults.playbackSpeed;
  var lastRatio = defaults.keywordRatio;
  int? lastSeconds;
  return (duration, pause, ratio, speed) {
    if (speed != lastSpeed) {
      n.setPlaybackSpeed(slot, speed);
      lastSpeed = speed;
    }
    if (pause != lastPause) {
      switch (pause.mode) {
        case PauseMode.smart:
          n.setPauseMode(slot, PauseMode.smart);
        case PauseMode.fixed:
          n.setPauseMode(slot, PauseMode.fixed);
          n.setFixedPauseSeconds(slot, pause.fixedSeconds);
        case PauseMode.multiplier:
          n.setPauseMode(slot, PauseMode.multiplier);
          n.setPauseMultiplier(slot, pause.multiplier);
      }
      lastPause = pause;
    }
    if (ratio != null && ratio != lastRatio) {
      n.setKeywordRatio(slot, ratio);
      lastRatio = ratio;
    }
    final seconds = duration.inHours >= 24 ? -1 : duration.inSeconds;
    if (seconds != lastSeconds && paragraphDurationOptions.contains(seconds)) {
      n.setTargetSeconds(slot, seconds);
      lastSeconds = seconds;
    }
  };
}

