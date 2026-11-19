import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateException implements Exception {
  UpdateException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.installerUrl,
    required this.sha256,
    required this.notes,
    this.publisherThumbprint,
    this.mandatory = false,
  });

  final String version;
  final String installerUrl;
  final String sha256;
  final String notes;
  final String? publisherThumbprint;
  final bool mandatory;

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as String?;
    final installerUrl = json['installer_url'] as String?;
    final sha256 = json['sha256'] as String?;
    if (version == null || installerUrl == null || sha256 == null) {
      throw UpdateException('The update feed is missing required fields.');
    }
    return AppUpdate(
      version: version,
      installerUrl: installerUrl,
      sha256: sha256.toLowerCase(),
      notes: json['notes'] as String? ?? '',
      publisherThumbprint: json['publisher_thumbprint'] as String?,
      mandatory: json['mandatory'] as bool? ?? false,
    );
  }
}

class UpdateService {
  UpdateService._();
  static final UpdateService instance = UpdateService._();

  static const String defaultManifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue:
        'https://github.com/wacky004/ACES-Reviewer-Releases/releases/latest/download/latest.json',
  );

  bool get isSupported => Platform.isWindows;

  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<AppUpdate?> check({
    http.Client? client,
    String manifestUrl = defaultManifestUrl,
  }) async {
    if (!isSupported) return null;
    final httpClient = client ?? http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw UpdateException(
          'Update check failed (HTTP ${response.statusCode}).',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw UpdateException('The update feed is invalid.');
      }
      final update = AppUpdate.fromJson(decoded);
      final installed = await currentVersion();
      if (!_isNewer(update.version, installed)) return null;
      return update;
    } on UpdateException {
      rethrow;
    } catch (error) {
      throw UpdateException('Could not check for updates: $error');
    } finally {
      if (client == null) httpClient.close();
    }
  }

  Future<bool> shouldAutoCheck() async {
    if (!isSupported) return false;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt('last_update_check_ms') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < const Duration(hours: 24).inMilliseconds) return false;
    await prefs.setInt('last_update_check_ms', now);
    return true;
  }

  Future<File> download(
    AppUpdate update, {
    required void Function(int received, int total) onProgress,
  }) async {
    if (!isSupported) {
      throw UpdateException('Updates are only supported on Windows.');
    }
    final support = await getApplicationSupportDirectory();
    final directory = Directory(p.join(support.path, 'updates'));
    await directory.create(recursive: true);
    final uri = Uri.parse(update.installerUrl);
    final name = uri.pathSegments.isEmpty
        ? 'CPE-Reviewer-Update.exe'
        : uri.pathSegments.last;
    final file = File(p.join(directory.path, name));
    if (await file.exists()) await file.delete();

    final client = http.Client();
    try {
      final request = http.Request('GET', uri);
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw UpdateException(
          'Update download failed (HTTP ${response.statusCode}).',
        );
      }
      final total = response.contentLength ?? 0;
      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress(received, total);
        }
      } finally {
        await sink.close();
      }
    } finally {
      client.close();
    }

    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString().toLowerCase() != update.sha256) {
      await file.delete();
      throw UpdateException('The update failed its integrity check.');
    }
    await _verifySignature(file, update.publisherThumbprint);
    return file;
  }

  Future<void> launchInstaller(File installer) async {
    if (!await installer.exists()) {
      throw UpdateException('The downloaded installer is missing.');
    }
    await Process.start(installer.path, const [
      '/UPDATECHECK=1',
    ], mode: ProcessStartMode.detached);
  }

  Future<void> _verifySignature(File file, String? expectedThumbprint) async {
    if (expectedThumbprint == null || expectedThumbprint.isEmpty) return;
    final escapedPath = file.path.replaceAll("'", "''");
    final command =
        "Get-AuthenticodeSignature -LiteralPath '$escapedPath' | "
        "Select-Object Status,@{Name='Thumbprint';Expression={\$_.SignerCertificate.Thumbprint}} | "
        'ConvertTo-Json -Compress';
    final result = await Process.run('powershell.exe', [
      '-NoProfile',
      '-NonInteractive',
      '-Command',
      command,
    ]);
    if (result.exitCode != 0) {
      throw UpdateException('Could not verify the installer signature.');
    }
    final decoded = jsonDecode(result.stdout.toString());
    if (decoded is! Map<String, dynamic>) {
      throw UpdateException('Could not read the installer signature.');
    }
    if (decoded['Status'] != 'Valid') {
      throw UpdateException('The downloaded installer is not signed.');
    }
    final thumbprint = (decoded['Thumbprint'] as String? ?? '')
        .replaceAll(' ', '')
        .toLowerCase();
    if (thumbprint != expectedThumbprint.replaceAll(' ', '').toLowerCase()) {
      throw UpdateException('The installer publisher did not match.');
    }
  }

  bool _isNewer(String latest, String installed) {
    final a = _versionParts(latest);
    final b = _versionParts(installed);
    for (var i = 0; i < 3; i++) {
      if (a[i] != b[i]) return a[i] > b[i];
    }
    return false;
  }

  List<int> _versionParts(String version) {
    final clean = version.split('+').first.split('-').first;
    final parts = clean
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts.take(3).toList();
  }
}
