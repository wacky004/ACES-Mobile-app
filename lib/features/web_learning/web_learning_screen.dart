import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_all/webview_all.dart';

import '../../core/layout.dart';
import '../../core/theme.dart';
import 'web_learning_resource.dart';

class WebLearningScreen extends StatefulWidget {
  const WebLearningScreen({super.key, required this.resource});

  final WebLearningResource resource;

  @override
  State<WebLearningScreen> createState() => _WebLearningScreenState();
}

class _WebLearningScreenState extends State<WebLearningScreen> {
  late final WebViewController _controller;
  late final Uri _initialUri;
  late final String _allowedHost;

  bool _ready = false;
  bool _loading = true;
  int _progress = 0;
  bool _canGoBack = false;
  bool _canGoForward = false;
  late String _currentUrl;
  String? _error;
  bool _webViewRuntimeMissing = false;

  @override
  void initState() {
    super.initState();
    _initialUri = Uri.parse(widget.resource.url);
    _allowedHost = _initialUri.host;
    _currentUrl = widget.resource.url;
    _controller = WebViewController();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await _controller.setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: (url) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _error = null;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) {
            if (!mounted) return;
            setState(() {
              _loading = false;
              _currentUrl = url;
            });
            unawaited(_refreshHistory());
          },
          onProgress: (progress) {
            if (!mounted) return;
            setState(() {
              _progress = progress;
              if (progress < 100) _loading = true;
            });
          },
          onUrlChange: (change) {
            if (!mounted || change.url == null) return;
            setState(() {
              _currentUrl = change.url!;
              _error = null;
            });
            unawaited(_refreshHistory());
          },
          onWebResourceError: (error) {
            if (!mounted || error.isForMainFrame != true) return;
            setState(() {
              _loading = false;
              _error =
                  '${widget.resource.title} could not be loaded. '
                  'Check your internet connection and try again.';
            });
          },
        ),
      );
      await _controller.loadRequest(_initialUri);
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _loading = false;
        _webViewRuntimeMissing = Platform.isWindows;
        _error =
            'The in-app browser could not start. '
            '${Platform.isWindows ? 'Install the Microsoft Edge WebView2 Runtime and try again.' : 'Try opening the site in your browser.'}';
      });
    }
  }

  Future<NavigationDecision> _onNavigationRequest(
    NavigationRequest request,
  ) async {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (uri.scheme == 'https' && uri.host == _allowedHost) {
      return NavigationDecision.navigate;
    }
    if (uri.scheme == 'http' ||
        uri.scheme == 'https' ||
        uri.scheme == 'mailto') {
      await _openInBrowser(uri);
    }
    return NavigationDecision.prevent;
  }

  Future<void> _refreshHistory() async {
    try {
      final canBack = await _controller.canGoBack();
      final canForward = await _controller.canGoForward();
      if (!mounted) return;
      setState(() {
        _canGoBack = canBack;
        _canGoForward = canForward;
      });
    } catch (_) {}
  }

  Future<void> _handleBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _loading = true;
      _webViewRuntimeMissing = false;
    });
    try {
      await _controller.loadRequest(Uri.parse(_currentUrl));
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not reload ${widget.resource.title}.';
        });
      }
    }
  }

  Future<void> _openInBrowser([Uri? uri]) async {
    final target = uri ?? Uri.parse(_currentUrl);
    final opened = await launchUrl(
      target,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open browser.')));
    }
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: widget.resource.title,
      applicationVersion: 'by Dilum Sanjaya',
      applicationIcon: Icon(
        widget.resource.icon,
        size: 44,
        color: widget.resource.accent,
      ),
      children: [
        Text(widget.resource.about),
        const SizedBox(height: 10),
        const Text(
          'This screen loads the live public website and requires internet.',
          style: TextStyle(fontSize: 11.5, color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => _openInBrowser(_initialUri),
          icon: const Icon(Icons.open_in_new_rounded, size: 17),
          label: const Text('Open in browser'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = AppLayout.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) unawaited(_handleBack());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.resource.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'by Dilum Sanjaya',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          actions: [
            if (desktop) ...[
              IconButton(
                tooltip: 'Back in lesson',
                onPressed: _canGoBack ? () => _controller.goBack() : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Forward in lesson',
                onPressed: _canGoForward ? () => _controller.goForward() : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
            IconButton(
              tooltip: 'Reload',
              onPressed: _loading ? null : () => _controller.reload(),
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Open in browser',
              onPressed: () => _openInBrowser(),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
            IconButton(
              tooltip: 'About ${widget.resource.title}',
              onPressed: _showAbout,
              icon: const Icon(Icons.info_outline_rounded),
            ),
          ],
          bottom: _loading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress / 100 : null,
                    minHeight: 2,
                  ),
                )
              : null,
        ),
        body: ColoredBox(
          color: isDark ? AppColors.darkBackground : AppColors.surfaceAlt,
          child: _error != null
              ? _errorView()
              : _ready
              ? WebViewWidget(controller: _controller)
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.public_off_rounded,
                size: 54,
                color: widget.resource.accent,
              ),
              const SizedBox(height: 14),
              Text(
                '${widget.resource.title} is offline',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Check your internet connection and try again.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try again'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _openInBrowser(),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open in browser'),
                  ),
                  if (_webViewRuntimeMissing && Platform.isWindows)
                    TextButton(
                      onPressed: () => _openInBrowser(
                        Uri.parse(
                          'https://go.microsoft.com/fwlink/p/?LinkId=2124703',
                        ),
                      ),
                      child: const Text('Install WebView2'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
