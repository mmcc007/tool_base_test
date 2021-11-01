// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

//import 'package:tool_base/src/commands/create.dart';
//import 'package:tool_base/src/runner/flutter_command.dart';
//import 'package:tool_base/src/runner/flutter_command_runner.dart';
import 'package:test_api/test_api.dart' as test_package show TypeMatcher;
import 'package:test_api/test_api.dart' hide TypeMatcher, isInstanceOf;
//import 'package:args/command_runner.dart';
import 'package:tool_base/src/base/common.dart';
import 'package:tool_base/src/base/file_system.dart';
import 'package:tool_base/src/base/process.dart';

export 'package:test_core/test_core.dart' hide TypeMatcher, isInstanceOf; // Defines a 'package:test' shim.

/// A matcher that compares the type of the actual value to the type argument T.
// TODO(ianh): Remove this once https://github.com/dart-lang/matcher/issues/98 is fixed
Matcher isInstanceOf<T>() => test_package.TypeMatcher<T>();

//CommandRunner<void> createTestCommandRunner([ FlutterCommand command ]) {
//  final FlutterCommandRunner runner = FlutterCommandRunner();
//  if (command != null)
//    runner.addCommand(command);
//  return runner;
//}

/// Updates [path] to have a modification time [seconds] from now.
void updateFileModificationTime(
    String path,
    DateTime baseTime,
    int seconds,
    ) {
  final modificationTime = baseTime.add(Duration(seconds: seconds));
  fs.file(path).setLastModifiedSync(modificationTime);
}

/// Matcher for functions that throw [ToolExit].
Matcher throwsToolExit({ int? exitCode, Pattern? message }) {
  var matcher = isToolExit;
  if (exitCode != null) {
    matcher = allOf(matcher, (ToolExit e) => e.exitCode == exitCode);
  }
  if (message != null) {
    matcher = allOf(matcher, (ToolExit e) => e.message.contains(message));
  }
  return throwsA(matcher);
}

/// Matcher for [ToolExit]s.
final Matcher isToolExit = isInstanceOf<ToolExit>();

/// Matcher for functions that throw [ProcessExit].
Matcher throwsProcessExit([ dynamic exitCode ]) {
  return exitCode == null
      ? throwsA(isProcessExit)
      : throwsA(allOf(isProcessExit, (ProcessExit e) => e.exitCode == exitCode));
}

/// Matcher for [ProcessExit]s.
final Matcher isProcessExit = isInstanceOf<ProcessExit>();

///// Creates a flutter project in the [temp] directory using the
///// [arguments] list if specified, or `--no-pub` if not.
///// Returns the path to the flutter project.
//Future<String> createProject(Directory temp, { List<String> arguments }) async {
//  arguments ??= <String>['--no-pub'];
//  final String projectPath = fs.path.join(temp.path, 'flutter_project');
//  final CreateCommand command = CreateCommand();
//  final CommandRunner<void> runner = createTestCommandRunner(command);
//  await runner.run(<String>['create', ...arguments, projectPath]);
//  return projectPath;
//}

/// Test case timeout for tests involving remote calls to `pub get` or similar.
const Timeout allowForRemotePubInvocation = Timeout.factor(10.0);

/// Test case timeout for tests involving creating a Flutter project with
/// `--no-pub`. Use [allowForRemotePubInvocation] when creation involves `pub`.
const Timeout allowForCreateFlutterProject = Timeout.factor(3.0);

Future<void> expectToolExitLater(Future<dynamic> future, Matcher messageMatcher) async {
  try {
    await future;
    fail('ToolExit expected, but nothing thrown');
  } on ToolExit catch(e) {
    expect(e.message, messageMatcher);
  } catch(e, trace) {
    fail('ToolExit expected, got $e\n$trace');
  }
}
