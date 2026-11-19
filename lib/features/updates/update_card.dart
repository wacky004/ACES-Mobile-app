import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/theme.dart';
import '../../services/updates/update_service.dart';
import 'update_flow.dart';

class WindowsUpdateCard extends StatefulWidget {
  const WindowsUpdateCard({super.key});

  @override
  State<WindowsUpdateCard> createState() => _WindowsUpdateCardState();
}

class _WindowsUpdateCardState extends State<WindowsUpdateCard> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!UpdateService.instance.isSupported) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Windows updates',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            'Installed version${_version.isEmpty ? '' : ' $_version'}. '
            'Updates open the signed setup wizard and keep your data.',
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => checkForUpdates(context),
              icon: const Icon(Icons.system_update_alt_rounded, size: 18),
              label: const Text('Check for updates'),
            ),
          ),
        ],
      ),
    );
  }
}
