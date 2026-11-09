import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/deepseek_config.dart';
import '../../models/deepseek_models.dart';
import 'prompt_builder.dart';

class DeepSeekService {
  DeepSeekService({
    DeepSeekConfig? config,
    http.Client Function()? clientFactory,
  }) : _config = config ?? DeepSeekConfig.instance,
       _clientFactory = clientFactory ?? http.Client.new;

  final DeepSeekConfig _config;
  final http.Client Function() _clientFactory;
  http.Client? _activeClient;
  bool _stopped = false;

  String get _baseUrl => 'https://api.deepseek.com';

  Future<DeepSeekBalance> balance({String? apiKey}) async {
    final key = await _resolveKey(apiKey);
    final client = _clientFactory();
    try {
      final response = await client
          .get(
            Uri.parse('$_baseUrl/user/balance'),
            headers: {'Authorization': 'Bearer $key'},
          )
          .timeout(const Duration(seconds: 25));
      if (response.statusCode != 200) {
        throw _errorFromResponse(response.statusCode, response.body);
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final infos = (decoded['balance_infos'] as List<dynamic>? ?? const [])
          .map((item) => (item as Map).cast<String, dynamic>())
          .toList(growable: false);
      final first = infos.isEmpty ? const <String, dynamic>{} : infos.first;
      return DeepSeekBalance(
        isAvailable: decoded['is_available'] as bool? ?? false,
        currency: first['currency'] as String? ?? '',
        totalBalance: first['total_balance'] as String? ?? '0',
        grantedBalance: first['granted_balance'] as String? ?? '0',
        toppedUpBalance: first['topped_up_balance'] as String? ?? '0',
      );
    } on TimeoutException {
      throw const DeepSeekException(
        'DeepSeek did not respond. Check your connection and try again.',
      );
    } finally {
      client.close();
    }
  }

  Stream<DeepSeekChunk> chat({
    required DeepSeekModelSpec model,
    required String systemPrompt,
    required String userPrompt,
    List<ChatTurn> history = const [],
    List<DeepSeekAttachment> attachments = const [],
    bool thinking = false,
    String reasoningEffort = 'high',
    bool jsonMode = false,
    int maxOutputTokens = 1200,
    String? apiKey,
  }) async* {
    _stopped = false;
    final key = await _resolveKey(apiKey);
    if (attachments.isNotEmpty && attachments.any((item) => item.hasImages)) {
      if (!model.supportsVision) {
        throw DeepSeekException(
          '${model.displayName} does not support images. Use DeepSeek Flash '
          'for photos or PDF page images.',
        );
      }
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      for (final turn in _trimHistory(history))
        {'role': turn.isUser ? 'user' : 'assistant', 'content': turn.text},
      {'role': 'user', 'content': _buildUserContent(userPrompt, attachments)},
    ];

    final body = <String, dynamic>{
      'model': model.id,
      'messages': messages,
      'stream': true,
      'max_tokens': maxOutputTokens,
      'thinking': {'type': thinking ? 'enabled' : 'disabled'},
    };
    if (thinking) {
      body['reasoning_effort'] = reasoningEffort;
    } else {
      body['temperature'] = 0.2;
    }
    if (jsonMode) {
      body['response_format'] = {'type': 'json_object'};
    }

    final encodedBody = jsonEncode(body);
    if (encodedBody.length > 47 * 1024 * 1024) {
      throw const DeepSeekException(
        'The request is too large for DeepSeek. Remove an attachment or '
        'send fewer PDF pages.',
      );
    }

    final request =
        http.Request('POST', Uri.parse('$_baseUrl/chat/completions'))
          ..headers['Authorization'] = 'Bearer $key'
          ..headers['Content-Type'] = 'application/json'
          ..headers['Accept'] = 'text/event-stream'
          ..body = encodedBody;

    final client = _clientFactory();
    _activeClient = client;
    try {
      final response = await client
          .send(request)
          .timeout(const Duration(seconds: 60));
      if (response.statusCode != 200) {
        final text = await response.stream.bytesToString();
        throw _errorFromResponse(response.statusCode, text);
      }
      await for (final line
          in response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())) {
        if (_stopped) break;
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty) continue;
        if (data == '[DONE]') break;
        final decoded = jsonDecode(data);
        if (decoded is! Map<String, dynamic>) continue;
        final choices = decoded['choices'] as List<dynamic>? ?? const [];
        final usage = decoded['usage'];
        if (choices.isNotEmpty) {
          final first = (choices.first as Map).cast<String, dynamic>();
          final delta = (first['delta'] as Map?)?.cast<String, dynamic>();
          final content = delta?['content'] as String?;
          final reasoning = delta?['reasoning_content'] as String?;
          final chunkUsage = usage is Map
              ? DeepSeekUsage.fromJson(usage.cast<String, dynamic>())
              : null;
          if ((content != null && content.isNotEmpty) ||
              (reasoning != null && reasoning.isNotEmpty) ||
              chunkUsage != null) {
            yield DeepSeekChunk(
              content: content,
              reasoning: reasoning,
              usage: chunkUsage,
            );
          }
        }
      }
    } on DeepSeekException {
      rethrow;
    } on http.ClientException catch (error) {
      if (_stopped) return;
      throw DeepSeekException('Could not reach DeepSeek: ${error.message}');
    } on TimeoutException {
      if (_stopped) return;
      throw const DeepSeekException(
        'DeepSeek did not respond. Check your connection and try again.',
      );
    } catch (error) {
      if (_stopped) return;
      throw DeepSeekException('DeepSeek request failed: $error');
    } finally {
      _activeClient = null;
      client.close();
    }
  }

  Future<void> stop() async {
    _stopped = true;
    _activeClient?.close();
    _activeClient = null;
  }

  Future<String> _resolveKey(String? override) async {
    if (override != null && override.trim().isNotEmpty) return override.trim();
    await _config.load();
    final key = _config.apiKey?.trim() ?? '';
    if (key.isEmpty) {
      throw const DeepSeekException(
        'Add your DeepSeek API key in Settings first.',
      );
    }
    return key;
  }

  List<ChatTurn> _trimHistory(List<ChatTurn> history) {
    if (history.length <= 8) return history;
    return history.sublist(history.length - 8);
  }

  List<Map<String, dynamic>> _buildUserContent(
    String prompt,
    List<DeepSeekAttachment> attachments,
  ) {
    final parts = <Map<String, dynamic>>[
      {'type': 'text', 'text': prompt},
    ];
    for (final attachment in attachments) {
      switch (attachment.kind) {
        case DeepSeekAttachmentKind.image:
          final bytes = attachment.bytes;
          if (bytes == null) continue;
          parts.add({
            'type': 'image_url',
            'image_url': {
              'url':
                  'data:${attachment.mimeType};base64,${base64Encode(bytes)}',
              'detail': attachment.highDetail ? 'high' : 'low',
            },
          });
        case DeepSeekAttachmentKind.text:
          final text = attachment.text;
          if (text == null || text.trim().isEmpty) continue;
          parts.add({
            'type': 'text',
            'text': '\n[Attached text file: ${attachment.filename}]\n$text',
          });
        case DeepSeekAttachmentKind.pdf:
          final text = attachment.text;
          if (text != null && text.trim().isNotEmpty) {
            parts.add({
              'type': 'text',
              'text': '\n[PDF: ${attachment.filename} · page text]\n$text',
            });
          }
          for (final page in attachment.pageImages) {
            parts.add({
              'type': 'text',
              'text': '\n[PDF page ${page.page} of ${attachment.filename}]',
            });
            parts.add({
              'type': 'image_url',
              'image_url': {
                'url': 'data:image/jpeg;base64,${base64Encode(page.bytes)}',
                'detail': 'high',
              },
            });
          }
      }
    }
    return parts;
  }

  DeepSeekException _errorFromResponse(int status, String body) {
    String? apiMessage;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['error'] is Map) {
        apiMessage = (decoded['error'] as Map)['message'] as String?;
      }
    } catch (_) {}
    final message = switch (status) {
      401 => 'DeepSeek API key is invalid. Check it in Settings.',
      402 => 'DeepSeek balance is insufficient. Top up your account.',
      429 => 'DeepSeek rate limit reached. Wait a moment and retry.',
      400 => apiMessage ?? 'DeepSeek rejected the request (400).',
      413 => 'The request is too large for DeepSeek. Use a smaller PDF/photo.',
      >= 500 => 'DeepSeek server error ($status). Try again shortly.',
      _ => apiMessage ?? 'DeepSeek request failed (HTTP $status).',
    };
    return DeepSeekException(message, statusCode: status);
  }
}
