---
name: "Echo Loop"
description: "Focused Audio Studio design system for Echo Loop — calm, zero-distraction English listening & speaking loop UI with crisp light surfaces and true OLED dark mode."
tokens:
  colors:
    primary: "#1976D2"
    primaryDark: "#90CAF9"
    navActive: "#3AA0FF"
    scaffoldLight: "#F5F6FA"
    surfaceLight: "#FFFFFF"
    pureBlack: "#000000"
    surfaceBlack: "#0B0B0B"
    surfaceBorderDark: "#1F1F1F"
    sheetBlack: "#1E1E20"
    success: "#2E9E5B"
    successContainer: "#E3F4E9"
    pin: "#E53935"
    bookmark: "#FFC107"
    premiumGoldLight: "#C8941A"
    premiumGoldDark: "#E8B84B"
    premiumUpgradeLight: "#FCE76B"
    premiumUpgradeDark: "#D8B11E"
    reviewAgain: "#C56B45"
    reviewGood: "#4D9271"
    reviewUpcoming: "#597C65"
    reviewEasy: "#2B6C8F"
    reviewMastery: "#D88A36"
  typography:
    scale:
      display: "24px / 700"
      headline: "20px / 700"
      titleMedium: "16px / 600"
      bodyLarge: "16px / 400 (line-height 1.4, reading base)"
      bodyMedium: "14px / 400 (line-height 1.5, explanations & translations)"
      caption: "12px / 500"
    tabularFigures: true
  rounded:
    sm: "8px"
    md: "12px"
    lg: "16px"
    xl: "20px"
    pill: "999px"
  spacing:
    unit: "4px"
    xs: "4px"
    s: "8px"
    m: "16px"
    l: "24px"
    xl: "32px"
  components:
    - "Card (radius 16px, light elevation 1, dark 1px #1F1F1F border)"
    - "CyanBanner (CommunityInviteCard & DiscoverEntryBanner)"
    - "SpeechRatingBadge (5 tiers: perfect / excellent / good / fair / keepGoing)"
    - "WarmUpCard (amber recommendation card before intensive listening)"
    - "ActivityDayCell (12-level GitHub-style study heatmap)"
    - "DailyGoalToast (capsule notification with liveRegion semantics)"
---

# Echo Loop Design System (`DESIGN.md`)

> 本规范是 Echo Loop 客户端界面（iOS / Android / macOS / Web）的单一视觉真相来源，与 [`lib/theme/app_theme.dart`](./lib/theme/app_theme.dart) 和 [`lib/theme/learning_progress_colors.dart`](./lib/theme/learning_progress_colors.dart) 保持一一对应。

---

## Overview

Echo Loop 的界面美学定位为 **Focused Audio Studio（专注音频工作室）**：

- **低认知负荷**：学习流程已由“精听 → 跟读 → 盲听 → 复述 → 间隔复习”自动编排，UI 不使用炫目霓虹渐变或游戏化弹窗干扰注意，而是通过克制的留白、清晰排版与局部语义色彩引导用户专注听与说。
- **亮暗双主题分级**：
  - **浅色模式**：温润浅灰画布（`#F5F6FA`）衬托纯白浮起卡片（`#FFFFFF`），品牌明亮蓝（`#1976D2`）仅用于主操作、播放锚点与激活态。
  - **深色模式（AMOLED OLED）**：纯黑页面背景（`#000000`）+ 近黑卡片（`#0B0B0B`）+ `1px` 细描边（`#1F1F1F`），弹出层抬升至 `#1E1E20`，避免大面积纯黑糊成一片，同时适配夜间沉浸听力训练。

---

## Colors

所有业务 UI 色彩必须从 `AppTheme`、`LearningProgressColors`、`ActivityHeatmapColors` 或当前 `Theme.of(context).colorScheme` 获取，严禁在组件文件内散落硬编码 `Color(0x...)`。

### 1. 核心品牌色与表面层级

| 令牌名 | 浅色值 | 深色值 | 语义与用途 |
|---|---|---|---|
| `AppTheme.seedColor` / `primary` | `#1976D2` | `#90CAF9` (`fromSeed` 派生) | 主 CTA 按钮、进度主色、播放主控图标 |
| `AppTheme.navActiveColor` | `#3AA0FF` | `#3AA0FF` | 底部导航栏 / 侧边导航栏激活态图标与标签 |
| Scaffold 背景 | `#F5F6FA` | `#000000` | 页面底层画布 |
| Card / AppBar 表面 | `#FFFFFF` | `#0B0B0B` | 主卡片表面 |
| Card 描边（深色） | 无（依赖轻阴影） | `#1F1F1F` | OLED 黑底下的边界区分 |
| BottomSheet / Menu 浮层 | 系统默认浅色 surface | `#1E1E20` | 弹出层与菜单，清晰浮于纯黑背景之上 |

### 2. 语义与功能色

| 令牌名 | 浅色值 | 深色值 | 用途 |
|---|---|---|---|
| `AppTheme.successColor` | `#2E9E5B` | `#2E9E5B` | 完成勾选、今日目标角标 |
| `AppTheme.pinColor` | `#E53935` | `#E53935` | 置顶图钉 |
| `AppTheme.bookmarkColor` | `Colors.amber` | `Colors.amber` | 书签 / 收藏星标 |
| `AppTheme.wordHighlightBackgroundColor` | `#BCE7C6` | `#245D35` | 逐词高亮同步底色 |
| `AppTheme.speechPassedColor` | `#2E9B51` | `#2E9B51` | 跟读通过状态文字 |
| `AppTheme.premiumUpgradeBadgeBackground` | `#FCE76B` | `#D8B11E` | 升级高亮角标 / 特别优惠条底色（配 `#111111` 深字） |

### 3. 复习统计与记忆保留率语义色

| 令牌名 | 色值 | 用途 |
|---|---|---|
| `AppTheme.reviewAgainColor` | `#C56B45` | 「再来一遍 / 今日到期」陶土橙红 |
| `AppTheme.reviewGoodColor` | `#4D9271` | 「听懂了 / 学习时长 / 词汇统计」鼠尾草绿 |
| `AppTheme.reviewUpcomingColor` | `#597C65` | 未来到期规划柱体灰绿 |
| `AppTheme.reviewEasyColor` | `#2B6C8F` | 「轻松听懂 / 记忆保留率」岩蓝 |
| `AppTheme.reviewMasteryColor` | `#D88A36` | 连续复习 / 掌握度琥珀金 |

### 4. 月度统计与青色入口横幅

- **月度统计指标**（`AppTheme.monthlyStat*Color`）：在浅色模式下采用高饱和材质色（`#1976D2`、`#7B1FA2`、`#388E3C`），深色模式下自动提亮至 Pastel 档位（`#64B5F6`、`#CE93D8`、`#81C784`），确保在 `#0B0B0B` 卡片上的 WCAG AA 可读性。
- **青色渐变横幅**（`AppTheme.cyanBannerPalette`）：学习首页「加入社群」与资源库「发现资源」入口共用同一套渐变色板（浅色 `#EAF8FA → #DDEFFA`，深色 `#102A36 → #172D46`）。
- **学习热力图色阶**（`ActivityHeatmapColors`）：按 12 档分钟阈值（`0–5–10–20–35–55–80–110–145–185–230–280+`）映射 12 级纯正绿；`level ≥ 7` 时文字切换为白色，保证对比度。

---

## Typography

Echo Loop 采用中英双语混排排版，优先保证学习正文的阅读舒适度与听力时间轴数字对齐：

- **学习原文正文基准**：统一基于 `bodyLarge`（`16px`、`w400`、字间距 `0`、行高 `1.4`），支持 `readingFontScaleSteps`（85%～150%）叠加系统文字缩放。
- **AI 解析与译文**：基于 `bodyMedium`（`14px`、行高 `1.5`）；解析分类标题使用 `titleMedium`（`16px`、`w600`）并跟随学习内容字号缩放。
- **页面与应用栏标题**：`AppBar` 标题 `17px`、`FontWeight.bold`；卡片分组标题 `titleSmall`、`w600`。
- **辅助信息与标签**：`AppTextStyles.caption`（`11px`）与 `AppTextStyles.label`（`12px`），颜色取 `colorScheme.onSurfaceVariant`。
- **数字对齐**：统计数字、时长与进度计数（`StatValueText`）使用清晰字重区分（`w700`–`w800`）与负字距收紧，禁止因为位数变化造成横向跳动。

---

## Layout

- **4px 基准网格**（`AppSpacing`）：`xs = 4`、`s = 8`、`m = 16`、`l = 24`、`xl = 32`。
- **标准页边距**：主列表与详情卡片水平内边距 `16dp`（紧凑横幅条目可用 `12dp`）。
- **自适应多列布局**：所有宽屏适配使用 `LayoutBuilder` 与 `SliverGridDelegateWithMaxCrossAxisExtent` 等真实可用约束，严禁依赖设备型号或屏幕方向硬编码分支。
- **安全区与底部遮挡防护**：所有滚动列表、学习任务底栏与弹窗必须正确处理 `SafeArea`、键盘遮挡（`MediaQuery.viewInsetsOf`）及迷你播放器高度占位；仅订阅性能所需的 `MediaQuery.sizeOf(context)` 等精准切片。

---

## Elevation & Depth

- **浅色模式**：通过**弱阴影 + 纯白浮起表面**建立层次。主卡片 `elevation: 1`、`shadowColor: black @ 8%`；悬浮气泡与菜单使用更大模糊半径与极轻阴影（`alpha: 0.03–0.09`）。
- **深色模式**：因为阴影在纯黑 `#000000` 上几乎不可见，深色卡片统一设为 `elevation: 0` + **`1px` 细边框（`#1F1F1F`）**；浮层菜单与 BottomSheet 则通过**表面提亮（`#1E1E20`）+ 半透明 `outlineVariant` 边框**建立清晰边界。

---

## Shapes

| 元素类型 | 圆角半径 | 示例 |
|---|---|---|
| 小型控件 / 徽标 | `8px`–`10px` | 评分图例色块、`Paywall` 推荐小徽标 |
| 输入框 / 列表项 / 入口横幅 | `12px` | `InputDecoration`、`ListTile`、`DiscoverEntryBanner` |
| 主卡片 / 主按钮 | `16px` | `CardTheme`、`FilledButton`、`OutlinedButton`、`WarmUpCard` |
| 对话框 / 悬浮气泡 / 指标块 | `20px` | `DialogTheme`、`CapsuleSelector` 浮层、复习指标卡 |
| 胶囊与微提示 | `24px`–`999px` | `AppToast`（`24px` 兼顾多行）、`SpeechRatingBadge`（`999px`） |

---

## Components

1. **交互播放主控（`PlaybackControls` / `PracticePlaybackFooter`）**：
   - 统一无底色 SVG 主播放图标（`44dp`、`primary` 主色），`56dp` 最小触控热区，常规中心距 `104dp`，含快捷速度按钮时窄于 `312dp` 自动降级隐藏速度按钮以防 320pt 屏幕溢出。
2. **跟读评分徽章（`SpeechRatingBadge`）**：
   - 融合评级文案与录音回放按钮的胶囊徽章，支持 5 个等级（`perfect`、`excellent`、`good`、`fair`、`keepGoing`），在亮/暗主题下通过 `AppTheme.speechRatingBadgeStyle` 提供低对比渐变底 + 高对比前景文字。
   - 无障碍要求：带录音时必须标注 `Semantics(button: true)` 与可播放状态描述。
3. **每日目标达成提示（`DailyGoalToast` / `showAppToast`）**：
   - 顶部居中浮动胶囊，绿色高对比配色由 `AppTheme.dailyGoalToastPalette` 提供。
   - 无障碍要求：必须标记 `Semantics(liveRegion: true, button: dismissOnTap, label: message)`，使屏幕阅读器主动播报打卡达成提示。
4. **听前预热卡（`_WarmUpCard`）**：
   - 位于学习计划“首次学习”之上的轻引导卡片，使用 `AppTheme.warmUpCardPalette` 暖琥珀色调区别于常规卡片，整卡带有明确按钮 `Semantics`。
5. **活动日历热力图（`ActivityDayCell`）**：
   - 12 级绿阶由 `ActivityHeatmapColors` 管理，内含“今天”红圈与“选中”橙圈指示器，以及独立语义标签（日期 + 学习分钟 + 是否达成每日目标）。

---

## Do's and Don'ts

- **DO（必须遵守）**：
  - ✅ 在新增或修改任何组件配色时，将语义化颜色加入 `AppTheme` 或 `lib/theme/` 下专职调色板类，并提供明暗两套对比度达标的色值。
  - ✅ 为所有基于 `GestureDetector`、`InkWell`、`TappableWrapper` 的自定义可点击卡片、徽章、横幅和浮动提示补充清晰的 `Semantics`（`button`、`label`、`selected`、`liveRegion`）。
  - ✅ 使用 `MediaQuery.sizeOf(context)` / `MediaQuery.viewInsetsOf(context)` 替代 `MediaQuery.of(context)`，避免无关媒体查询变更引起整页重建。
- **DON'T（严禁出现）**：
  - ❌ 严禁在业务 Screen/Widget 中硬编码仅适配浅色或重复拷贝的 `Color(0x...)` 调色板类。
  - ❌ 严禁使用未经主题包装的裸紫色发光渐变或“AI 味”装饰光晕破坏音频工作室的沉静氛围。
  - ❌ 严禁使用 `withOpacity()`（已废弃），统一使用 `.withValues(alpha: ...)`。
