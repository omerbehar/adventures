// Core import-discipline gate (ADR-0009 Decision Point 1). Fails CI if any file in the
// pure-Dart core (lib/game, lib/resolver, lib/scene) imports Flutter — package:flutter or
// dart:ui — which would destroy the core's headless testability and edge-side deployability.
//
//   dart run tool/check_core_imports.dart
//
// Pure Dart (no Flutter) so it runs headlessly in CI, before the Flutter toolchain steps.

import 'dart:io';

const List<String> _coreDirs = ['lib/game', 'lib/resolver', 'lib/scene'];

final RegExp _bannedImport = RegExp(
  r'''^\s*(import|export)\s+['"](package:flutter/|dart:ui)''',
);

void main() {
  final offenders = <String>[];

  for (final path in _coreDirs) {
    final dir = Directory(path);
    if (!dir.existsSync()) continue;
    final files =
        dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (_bannedImport.hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
  }

  if (offenders.isNotEmpty) {
    stderr.writeln(
      'ADR-0009 layering violation — Flutter imports in the pure-Dart core:',
    );
    for (final o in offenders) {
      stderr.writeln('  $o');
    }
    exit(1);
  }

  stdout.writeln(
    'Core import discipline OK — no package:flutter / dart:ui in '
    '${_coreDirs.join(", ")}.',
  );
}
