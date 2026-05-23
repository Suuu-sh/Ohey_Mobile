import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart scripts/check_dart_define_keys.dart <file1.json> <file2.json> [file3.json ...]',
    );
    exitCode = 2;
    return;
  }

  final entries = <String, List<String>>{};
  for (final path in args) {
    final raw = File(path).readAsStringSync();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      stderr.writeln('$path must be a JSON object.');
      exitCode = 2;
      return;
    }
    entries[path] = decoded.keys.toList();
  }

  final referencePath = entries.keys.first;
  final referenceKeys = entries[referencePath]!;
  final referenceSet = referenceKeys.toSet();
  var hasMismatch = false;

  for (final entry in entries.entries.skip(1)) {
    final keys = entry.value;
    final keySet = keys.toSet();
    final missing = referenceKeys
        .where((key) => !keySet.contains(key))
        .toList(growable: false);
    final extra = keys
        .where((key) => !referenceSet.contains(key))
        .toList(growable: false);

    if (missing.isEmpty && extra.isEmpty) continue;

    hasMismatch = true;
    stderr.writeln('${entry.key} keys differ from $referencePath.');
    if (missing.isNotEmpty) {
      stderr.writeln('  Missing: ${missing.join(', ')}');
    }
    if (extra.isNotEmpty) {
      stderr.writeln('  Extra: ${extra.join(', ')}');
    }
  }

  if (hasMismatch) {
    exitCode = 1;
    return;
  }

  stdout.writeln('dart-define keys match: ${args.join(', ')}');
}
