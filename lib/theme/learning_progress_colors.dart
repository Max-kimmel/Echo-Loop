import 'package:flutter/material.dart';

/// 学习进度配色（日间 / 夜间各一组）
///
/// active：进行中；completed：已完成；track：进度条底轨。
class LearningProgressColors {
  // 日间模式
  static const lightActive = Color(0xFF3B75C4);
  static const lightCompleted = Color(0xFF24A58B);
  static const lightTrack = Color(0xFFE5E8EE);

  // 夜间模式
  static const darkActive = Color(0xFF6A9FE6);
  static const darkCompleted = Color(0xFF45C6A8);
  static const darkTrack = Color(0xFF394252);
}

/// 按明暗主题取学习进度配色（学习页与学习日历的今日目标共用）
({Color active, Color completed, Color track}) learningProgressPalette(
  Brightness brightness,
) {
  return brightness == Brightness.dark
      ? (
          active: LearningProgressColors.darkActive,
          completed: LearningProgressColors.darkCompleted,
          track: LearningProgressColors.darkTrack,
        )
      : (
          active: LearningProgressColors.lightActive,
          completed: LearningProgressColors.lightCompleted,
          track: LearningProgressColors.lightTrack,
        );
}

/// 活动日历 12 级学习强度热力图色阶（浅色 / 深色双套）。
///
/// 12 档分钟阈值：0–5–10–20–35–55–80–110–145–185–230–280+。
/// 由浅到深表达当日投入时长；level ≥ 7 时单元格文字改用白色以维持对比度。
class ActivityHeatmapColors {
  ActivityHeatmapColors._();

  /// 当日圆环标识色
  static const Color todayBorderColor = Colors.red;

  /// 选中日期圆环标识色
  static const Color selectedBorderColor = Colors.orange;

  /// 12 级绿色（亮色主题），从极浅到极深
  static const List<Color> lightScale = [
    Color(0xFFE8F5E9), // level 1  ≤5min
    Color(0xFFD7F5DD), // level 2  ≤10min
    Color(0xFFC0EDCA), // level 3  ≤20min
    Color(0xFF9BE9A8), // level 4  ≤35min
    Color(0xFF6DDC80), // level 5  ≤55min
    Color(0xFF4FCC6A), // level 6  ≤80min
    Color(0xFF40C463), // level 7  ≤110min
    Color(0xFF30A14E), // level 8  ≤145min
    Color(0xFF278C41), // level 9  ≤185min
    Color(0xFF216E39), // level 10 ≤230min
    Color(0xFF1A5E30), // level 11 ≤280min
    Color(0xFF155C2B), // level 12 >280min
  ];

  /// 12 级绿色（暗色主题）
  static const List<Color> darkScale = [
    Color(0xFF071E0B), // level 1
    Color(0xFF0A3018), // level 2
    Color(0xFF0C3A1E), // level 3
    Color(0xFF0E4429), // level 4
    Color(0xFF065525), // level 5
    Color(0xFF006D32), // level 6
    Color(0xFF0E8A3E), // level 7
    Color(0xFF26A641), // level 8
    Color(0xFF2DBF4E), // level 9
    Color(0xFF39D353), // level 10
    Color(0xFF48DA62), // level 11
    Color(0xFF56E067), // level 12
  ];

  /// 根据档位（1..12）与当前明暗主题返回单元格填充色；0 档返回透明。
  static Color colorForLevel(int level, Brightness brightness) {
    if (level <= 0) return Colors.transparent;
    final clampedIndex = (level - 1).clamp(0, lightScale.length - 1);
    final colors = brightness == Brightness.dark ? darkScale : lightScale;
    return colors[clampedIndex];
  }
}
