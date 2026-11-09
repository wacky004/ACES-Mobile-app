import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../data/openai_compatible_config.dart';
import '../../models/deepseek_models.dart';
import 'prompt_builder.dart';

class OpenAiCompatibleService {
  OpenAiCompatibleService({
    OpenAiCompatibleConfig? config,
    http.Client Function()? clientFactory,
  })  : _config = config ?? OpenAiCompatibleConfig.instance,
        _clientFactory = clientFactory ?? http.Client.new;

  final OpenAiCompatibleConfig _config;
  final http.Client Function() _clientFactory;
  http.Client? _activeClient;
  bool _stopped = false;

  Future<void> testConnection({String? apiKey}) async {
    final key = _resolveKey(apiKey);
    final client = _clientFactory();
    try {
      final response = await client
          .get(
            Uri.parse(_config.modelsUrl),
            headers: {'Authorization': 'Bearer $key'},
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw _errorFromResponse(response.statusCode, response.body);
      }
    } on TimeoutException {
      throw const DeepSeekException(
        'The provider did not respond. Check the base URL and connection.',
      );
    } finally {
      client.close();
    }
  }

  Stream<DeepSeekChunk> chat({
    required String systemPrompt,
    required String userPrompt,
    List<ChatTurn> history = const [],
    List<DeepSeekAttachment> attachments = const [],
    bool jsonMode = false,
    int maxOutputTokens = 1600,
    String? apiKey,
  }) async* {
    _stopped = false;
    final key = _resolveKey(apiKey);
    final hasImages = attachments.any((item) => item.hasImages);
    if (hasImages && !_config.supportsVision) {
      throw const DeepSeekException(
        'This provider is configured as text-only. Enable image support in '
        'its settings only if the selected model accepts images.',
      );
    }
    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
      for (final turn in _trimHistory(history))
        {'role': turn.isUser ? 'user' : 'assistant', 'content': turn.text},
      {'role': 'user', 'content': _buildUserContent(userPrompt, attachments)},
    ];
    final body = <String, dynamic>{
      'model': _config.modelId,
      'messages': messages,
      'stream': true,
      'max_tokens': maxOutputTokens,
      'temperature': 0.2,
    };
    if (jsonMode && _config.supportsJson) {
      body['response_format'] = {'type': 'json_object'};
    }
    final encodedBody = jsonEncode(body);
    if (encodedBody.length > 47 * 1024 * 1024) {
      throw const DeepSeekException(
        'The request is too large for this provider. Remove an attachment.',
      );
    }
    final request = http.Request('POST', Uri.parse(_config.chatUrl))
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
      await for (final line in response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (_stopped) break;
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty || data == '[DONE]') continue;
        final decoded = jsonDecode(data);
        if (decoded is! Map<String, dynamic>) continue;
        final choices = decoded['choices'] as List<dynamic>? ?? const [];
        final usage = decoded['usage'];
        final chunkUsage = usage is Map
            ? DeepSeekUsage.fromJson(usage.cast<String, dynamic>())
            : null;
        if (choices.isNotEmpty) {
          final first = (choices.first as Map).cast<String, dynamic>();
          final delta = (first['delta'] as Map?)?.cast<String, dynamic>();
          final content = delta?['content'] as String?;
          final reasoning = delta?['reasoning_content'] as String?;
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
      throw DeepSeekException('Could not reach the provider: ${error.message}');
    } on TimeoutException {
      if (_stopped) return;
      throw const DeepSeekException(
        'The provider did not respond. Check the endpoint and connection.',
      );
    } catch (error) {
      if (_stopped) return;
      throw DeepSeekException('Provider request failed: $error');
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

  String _resolveKey(String? override) {
    final key = override?.trim().isNotEmpty == true
        ? override!.trim()
        : _config.apiKey?.trim() ?? '';
    if (key.isEmpty) {
      throw const DeepSeekException(
        'Add an API key for the custom cloud provider in Settings.',
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
              'url': 'data:${attachment.mimeType};base64,${base64Encode(bytes)}',
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
              'text': '\n[PDF: ${attachment.filename} - page text]\n$text',
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
      401 => 'The custom provider API key is invalid.',
      402 => 'The custom provider account has insufficient credit.',
      429 => 'The custom provider rate limit was reached. Wait and retry.',
      404 => 'The endpoint was not found. Check the base URL and model ID.',
      >= 500 => 'Custom provider server error ($status). Try again shortly.',
      _ => apiMessage ?? 'Custom provider request failed (HTTP $status).',
    };
    return DeepSeekException(message, statusCode: status);
  }
}
