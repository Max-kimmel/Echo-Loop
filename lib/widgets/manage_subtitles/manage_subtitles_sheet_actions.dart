part of '../manage_subtitles_sheet.dart';

extension _ManageSubtitlesSheetActions on _ManageSubtitlesSheetState {
  /// 处理操作按钮点击
  Future<void> _handleAction(BuildContext context, AudioItem audioItem) async {
    switch (_selectedAction) {
      case _SubtitleAction.podcastDownload:
        await _handlePodcastDownload(context, audioItem);
      case _SubtitleAction.localUpload:
        await _handleLocalUpload(context, audioItem);
      case _SubtitleAction.aiTranscription:
        await _handleAiTranscription(context, audioItem);
      case _SubtitleAction.offlineTranscription:
        await _handleOfflineTranscription(context, audioItem);
    }
  }

  /// 处理本地（离线）转录：确认覆盖/异常音频 → 门控下载模型 → 启动后台任务。
  ///
  /// 无需登录、无云端大小/时长限制。
  Future<void> _handleOfflineTranscription(
    BuildContext context,
    AudioItem audioItem,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // 内容异常确认（与 AI 转录一致，用确认而非硬拦截）。
    if (audioItem.contentStatus case final status?
        when status != AudioContentStatus.ok) {
      final proceed = await _showContentStatusConfirmDialog(
        context,
        audioItem,
        status,
      );
      if (!proceed || !context.mounted) return;
    }

    // 已有字幕时弹出覆盖确认。
    if (audioItem.hasTranscript) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.overwriteExistingSubtitle),
          content: Text(l10n.overwriteExistingSubtitleMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.overwrite),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }

    // 门控：确保所选档位模型已下载（无视评分后端，不改评分设置）。
    final model = ref.read(localTranscriptionModelProvider);
    final ready = await ensureAsrModelReadyForTranscription(
      context,
      ref,
      model: model,
    );
    if (!ready || !context.mounted) return;

    // 启动后台本地转录任务。
    ref
        .read(localTranscriptionTaskManagerProvider.notifier)
        .startLocalTranscription(
          audioItem,
          model: model,
          autoMergeShortSentences: _autoMergeShortSentences,
        );
  }

  /// 下载播客 RSS 提供的字幕，并以本地字幕主干入库。
  ///
  /// 已有字幕时先弹覆盖确认。任何失败（网络、非 2xx、空字幕、解析错误）都以内联错误
  /// 提示，且不写入数据库，原有字幕保持不变。
  Future<void> _handlePodcastDownload(
    BuildContext context,
    AudioItem audioItem,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final url = audioItem.podcastTranscriptUrl;
    final format = audioItem.podcastTranscriptFormat;
    if (url == null || format == null || _isDownloadingSubtitle) return;

    if (audioItem.hasTranscript) {
      final confirmed = await _confirmOverwriteSubtitle(context);
      if (!confirmed || !mounted) return;
    }

    // 播客字幕质量参差不齐：首次下载前提醒一次，之后不再打扰。
    if (!ref.read(learningSettingsProvider).podcastTranscriptReminderShown) {
      if (!context.mounted) return;
      await showPodcastTranscriptReminderDialog(context);
      if (!mounted) return;
      await ref
          .read(learningSettingsProvider.notifier)
          .markPodcastTranscriptReminderShown();
      if (!mounted) return;
    }

    _updateSheetState(() {
      _isDownloadingSubtitle = true;
      _error = null;
    });
    try {
      AppLogger.log(
        'SubtitleDownload',
        'start audioId=${audioItem.id} format=$format',
      );
      final text = await ref
          .read(podcastTranscriptDownloaderProvider)
          .download(url, format: format);
      if (!mounted) return;
      // 解析后无句子视为空字幕，不入库。
      final sentences = await parseSupportedSubtitle(text, ext: format);
      if (!mounted) return;
      if (sentences.isEmpty) {
        throw const SubtitleParseException(SubtitleParseErrorKind.empty);
      }
      await importLocalSubtitle(ref, audioItem, text: text, ext: format);
      ref.invalidate(audioSentencesProvider(audioItem.id));
      AppLogger.log(
        'SubtitleDownload',
        'saved audioId=${audioItem.id} sentences=${sentences.length}',
      );
      if (context.mounted) Navigator.pop(context);
    } on SubtitleParseException catch (e) {
      AppLogger.log(
        'SubtitleDownload',
        'parse failed audioId=${audioItem.id} kind=${e.kind} detail=${e.detail}',
      );
      if (!mounted) return;
      _showInlineError(_inlineErrorFromParseException(l10n, e));
    } catch (e, st) {
      AppLogger.log(
        'SubtitleDownload',
        'failed audioId=${audioItem.id} errorType=${e.runtimeType} error=$e',
      );
      AppLogger.log('SubtitleDownload', st.toString());
      if (!mounted) return;
      _showInlineError(
        _InlineError(
          _UploadErrorKind.generic,
          '${l10n.downloadSubtitleFailed}: $e',
        ),
      );
    } finally {
      if (mounted) _updateSheetState(() => _isDownloadingSubtitle = false);
    }
  }

  /// 把字幕解析异常映射为内联错误（种类决定图标，文案由 l10n 生成）。
  _InlineError _inlineErrorFromParseException(
    AppLocalizations l10n,
    SubtitleParseException e,
  ) {
    final kind = switch (e.kind) {
      SubtitleParseErrorKind.unsupportedFormat =>
        _UploadErrorKind.unsupportedFormat,
      SubtitleParseErrorKind.formatInvalid => _UploadErrorKind.formatInvalid,
      SubtitleParseErrorKind.empty => _UploadErrorKind.empty,
    };
    return _InlineError(kind, subtitleParseErrorMessage(l10n, e));
  }

  /// 已有字幕时的覆盖确认，返回用户是否确认覆盖。
  Future<bool> _confirmOverwriteSubtitle(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.overwriteExistingSubtitle),
        content: Text(l10n.overwriteExistingSubtitleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.overwrite),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  /// 处理本地上传
  Future<void> _handleLocalUpload(
    BuildContext context,
    AudioItem audioItem,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    // 已有字幕时弹出覆盖确认
    if (audioItem.hasTranscript) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: this.context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.overwriteExistingSubtitle),
          content: Text(l10n.overwriteExistingSubtitleMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.overwrite),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) return;
    }

    try {
      AppLogger.log(
        'SubtitleUpload',
        'start local upload audioId=${audioItem.id} name=${audioItem.name}',
      );
      final contentPicker =
          widget.transcriptContentPicker ?? pickTranscriptContentWithMetadata;
      final transcript = await contentPicker();
      if (transcript == null) {
        AppLogger.log(
          'SubtitleUpload',
          'canceled local upload audioId=${audioItem.id}',
        );
        return;
      }
      AppLogger.log(
        'SubtitleUpload',
        'picked transcript audioId=${audioItem.id} '
            'charset=${transcript.charset} ext=${transcript.ext} '
            'chars=${transcript.text.length}',
      );

      // 按音频时长把字幕（srt/vtt/lrc）规范化为 SRT 并原子入库
      // （含统计与近似词级时间戳、来源标记）。
      await importLocalSubtitle(
        ref,
        audioItem,
        text: transcript.text,
        ext: transcript.ext,
      );
      AppLogger.log(
        'SubtitleUpload',
        'saved & updated transcript audioId=${audioItem.id}',
      );

      if (!context.mounted) return;

      ref
          .read(usageTrackerProvider)
          .record(
            UsageEvent.subtitleUploaded,
            analyticsParams: {
              EventParams.audioId: audioItem.id,
              EventParams.audioName: audioItem.name,
            },
          );
      AppLogger.log(
        'SubtitleUpload',
        'completed local upload audioId=${audioItem.id}',
      );
      if (context.mounted) Navigator.pop(context);
    } on SubtitleParseException catch (e) {
      AppLogger.log(
        'SubtitleUpload',
        'parse failed audioId=${audioItem.id} kind=${e.kind} detail=${e.detail}',
      );
      if (!mounted) return;
      _showInlineError(_inlineErrorFromParseException(l10n, e));
    } catch (e, st) {
      AppLogger.log(
        'SubtitleUpload',
        'failed local upload audioId=${audioItem.id} '
            'errorType=${e.runtimeType} error=$e',
      );
      AppLogger.log('SubtitleUpload', st.toString());
      if (!mounted) return;
      _showInlineError(
        _InlineError(
          _UploadErrorKind.generic,
          '${l10n.pickTranscriptFileFailed}: $e',
        ),
      );
    }
  }

  /// 处理 AI 转录
  Future<void> _handleAiTranscription(
    BuildContext context,
    AudioItem audioItem,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final accessToken = (await ref.read(supabaseSessionProvider.future))
        ?.accessToken;
    if (!mounted || !context.mounted) return;
    if (accessToken == null || accessToken.isEmpty) {
      await _showTranscriptionSignInDialog(context);
      return;
    }
    // 已登录但未解锁（非会员且 AI 转录试用用尽）→ 先明确提示额度。
    if (!ref.read(featureAccessProvider(PremiumFeature.aiTranscription))) {
      await _showAiTranscriptionQuotaDialog();
      return;
    }

    final limits = ref.read(remoteTranscriptionLimitsProvider);

    // 检查时长限制
    if (audioItem.totalDuration > limits.maxDurationSeconds) {
      _showInlineError(
        _InlineError(
          _UploadErrorKind.generic,
          l10n.transcriptionErrorTooLong(limits.maxDurationMinutesForDisplay),
        ),
      );
      return;
    }

    // 读取文件只确认路径可用；体积判断由任务层处理，超过 25MiB 时会先压缩。
    final fullPath = await audioItem.getFullAudioPath();
    if (fullPath == null) {
      if (!mounted) return;
      _showInlineError(
        _InlineError(_UploadErrorKind.generic, l10n.audioFileNotFound),
      );
      return;
    }
    // 内容异常（损坏 / 静音）确认：用确认而非硬拦截，给用户保留继续转录入口。
    if (audioItem.contentStatus case final status?
        when status != AudioContentStatus.ok) {
      if (!context.mounted) return;
      final proceed = await _showContentStatusConfirmDialog(
        context,
        audioItem,
        status,
      );
      if (!proceed) return;
    }

    // 已有字幕时弹出覆盖确认
    if (audioItem.hasTranscript) {
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.overwriteExistingSubtitle),
          content: Text(l10n.overwriteExistingSubtitleMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.overwrite),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    // 消耗一次免费试用（会员无限不计数）。转录为后台任务，于发起时计数。
    if (!ref.read(subscriptionControllerProvider).isActive) {
      ref
          .read(aiTrialUsageProvider.notifier)
          .consume(PremiumFeature.aiTranscription);
    }

    // 启动后台转录任务
    ref
        .read(transcriptionTaskManagerProvider.notifier)
        .startTranscription(
          audioItem,
          _selectedLanguage,
          accessToken: accessToken,
          autoMergeShortSentences: _autoMergeShortSentences,
        );
    ref
        .read(usageTrackerProvider)
        .record(
          UsageEvent.aiTranscriptionStarted,
          analyticsParams: {
            EventParams.audioId: audioItem.id,
            EventParams.audioName: audioItem.name,
          },
        );
  }

  /// AI 转录额度用尽提示；同一时间只允许一个弹窗存在。
  Future<void> _showAiTranscriptionQuotaDialog({
    AiQuotaRejectionReason reason = AiQuotaRejectionReason.exhausted,
  }) async {
    if (_isShowingAiQuotaDialog || !mounted) return;
    _isShowingAiQuotaDialog = true;
    try {
      await showAiQuotaExceededDialog(
        context: context,
        ref: ref,
        feature: PremiumFeature.aiTranscription,
        reason: reason,
      );
    } finally {
      _isShowingAiQuotaDialog = false;
    }
  }

  Future<bool> _showContentStatusConfirmDialog(
    BuildContext context,
    AudioItem audioItem,
    AudioContentStatus status,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final info = await _loadAudioDiagnosticInfo(audioItem);
    if (!context.mounted) return false;
    final title = switch (status) {
      AudioContentStatus.damaged => l10n.transcriptionDamagedConfirmTitle,
      AudioContentStatus.silent => l10n.transcriptionSilentConfirmTitle,
      AudioContentStatus.ok => l10n.transcriptionSilentConfirmTitle,
    };
    final message = switch (status) {
      AudioContentStatus.damaged => l10n.transcriptionDamagedConfirmMessage,
      AudioContentStatus.silent => l10n.transcriptionSilentConfirmMessage,
      AudioContentStatus.ok => l10n.transcriptionSilentConfirmMessage,
    };

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            Text(l10n.transcriptionAudioFileSize(info.fileSizeText)),
            Text(l10n.transcriptionAudioDuration(info.durationText)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.transcriptionSilentConfirmProceed),
          ),
        ],
      ),
    );
    return proceed == true;
  }

  Future<_AudioDiagnosticInfo> _loadAudioDiagnosticInfo(
    AudioItem audioItem,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final fullPath = await audioItem.getFullAudioPath();
    final fileSizeText = fullPath == null
        ? l10n.transcriptionAudioUnknown
        : await _formatExistingFileSize(fullPath, l10n);
    final durationSeconds = audioItem.totalDuration > 0
        ? audioItem.totalDuration
        : audioItem.audioPath == null
        ? 0
        : await getMediaDurationSeconds(audioItem.audioPath!);
    final durationText = durationSeconds > 0
        ? SubtitleParser.formatDuration(Duration(seconds: durationSeconds))
        : l10n.transcriptionAudioUnknown;
    return _AudioDiagnosticInfo(
      fileSizeText: fileSizeText,
      durationText: durationText,
    );
  }

  Future<String> _formatExistingFileSize(
    String fullPath,
    AppLocalizations l10n,
  ) async {
    try {
      final file = File(fullPath);
      if (!await file.exists()) return l10n.transcriptionAudioUnknown;
      return formatBytes(await file.length());
    } catch (_) {
      return l10n.transcriptionAudioUnknown;
    }
  }

  /// 展示 AI 转录登录引导弹窗。
  ///
  /// AI 转录会上传音频并访问云端转录服务，因此只允许登录用户发起；
  /// 本地上传字幕和已有本地字幕不受影响。
  Future<void> _showTranscriptionSignInDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await ensureSignedInForAction(
      context: context,
      ref: ref,
      title:
          l10n?.transcriptionSignInRequiredTitle ??
          'Sign in to use AI transcription',
      message: l10n?.transcriptionSignInRequiredMessage ?? 'AI transcription uses the cloud transcription service. Sign in to transcribe audio with AI.',
    );
  }

  /// 处理删除字幕
  Future<void> _handleDeleteSubtitle(
    BuildContext context,
    AudioItem audioItem,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(ctx).colorScheme.error,
        ),
        title: Text(l10n.deleteSubtitleConfirm),
        content: Text(l10n.deleteSubtitleWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // 1. 删除本地字幕文件
    if (audioItem.transcriptPath != null) {
      try {
        final fullPath = await audioItem.getFullTranscriptPath();
        if (fullPath != null) {
          final file = File(fullPath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      } catch (_) {
        // 文件不存在不报错
      }
    }

    // 注意：不删除后端转录记录。
    // userAudios 表按 SHA256 去重，多个用户共享同一条记录，
    // 删除后端 transcript 会影响所有共用同一音频的用户。
    // 用户重新转录时，后端 upsert 会覆盖旧记录，无需手动删除。

    // 3. 清除字幕内容列与词级时间戳
    final audioDao = ref.read(audioItemDaoProvider);
    await audioDao.updateTranscriptSrt(audioItem.id, null);
    await audioDao.updateWordTimestamps(audioItem.id, null);
    // 字幕已变更（清空）→ 失效共享字幕投影，令其按新真相源（空）重解析。
    // autoDispose 通常已在离开本页时释放该 provider，此处为显式兜底保证同步。
    ref.invalidate(audioSentencesProvider(audioItem.id));

    // 4. 更新本地数据库：清除字幕相关字段
    ref
        .read(audioLibraryProvider.notifier)
        .updateAudioItem(
          audioItem.copyWith(
            transcriptPath: null,
            transcriptSource: null,
            transcriptLanguage: null,
            sentenceCount: 0,
            wordCount: 0,
          ),
        );

    // 5. 删除该音频的所有收藏句子
    await ref
        .read(favoriteSentenceLifecycleProvider)
        .removeAllForAudio(audioItem.id);

    // 6. 重置该音频的学习进度
    // 学习进度基于句子索引/段落索引，字幕删除后这些索引失去参照；
    // 若不重置，重新导入字幕时旧断点会指向错位的句子。
    await ref
        .read(learningProgressProvider.notifier)
        .resetProgress(audioItem.id);

    // 7. 清除 listeningPracticeProvider 中缓存的句子数据
    // 字幕内容入库后 transcriptPath 恒为 null，loadAudio 去重守卫（比较 id +
    // transcriptPath）无法察觉变化，必须强制重载才能让 keepAlive 的 LP 丢弃旧句子。
    final practiceState = ref.read(listeningPracticeProvider);
    if (practiceState.currentAudioItem?.id == audioItem.id) {
      ref
          .read(listeningPracticeProvider.notifier)
          .loadAudio(
            audioItem.copyWith(
              transcriptPath: null,
              transcriptSource: null,
              transcriptLanguage: null,
              sentenceCount: 0,
              wordCount: 0,
            ),
            forceTranscriptReload: true,
          );
    }
  }
}

/// 模型档位下载状态 badge：已就绪（primaryContainer）/ 需下载（surfaceVariant）。
class _ModelStatusBadge extends StatelessWidget {
  const _ModelStatusBadge({
    required this.label,
    required this.ready,
    required this.theme,
  });

  /// badge 文案（就绪 · 150 MB / 需下载 · 150 MB）。
  final String label;

  /// 是否已就绪（决定配色）。
  final bool ready;

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    final bg = ready
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final fg = ready
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
