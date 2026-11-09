import 'package:sembast/sembast.dart';

import '../models/imported_pdf.dart';

class PdfRepository {
  PdfRepository(this._db);

  final Database _db;
  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('pdf_docs');
  static final StoreRef<String, Map<String, Object?>> _draftStore =
      stringMapStoreFactory.store('draft_sets');

  Future<void> savePdf(ImportedPdf pdf) async {
    await _store.record(pdf.id).put(_db, pdf.toJson());
  }

  Future<List<ImportedPdf>> listPdfs() async {
    final records = await _store.find(
      _db,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)]),
    );
    return records
        .map((record) => ImportedPdf.fromJson(record.value))
        .toList(growable: false);
  }

  Future<ImportedPdf?> getPdf(String id) async {
    final raw = await _store.record(id).get(_db);
    return raw == null ? null : ImportedPdf.fromJson(raw);
  }

  Future<void> deletePdf(String id) async {
    await _store.record(id).delete(_db);
    await _draftStore.delete(
      _db,
      finder: Finder(filter: Filter.equals('pdfId', id)),
    );
  }

  Future<void> saveDraft(DraftSet draft) async {
    await _draftStore.record(draft.id).put(_db, draft.toJson());
  }

  Future<List<DraftSet>> listDrafts() async {
    final records = await _draftStore.find(
      _db,
      finder: Finder(sortOrders: [SortOrder('createdAt', false)]),
    );
    return records
        .map((record) => DraftSet.fromJson(record.value))
        .toList(growable: false);
  }

  Future<DraftSet?> getDraft(String id) async {
    final raw = await _draftStore.record(id).get(_db);
    return raw == null ? null : DraftSet.fromJson(raw);
  }

  Future<void> deleteDraft(String id) async {
    await _draftStore.record(id).delete(_db);
  }

  Future<void> clear() async {
    await _store.delete(_db);
    await _draftStore.delete(_db);
  }
}
