import 'dart:io';

import 'package:cpe_reviewer/services/ai/ai_model_catalog.dart';
import 'package:cpe_reviewer/services/ai/model_downloader.dart';
import 'package:cpe_reviewer/services/ai/model_store.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:flutter_test/flutter_test.dart';

AiModelSpec specFor({
  required String url,
  required List<int> bytes,
  required String sha,
}) =>
    AiModelSpec(
      id: 'test-model',
      displayName: 'Test model',
      filename: 'test-model.gguf',
      url: url,
      sizeBytes: bytes.length,
      sizeLabel: '${bytes.length} B',
      sha256: sha,
      modelType: ModelType.qwen,
      license: 'Test',
      ramGuide: 'Test',
      tag: 'TEST',
      description: 'Test',
      minRamGb: 1,
    );

Future<HttpServer> startRangeServer(List<int> bytes) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    final range = request.headers.value(HttpHeaders.rangeHeader);
    var start = 0;
    if (range != null && range.startsWith('bytes=')) {
      start = int.tryParse(range.substring(6).split('-').first) ?? 0;
    }
    if (start > 0) {
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-${bytes.length - 1}/${bytes.length}',
      );
    } else {
      request.response.statusCode = HttpStatus.ok;
    }
    request.response.headers.set(
      HttpHeaders.acceptRangesHeader,
      'bytes',
    );
    request.response.headers.contentType = ContentType.binary;
    request.response.contentLength = bytes.length - start;
    final chunkSize = 64 * 1024;
    for (var offset = start; offset < bytes.length; offset += chunkSize) {
      final end = (offset + chunkSize).clamp(0, bytes.length);
      request.response.add(bytes.sublist(offset, end));
      await request.response.flush();
    }
    await request.response.close();
  });
  return server;
}

void main() {
  test('downloads, verifies, and installs a model file', () async {
    final data = List<int>.generate(300 * 1024, (index) => index % 251);
    final sha = sha256.convert(data).toString();
    final server = await startRangeServer(data);
    final root = await Directory.systemTemp.createTemp('cpe-model-test');
    addTearDown(() async {
      await server.close(force: true);
      await root.delete(recursive: true);
    });
    final spec = specFor(
      url: 'http://127.0.0.1:${server.port}/model.gguf',
      bytes: data,
      sha: sha,
    );
    final store = ModelStore(root);
    final downloader = ModelDownloader(store: store);
    var lastPercent = 0;
    final file = await downloader.download(
      spec,
      onProgress: (received, total, percent) => lastPercent = percent,
      onStatus: (_) {},
      isCancelled: () => false,
    );

    expect(await file.exists(), isTrue);
    expect(await file.length(), data.length);
    expect(lastPercent, 100);
    expect(await store.isDownloaded(spec), isTrue);
  });

  test('resumes a partial download with an HTTP range', () async {
    final data = List<int>.generate(500 * 1024, (index) => index % 239);
    final sha = sha256.convert(data).toString();
    final server = await startRangeServer(data);
    final root = await Directory.systemTemp.createTemp('cpe-model-resume');
    addTearDown(() async {
      await server.close(force: true);
      await root.delete(recursive: true);
    });
    final spec = specFor(
      url: 'http://127.0.0.1:${server.port}/model.gguf',
      bytes: data,
      sha: sha,
    );
    final store = ModelStore(root);
    final part = await store.partFor(spec);
    await part.parent.create(recursive: true);
    await part.writeAsBytes(data.sublist(0, 200 * 1024));

    final file = await ModelDownloader(store: store).download(
      spec,
      onProgress: (_, _, _) {},
      onStatus: (_) {},
      isCancelled: () => false,
    );
    expect(await file.readAsBytes(), data);
  });

  test('honors cancellation and keeps the partial file', () async {
    final data = List<int>.generate(400 * 1024, (index) => index % 223);
    final sha = sha256.convert(data).toString();
    final server = await startRangeServer(data);
    final root = await Directory.systemTemp.createTemp('cpe-model-cancel');
    addTearDown(() async {
      await server.close(force: true);
      await root.delete(recursive: true);
    });
    final spec = specFor(
      url: 'http://127.0.0.1:${server.port}/model.gguf',
      bytes: data,
      sha: sha,
    );
    final store = ModelStore(root);
    expect(
      () => ModelDownloader(store: store).download(
        spec,
        onProgress: (_, _, _) {},
        onStatus: (_) {},
        isCancelled: () => true,
      ),
      throwsA(isA<ModelDownloadCancelled>()),
    );
  });

  test('rejects a checksum mismatch', () async {
    final data = List<int>.generate(100 * 1024, (index) => index % 211);
    final server = await startRangeServer(data);
    final root = await Directory.systemTemp.createTemp('cpe-model-badsha');
    addTearDown(() async {
      await server.close(force: true);
      await root.delete(recursive: true);
    });
    final spec = specFor(
      url: 'http://127.0.0.1:${server.port}/model.gguf',
      bytes: data,
      sha: List.filled(64, '0').join(),
    );
    expect(
      () => ModelDownloader(store: ModelStore(root)).download(
        spec,
        onProgress: (_, _, _) {},
        onStatus: (_) {},
        isCancelled: () => false,
      ),
      throwsA(isA<ModelDownloadException>()),
    );
  });
}
