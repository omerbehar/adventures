// Scene lint CLI — runs the deterministic Scene Linter (ADR-0005) over every scene JSON
// and exits non-zero if any scene fails to parse or has error-severity findings.
//
//   dart run tool/lint_scenes.dart [dir]      # default dir: assets/scenes
//
// Pure Dart (no Flutter) so it runs headlessly in CI. Supports single-node scene files
// and SceneGraph files (a top-level `nodes` map + optional globalFacets/globalMeters).

import 'dart:convert';
import 'dart:io';

import 'package:adventures/scene/authoring/grounding_tables.dart';
import 'package:adventures/scene/authoring/scene_linter.dart';
import 'package:adventures/scene/scene_model.dart';

void main(List<String> args) {
  final dir = Directory(args.isNotEmpty ? args.first : 'assets/scenes');
  if (!dir.existsSync()) {
    stdout.writeln('No scenes directory at ${dir.path} — nothing to lint.');
    exit(0);
  }

  final files =
      dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  final linter = SceneLinter(grounding: GroundingTables.defaults());
  var scenesWithErrors = 0;
  var totalFindings = 0;

  for (final file in files) {
    stdout.writeln('• ${file.path}');
    final Map<String, LintReport> reports;
    try {
      reports = _lintFile(file.readAsStringSync(), linter);
    } on Object catch (e) {
      stdout.writeln('  PARSE FAIL: $e');
      scenesWithErrors++;
      continue;
    }

    var sceneHasError = false;
    for (final entry in reports.entries) {
      for (final finding in entry.value.findings) {
        totalFindings++;
        stdout.writeln('    ${entry.key}: $finding');
      }
      if (!entry.value.passes) sceneHasError = true;
    }
    if (sceneHasError) {
      scenesWithErrors++;
    } else if (reports.values.every((r) => r.findings.isEmpty)) {
      stdout.writeln('  OK');
    } else {
      stdout.writeln('  OK (warnings only)');
    }
  }

  stdout.writeln(
    '\n${files.length} scene file(s) · $totalFindings finding(s) · $scenesWithErrors with errors.',
  );
  exit(scenesWithErrors > 0 ? 1 : 0);
}

/// Lint a scene file's JSON. Returns node-id → report. A file with a top-level `nodes`
/// map is treated as a SceneGraph; otherwise as a single SceneModel node.
Map<String, LintReport> _lintFile(String source, SceneLinter linter) {
  final json = (jsonDecode(source) as Map).cast<String, Object?>();
  final out = <String, LintReport>{};

  if (json.containsKey('nodes')) {
    final globalFacets = {
      ...(json['globalFacets'] as List? ?? const []).cast<String>(),
    };
    final globalMeters = {
      for (final e in ((json['globalMeters'] as Map?) ?? const {}).entries)
        e.key as String: MeterSpec.fromJson((e.value as Map).cast()),
    };
    for (final e in (json['nodes'] as Map).entries) {
      final node = SceneModel.fromJson((e.value as Map).cast());
      out[e.key as String] = linter.lint(
        node,
        globalFacets: globalFacets,
        globalMeters: globalMeters,
      );
    }
  } else {
    final node = SceneModel.fromJson(json);
    out[node.id] = linter.lint(node);
  }
  return out;
}
