import 'dart:convert';
import 'dart:typed_data';

import 'package:cpe_reviewer/models/deepseek_models.dart';
import 'package:cpe_reviewer/services/ai/deepseek_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('balance parses the DeepSeek balance response', () async {
    late http.Request captured;
    final service = DeepSeekService(
      clientFactory: () => MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'is_available': true,
            'balance_infos': [
              {
                'currency': 'USD',
                'total_balance': '10.00',
                'granted_balance': '1.00',
                'topped_up_balance': '9.00',
              },
            ],
          }),
          200,
        );
      }),
    );

    final balance = await service.balance(apiKey: 'sk-test');

    expect(captured.url.toString(), 'https://api.deepseek.com/user/balance');
    expect(captured.headers['Authorization'], 'Bearer sk-test');
    expect(balance.isAvailable, isTrue);
    expect(balance.currency, 'USD');
    expect(balance.totalBalance, '10.00');
    expect(balance.toppedUpBalance, '9.00');
  });

  test('chat sends text, vision image, thinking, and usage', () async {
    late Map<String, dynamic> body;
    final service = DeepSeekService(
      clientFactory: () => MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          [
            'data: {"choices":[{"delta":{"reasoning_content":"Let me think."}}]}',
            'data: {"choices":[{"delta":{"content":"Hello"}}]}',
            'data: {"choices":[{"delta":{},"finish_reason":"stop"}],'
                '"usage":{"prompt_tokens":10,"completion_tokens":4,'
                '"total_tokens":14,"completion_tokens_details":{"reasoning_tokens":2}}}',
            'data: [DONE]',
            '',
          ].join('\n'),
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
    );

    final chunks = await service
        .chat(
          model: deepSeekModels.first,
          systemPrompt: 'system',
          userPrompt: 'What is this?',
          attachments: [
            DeepSeekAttachment(
              kind: DeepSeekAttachmentKind.image,
              filename: 'photo.jpg',
              bytes: Uint8List.fromList([1, 2, 3]),
            ),
          ],
          thinking: true,
          apiKey: 'sk-test',
        )
        .toList();

    expect(body['model'], 'deepseek-flash');
    expect(body['stream'], isTrue);
    expect(body['max_tokens'], 1200);
    expect(body['thinking'], {'type': 'enabled'});
    expect(body['reasoning_effort'], 'high');
    expect(body['response_format'], isNull);
    expect(body['messages'], isA<List>());

    final user = (body['messages'] as List).last as Map<String, dynamic>;
    final parts = user['content'] as List;
    expect(parts.first['type'], 'text');
    expect(parts.first['text'], 'What is this?');
    expect(parts[1]['type'], 'image_url');
    expect(parts[1]['image_url']['url'], startsWith('data:image/jpeg;base64,'));
    expect(parts[1]['image_url']['detail'], 'low');

    expect(
      chunks.map((chunk) => chunk.reasoning).whereType<String>(),
      contains('Let me think.'),
    );
    expect(
      chunks.map((chunk) => chunk.content).whereType<String>(),
      contains('Hello'),
    );
    final usage = chunks.last.usage;
    expect(usage, isNotNull);
    expect(usage!.totalTokens, 14);
    expect(usage.reasoningTokens, 2);
  });

  test('chat requests JSON mode and disables thinking', () async {
    late Map<String, dynamic> body;
    final service = DeepSeekService(
      clientFactory: () => MockClient((request) async {
        body = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          'data: {"choices":[{"delta":{"content":"{}"}}]}\n'
          'data: {"choices":[{"delta":{},"finish_reason":"stop"}],'
          '"usage":{"prompt_tokens":1,"completion_tokens":1,"total_tokens":2}}\n'
          'data: [DONE]\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
    );

    await service
        .chat(
          model: deepSeekModels.last,
          systemPrompt: 'Return JSON.',
          userPrompt: 'Create questions.',
          jsonMode: true,
          apiKey: 'sk-test',
        )
        .toList();

    expect(body['model'], 'deepseek-v4-pro');
    expect(body['thinking'], {'type': 'disabled'});
    expect(body['response_format'], {'type': 'json_object'});
    expect(body['temperature'], 0.2);
  });

  test('images are rejected for v4 pro before sending', () async {
    var called = false;
    final service = DeepSeekService(
      clientFactory: () => MockClient((request) async {
        called = true;
        return http.Response('{}', 200);
      }),
    );

    await expectLater(
      service
          .chat(
            model: deepSeekModels.last,
            systemPrompt: 'system',
            userPrompt: 'explain',
            attachments: [
              DeepSeekAttachment(
                kind: DeepSeekAttachmentKind.image,
                filename: 'x.jpg',
                bytes: Uint8List.fromList([1]),
              ),
            ],
            apiKey: 'sk-test',
          )
          .toList(),
      throwsA(isA<DeepSeekException>()),
    );
    expect(called, isFalse);
  });

  test('401 responses become a key error', () async {
    final service = DeepSeekService(
      clientFactory: () => MockClient((request) async {
        return http.Response(
          jsonEncode({
            'error': {'message': 'invalid key'},
          }),
          401,
        );
      }),
    );

    await expectLater(
      service
          .chat(
            model: deepSeekModels.first,
            systemPrompt: 'system',
            userPrompt: 'question',
            apiKey: 'sk-bad',
          )
          .toList(),
      throwsA(
        isA<DeepSeekException>().having(
          (error) => error.statusCode,
          'statusCode',
          401,
        ),
      ),
    );
  });
}
