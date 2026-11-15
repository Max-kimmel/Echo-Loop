import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../analytics/analytics_providers.dart';
import '../../../analytics/models/event_names.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/collection_provider.dart';
import '../../../theme/app_theme.dart';
import '../community_collection_routes.dart';

/// 合集列表顶部固定的「发现资源」入口条。
///
/// 不滚动、永远可见，点击进入资源库主导航壳内的发现页。文案固定为「发现资源 / 播客、托福、雅思、四六级、口译...」，
/// 副标题直接列出代表性合集类型，便于用户一眼看出"里面是什么"。
class DiscoverEntryBanner extends ConsumerWidget {
  /// 点击回调；默认打开发现资源列表。测试可注入 mock。
  final VoidCallback? onTap;

  const DiscoverEntryBanner({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final title = l10n.discoverEntryTitleA;
    final subtitle = l10n.discoverEntrySubtitleA;
    final palette = AppTheme.cyanBannerPalette(theme.brightness);
    const radius = BorderRadius.all(Radius.circular(12));

    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.backgroundStart, palette.backgroundEnd],
            ),
            border: Border.all(color: palette.border),
            boxShadow: palette.shadow,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                splashColor: palette.inkSplash,
                highlightColor: palette.inkHighlight,
                onTap:
                    onTap ??
                    () {
                      // 仅 onTap 时点查一次 enrolled 数量，作为 analytics 维度上报，
                      // 不再驱动文案切换，所以不进入 watch 路径。
                      final enrolledCommunityCount = ref
                          .read(collectionListProvider)
                          .collections
                          .where((c) => c.isCommunity && !c.isDeprecated)
                          .length;
                      ref.read(analyticsServiceProvider).track(
                        Events.discoverEntryTapped,
                        {EventParams.enrolledCount: enrolledCommunityCount},
                      );
                      context.push(CommunityCollectionRoutes.discoverResources);
                    },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 34,
                        height: 34,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 25,
                          color: palette.icon,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: palette.title,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: palette.subtitle,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right, size: 22, color: palette.chevron),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
