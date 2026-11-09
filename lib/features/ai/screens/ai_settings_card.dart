import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../state/app_scope.dart';
import '../../../widgets/ui_kit.dart';
import '../ai_controller.dart';
import 'deepseek_setup_screen.dart';
import 'openai_compatible_setup_screen.dart';
import 'model_manager_screen.dart';

class AiSettingsCard extends StatefulWidget {
  const AiSettingsCard({super.key});

  @override
  State<AiSettingsCard> createState() => _AiSettingsCardState();
}

class _AiSettingsCardState extends State<AiSettingsCard> {
  AiController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = AppScope.of(context);
    _controller = AiController(
      pdfRepository: scope.pdfRepository,
      subjectId: scope.session.subject.id,
    );
    _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openDeepSeek() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const DeepSeekSetupScreen()));
  }

  void _openCompatible() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OpenAiCompatibleSetupScreen()),
    );
  }

  void _openModels(AiController controller) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AiModelManagerScreen(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
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
      child: controller == null
          ? const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading AI settings…', style: TextStyle(fontSize: 11.5)),
              ],
            )
          : ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final online = controller.usesCloud;
                final selected = controller.selectedModel;
                final installed = controller.selectedModelInstalled;
                final ready = controller.isReady;
                final deepSeekReady = controller.deepSeekReady;
                final compatibleReady = controller.compatibleReady;
                final checking = controller.modelChecking && !online;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: (online ? AppColors.blue : AppColors.teal)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            online
                                ? Icons.cloud_queue_rounded
                                : Icons.memory_rounded,
                            color: online ? AppColors.blue : AppColors.teal,
                            size: 19,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI providers',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Use DeepSeek or your own OpenAI-compatible '
                                'cloud key, or download an on-device model. '
                                'The web build has no AI.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (checking)
                      const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Checking models…',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ],
                      )
                    else ...[
                      Row(
                        children: [
                          StatusPill(
                            label: ready ? 'READY' : 'NOT READY',
                            color: ready ? AppColors.green : AppColors.amber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              online
                                  ? (deepSeekReady
                                        ? 'DeepSeek · ${controller.deepSeekModel.displayName} · online'
                                        : 'DeepSeek selected · no API key')
                                  : (installed
                                        ? '${selected.displayName} · ${selected.sizeLabel} · offline'
                                        : 'No offline model installed'),
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        online
                            ? (deepSeekReady
                                  ? 'Saved key ${controller.deepSeekConfig.maskedKey}. '
                                        'Online requests are billed by DeepSeek.'
                                  : 'Add a key to use photos, PDFs, and online answers.')
                            : '${controller.installedCount} installed · '
                                  '${_sizeLabel(controller.installedBytes)} stored',
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: AppColors.muted,
                        ),
                      ),
                      if (controller.downloading) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${controller.downloadStatus} '
                          '${controller.downloadProgress}%',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: controller.downloadProgress / 100,
                            minHeight: 6,
                          ),
                        ),
                      ],
                      if (deepSeekReady && !controller.usesDeepSeek)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                controller.selectDeepSeekProvider(),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(
                              Icons.cloud_queue_rounded,
                              size: 15,
                            ),
                            label: const Text(
                              'Use DeepSeek online',
                              style: TextStyle(fontSize: 10.5),
                            ),
                          ),
                        )
                      else if (compatibleReady && !controller.usesCompatible)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                controller.selectCompatibleProvider(),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.hub_outlined, size: 15),
                            label: const Text(
                              'Use custom cloud AI',
                              style: TextStyle(fontSize: 10.5),
                            ),
                          ),
                        )
                      else if (online && controller.installedCount > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => controller.selectLocalProvider(),
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            icon: const Icon(Icons.memory_rounded, size: 15),
                            label: const Text(
                              'Switch to an offline model',
                              style: TextStyle(fontSize: 10.5),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _openDeepSeek,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                        ),
                        icon: Icon(
                          deepSeekReady
                              ? Icons.tune_rounded
                              : Icons.key_rounded,
                          size: 18,
                        ),
                        label: Text(
                          deepSeekReady
                              ? 'DeepSeek settings'
                              : 'Connect DeepSeek',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _openCompatible,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: AppColors.blue,
                          side: BorderSide(
                            color: AppColors.blue.withValues(alpha: 0.35),
                          ),
                        ),
                        icon: const Icon(Icons.hub_outlined, size: 18),
                        label: Text(
                          compatibleReady
                              ? 'OpenAI-compatible settings'
                              : 'Connect OpenAI-compatible cloud',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _openModels(controller),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          foregroundColor: AppColors.teal,
                          side: BorderSide(
                            color: AppColors.teal.withValues(alpha: 0.35),
                          ),
                        ),
                        icon: const Icon(Icons.memory_rounded, size: 18),
                        label: Text(
                          installed
                              ? 'Manage offline models'
                              : 'Download an offline model',
                        ),
                      ),
                    ],
                    if (controller.error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        controller.error!,
                        style: const TextStyle(
                          fontSize: 10.5,
                          height: 1.4,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }

  static String _sizeLabel(int bytes) {
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
