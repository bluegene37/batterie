// Gene - Oct 24, 2026: Tests for UpdateService semantic version comparison and release checking.

import 'package:flutter_test/flutter_test.dart';
import 'package:batterie/services/update_service.dart';

void main() {
  group('UpdateService.isNewerVersion tests', () {
    test('returns true when candidate has higher patch version', () {
      expect(UpdateService.isNewerVersion('1.0.3', '1.0.4'), isTrue);
    });

    test('returns true when candidate has higher minor version', () {
      expect(UpdateService.isNewerVersion('1.0.3', '1.1.0'), isTrue);
    });

    test('returns true when candidate has higher major version', () {
      expect(UpdateService.isNewerVersion('1.0.3', '2.0.0'), isTrue);
    });

    test('returns false when candidate is same version', () {
      expect(UpdateService.isNewerVersion('1.0.3', '1.0.3'), isFalse);
    });

    test('returns false when candidate is older version', () {
      expect(UpdateService.isNewerVersion('1.0.3', '1.0.2'), isFalse);
      expect(UpdateService.isNewerVersion('2.0.0', '1.9.9'), isFalse);
    });

    test('handles build numbers and prefixes cleanly', () {
      expect(UpdateService.isNewerVersion('1.0.3+4', '1.0.4+5'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.3+4', 'v1.0.4'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.3+4', '1.0.3+5'), isFalse);
    });
  });
}
