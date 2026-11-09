import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ai_model_catalog.dart';

class ModelStore {
  ModelStore([this._root]);

  final Directory? _root;

  Future<Directory> folder() async {
    final base = _root ?? await getApplicationSupportDirectory();
    final directory = Directory(p.join(base.path, 'ai_models'));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<File> fileFor(AiModelSpec spec) async =>
      File(p.join((await folder()).path, spec.filename));

  Future<File> partFor(AiModelSpec spec) async =>
      File('${(await fileFor(spec)).path}.part');

  Future<bool> isDownloaded(AiModelSpec spec) async {
    final file = await fileFor(spec);
    if (!await file.exists()) return false;
    return await file.length() == spec.sizeBytes;
  }

  Future<bool> hasPartial(AiModelSpec spec) async => (await partFor(spec)).exists();

  Future<int> installedBytes() async {
    var total = 0;
    for (final spec in aiModelCatalog) {
      final file = await fileFor(spec);
      if (await file.exists()) {
        total += await file.length();
      }
    }
    return total;
  }

  Future<void> delete(AiModelSpec spec) async {
    final file = await fileFor(spec);
    final part = await partFor(spec);
    if (await file.exists()) await file.delete();
    if (await part.exists()) await part.delete();
  }
}
