import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/openai_compatible_config.dart';
import '../../../services/ai/openai_compatible_service.dart';
import '../../../widgets/ui_kit.dart';

class OpenAiCompatibleSetupScreen extends StatefulWidget {
  const OpenAiCompatibleSetupScreen({super.key});

  @override
  State<OpenAiCompatibleSetupScreen> createState() =>
      _OpenAiCompatibleSetupScreenState();
}

class _OpenAiCompatibleSetupScreenState
    extends State<OpenAiCompatibleSetupScreen> {
  final _config = OpenAiCompatibleConfig.instance;
  final _service = OpenAiCompatibleService();
  final _baseUrl = TextEditingController();
  final _modelId = TextEditingController();
  final _displayName = TextEditingController();
  final _key = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  bool _obscure = true;
  bool _vision = false;
  bool _json = true;
  bool _shareContext = false;
  String? _message;
  bool _messageError = false;

  @override
  void initState() {
    super.initState();
    _config.load().then((_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _baseUrl.text = _config.baseUrl;
        _modelId.text = _config.modelId;
        _displayName.text = _config.displayName;
        _vision = _config.supportsVision;
        _json = _config.supportsJson;
        _shareContext = _config.shareHandoutContext;
      });
    });
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _modelId.dispose();
    _displayName.dispose();
    _key.dispose();
    super.dispose();
  }

  void _setMessage(String message, {bool error = false}) {
    setState(() {
      _message = message;
      _messageError = error;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_modelId.text.trim().isEmpty || _baseUrl.text.trim().isEmpty) {
      _setMessage('Enter a base URL and model ID first.', error: true);
      return;
    }
    if (_key.text.trim().isEmpty && !_config.hasKey) {
      _setMessage('Enter an API key first.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      if (_key.text.trim().isNotEmpty) {
        await _config.saveKey(_key.text);
        _key.clear();
      }
      await _config.saveSettings(
        baseUrl: _baseUrl.text,
        modelId: _modelId.text,
        displayName: _displayName.text,
        supportsVision: _vision,
        supportsJson: _json,
        shareHandoutContext: _shareContext,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      _setMessage('Custom cloud provider saved.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _setMessage('Could not save: $error', error: true);
    }
  }

  Future<void> _test() async {
    if (_testing) return;
    if (_key.text.trim().isEmpty && !_config.hasKey) {
      _setMessage('Enter an API key first.', error: true);
      return;
    }
    setState(() => _testing = true);
    try {
      await _service.testConnection(
        apiKey: _key.text.trim().isEmpty ? null : _key.text,
      );
      if (!mounted) return;
      setState(() => _testing = false);
      _setMessage('Connection successful.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _testing = false);
      _setMessage('$error', error: true);
    }
  }

  Future<void> _clearKey() async {
    await _config.clearKey();
    if (!mounted) return;
    setState(() {});
    _setMessage('API key removed.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('OpenAI-compatible cloud')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.blue.withValues(alpha: 0.22),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.hub_outlined,
                          color: AppColors.blue,
                          size: 22,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Use your own OpenAI-compatible endpoint and key. '
                            'This app never bundles a provider key or reuses '
                            'OpenCode credentials.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.4,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    isDark: isDark,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Connection',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            StatusPill(
                              label: _config.hasKey ? 'KEY SAVED' : 'NO KEY',
                              color: _config.hasKey
                                  ? AppColors.green
                                  : AppColors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _baseUrl,
                          decoration: InputDecoration(
                            labelText: 'Base URL',
                            hintText: 'https://openrouter.ai/api/v1',
                            helperText:
                                'Use the full OpenAI-compatible API base URL.',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _modelId,
                          decoration: InputDecoration(
                            labelText: 'Model ID',
                            hintText: 'provider/model-name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _displayName,
                          decoration: InputDecoration(
                            labelText: 'Display name',
                            hintText: 'Custom cloud AI',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _key,
                          obscureText: _obscure,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            labelText: _config.hasKey
                                ? 'Replace API key (optional)'
                                : 'API key',
                            helperText: _config.hasKey
                                ? 'Saved key: ${_config.maskedKey}'
                                : 'Stored in secure storage.',
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _save,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(44),
                                  backgroundColor: AppColors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                icon: const Icon(Icons.save_outlined, size: 17),
                                label: Text(_saving ? 'Saving...' : 'Save'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _testing ? null : _test,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                              ),
                              child: _testing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Test'),
                            ),
                          ],
                        ),
                        if (_config.hasKey)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: _clearKey,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.red,
                              ),
                              child: const Text('Remove key'),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _message!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _messageError ? AppColors.red : AppColors.green,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  _Panel(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Capabilities',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _vision,
                          onChanged: (value) => setState(() => _vision = value),
                          title: const Text(
                            'Model accepts images',
                            style: TextStyle(fontSize: 12.5),
                          ),
                          subtitle: const Text(
                            'Enable only if the selected free/custom model '
                            'actually supports image input.',
                            style: TextStyle(fontSize: 10.5),
                          ),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _json,
                          onChanged: (value) => setState(() => _json = value),
                          title: const Text(
                            'Supports JSON output',
                            style: TextStyle(fontSize: 12.5),
                          ),
                          subtitle: const Text(
                            'Used for draft question generation. Disable if the '
                            'endpoint rejects response_format.',
                            style: TextStyle(fontSize: 10.5),
                          ),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _shareContext,
                          onChanged: (value) =>
                              setState(() => _shareContext = value),
                          title: const Text(
                            'Include tutor handout excerpts',
                            style: TextStyle(fontSize: 12.5),
                          ),
                          subtitle: const Text(
                            'PDF chats always use relevant excerpts from the '
                            'opened PDF automatically. This switch only affects '
                            'the main tutor.',
                            style: TextStyle(fontSize: 10.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Free tiers still require an account and API key. Rate '
                    'limits and model availability are controlled by the '
                    'provider. OpenCode credentials are not reused.',
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
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: child,
    );
  }
}
