/// ---------------------------------------------------------------------------
/// Shared wire-format helpers for converting between Dart's camelCase enum
/// names and Spring/Java's SCREAMING_SNAKE_CASE enum constants, and for
/// coercing ids that may arrive as int, double, or String depending on how
/// Jackson serialized them.
///
/// This is the same logic that used to live as private helpers inside
/// opportunity.dart (`_toWireEnum` / `_fromWireEnum` / `_idToInt`). Now that
/// Business needs the identical conversion, it's pulled out here so both
/// models import one copy instead of drifting apart.
///
/// Migration note for opportunity.dart: delete its private `_toWireEnum` /
/// `_fromWireEnum` / `_idToInt` / `_WireEnum` extension, add
/// `import 'core/wire_format.dart';` (adjust relative path to your project
/// layout), and it keeps working unchanged — the public names here match
/// 1:1, minus the leading underscore.
/// ---------------------------------------------------------------------------

String toWireEnum(String dartName) =>
    dartName.replaceAllMapped(RegExp('([A-Z])'), (m) => '_${m[1]}').toUpperCase();

String fromWireEnum(String wireName) {
  final parts = wireName.toLowerCase().split('_');
  return parts.first +
      parts.skip(1).map((p) => p.isEmpty ? '' : p[0].toUpperCase() + p.substring(1)).join();
}

int idToInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.parse(v);
  throw FormatException('Unexpected id type: ${v.runtimeType}');
}

extension WireEnum on Enum {
  String get wire => toWireEnum(name);
}