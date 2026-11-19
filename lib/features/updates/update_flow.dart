import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../services/updates/update_service.dart';

Future<void> checkForUpdates(
  BuildContext context, {
  bool silent = false,
}) async {
  final service = UpdateService.instance;
  if (!service.isSupported) return;

  AppUpdate? update;
  try {
    update = await service.check();
  } catch (error) {
    if (!silent && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
    return;
  }
  if (!context.mounted) return;
  if (update == null) {
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CPE Reviewer is up to date.')),
      );
    }
    return;
  }

  final install = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Update ${update!.version} is available'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              update.mandatory
                  ? 'This update is required before continuing.'
                  : 'A newer Windows build is ready to install.',
              style: const TextStyle(fontSize: 12.5, height: 1.5),
            ),
            if (update.notes.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  update.notes,
                  style: const TextStyle(fontSize: 11.5, height: 1.5),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'The installer will open a setup wizard and preserve your '
              'progress, chats, and downloaded models.',
              style: TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
          ],
        ),
      ),
      actions: [
        if (!update.mandatory)
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Later'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Download and install'),
        ),
      ],
    ),
  );
  if (install != true || !context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _UpdateProgressDialog(update: update!),
  );
}

class _UpdateProgressDialog extends StatefulWidget {
  const _UpdateProgressDialog({required this.update});

  final AppUpdate update;

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  double? _progress;
  String _status = 'Preparing download...';
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final file = await UpdateService.instance.download(
        widget.update,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _progress = total > 0 ? received / total : null;
            _status = total > 0
                ? '${(received / 1024 / 1024).toStringAsFixed(1)} MB of '
                      '${(total / 1024 / 1024).toStringAsFixed(1)} MB'
                : '${(received / 1024 / 1024).toStringAsFixed(1)} MB';
          });
        },
      );
      if (!mounted) return;
      setState(() => _status = 'Opening the installer wizard...');
      await UpdateService.instance.launchInstaller(file);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      exit(0);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Updating to ${widget.update.version}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(value: _error == null ? _progress : null),
            const SizedBox(height: 12),
            Text(
              _error ?? _status,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: _error == null ? AppColors.muted : AppColors.red,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              const Text(
                'The current version is unchanged. You can try again from '
                'Settings.',
                style: TextStyle(fontSize: 10.5, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_error != null)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
      ],
    );
  }
}
