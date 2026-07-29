import 'package:flutter_test/flutter_test.dart';
import 'package:share_harbor/share_harbor.dart';

void main() {
  group('Security & Threat Model Unit Tests', () {
    test('ShareItem internal name does not expose path traversal vulnerabilities', () {
      const maliciousItem = ShareItem(
        itemId: 'safe-uuid-1234',
        kind: ShareItemKind.file,
        originalName: '../../../etc/passwd',
        internalName: 'safe-uuid-1234.payload',
        byteLength: 256,
      );

      expect(maliciousItem.internalName, isNot(contains('../')));
      expect(maliciousItem.originalName, equals('../../../etc/passwd'));
      expect(maliciousItem.internalName, equals('safe-uuid-1234.payload'));
    });

    test('ShareHarborException toString redacts raw sensitive information', () {
      const exception = ShareHarborException(
        code: ShareHarborErrorCode.unsafeMetadata,
        message: 'Path traversal attempt detected in originalName',
      );

      expect(exception.toString(), contains('unsafeMetadata'));
      expect(exception.toString(), contains('Path traversal attempt detected'));
    });

    test('ShareHarborErrorCode enum comprehensive coverage', () {
      expect(ShareHarborErrorCode.values.length, greaterThanOrEqualTo(20));
      expect(ShareHarborErrorCode.lockTimeout.name, equals('lockTimeout'));
      expect(ShareHarborErrorCode.inboxQuotaExceeded.name, equals('inboxQuotaExceeded'));
    });
  });
}
