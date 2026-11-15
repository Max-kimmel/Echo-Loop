/// 每日学习目标打卡成功 toast。
library;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_toast.dart';

/// 在根 [overlayState] 上弹出打卡成功提示，3 秒后自动消失，点击可提前关闭。
///
/// 根 overlay 位于根 Navigator 之上，因此即使学习页是全屏页也能看到。
void showDailyGoalCompletedToast({
  required OverlayState overlayState,
  required String message,
  required Brightness brightness,
}) {
  final palette = AppTheme.dailyGoalToastPalette(brightness);
  showAppToast(
    overlayState: overlayState,
    message: message,
    icon: Icons.check_circle_outline,
    background: palette.backgroundColor,
    foreground: palette.foregroundColor,
  );
}
