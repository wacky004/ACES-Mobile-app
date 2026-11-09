import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../services/ai/ai_model_catalog.dart';
import '../../../state/app_scope.dart';
import '../../../widgets/ui_kit.dart';
import '../ai_controller.dart';

class AiModelManagerScreen extends StatefulWidget {
  const AiModelManagerScreen({super.key, this.controller});

  final AiController? controller;

  @override
  State<AiModelManagerScreen> createState() => _AiModelManagerScreenState();
}

class _AiModelManagerScreenState extends State<AiModelManagerScreen> {
  AiController? _controller;
  bool _ownsController = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final scope = AppScope.of(context);
    _controller =
        widget.controller ??
        AiController(
          pdfRepository: scope.pdfRepository,
          subjectId: scope.session.subject.id,
        );
    _ownsController = widget.controller == null;
    _controller!.initialize();
  }

  @override
  void dispose() {
    if (_ownsController) _controller?.dispose();
    super.dispose();
  }

  Future<void> _delete(AiController controller, AiModelSpec spec) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${spec.displayName}?'),
        content: Text(
          'This frees ${spec.sizeLabel}. You can download it again later. '
          'Chats, PDFs, and drafts are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteModel(spec);
    }
  }

  Future<void> _use(AiController controller, AiModelSpec spec) async {
    await controller.selectModel(spec);
    if (!mounted) return;
    if (controller.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(controller.error!)));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Using ${spec.displayName}.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final installedCount = controller.installedCount;
        final totalSize = controller.installedBytes;
        return Scaffold(
          appBar: AppBar(title: const Text('Offline models')),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.teal.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.teal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.memory_rounded,
                          color: AppColors.teal,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.selectedModelInstalled
                                  ? 'Current: ${controller.selectedModel.displayName}'
                                  : 'No model installed',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$installedCount installed · '
                              '${_sizeLabel(totalSize)} stored · '
                              'one model is loaded at a time',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (controller.error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    controller.error!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.red,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const SectionHeader(
                  title: 'Model library',
                  subtitle:
                      'Choose a balance of speed and quality. Qwen2.5 3B is '
                      'recommended for 8 GB phones.',
                ),
                const SizedBox(height: 10),
                for (final spec in aiModelCatalog) ...[
                  _ModelTile(
                    spec: spec,
                    controller: controller,
                    onDownload: () => controller.downloadModel(spec),
                    onUse: () => _use(controller, spec),
                    onDelete: () => _delete(controller, spec),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 6),
                const Text(
                  'Models stay on this device. Qwen models are Apache 2.0; '
                  'Gemma models follow the Gemma Terms of Use. '
                  'Keep the app open while downloading.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    height: 1.45,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _sizeLabel(int bytes) {
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

class _ModelTile extends StatelessWidget {
  const _ModelTile({
    required this.spec,
    required this.controller,
    required this.onDownload,
    required this.onUse,
    required this.onDelete,
  });

  final AiModelSpec spec;
  final AiController controller;
  final VoidCallback onDownload;
  final VoidCallback onUse;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = controller.selectedModel.id == spec.id;
    final installed = controller.isInstalled(spec);
    final downloading = controller.isDownloadingModel(spec);
    final partial = controller.hasPartial(spec);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppColors.teal.withValues(alpha: 0.55)
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.teal.withValues(alpha: 0.14)
                      : AppColors.blue.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.memory_rounded,
                  color: selected ? AppColors.teal : AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            spec.displayName,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        StatusPill(
                          label: spec.tag,
                          color: spec.recommended
                              ? AppColors.teal
                              : AppColors.blue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${spec.sizeLabel} · ${spec.ramGuide} · ${spec.license}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            spec.description,
            style: const TextStyle(
              fontSize: 11,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 10),
          if (downloading) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.downloadStatus,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${controller.downloadProgress}%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.teal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: controller.downloadProgress / 100,
                minHeight: 7,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: controller.cancelDownload,
                child: const Text('Cancel'),
              ),
            ),
          ] else if (installed) ...[
            Row(
              children: [
                const StatusPill(
                  label: 'INSTALLED',
                  color: AppColors.green,
                  icon: Icons.check_rounded,
                ),
                const Spacer(),
                if (!selected)
                  OutlinedButton(
                    onPressed: onUse,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      foregroundColor: AppColors.teal,
                      side: BorderSide(
                        color: AppColors.teal.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text('Use'),
                  )
                else
                  const StatusPill(label: 'IN USE', color: AppColors.teal),
                const SizedBox(width: 6),
                IconButton(
                  tooltip: 'Delete model',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: AppColors.red,
                  ),
                ),
              ],
            ),
          ] else ...[
            FilledButton.icon(
              onPressed: onDownload,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(42),
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.navy,
              ),
              icon: const Icon(Icons.download_rounded, size: 17),
              label: Text(partial ? 'Resume download' : 'Download model'),
            ),
            if (spec.minRamGb >= 8)
              const Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text(
                  'Best on 8 GB RAM; slower and closer to the memory limit.',
                  style: TextStyle(fontSize: 9.5, color: AppColors.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
