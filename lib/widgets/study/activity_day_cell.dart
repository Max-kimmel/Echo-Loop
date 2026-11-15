import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/monthly_study_records_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/learning_progress_colors.dart';

/// 活动日历的自定义日期单元格
///
/// 本月日期统一黑色、统一字重，仅通过圆形背景色深浅区分学习强度。
/// 非本月日期显示为浅灰色。今天额外加红色圆环标识。
///
/// 背景色使用 GitHub 风格纯正绿，12 档固定阈值（分钟）：
/// 0–5–10–20–35–55–80–110–145–185–230–280+
/// 颜色越深表示学习时长越长，level ≥ 7 时文字改白色。
class ActivityDayCell extends StatelessWidget {
  /// 当前日期
  final DateTime day;

  /// 当天学习数据（可为 null 表示无活动）
  final MonthDayRecord? record;

  /// 是否为今天
  final bool isToday;

  /// 是否被选中
  final bool isSelected;

  /// 是否属于当前月份
  final bool isOutside;

  const ActivityDayCell({
    super.key,
    required this.day,
    this.record,
    this.isToday = false,
    this.isSelected = false,
    this.isOutside = false,
  });

  /// 12 档分钟阈值（递增），超过最后一档按最深色处理
  static const _thresholds = [5, 10, 20, 35, 55, 80, 110, 145, 185, 230, 280];

  /// 按固定阈值将学习时长（秒）映射到 1–12 档
  ///
  /// 阈值（分钟）：5–10–20–35–55–80–110–145–185–230–280
  /// 直接归类，无需 log 或归一化。
  static int _toLevel(int seconds) {
    final minutes = seconds ~/ 60;
    if (minutes <= 0) return 0;
    for (int i = 0; i < _thresholds.length; i++) {
      if (minutes <= _thresholds[i]) return i + 1;
    }
    return 12;
  }

  /// 根据学习时长返回圆形背景色
  static Color intensityColor(int seconds, Brightness brightness) =>
      ActivityHeatmapColors.colorForLevel(_toLevel(seconds), brightness);

  /// level >= 7 时背景较深，文字需要用白色保证可读性
  static bool _needsLightText(int seconds) => _toLevel(seconds) >= 7;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    // 非本月日期：浅灰色，无背景
    if (isOutside) {
      return Center(
        child: Text(
          '${day.day}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 14,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
          ),
        ),
      );
    }

    final hasActivity = record?.hasActivity ?? false;
    final seconds = record?.studyTimeSeconds ?? 0;
    final semanticLabel = _buildSemanticLabel(l10n, hasActivity);

    // 圆形背景色：有活动按强度着色，无活动透明
    final bgColor = hasActivity
        ? intensityColor(seconds, theme.brightness)
        : Colors.transparent;

    // 深色背景用白色文字，其余用黑色
    final textColor = (hasActivity && _needsLightText(seconds))
        ? Colors.white
        : theme.colorScheme.onSurface;

    final isCheckedIn = record?.isCheckedIn ?? false;

    return Semantics(
      label: semanticLabel,
      selected: isSelected,
      child: Center(
        child: SizedBox(
          width: 36,
          height: 36,
          // 角标允许超出圆形边界，因此不能裁剪。
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(
                          color: ActivityHeatmapColors.todayBorderColor,
                          width: 1.5,
                        )
                      : isSelected
                      ? Border.all(
                          color: ActivityHeatmapColors.selectedBorderColor,
                          width: 1.5,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${day.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              if (isCheckedIn)
                const Positioned(
                  right: -2,
                  bottom: -2,
                  child: DailyGoalCheckInBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建无障碍标签
  String _buildSemanticLabel(AppLocalizations l10n, bool hasActivity) {
    final isZh = l10n.localeName == 'zh';
    final dateStr = isZh
        ? '${day.month}月${day.day}日'
        : '${_monthShort(day.month)} ${day.day}';
    if (!hasActivity) {
      return '$dateStr, ${isZh ? "无学习记录" : "no activity"}';
    }
    final minutes = (record!.studyTimeSeconds / 60).ceil();
    final activityLabel = isZh ? "学习$minutes分钟" : "studied $minutes minutes";
    final checkInLabel = record!.isCheckedIn
        ? l10n.activityDayCheckedInSemantics
        : '';
    return '$dateStr, $activityLabel$checkInLabel';
  }

  String _monthShort(int m) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][m - 1];
}

/// 已完成每日学习目标的角标：绿色小对勾。
///
/// 外圈用页面底色描边，叠在深绿格子或绿色图例上都能看清。
/// 日历格子与图例共用，保证视觉一致。
class DailyGoalCheckInBadge extends StatelessWidget {
  const DailyGoalCheckInBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: AppTheme.successColor,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.surface, width: 1.5),
      ),
      child: const Icon(Icons.check, size: 9, color: Colors.white),
    );
  }
}
