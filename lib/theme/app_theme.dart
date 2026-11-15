/// 应用主题系统
///
/// 集中定义所有视觉规范：配色方案、组件主题、间距常量、语义色、文字样式辅助。
/// 参考 Learna AI 风格：干净现代 + 彩色点缀，浅灰背景 + 白色卡片浮起。
/// 种子色 `#1976D2`（明亮蓝），专业清爽。
library;

import 'package:flutter/material.dart';

/// 应用主题配置
class AppTheme {
  AppTheme._();

  /// 种子色：明亮蓝
  static const Color seedColor = Color(0xFF1976D2);

  /// 浅灰页面背景色
  static const Color _scaffoldBg = Color(0xFFF5F6FA);

  /// 纯黑色板（深色主题专用，AMOLED 省电 + 沉浸式）
  ///
  /// 分层策略：页面背景纯黑，卡片/AppBar/底栏近黑浮起，浮层逐级提亮，
  /// 既得纯黑效果又保留 M3 elevation 层次，避免大面积纯黑糊成一片。
  static const Color _pureBlack = Color(0xFF000000); // 页面背景
  static const Color _surfaceBlack = Color(0xFF0B0B0B); // 卡片 / AppBar / 底栏
  static const Color _surfaceBorder = Color(0xFF1F1F1F); // 卡片描边
  static const Color _sheetBlack = Color(0xFF1E1E20); // 弹出层（BottomSheet）

  /// 导航栏选中态颜色：明亮蓝
  static const Color navActiveColor = Color(0xFF3AA0FF);

  /// 视频类型图标的紫色强调色；深色主题下提亮，维持可辨识度。
  static Color videoMediaTypeColor(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFFB39DDB)
      : const Color(0xFF7655A6);

  /// 学习页「为你推荐」区段的蓝紫强调色。
  static Color studyRecommendationAccentColor(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFFB39DDB)
      : const Color(0xFF7655A6);

  /// 语义色：书签/收藏/星标
  static const Color bookmarkColor = Colors.amber;
  static const Color bookmarkCountBadgeColor = bookmarkColor;
  static const Color bookmarkCountBadgeTextColor = Color(0xFF3D2E00);
  static const Color bookmarkCountSelectedBadgeColor = Color(0xFF405A7A);
  static const Color bookmarkCountSelectedBadgeTextColor = Colors.white;

  /// 语义色：置顶图钉
  static const Color pinColor = Color(0xFFE53935);

  /// 语义色：收藏词/词组正文标记（点状下划线）
  ///
  /// 沿用「橙色 = 收藏」视觉语言（与意群收藏色系一致），
  /// 深色主题提亮一档保证对比度。
  static Color savedTextMarkColor(Brightness brightness) =>
      brightness == Brightness.dark
      ? Colors.orange.shade300
      : Colors.orange.shade400;

  /// 当前播放词的底色：用明显的绿色区分当前播放位置，同时保持文字易读。
  static Color wordHighlightBackgroundColor(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark
      ? const Color(0xFF245D35)
      : const Color(0xFFBCE7C6);

  /// 语义色：成功/完成（用于完成对话框的勾选徽章，清新绿）
  static const Color successColor = Color(0xFF2E9E5B);

  /// 语义色：女声标签（国际通用粉/玫瑰，浅深色均可读）
  static const Color femaleVoiceColor = Color(0xFFE0709F);

  /// 语义色：男声标签（国际通用蓝，区别于品牌选中蓝，浅深色均可读）
  static const Color maleVoiceColor = Color(0xFF4F8FE0);

  /// 语义色：成功/完成的浅色容器底（完成对话框英雄区色带，浅绿）
  static const Color successContainer = Color(0xFFE3F4E9);

  /// 会员/订阅专用强调色（业界标准做法：品牌色主导 + 少量金色点缀）。
  ///
  /// 经设计评审：大面积金色铺底显廉价发脏。改为「品牌蓝做主色」（CTA、选中态、
  /// 单选钮、勾选图标），金色压缩到「皇冠图标 + 推荐徽标」两处小点缀保留尊贵语义。
  /// 仅用于会员入口卡与 Paywall，不进全局主题。按 [Brightness] 取浅色/深色档值。
  static const Color _premiumAccentLight = Color(0xFF1976D2);
  static const Color _premiumAccentDark = Color(0xFF3AA0FF);
  static const Color _onPremiumAccentLight = Color(0xFFFFFFFF);
  static const Color _onPremiumAccentDark = Color(0xFF06223D);
  static const Color _premiumSelectedFillLight = Color(0xFFEAF3FC);
  static const Color _premiumSelectedFillDark = Color(0xFF0E1B26);
  static const Color _premiumGoldLight = Color(0xFFC8941A);
  static const Color _premiumGoldDark = Color(0xFFE8B84B);

  /// 会员态 hero 卡金色渐变两端（深→浅古铜金），配白字尊贵不发脏。按 [Brightness] 微调。
  static const Color _premiumHeroTopLight = Color(0xFFB8841A);
  static const Color _premiumHeroBottomLight = Color(0xFF8A6218);
  static const Color _premiumHeroTopDark = Color(0xFF8C6A22);
  static const Color _premiumHeroBottomDark = Color(0xFF5E4712);

  /// 状态胶囊色：有效（绿）/ 即将到期（琥珀）。含浅深两档，保证对比度。
  static const Color _premiumStatusActiveLight = Color(0xFF2E7D32);
  static const Color _premiumStatusActiveDark = Color(0xFF66BB6A);
  static const Color _premiumStatusExpiringLight = Color(0xFFB26A00);
  static const Color _premiumStatusExpiringDark = Color(0xFFE0A030);

  /// 「立省」徽标专用深古铜金底（配白字，对比清晰；点缀金太浅时白字/深字都糊）。
  static const Color premiumBadge = Color(0xFF8A6A1F);

  /// 会员强调主色（CTA 填充、选中边框、选中单选钮、勾选图标）。
  static Color premiumAccent(Brightness b) =>
      b == Brightness.dark ? _premiumAccentDark : _premiumAccentLight;

  /// 强调主色填充上的文字色。
  static Color onPremiumAccent(Brightness b) =>
      b == Brightness.dark ? _onPremiumAccentDark : _onPremiumAccentLight;

  /// 选中套餐卡的极淡蓝染底。
  static Color premiumSelectedFill(Brightness b) => b == Brightness.dark
      ? _premiumSelectedFillDark
      : _premiumSelectedFillLight;

  /// 金色点缀（仅皇冠图标 + 推荐徽标填充）。
  static Color premiumGold(Brightness b) =>
      b == Brightness.dark ? _premiumGoldDark : _premiumGoldLight;

  /// 「升级」高亮徽章底色（订阅入口与会员角标共用，保证金色系一致）。
  static Color premiumUpgradeBadgeBackground(Brightness b) =>
      b == Brightness.dark ? const Color(0xFFD8B11E) : const Color(0xFFFCE76B);

  /// 金色徽章上的文字色。
  static const Color onPremiumUpgradeBadge = Color(0xFF111111);

  /// 会员角标（「我的」导航 VIP）的文字色：比 [onPremiumUpgradeBadge] 柔和，小号下不发黑。
  static const Color memberBadgeText = Color(0xFF3D2E00);

  /// 会员态 hero 卡金色渐变（上→下），配白字。
  static List<Color> premiumHeroGradient(Brightness b) => b == Brightness.dark
      ? const [_premiumHeroTopDark, _premiumHeroBottomDark]
      : const [_premiumHeroTopLight, _premiumHeroBottomLight];

  /// 状态色：有效（绿）。
  static Color premiumStatusActiveColor(Brightness b) => b == Brightness.dark
      ? _premiumStatusActiveDark
      : _premiumStatusActiveLight;

  /// 状态色：即将到期（琥珀）。
  static Color premiumStatusExpiringColor(Brightness b) => b == Brightness.dark
      ? _premiumStatusExpiringDark
      : _premiumStatusExpiringLight;

  /// 语义色：本地合集角标（深蓝，配白字）。
  static const Color localCollectionBadgeColor = Color(0xFF1565C0);

  /// 语义色：共享合集角标（绿色，配白字）。
  static const Color communityBadgeColor = successColor;

  /// 语义色：Podcast 合集角标（深紫，配白字）。
  static const Color podcastCollectionBadgeColor = Color(0xFF6A1B9A);

  /// 语义色：复习统计与完成总结（「再来一遍 / 今日到期」陶土橙红）。
  static const Color reviewAgainColor = Color(0xFFC56B45);

  /// 语义色：复习统计与完成总结（「听懂了 / 时长 / 词汇」鼠尾草绿）。
  static const Color reviewGoodColor = Color(0xFF4D9271);

  /// 语义色：复习统计（未来到期柱体灰绿）。
  static const Color reviewUpcomingColor = Color(0xFF597C65);

  /// 语义色：复习统计与完成总结（「轻松听懂 / 记忆保留率」岩蓝）。
  static const Color reviewEasyColor = Color(0xFF2B6C8F);

  /// 语义色：复习统计（连续复习 / 掌握度琥珀金）。
  static const Color reviewMasteryColor = Color(0xFFD88A36);

  /// 语义色：跟读通过状态文字（清新绿）。
  static const Color speechPassedColor = Color(0xFF2E9B51);

  /// 月度统计「总计学习时长」图标与数字色（深色主题提亮以保证 OLED 表面对比度）。
  static Color monthlyStatTotalColor(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFF64B5F6)
      : const Color(0xFF1976D2);

  /// 月度统计「日均学习时长」图标与数字色（深色主题提亮以保证 OLED 表面对比度）。
  static Color monthlyStatAverageColor(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFFCE93D8)
      : const Color(0xFF7B1FA2);

  /// 月度统计「活跃学习天数」图标与数字色（深色主题提亮以保证 OLED 表面对比度）。
  static Color monthlyStatActiveDaysColor(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFF81C784)
      : const Color(0xFF388E3C);

  /// 获取每日目标达成提示胶囊调色板。
  static DailyGoalToastPalette dailyGoalToastPalette(Brightness brightness) =>
      brightness == Brightness.dark
      ? const DailyGoalToastPalette(
          backgroundColor: Color(0xFF1E3A2C),
          foregroundColor: Color(0xFF9FD8B5),
        )
      : const DailyGoalToastPalette(
          backgroundColor: Color(0xFFD3EEDF),
          foregroundColor: Color(0xFF2E7D57),
        );

  /// 获取学习首页「加入社群」与资源库「发现资源」共用的青色渐变横幅调色板。
  static CyanBannerPalette cyanBannerPalette(Brightness brightness) =>
      CyanBannerPalette.resolve(brightness);

  /// 获取「听前预热卡」暖琥珀色调色板。
  static WarmUpCardPalette warmUpCardPalette(
    Brightness brightness,
    ColorScheme colorScheme,
  ) => WarmUpCardPalette.resolve(brightness, colorScheme);

  /// 获取语音跟读评级徽章样式。
  static SpeechRatingBadgeStyle speechRatingBadgeStyle(
    SpeechRatingTier tier,
    Brightness brightness,
  ) => SpeechRatingBadgeStyle.resolve(tier, brightness);

  /// 设置类底部弹窗的分组卡片背景色。
  ///
  /// 浅色比弹层背景略灰（内凹分组，类似 iOS 分组列表）；
  /// 深色保持透明，让设置项融入弹层背景，避免出现突兀的灰色块。
  static Color settingsSectionBackground(Brightness brightness) =>
      brightness == Brightness.dark
      ? Colors.transparent
      : const Color(0xFFF2F3F7);

  /// 设置类底部弹窗中，展开态的可折叠分组标题行背景色。
  ///
  /// 比分组卡片背景更深一档（浅色）/更亮一档（深色），让用户能一眼看出
  /// 当前哪个分组处于展开状态；收起态仍保持透明，融入卡片背景。
  static Color settingsExpandedBackground(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xFF2E2E32)
      : const Color(0xFFE8E9EF);

  /// 亮色主题
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      surface: Colors.white,
      surfaceContainerLowest: _scaffoldBg,
    );
    return _buildTheme(colorScheme, Brightness.light);
  }

  /// 暗色主题（纯黑 / AMOLED）
  ///
  /// 保留 `fromSeed` 派生的完整角色色（primary/secondary/container 等），
  /// 仅用 `copyWith` 把 surface 系列覆盖为分级近黑，确保品牌蓝等不丢失。
  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    final colorScheme = base.copyWith(
      surface: _surfaceBlack,
      surfaceContainerLowest: _pureBlack,
      surfaceContainerLow: _surfaceBlack,
      surfaceContainer: const Color(0xFF101010),
      surfaceContainerHigh: const Color(0xFF161616),
      surfaceContainerHighest: const Color(0xFF1C1C1C),
    );
    return _buildTheme(colorScheme, Brightness.dark);
  }

  /// 根据 ColorScheme 构建完整主题
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isLight ? _scaffoldBg : _pureBlack,

      // 经典 DropdownButton 的下拉菜单背景取自 canvasColor（默认=surface #0B0B0B），
      // 在纯黑/弹出层上几乎不可见。深色抬高到 #1E1E20 让菜单清晰浮起；浅色用默认。
      canvasColor: isLight ? null : _sheetBlack,

      // Card 主题：
      // - 浅色：去边框 + 微弱阴影，白色浮于灰底
      // - 深色（纯黑）：阴影在纯黑上不可见，改用 1px 近黑描边区分卡片边界
      cardTheme: CardThemeData(
        elevation: isLight ? 1 : 0,
        shadowColor: isLight ? Colors.black.withValues(alpha: 0.08) : null,
        color: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isLight
              ? BorderSide.none
              : BorderSide(color: _surfaceBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // 全局禁用 Tooltip（长按提示）
      tooltipTheme: const TooltipThemeData(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        constraints: BoxConstraints(maxHeight: 0, maxWidth: 0),
        textStyle: TextStyle(fontSize: 0),
        decoration: BoxDecoration(color: Colors.transparent),
        waitDuration: Duration(days: 1),
      ),

      // AppBar 主题：与页面背景一致，标题加粗
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        backgroundColor: isLight ? _scaffoldBg : _pureBlack,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),

      // 底部导航栏主题：白色底栏，选中态 #3AA0FF 蓝色图标和标签，无背景指示器
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: isLight ? Colors.white : _pureBlack,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: navActiveColor);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: navActiveColor,
            );
          }
          return TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant);
        }),
      ),

      // 侧边导航栏主题：白色侧栏，选中态 #3AA0FF 蓝色图标和标签，无背景指示器
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: Colors.transparent,
        backgroundColor: isLight ? Colors.white : _pureBlack,
        selectedIconTheme: const IconThemeData(color: navActiveColor),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        selectedLabelTextStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: navActiveColor,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // 输入框主题：圆角 12
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
      ),

      // 对话框主题：圆角 20
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),

      // BottomSheet 主题：
      // 纯黑深色下，sheet 默认背景（surfaceContainerLow #0B0B0B）几乎贴页面纯黑，
      // scrim 又压不暗已全黑的背景，导致弹窗与主界面无边界。
      // 显式抬高弹出层背景到 #1E1E20，让它清晰浮于纯黑之上。浅色保持默认。
      bottomSheetTheme: isLight
          ? null
          : const BottomSheetThemeData(
              backgroundColor: _sheetBlack,
              modalBackgroundColor: _sheetBlack,
            ),

      // 弹出菜单（PopupMenuButton）主题：
      // 统一为更克制的悬浮卡片：圆角更大、描边更弱，主要靠轻阴影和留白建立层级，
      // 避免菜单本身像一块硬边白板。深色仍抬高到 _sheetBlack，浅色保持纯净 surface。
      popupMenuTheme: PopupMenuThemeData(
        color: isLight ? colorScheme.surface : _sheetBlack,
        elevation: isLight ? 10 : 12,
        surfaceTintColor: Colors.transparent,
        shadowColor: isLight
            ? Colors.black.withValues(alpha: 0.09)
            : Colors.black.withValues(alpha: 0.28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.52),
            width: 0.75,
          ),
        ),
        menuPadding: const EdgeInsets.symmetric(vertical: 6),
      ),

      // 列表项主题：圆角 + 宽松间距
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // 图标主题
      iconTheme: IconThemeData(size: 24, color: colorScheme.onSurfaceVariant),

      // TabBar 主题：激活态用浅色背景铺满整个 tab（无圆角、贴底分割线），背景更显眼
      tabBarTheme: TabBarThemeData(
        indicator: BoxDecoration(
          color: colorScheme.secondaryContainer,
          // 激活段的分割线高亮：底部加一条主色边框
          border: Border(
            bottom: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: colorScheme.onSecondaryContainer,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        dividerColor: colorScheme.outlineVariant,
      ),

      // SnackBar 主题：圆角 12
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      // ElevatedButton 主题：圆角 16 + 加粗文字 + 更大 padding
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton 主题：圆角 16
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      // FilledButton 主题：圆角 16 + 加粗文字 + 更大 padding
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton 主题：与 FilledButton 形状对齐（圆角 16），
      // 避免对话框「完成 / 继续」并排时一个胶囊一个圆角矩形造成视觉不一致。
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // 分割线主题
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // Slider 主题:
      // M3 默认的 inactive track 颜色 ≈ surfaceContainerHighest，在纯黑页面/弹出层上
      // 对比度极低，几乎不可见（深色模式下滑块轨道像凭空消失）。
      // 显式用 onSurface 的低透明度做 inactive（浅色=近黑、深色=近白，两种模式对比方向都正确），
      // active/thumb 统一用品牌蓝，确保所有未单独配色的 Slider 在深色下清晰可见。
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.onSurface.withValues(
          alpha: isLight ? 0.18 : 0.34,
        ),
        thumbColor: colorScheme.primary,
        valueIndicatorColor: colorScheme.primary,
        valueIndicatorTextStyle: TextStyle(color: colorScheme.onPrimary),
      ),
    );
  }
}

/// 间距常量
class AppSpacing {
  AppSpacing._();

  /// 4.0
  static const double xs = 4;

  /// 8.0
  static const double s = 8;

  /// 16.0
  static const double m = 16;

  /// 24.0
  static const double l = 24;

  /// 32.0
  static const double xl = 32;
}

/// 文字样式辅助
///
/// 基于当前 BuildContext 的 Theme 生成常用文字样式。
class AppTextStyles {
  AppTextStyles._();

  /// 辅助文字样式：用于时间戳、次要信息
  ///
  /// fontSize 11, onSurfaceVariant 色
  static TextStyle caption(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant);
  }

  /// 标签文字样式：用于标签、badge
  ///
  /// fontSize 12, onSurfaceVariant 色
  static TextStyle label(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant);
  }

  /// 分组标题文字样式：用于设置类弹窗内的二级分组标题
  ///
  /// 基于 titleSmall 加粗，颜色与普通行内文字一致（不染主色），避免与
  /// 可点击/可折叠元素的语义混淆；层级区分完全依赖字重与间距。
  static TextStyle? sectionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
  }
}

/// 每日目标达成提示胶囊的明暗主题配色。
///
/// 亮色背景需要与白色/浅灰页面拉开对比，因此取更饱和的绿；暗色收敛为深森绿底配浅绿字。
@immutable
class DailyGoalToastPalette {
  final Color backgroundColor;
  final Color foregroundColor;

  const DailyGoalToastPalette({
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

/// 青色渐变横幅共享调色板（「加入社群」与「发现资源」入口条共用）。
@immutable
class CyanBannerPalette {
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color border;
  final Color icon;
  final Color title;
  final Color subtitle;
  final Color chevron;
  final Color inkSplash;
  final Color inkHighlight;
  final List<BoxShadow> shadow;

  const CyanBannerPalette({
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.border,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chevron,
    required this.inkSplash,
    required this.inkHighlight,
    required this.shadow,
  });

  static CyanBannerPalette resolve(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const CyanBannerPalette(
        backgroundStart: Color(0xFF102A36),
        backgroundEnd: Color(0xFF172D46),
        border: Color(0x6672C7D6),
        icon: Color(0xFF8AD8E4),
        title: Color(0xFFE7F4F8),
        subtitle: Color(0xFFB8CBD4),
        chevron: Color(0xCC79D6E6),
        inkSplash: Color(0x3379D6E6),
        inkHighlight: Color(0x1A79D6E6),
        shadow: [],
      );
    }

    return const CyanBannerPalette(
      backgroundStart: Color(0xFFEAF8FA),
      backgroundEnd: Color(0xFFDDEFFA),
      border: Color(0xFFA9D5DF),
      icon: Color(0xFF32758D),
      title: Color(0xFF17384A),
      subtitle: Color(0xFF587080),
      chevron: Color(0xCC3B7F94),
      inkSplash: Color(0x26256B86),
      inkHighlight: Color(0x14256B86),
      shadow: [
        BoxShadow(
          color: Color(0x1A256B86),
          blurRadius: 16,
          offset: Offset(0, 7),
        ),
      ],
    );
  }
}

/// 听前预热卡（暖琥珀色调）的明暗主题调色板。
///
/// 不直接读取 colorScheme.tertiary 以避免主色种子变更时偏色，
/// 与学习计划页白底蓝调主卡片形成次要引导区分。
@immutable
class WarmUpCardPalette {
  final Color backgroundColor;
  final Color borderColor;
  final Color iconBackgroundColor;
  final Color iconForegroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color badgeBackgroundColor;
  final Color badgeForegroundColor;
  final Color chevronColor;

  const WarmUpCardPalette({
    required this.backgroundColor,
    required this.borderColor,
    required this.iconBackgroundColor,
    required this.iconForegroundColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.badgeBackgroundColor,
    required this.badgeForegroundColor,
    required this.chevronColor,
  });

  static WarmUpCardPalette resolve(
    Brightness brightness,
    ColorScheme colorScheme,
  ) {
    final isDark = brightness == Brightness.dark;
    const amber = Color(0xFFFFB300);
    final iconFg = isDark ? const Color(0xFFFFB74D) : const Color(0xFFE8870C);
    final titleColor = isDark
        ? const Color(0xFFFFE2B8)
        : const Color(0xFF5A3A12);
    return WarmUpCardPalette(
      backgroundColor: isDark
          ? Color.alphaBlend(amber.withValues(alpha: 0.12), colorScheme.surface)
          : const Color(0xFFFFF4E2),
      borderColor: isDark
          ? amber.withValues(alpha: 0.20)
          : const Color(0xFFF4D7A8).withValues(alpha: 0.6),
      iconBackgroundColor: amber.withValues(alpha: isDark ? 0.22 : 0.16),
      iconForegroundColor: iconFg,
      titleColor: titleColor,
      subtitleColor: titleColor.withValues(alpha: isDark ? 0.70 : 0.72),
      badgeBackgroundColor: isDark ? amber : const Color(0xFFF38B00),
      badgeForegroundColor: isDark ? const Color(0xFF3A2400) : Colors.white,
      chevronColor: iconFg.withValues(alpha: 0.7),
    );
  }
}

/// 语音跟读评级档位，按从高到低排列。
enum SpeechRatingTier { perfect, excellent, good, fair, keepGoing }

/// 语音跟读评级徽章的明暗主题渐变与前景配色样式。
@immutable
class SpeechRatingBadgeStyle {
  final Color textColor;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color borderColor;

  const SpeechRatingBadgeStyle({
    required this.textColor,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.borderColor,
  });

  static SpeechRatingBadgeStyle resolve(
    SpeechRatingTier tier,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;
    return switch (tier) {
      SpeechRatingTier.perfect =>
        isDark
            ? const SpeechRatingBadgeStyle(
                textColor: Color(0xFFFFE082),
                backgroundStart: Color(0x33C9A030),
                backgroundEnd: Color(0x1A7A5F14),
                borderColor: Color(0x40E0B84A),
              )
            : const SpeechRatingBadgeStyle(
                textColor: Color(0xFF8B6914),
                backgroundStart: Color(0xFFFFF8E1),
                backgroundEnd: Color(0xFFFFF0B8),
                borderColor: Color(0xFFE0C068),
              ),
      SpeechRatingTier.excellent =>
        isDark
            ? const SpeechRatingBadgeStyle(
                textColor: Color(0xFFB9F5C8),
                backgroundStart: Color(0x3347B66B),
                backgroundEnd: Color(0x1A245B38),
                borderColor: Color(0x4057C878),
              )
            : const SpeechRatingBadgeStyle(
                textColor: Color(0xFF1E7A3D),
                backgroundStart: Color(0xFFEAF8EF),
                backgroundEnd: Color(0xFFDDF2E4),
                borderColor: Color(0xFFA8D6B6),
              ),
      SpeechRatingTier.good =>
        isDark
            ? const SpeechRatingBadgeStyle(
                textColor: Color(0xFFE4F3B2),
                backgroundStart: Color(0x33A4B84B),
                backgroundEnd: Color(0x1A56611F),
                borderColor: Color(0x40BDD460),
              )
            : const SpeechRatingBadgeStyle(
                textColor: Color(0xFF687A18),
                backgroundStart: Color(0xFFF6F8DF),
                backgroundEnd: Color(0xFFEEF3C8),
                borderColor: Color(0xFFD6DD9A),
              ),
      SpeechRatingTier.fair =>
        isDark
            ? const SpeechRatingBadgeStyle(
                textColor: Color(0xFFF7D79B),
                backgroundStart: Color(0x33C68A38),
                backgroundEnd: Color(0x1A6D4617),
                borderColor: Color(0x40E0A450),
              )
            : const SpeechRatingBadgeStyle(
                textColor: Color(0xFF8A5A14),
                backgroundStart: Color(0xFFFFF1DD),
                backgroundEnd: Color(0xFFF9E3BF),
                borderColor: Color(0xFFE6C48C),
              ),
      SpeechRatingTier.keepGoing =>
        isDark
            ? const SpeechRatingBadgeStyle(
                textColor: Color(0xFFB0BEC5),
                backgroundStart: Color(0x33607D8B),
                backgroundEnd: Color(0x1A37474F),
                borderColor: Color(0x4078909C),
              )
            : const SpeechRatingBadgeStyle(
                textColor: Color(0xFF546E7A),
                backgroundStart: Color(0xFFECEFF1),
                backgroundEnd: Color(0xFFE0E4E8),
                borderColor: Color(0xFFB0BEC5),
              ),
    };
  }
}
