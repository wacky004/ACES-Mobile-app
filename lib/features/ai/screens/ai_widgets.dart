import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme.dart';
import '../../../models/deepseek_models.dart';
import '../../../services/ai/ai_model_catalog.dart';
import '../../../services/ai/rag_index.dart';
import '../../../state/app_scope.dart';
import '../../../widgets/ui_kit.dart';
import '../ai_controller.dart';
import 'deepseek_setup_screen.dart';
import 'openai_compatible_setup_screen.dart';
import 'model_manager_screen.dart';

class AiModelCard extends StatelessWidget {
  const AiModelCard({
    super.key,
    required this.controller,
    this.compact = false,
  });

  final AiController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkSurface : AppColors.surface;
    final border = isDark ? AppColors.darkBorder : AppColors.border;

    Widget content;
    if (controller.usesCompatible) {
      content = _compatibleContent(context);
    } else if (controller.usesDeepSeek) {
      content = _deepSeekContent(context);
    } else {
      content = _localContent(context);
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: border),
      ),
      child: content,
    );
  }

  Widget _compatibleContent(BuildContext context) {
    final config = controller.compatibleConfig;
    if (controller.compatibleReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Custom cloud AI is ready',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${config.displayName} - ${config.modelId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusPill(label: 'ONLINE', color: AppColors.blue),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => openCompatibleSetup(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('Provider settings'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => showModelPicker(context, controller),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.navy,
                  ),
                  child: const Text('Change provider'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.hub_outlined,
                color: AppColors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Connect a custom cloud provider',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            const StatusPill(label: 'SETUP', color: AppColors.amber),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Use your own OpenAI-compatible base URL, model ID, and API key. '
          'Free tiers and self-hosted endpoints are supported when they '
          'expose a compatible API. No key is bundled.',
          style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.muted),
        ),
        if (controller.error != null) ...[
          const SizedBox(height: 7),
          Text(
            controller.error!,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: AppColors.red,
            ),
          ),
        ],
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => openCompatibleSetup(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.hub_outlined, size: 18),
          label: const Text('Configure custom cloud'),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => openModelManager(context, controller),
            child: const Text('Use an offline model instead'),
          ),
        ),
      ],
    );
  }

  Widget _deepSeekContent(BuildContext context) {
    final ready = controller.deepSeekReady;
    final model = controller.deepSeekModel;
    if (ready) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.cloud_done_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DeepSeek online is ready',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${model.displayName} · online · pay-as-you-go',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const StatusPill(label: 'ONLINE', color: AppColors.blue),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => openDeepSeekSetup(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                  child: const Text('DeepSeek settings'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => showModelPicker(context, controller),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                    backgroundColor: AppColors.teal,
                    foregroundColor: AppColors.navy,
                  ),
                  child: const Text('Change model'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            controller.deepSeekConfig.shareHandoutContext
                ? 'Handout excerpts are included with online questions.'
                : 'Handout context sharing is off by default.',
            style: const TextStyle(
              fontSize: 9.5,
              height: 1.35,
              color: AppColors.muted,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.cloud_queue_rounded,
                color: AppColors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Connect DeepSeek',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            const StatusPill(label: 'API KEY', color: AppColors.amber),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Ask with text, photos, or PDF pages using your own DeepSeek key. '
          'The key stays in secure storage and is never bundled in the app.',
          style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.muted),
        ),
        if (controller.error != null) ...[
          const SizedBox(height: 7),
          Text(
            controller.error!,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: AppColors.red,
            ),
          ),
        ],
        const SizedBox(height: 10),
        FilledButton.icon(
          onPressed: () => openDeepSeekSetup(context),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            backgroundColor: AppColors.blue,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.key_rounded, size: 18),
          label: const Text('Add DeepSeek API key'),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: () => openModelManager(context, controller),
            child: const Text('Use an offline model instead'),
          ),
        ),
      ],
    );
  }

  Widget _localContent(BuildContext context) {
    final selected = controller.selectedModel;
    if (!controller.localAiEnabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.power_settings_new_rounded,
                  color: AppColors.amber,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Local AI is off',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                ),
              ),
              const StatusPill(label: 'PAUSED', color: AppColors.amber),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Downloaded models are kept, but the local model is unloaded from '
            'memory. Turn Local AI on to use offline models again.',
            style: TextStyle(fontSize: 11, height: 1.4, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => controller.setLocalAiEnabled(true),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: AppColors.teal,
              foregroundColor: AppColors.navy,
            ),
            icon: const Icon(Icons.power_settings_new_rounded, size: 17),
            label: const Text('Turn on Local AI'),
          ),
        ],
      );
    }
    final installed = controller.isInstalled(selected);
    if (controller.modelChecking) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Checking installed models…',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      );
    }
    if (controller.downloading) {
      final downloadingSpec = aiModelById(controller.downloadingModelId);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.downloading_rounded,
                size: 18,
                color: AppColors.teal,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  downloadingSpec == null
                      ? 'Downloading model'
                      : 'Downloading ${downloadingSpec.displayName}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${controller.downloadProgress}%',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: controller.downloadProgress / 100,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            controller.downloadStatus,
            style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: controller.cancelDownload,
              child: const Text('Cancel download'),
            ),
          ),
        ],
      );
    }
    if (installed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offline AI is ready',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${selected.displayName} · ${selected.sizeLabel} · English',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => showModelPicker(context, controller),
                child: const Text('Change'),
              ),
            ],
          ),
          if (controller.error != null) ...[
            const SizedBox(height: 6),
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
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.teal,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Choose an offline model',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
            StatusPill(label: defaultAiModel.sizeLabel, color: AppColors.blue),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Recommended: ${defaultAiModel.displayName} · '
          '${defaultAiModel.sizeLabel} · ${defaultAiModel.ramGuide}. '
          'Download over Wi-Fi; the model runs entirely on this phone.',
          style: const TextStyle(
            fontSize: 11,
            height: 1.4,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => controller.selectDeepSeekProvider(),
          icon: const Icon(Icons.cloud_queue_rounded, size: 16),
          label: const Text('Use DeepSeek online instead'),
        ),
        if (controller.error != null) ...[
          const SizedBox(height: 2),
          Text(
            controller.error!,
            style: const TextStyle(
              fontSize: 10.5,
              height: 1.4,
              color: AppColors.red,
            ),
          ),
        ],
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => openModelManager(context, controller),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            backgroundColor: AppColors.teal,
            foregroundColor: AppColors.navy,
          ),
          icon: const Icon(Icons.memory_rounded, size: 18),
          label: const Text('Choose a model'),
        ),
        const SizedBox(height: 6),
        const Text(
          'You can keep using the curated reviewer without AI.',
          style: TextStyle(fontSize: 10, height: 1.35, color: AppColors.muted),
        ),
      ],
    );
  }
}

class ModelSelectorChip extends StatelessWidget {
  const ModelSelectorChip({super.key, required this.controller});

  final AiController controller;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final online = controller.usesCloud;
    final ready = controller.isReady;
    final label = controller.usesCompatible
        ? (controller.compatibleReady
              ? controller.compatibleConfig.displayName
              : 'Custom cloud · setup')
        : controller.usesDeepSeek
        ? (controller.deepSeekReady
              ? controller.deepSeekModel.displayName
              : 'DeepSeek · connect')
        : (controller.selectedModelInstalled
              ? controller.selectedModel.displayName
              : 'Choose model');
    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.surface,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () => showModelPicker(context, controller),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: online
                  ? AppColors.blue.withValues(alpha: 0.35)
                  : (isDark ? AppColors.darkBorder : AppColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                online ? Icons.cloud_queue_rounded : Icons.memory_rounded,
                size: 14,
                color: ready
                    ? (online ? AppColors.blue : AppColors.teal)
                    : AppColors.amber,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 15,
                color: AppColors.muted.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showModelPicker(
  BuildContext context,
  AiController controller,
) async {
  final pageContext = context;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      final installed = controller.catalog
          .where((spec) => controller.isInstalled(spec))
          .toList(growable: false);
      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose AI provider',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Cloud AI uses your own provider key. Offline models run on this phone.',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      Icons.cloud_queue_rounded,
                      size: 17,
                      color: AppColors.blue,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'DeepSeek online',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    StatusPill(
                      label: controller.deepSeekReady
                          ? 'KEY SAVED'
                          : 'KEY NEEDED',
                      color: controller.deepSeekReady
                          ? AppColors.green
                          : AppColors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                for (final spec in deepSeekModels)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      controller.usesDeepSeek &&
                              controller.deepSeekModel.id == spec.id
                          ? Icons.check_circle_rounded
                          : Icons.cloud_outlined,
                      color:
                          controller.usesDeepSeek &&
                              controller.deepSeekModel.id == spec.id
                          ? AppColors.blue
                          : AppColors.muted,
                    ),
                    title: Text(
                      spec.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      spec.description,
                      style: const TextStyle(fontSize: 10.5),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await controller.selectDeepSeekProvider(model: spec);
                      if (!pageContext.mounted) return;
                      if (!controller.deepSeekReady) {
                        openDeepSeekSetup(pageContext);
                      }
                    },
                  ),
                const Divider(height: 16),
                Row(
                  children: [
                    const Icon(
                      Icons.memory_rounded,
                      size: 17,
                      color: AppColors.teal,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Offline models',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    StatusPill(
                      label: '${installed.length} READY',
                      color: installed.isEmpty
                          ? AppColors.amber
                          : AppColors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (installed.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No models are installed yet. Open Models to download one.',
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  )
                else
                  for (final spec in installed)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        !controller.usesDeepSeek &&
                                spec.id == controller.selectedModel.id
                            ? Icons.check_circle_rounded
                            : Icons.memory_rounded,
                        color:
                            !controller.usesDeepSeek &&
                                spec.id == controller.selectedModel.id
                            ? AppColors.teal
                            : AppColors.muted,
                      ),
                      title: Text(
                        spec.displayName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${spec.sizeLabel} · ${spec.ramGuide}',
                        style: const TextStyle(fontSize: 10.5),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        controller.selectModel(spec);
                      },
                    ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.hub_outlined,
                    color: AppColors.blue,
                  ),
                  title: const Text(
                    'OpenAI-compatible cloud',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    controller.compatibleReady
                        ? '${controller.compatibleConfig.displayName} - '
                              '${controller.compatibleConfig.modelId}'
                        : 'Use your own free/custom OpenAI-compatible endpoint.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openCompatibleSetup(pageContext);
                  },
                ),
                for (final profile in controller.compatibleConfig.profiles)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      controller.usesCompatible &&
                              controller.compatibleConfig.activeProfileId ==
                                  profile.id
                          ? Icons.check_circle_rounded
                          : Icons.cloud_outlined,
                      color:
                          controller.usesCompatible &&
                              controller.compatibleConfig.activeProfileId ==
                                  profile.id
                          ? AppColors.blue
                          : AppColors.muted,
                    ),
                    title: Text(
                      profile.displayName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${profile.modelId} ? ${controller.compatibleConfig.maskedKeyFor(profile.id)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await controller.compatibleConfig.selectProfile(
                        profile.id,
                      );
                      await controller.selectCompatibleProvider();
                    },
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.key_rounded, color: AppColors.blue),
                  title: const Text(
                    'DeepSeek settings',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    controller.deepSeekReady
                        ? 'Key ${controller.deepSeekConfig.maskedKey} · balance, model, privacy'
                        : 'Add your API key, choose a model, and check balance.',
                    style: const TextStyle(fontSize: 10.5),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openDeepSeekSetup(pageContext);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.teal,
                  ),
                  title: const Text(
                    'Manage offline models',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Download, use, or delete offline models.',
                    style: TextStyle(fontSize: 10.5),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    openModelManager(pageContext, controller);
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void openDeepSeekSetup(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const DeepSeekSetupScreen()));
}

void openCompatibleSetup(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const OpenAiCompatibleSetupScreen()),
  );
}

void openModelManager(BuildContext context, AiController controller) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AiModelManagerScreen(controller: controller),
    ),
  );
}

class AiChatView extends StatefulWidget {
  const AiChatView({
    super.key,
    required this.controller,
    this.pdfId,
    this.showTermFilter = false,
    this.showSetupCard = false,
    this.showProviderBar = true,
    this.suggestions = const [],
    this.emptyTitle = 'Ask your AI tutor',
    this.emptyMessage =
        'Answers cite the handout page when context is available. '
        'AI can make mistakes — verify with the handout.',
  });

  final AiController controller;
  final String? pdfId;
  final bool showTermFilter;
  final bool showSetupCard;
  final bool showProviderBar;
  final List<String> suggestions;
  final String emptyTitle;
  final String emptyMessage;

  @override
  State<AiChatView> createState() => _AiChatViewState();
}

class _AiChatViewState extends State<AiChatView> {
  final _input = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    widget.controller.initialize();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    final message = (text ?? _input.text).trim();
    final controller = widget.controller;
    if (controller.isStreaming ||
        controller.preparingAttachment ||
        !controller.isReady) {
      return;
    }
    if (message.isEmpty && controller.pendingAttachments.isEmpty) return;
    _input.clear();
    FocusScope.of(context).unfocus();
    controller.ask(message, pdfId: widget.pdfId);
  }

  Future<void> _openAttachments() async {
    final controller = widget.controller;
    if (!controller.usesCloud) {
      await controller.selectDeepSeekProvider();
    }
    if (!mounted) return;
    if (!controller.isReady) {
      if (controller.usesCompatible) {
        openCompatibleSetup(context);
      } else {
        openDeepSeekSetup(context);
      }
      return;
    }
    final pageContext = context;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: Text(
                  'Attach to your question',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'Photos and PDF pages are sent to the selected cloud provider. '
                  'Smaller files get faster, cheaper answers.',
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.4,
                    color: AppColors.muted,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.teal,
                ),
                title: const Text('Choose a photo'),
                subtitle: const Text('JPEG, PNG, GIF, or WebP'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(pageContext, fromCamera: false);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.teal,
                ),
                title: const Text('Take a photo'),
                subtitle: const Text('Use the camera on this phone'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhoto(pageContext, fromCamera: true);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppColors.teal,
                ),
                title: const Text('Choose a PDF'),
                subtitle: const Text(
                  'Text is extracted first; scanned pages are sent as images',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPdf(pageContext);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.description_outlined,
                  color: AppColors.teal,
                ),
                title: const Text('Choose a text file'),
                subtitle: const Text('TXT, Markdown, or CSV'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickText(pageContext);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPhoto(
    BuildContext pageContext, {
    required bool fromCamera,
  }) async {
    final controller = widget.controller;
    try {
      final picked = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final name = picked.name.trim().isEmpty ? 'photo.jpg' : picked.name;
      final added = await controller.addImageAttachment(bytes, name);
      if (!added && pageContext.mounted) {
        _showError(pageContext, controller);
      }
    } catch (error) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Could not read the photo: $error')),
        );
      }
    }
  }

  Future<void> _pickPdf(BuildContext pageContext) async {
    final controller = widget.controller;
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Choose a PDF to attach',
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 48 * 1024 * 1024) {
        if (pageContext.mounted) {
          ScaffoldMessenger.of(pageContext).showSnackBar(
            const SnackBar(
              content: Text('This PDF is over 48 MB. Choose a smaller file.'),
            ),
          );
        }
        return;
      }
      final added = await controller.addPdfAttachment(bytes, picked.name);
      if (!added && pageContext.mounted) {
        _showError(pageContext, controller);
      }
    } catch (error) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Could not read the PDF: $error')),
        );
      }
    }
  }

  Future<void> _pickText(BuildContext pageContext) async {
    final controller = widget.controller;
    try {
      final picked = await FilePicker.pickFile(
        dialogTitle: 'Choose a text file to attach',
        type: FileType.custom,
        allowedExtensions: const ['txt', 'md', 'csv'],
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 250 * 1024) {
        if (pageContext.mounted) {
          ScaffoldMessenger.of(pageContext).showSnackBar(
            const SnackBar(
              content: Text(
                'This text file is too large. Use a file under 250 KB.',
              ),
            ),
          );
        }
        return;
      }
      final text = utf8.decode(bytes, allowMalformed: true);
      controller.addTextAttachment(text, picked.name);
      if (controller.error != null && pageContext.mounted) {
        _showError(pageContext, controller);
      }
    } catch (error) {
      if (pageContext.mounted) {
        ScaffoldMessenger.of(pageContext).showSnackBar(
          SnackBar(content: Text('Could not read the text file: $error')),
        );
      }
    }
  }

  void _showError(BuildContext context, AiController controller) {
    final message = controller.error ?? 'The attachment could not be added.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final terms = scope.session.subject.terms;
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final messages = controller.messages;
        final modelReady = controller.isReady;
        final online = controller.usesCloud;
        return Column(
          children: [
            if (widget.showProviderBar) _ActiveAiBanner(controller: controller),
            if (controller.sessionsEnabled)
              _ChatSessionBar(controller: controller),
            if (widget.showSetupCard && !modelReady)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AiModelCard(controller: controller, compact: true),
              ),
            if (widget.pdfId != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: (online ? AppColors.blue : AppColors.teal)
                        .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (online ? AppColors.blue : AppColors.teal)
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        online
                            ? Icons.cloud_queue_rounded
                            : Icons.phone_android_rounded,
                        size: 16,
                        color: online ? AppColors.blue : AppColors.teal,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          online
                              ? 'Cloud AI uses relevant excerpts from this PDF '
                                    'automatically. No re-upload needed.'
                              : 'This PDF is read automatically and stays on '
                                    'this phone.',
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.35,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      if (online)
                        TextButton(
                          onPressed: () => controller.usesCompatible
                              ? openCompatibleSetup(context)
                              : openDeepSeekSetup(context),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          child: const Text(
                            'Privacy',
                            style: TextStyle(fontSize: 9.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (widget.showTermFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ChoiceChip(
                        label: const Text('All terms'),
                        selected: controller.termFilter.isEmpty,
                        onSelected: (_) => controller.setTermFilter(const {}),
                      ),
                      for (final term in terms)
                        ChoiceChip(
                          label: Text(term.name),
                          selected: controller.termFilter.contains(term.id),
                          onSelected: (selected) {
                            final next = Set<String>.of(controller.termFilter);
                            if (selected) {
                              next.add(term.id);
                            } else {
                              next.remove(term.id);
                            }
                            controller.setTermFilter(next);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: messages.isEmpty
                  ? _EmptyChat(
                      title: widget.emptyTitle,
                      message: widget.emptyMessage,
                      suggestions: widget.suggestions,
                      onSuggestion: _send,
                      modelReady: modelReady,
                      online: online,
                    )
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        return _MessageBubble(message: message);
                      },
                    ),
            ),
            if (controller.pendingAttachments.isNotEmpty ||
                controller.preparingAttachment)
              _AttachmentTray(controller: controller),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Text(
                  controller.error!,
                  style: const TextStyle(fontSize: 10.5, color: AppColors.red),
                ),
              ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkSurface
                    : AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.darkBorder
                        : AppColors.border,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (online)
                          IconButton(
                            tooltip: 'Attach a photo, PDF, or text file',
                            onPressed:
                                modelReady && !controller.preparingAttachment
                                ? _openAttachments
                                : null,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.blue.withValues(
                                alpha: 0.10,
                              ),
                              foregroundColor: AppColors.blue,
                            ),
                            icon: const Icon(
                              Icons.attach_file_rounded,
                              size: 20,
                            ),
                          ),
                        if (online) const SizedBox(width: 6),
                        Expanded(
                          child: TextField(
                            controller: _input,
                            enabled: modelReady,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: InputDecoration(
                              hintText: !modelReady
                                  ? (online
                                        ? '${controller.providerLabel} needs setup'
                                        : 'Download the model to chat')
                                  : (online
                                        ? 'Ask DeepSeek about the handouts…'
                                        : 'Ask about the handouts…'),
                              filled: true,
                              fillColor:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? AppColors.darkBackground
                                  : AppColors.surfaceAlt,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 11,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (controller.isStreaming)
                          IconButton.filled(
                            tooltip: 'Stop',
                            onPressed: controller.stopStreaming,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.stop_rounded),
                          )
                        else
                          IconButton.filled(
                            tooltip: 'Send',
                            onPressed:
                                modelReady && !controller.preparingAttachment
                                ? _send
                                : null,
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              foregroundColor: AppColors.navy,
                            ),
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                      ],
                    ),
                    if (controller.usesDeepSeek) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          FilterChip(
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(
                              Icons.psychology_alt_outlined,
                              size: 15,
                            ),
                            label: const Text(
                              'Thinking',
                              style: TextStyle(fontSize: 10),
                            ),
                            selected: controller.deepSeekThinking,
                            onSelected: controller.setDeepSeekThinking,
                          ),
                          const Spacer(),
                          if (controller.lastUsage != null)
                            Text(
                              '${controller.lastUsage!.totalTokens} tokens last',
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.muted,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      online
                          ? 'Online AI can be wrong. Prompts and attachments go to the selected cloud provider; verify with the handout.'
                          : 'Offline AI can be wrong. Verify every answer with the handout.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveAiBanner extends StatelessWidget {
  const _ActiveAiBanner({required this.controller});

  final AiController controller;

  @override
  Widget build(BuildContext context) {
    final cloud = controller.usesCloud;
    final accent = cloud ? AppColors.blue : AppColors.teal;
    final localStatus = controller.localAiEnabled
        ? (cloud
              ? 'Local model paused while cloud AI is active'
              : 'Runs on this phone')
        : 'Local AI is off ? downloaded models are kept';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 3),
      child: Material(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => showModelPicker(context, controller),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  cloud
                      ? Icons.cloud_queue_rounded
                      : Icons.phone_android_rounded,
                  color: accent,
                  size: 20,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE AI',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        controller.activeModelDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        localStatus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Switch.adaptive(
                      value: controller.localAiEnabled,
                      onChanged: (value) => controller.setLocalAiEnabled(value),
                    ),
                    const Text(
                      'Local',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatSessionBar extends StatelessWidget {
  const _ChatSessionBar({required this.controller});

  final AiController controller;

  Future<void> _showSessions(BuildContext context) async {
    final sessions = await controller.refreshChatSessions();
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Chat sessions',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        controller.startNewSession();
                      },
                      icon: const Icon(Icons.add_comment_outlined, size: 17),
                      label: const Text('New'),
                    ),
                  ],
                ),
              ),
              if (sessions.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Text(
                    'No saved sessions yet. Send a message to create one.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final current = session.id == controller.currentSessionId;
                      return ListTile(
                        leading: Icon(
                          current
                              ? Icons.check_circle_rounded
                              : Icons.chat_bubble_outline_rounded,
                          color: current ? AppColors.teal : AppColors.muted,
                        ),
                        title: Text(
                          session.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          session.preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5),
                        ),
                        trailing: IconButton(
                          tooltip: 'Delete session',
                          onPressed: () async {
                            await controller.deleteChatSession(session.id);
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: AppColors.red,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          controller.openSession(session.id);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 10, 2),
      child: Row(
        children: [
          const Icon(Icons.forum_outlined, size: 14, color: AppColors.muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              controller.currentSessionTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: controller.isStreaming
                ? null
                : () => controller.startNewSession(),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6),
            ),
            icon: const Icon(Icons.add_comment_outlined, size: 15),
            label: const Text('New', style: TextStyle(fontSize: 10)),
          ),
          IconButton(
            tooltip: 'Saved sessions',
            onPressed: controller.isStreaming
                ? null
                : () => _showSessions(context),
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.history_rounded, size: 19),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTray extends StatelessWidget {
  const _AttachmentTray({required this.controller});

  final AiController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.preparingAttachment) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.attachmentStatus,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: controller.cancelAttachmentPreparation,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 10.5)),
                ),
              ],
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(minHeight: 5),
            ),
            const SizedBox(height: 6),
          ],
          if (controller.pendingAttachments.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (
                  var index = 0;
                  index < controller.pendingAttachments.length;
                  index++
                )
                  InputChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      controller.pendingAttachments[index].hasImages
                          ? Icons.image_outlined
                          : Icons.attach_file_rounded,
                      size: 15,
                    ),
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        controller.pendingAttachments[index].label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                    onDeleted: () => controller.removeAttachment(index),
                  ),
              ],
            ),
          for (final attachment in controller.pendingAttachments)
            if (attachment.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  attachment.note,
                  style: const TextStyle(
                    fontSize: 9.5,
                    height: 1.35,
                    color: AppColors.amber,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({
    required this.title,
    required this.message,
    required this.suggestions,
    required this.onSuggestion,
    required this.modelReady,
    required this.online,
  });

  final String title;
  final String message;
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;
  final bool modelReady;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: (online ? AppColors.blue : AppColors.teal).withValues(
                alpha: 0.12,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              online ? Icons.cloud_queue_rounded : Icons.auto_awesome_rounded,
              color: online ? AppColors.blue : AppColors.teal,
              size: 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: AppColors.muted,
            ),
          ),
          if (modelReady && suggestions.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final suggestion in suggestions)
                  ActionChip(
                    label: Text(suggestion),
                    onPressed: () => onSuggestion(suggestion),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasText = message.text.trim().isNotEmpty;
    final accent = message.isError ? AppColors.red : null;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.82 : 0.92),
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.navy
              : accent != null
              ? accent.withValues(alpha: 0.08)
              : (isDark ? AppColors.darkSurface : AppColors.surface),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser
              ? null
              : Border.all(
                  color:
                      accent ??
                      (isDark ? AppColors.darkBorder : AppColors.border),
                ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && message.providerLabel.isNotEmpty) ...[
              Text(
                message.providerLabel,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 3),
            ],
            if (isUser)
              Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.45,
                ),
              )
            else if (hasText)
              SelectableText(
                '${message.text}${message.isStreaming ? '▍' : ''}',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color:
                      accent ??
                      (isDark ? const Color(0xFFE8EEF8) : AppColors.ink),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.isStreaming ? 'Thinking…' : 'No answer.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            if (isUser && message.attachmentLabels.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final label in message.attachmentLabels)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 11,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 3),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 190),
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
            if (!isUser && message.reasoning.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(
                    Icons.psychology_alt_outlined,
                    size: 17,
                    color: AppColors.muted,
                  ),
                  title: const Text(
                    'Reasoning',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(
                        message.reasoning,
                        style: const TextStyle(
                          fontSize: 11,
                          height: 1.45,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isUser && message.citations.isNotEmpty) ...[
              const SizedBox(height: 9),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  for (final chunk in _uniqueCitations(message.citations))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        chunk.sourceLabel,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AppColors.teal,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            if (!isUser && message.usage != null) ...[
              const SizedBox(height: 7),
              Text(
                _usageLabel(message),
                style: const TextStyle(fontSize: 9, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _usageLabel(AiMessage message) {
    final usage = message.usage!;
    final reasoning = usage.reasoningTokens > 0
        ? ' · reasoning ${usage.reasoningTokens}'
        : '';
    return '${usage.totalTokens} tokens · prompt ${usage.promptTokens} · '
        'completion ${usage.completionTokens}$reasoning';
  }

  List<RagChunk> _uniqueCitations(List<RagChunk> citations) {
    final seen = <String>{};
    final result = <RagChunk>[];
    for (final chunk in citations) {
      if (seen.add(chunk.sourceLabel)) result.add(chunk);
    }
    return result;
  }
}
