/// Machine-readable error codes for ShareHarbor exceptions.
enum ShareHarborErrorCode {
  configurationInvalid,
  appGroupUnavailable,
  unsupportedType,
  unsupportedSchema,
  sourcePermissionDenied,
  sourceUnavailable,
  itemTooLarge,
  deliveryTooLarge,
  tooManyItems,
  inboxQuotaExceeded,
  cancelled,
  ioFailure,
  corruptManifest,
  unsafeMetadata,
  lockTimeout,
  deliveryNotFound,
  claimConflict,
  claimExpired,
  alreadyAcknowledged,
  platformFailure,
  unknown,
}

/// Exception thrown by the ShareHarbor package.
class ShareHarborException implements Exception {
  final ShareHarborErrorCode code;
  final String message;
  final Object? details;

  const ShareHarborException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'ShareHarborException($code): $message';
}
