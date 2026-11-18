/// Classification of a parsed Firestore document for read/display purposes.
enum ReadQuality { valid, legacy, invalid }

/// Why a field could not be used as a valid current-schema value.
enum FieldIssueKind {
  missing,
  nullValue,
  wrongType,
  outOfRange,
  unknownValue,
  extraOrMissingKey,
  malformedElement,
}

/// A single validated-field issue kept for diagnostics and UI decisions.
class FieldIssue {
  final String field;
  final FieldIssueKind kind;
  final String? expected;
  final String? actualType;

  const FieldIssue({
    required this.field,
    required this.kind,
    this.expected,
    this.actualType,
  });

  @override
  String toString() =>
      'FieldIssue($field, ${kind.name}, expected: $expected, actual: $actualType)';
}

/// Base for per-document read results. [documentId] is always preserved.
abstract class DocumentReadResult {
  String get documentId;
  ReadQuality get quality;
  List<FieldIssue> get issues;
  bool get isValid => quality == ReadQuality.valid;
  bool get isLegacy => quality == ReadQuality.legacy;
  bool get isInvalid => quality == ReadQuality.invalid;
}

/// Mutable helper used while parsing one document.
class FieldIssues {
  final List<FieldIssue> _items = <FieldIssue>[];

  List<FieldIssue> get items => List.unmodifiable(_items);
  bool get hasIssues => _items.isNotEmpty;

  void add(
    String field,
    FieldIssueKind kind, {
    String? expected,
    Object? actual,
  }) {
    _items.add(FieldIssue(
      field: field,
      kind: kind,
      expected: expected,
      actualType: actual?.runtimeType.toString(),
    ));
  }
}

String? actualTypeName(Object? value) =>
    value == null ? 'null' : value.runtimeType.toString();

bool isIntLike(Object? value) => value is int;

bool isNonEmptyString(Object? value) => value is String && value.trim().isNotEmpty;
