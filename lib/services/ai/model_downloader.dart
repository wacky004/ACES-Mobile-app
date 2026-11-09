import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'ai_model_catalog.dart';
import 'model_store.dart';

class ModelDownloadCancelled implements Exception {
  const ModelDownloadCancelled();
  @override
  String toString() => 'Download cancelled.';
}

class ModelDownloadException implements Exception {
  const ModelDownloadException(this.message);
  final String message;
  @override
  String toString() => message;
}

class ModelDownloader {
  ModelDownloader({ModelStore? store, http.Client Function()? clientFactory})
      : _store = store ?? ModelStore(),
        _clientFactory = clientFactory ?? http.Client.new;

  final ModelStore _store;
  final http.Client Function() _clientFactory;

  Future<File> download(
    AiModelSpec spec, {
    required void Function(int received, int total, int percent) onProgress,
    required void Function(String status) onStatus,
    required bool Function() isCancelled,
  }) async {
    final part = await _store.partFor(spec);
    final target = await _store.fileFor(spec);
    if (await part.exists()) {
      final length = await part.length();
      if (length > spec.sizeBytes) {
        await part.delete();
      } else if (length == spec.sizeBytes) {
        return _verifyAndFinish(spec, part, target, onProgress, onStatus);
      }
    }

    try {
      return await _downloadFrom(
        spec,
        spec.url,
        part: part,
        target: target,
        onProgress: onProgress,
        onStatus: onStatus,
        isCancelled: isCancelled,
      );
    } catch (error) {
      final mirror = spec.mirrorUrl;
      if (mirror != null &&
          mirror.isNotEmpty &&
          error is! ModelDownloadCancelled) {
        return _downloadFrom(
          spec,
          mirror,
          part: part,
          target: target,
          onProgress: onProgress,
          onStatus: onStatus,
          isCancelled: isCancelled,
        );
      }
      rethrow;
    }
  }

  Future<File> _downloadFrom(
    AiModelSpec spec,
    String url, {
    required File part,
    required File target,
    required void Function(int received, int total, int percent) onProgress,
    required void Function(String status) onStatus,
    required bool Function() isCancelled,
  }) async {
    var start = await part.exists() ? await part.length() : 0;
    if (start > spec.sizeBytes) {
      await part.delete();
      start = 0;
    }

    final client = _clientFactory();
    try {
      onStatus(start > 0
          ? 'Resuming download at ${_mb(start)}…'
          : 'Starting download…');
      final request = http.Request('GET', Uri.parse(url));
      request.headers['User-Agent'] = 'CPE-Reviewer/1.2.0';
      request.headers['Accept'] = 'application/octet-stream';
      if (start > 0) {
        request.headers['Range'] = 'bytes=$start-';
      }
      final response = await client.send(request);
      if (response.statusCode == 416 && start > 0) {
        // The server no longer accepts our range; restart clean.
        await part.delete();
        return _downloadFrom(
          spec,
          url,
          part: part,
          target: target,
          onProgress: onProgress,
          onStatus: onStatus,
          isCancelled: isCancelled,
        );
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        throw ModelDownloadException(
          'Download failed with HTTP ${response.statusCode}.',
        );
      }
      if (response.statusCode == 200 && start > 0) {
        // Server ignored the Range header: restart from zero.
        start = 0;
      }

      final sink = part.openWrite(
        mode: start > 0 ? FileMode.append : FileMode.write,
      );
      var received = start;
      var lastPercent = -1;
      onStatus('Downloading model…');
      try {
        await for (final chunk in response.stream) {
          if (isCancelled()) {
            throw const ModelDownloadCancelled();
          }
          sink.add(chunk);
          received += chunk.length;
          final percent =
              ((received / spec.sizeBytes) * 100).clamp(0, 99).round();
          if (percent != lastPercent) {
            lastPercent = percent;
            onProgress(received, spec.sizeBytes, percent);
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      final length = await part.length();
      if (length != spec.sizeBytes) {
        throw ModelDownloadException(
          'Downloaded ${_mb(length)} of ${spec.sizeLabel}. '
          'The download will resume when you try again.',
        );
      }
      return _verifyAndFinish(spec, part, target, onProgress, onStatus);
    } finally {
      client.close();
    }
  }

  Future<File> _verifyAndFinish(
    AiModelSpec spec,
    File part,
    File target,
    void Function(int received, int total, int percent) onProgress,
    void Function(String status) onStatus,
  ) async {
    onStatus('Verifying file…');
    onProgress(spec.sizeBytes, spec.sizeBytes, 99);
    final path = part.path;
    final digest = await Isolate.run(() async {
      final hash = await sha256.bind(File(path).openRead()).first;
      return hash.toString();
    });
    if (digest.toLowerCase() != spec.sha256.toLowerCase()) {
      await part.delete();
      throw const ModelDownloadException(
        'The downloaded file failed its checksum. Please download again.',
      );
    }
    if (await target.exists()) {
      await target.delete();
    }
    final finished = await part.rename(target.path);
    onProgress(spec.sizeBytes, spec.sizeBytes, 100);
    onStatus('Installing model…');
    return finished;
  }

  static String _mb(int bytes) =>
      '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
}
