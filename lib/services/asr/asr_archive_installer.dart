import 'dart:io';

import 'package:dio/dio.dart';

import '../reliable_http_downloader.dart' show ReliableHttpDownloader;
import '../resource_archive_installer.dart';

/// ASR 模型归档的下载、断点续传与原子安装流程。
///
/// 复用通用 [ResourceArchiveInstaller]，仅保留 ASR 专属日志标签与非空校验参数约束。
class AsrArchiveInstaller {
  AsrArchiveInstaller(ReliableHttpDownloader downloader)
    : _delegate = ResourceArchiveInstaller(
        downloader,
        logTag: 'AsrInstall',
        errorPrefix: 'ASR archive',
      );

  final ResourceArchiveInstaller _delegate;

  Future<void> install({
    required Directory root,
    required Directory target,
    required String resourceId,
    required Uri uri,
    required String expectedSha256,
    required Future<void> Function(File archive, Directory staging)
    extractAndValidate,
    CancelToken? cancelToken,
    void Function(double progress)? onProgress,
    void Function()? onInstalling,
  }) async {
    if (expectedSha256.isEmpty) {
      throw ArgumentError.value(
        expectedSha256,
        'expectedSha256',
        'Must not be empty',
      );
    }
    return _delegate.install(
      root: root,
      target: target,
      resourceId: resourceId,
      uri: uri,
      expectedSha256: expectedSha256,
      extractAndValidate: extractAndValidate,
      cancelToken: cancelToken,
      onProgress: onProgress,
      onInstalling: onInstalling,
    );
  }

  /// 丢弃用户明确取消的资源下载残留。
  ///
  /// 仅显式取消调用此方法；网络失败和进程中断保留 `.part`，以便后续续传。
  Future<void> discardPartial({
    required Directory root,
    required String resourceId,
  }) {
    return _delegate.discardPartial(
      root: root,
      resourceId: resourceId,
    );
  }
}
