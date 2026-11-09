import 'dart:convert';

import 'package:cpe_reviewer/data/openai_compatible_config.dart';
import 'package:cpe_reviewer/services/ai/openai_compatible_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sends a standard OpenAI-compatible streamed chat request', () async {
    SharedPreferences.setMockInitialValues({});
    final config = OpenAiCompatibleConfig.instance;
    await config.saveSettings(
      baseUrl: 'https://example.test/v1',
      modelId: 'free/model',
      displayName: 'Free Model',
      supportsVision: false,
      supportsJson: true,
      shareHandoutContext: false,
    );
    late http.Request captured;
    final service = OpenAiCompatibleService(
      clientFactory: () => MockClient((request) async {
        captured = request;
        return http.Response(
          'data: {"choices":[{"delta":{"content":"Hello"}}]}\n'
          'data: {"choices":[{"delta":{}}],"usage":{"prompt_tokens":2,'
          '"completion_tokens":1,"total_tokens":3}}\n'
          'data: [DONE]\n',
          200,
          headers: {'content-type': 'text/event-stream'},
        );
      }),
    );
    final chunks = await service
        .chat(systemPrompt: 'system', userPrompt: 'hello', apiKey: 'test-key')
        .toList();
    expect(captured.url.toString(), 'https://example.test/v1/chat/completions');
    expect(captured.headers['Authorization'], 'Bearer test-key');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], 'free/model');
    expect(body['stream'], true);
    expect(
      chunks.map((chunk) => chunk.content).whereType<String>(),
      contains('Hello'),
    );
    expect(chunks.last.usage!.totalTokens, 3);
  });
}
