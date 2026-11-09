import 'package:cpe_reviewer/models/cloud_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cloud profile round-trips and normalizes endpoint URLs', () {
    final profile = CloudProfile(
      id: 'p1',
      displayName: 'Free cloud',
      baseUrl: 'https://example.test/v1/',
      modelId: 'free/model',
      supportsVision: true,
      supportsJson: false,
      shareHandoutContext: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
    );
    final decoded = CloudProfile.fromJson(profile.toJson());
    expect(decoded.id, 'p1');
    expect(decoded.modelId, 'free/model');
    expect(decoded.supportsVision, isTrue);
    expect(decoded.supportsJson, isFalse);
    expect(decoded.chatUrl, 'https://example.test/v1/chat/completions');
    expect(decoded.modelsUrl, 'https://example.test/v1/models');
  });
}
