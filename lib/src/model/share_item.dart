import 'package:meta/meta.dart';

/// Categories of shared items.
enum ShareItemKind {
  text,
  url,
  html,
  image,
  video,
  file,
  unknown,
}

/// Represents an individual item within a share delivery.
@immutable
class ShareItem {
  /// Unique item ID.
  final String itemId;

  /// Kind/Category of the item.
  final ShareItemKind kind;

  /// Original filename provided by the sender, if any.
  final String? originalName;

  /// Safe internal payload file name.
  final String internalName;

  /// MIME type declared by sender.
  final String? declaredMimeType;

  /// MIME type resolved by receiver.
  final String? resolvedMimeType;

  /// Length in bytes.
  final int byteLength;

  /// Creates a [ShareItem].
  const ShareItem({
    required this.itemId,
    required this.kind,
    this.originalName,
    required this.internalName,
    this.declaredMimeType,
    this.resolvedMimeType,
    required this.byteLength,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareItem &&
          runtimeType == other.runtimeType &&
          itemId == other.itemId &&
          kind == other.kind &&
          originalName == other.originalName &&
          internalName == other.internalName &&
          declaredMimeType == other.declaredMimeType &&
          resolvedMimeType == other.resolvedMimeType &&
          byteLength == other.byteLength;

  @override
  int get hashCode =>
      itemId.hashCode ^
      kind.hashCode ^
      originalName.hashCode ^
      internalName.hashCode ^
      declaredMimeType.hashCode ^
      resolvedMimeType.hashCode ^
      byteLength.hashCode;
}
