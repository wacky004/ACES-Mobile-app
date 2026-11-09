import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme.dart';
import '../../../data/deepseek_config.dart';
import '../../../models/deepseek_models.dart';
import '../../../services/ai/deepseek_service.dart';
import '../../../widgets/ui_kit.dart';

class DeepSeekSetupScreen extends StatefulWidget {
  const DeepSeekSetupScreen({super.key});

  @override
  State<DeepSeekSetupScreen> createState() => _DeepSeekSetupScreenState();
}

class _DeepSeekSetupScreenState extends State<DeepSeekSetupScreen> {
  static const _keysUrl = 'https://platform.deepseek.com/api_keys';
  static const _billingUrl = 'https://platform.deepseek.com/top_up';

  final DeepSeekConfig _config = DeepSeekConfig.instance;
  final DeepSeekService _service = DeepSeekService();
  final TextEditingController _keyInput = TextEditingController();

  bool _loading = true;
  bool _obscure = true;
  bool _saving = false;
  bool _checking = false;
  String _modelId = 'deepseek-flash';
  bool _shareHandoutContext = false;
  String? _message;
  bool _messageIsError = false;
  DeepSeekBalance? _balance;

  @override
  void initState() {
    super.initState();
    _config.load().then((_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _modelId = _config.model.id;
        _shareHandoutContext = _config.shareHandoutContext;
      });
    });
  }

  @override
  void dispose() {
    _keyInput.dispose();
    super.dispose();
  }

  void _setMessage(String message, {bool isError = false}) {
    setState(() {
      _message = message;
      _messageIsError = isError;
      if (isError) _balance = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final entered = _keyInput.text.trim();
    if (entered.isEmpty && !_config.hasKey) {
      _setMessage('Enter your DeepSeek API key first.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      if (entered.isNotEmpty) {
        await _config.saveKey(entered);
        _keyInput.clear();
      }
      await _config.setModel(_modelId);
      await _config.setShareHandoutContext(_shareHandoutContext);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _balance = null;
      });
      _setMessage(
        entered.isNotEmpty
            ? 'API key saved securely on this device.'
            : 'Settings saved.',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _setMessage('Could not save the key: $error', isError: true);
    }
  }

  Future<void> _checkBalance() async {
    if (_checking) return;
    final entered = _keyInput.text.trim();
    if (entered.isEmpty && !_config.hasKey) {
      _setMessage('Enter or save an API key first.', isError: true);
      return;
    }
    setState(() {
      _checking = true;
      _balance = null;
      _message = null;
    });
    try {
      final balance = await _service.balance(
        apiKey: entered.isEmpty ? null : entered,
      );
      if (!mounted) return;
      setState(() {
        _balance = balance;
        _checking = false;
        _message = balance.isAvailable
            ? 'Connected to DeepSeek.'
            : 'The key works, but the account balance is unavailable.';
        _messageIsError = !balance.isAvailable;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _checking = false);
      _setMessage('$error', isError: true);
    }
  }

  Future<void> _clearKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove the DeepSeek key?'),
        content: const Text(
          'Online AI will stop working until you add another key. '
          'Offline models and your study data are not affected.',
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
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _config.clearKey();
    if (!mounted) return;
    setState(() {
      _balance = null;
      _message = null;
    });
    _setMessage('DeepSeek key removed.');
  }

  Future<void> _openUrl(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      _setMessage('Could not open the link. Visit $url', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('DeepSeek online AI')),
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
                      color: AppColors.teal.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.teal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(
                            Icons.cloud_done_rounded,
                            color: AppColors.teal,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bring your own DeepSeek key',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Online AI for text, photos, and PDF pages. '
                                'Usage is billed by DeepSeek to your account.',
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
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              label: _config.hasKey ? 'KEY SAVED' : 'NOT SET',
                              color: _config.hasKey
                                  ? AppColors.green
                                  : AppColors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _config.hasKey
                              ? 'Saved key: ${_config.maskedKey}'
                              : 'No key is saved on this device.',
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _keyInput,
                          obscureText: _obscure,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.visiblePassword,
                          decoration: InputDecoration(
                            labelText: _config.hasKey
                                ? 'Replace API key (optional)'
                                : 'DeepSeek API key',
                            hintText: 'sk-…',
                            helperText: _config.hasKey
                                ? 'Leave blank to keep the saved key.'
                                : 'Starts with sk-. Stored in secure storage.',
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Show key' : 'Hide key',
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
                                  backgroundColor: AppColors.teal,
                                  foregroundColor: AppColors.navy,
                                ),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.lock_rounded, size: 17),
                                label: Text(_saving ? 'Saving…' : 'Save key'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: _checking ? null : _checkBalance,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 44),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                              ),
                              child: _checking
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Check balance'),
                            ),
                          ],
                        ),
                        if (_balance != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.green.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Available: ${_balance!.currency} '
                              '${_balance!.totalBalance} · '
                              'granted ${_balance!.grantedBalance} · '
                              'topped up ${_balance!.toppedUpBalance}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.4,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openUrl(_keysUrl),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                size: 15,
                              ),
                              label: const Text('Get an API key'),
                            ),
                            TextButton.icon(
                              onPressed: () => _openUrl(_billingUrl),
                              icon: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 15,
                              ),
                              label: const Text('Billing / top up'),
                            ),
                          ],
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
                        height: 1.4,
                        color: _messageIsError
                            ? AppColors.red
                            : AppColors.green,
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
                          'Online model',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Flash accepts photos and rendered PDF pages. '
                          'V4 Pro is text-only but gives stronger answers.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.4,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        for (final model in deepSeekModels)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            leading: Icon(
                              _modelId == model.id
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: _modelId == model.id
                                  ? AppColors.blue
                                  : AppColors.muted,
                              size: 20,
                            ),
                            title: Text(
                              model.displayName,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              model.description,
                              style: const TextStyle(
                                fontSize: 10.5,
                                height: 1.35,
                              ),
                            ),
                            onTap: () async {
                              setState(() => _modelId = model.id);
                              await _config.setModel(model.id);
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Handout context',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _shareHandoutContext,
                          onChanged: (value) {
                            setState(() => _shareHandoutContext = value);
                            _config.setShareHandoutContext(value);
                          },
                          title: const Text(
                            'Include matching handout excerpts',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: const Text(
                            'Off by default for the main tutor. In a PDF '
                            'chat, relevant excerpts from that PDF are always '
                            'sent automatically; this switch only controls the '
                            'built-in handouts in the main tutor.',
                            style: TextStyle(fontSize: 10.5, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.shield_outlined,
                              size: 18,
                              color: AppColors.teal,
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'Privacy and security',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            if (_config.hasKey)
                              TextButton(
                                onPressed: _clearKey,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.red,
                                  visualDensity: VisualDensity.compact,
                                ),
                                child: const Text('Remove key'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'The key is stored with Android secure storage and '
                          'is never bundled in the app. Online requests go '
                          'directly to DeepSeek. Prompts, photos, PDF pages, '
                          'PDF excerpts used in a PDF chat, and any enabled '
                          'tutor handout excerpts are sent to DeepSeek. '
                          'The web version has no AI.',
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.45,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'DeepSeek is a third-party service with its own terms, '
                    'pricing, and data policies. Review every AI answer with '
                    'the original handout.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.4,
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
