import 'dart:async';
import 'dart:convert';
import 'dart:io' as io show IOSink, ProcessSignal, Stdout, StdoutException;

import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:tool_base/tool_base.dart';

/// A strategy for creating Process objects from a list of commands.
typedef ProcessFactory = Process Function(List<String> command);

/// A ProcessManager that starts Processes by delegating to a ProcessFactory.
class MockProcessManager extends Mock implements ProcessManager {
  ProcessFactory processFactory = (List<String> commands) => MockProcess();
  bool canRunSucceeds = true;
  bool runSucceeds = true;
  List<String> commands;

  @override
  bool canRun(dynamic command, { String workingDirectory }) => canRunSucceeds;

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    if (!runSucceeds) {
      final String executable = command[0];
      final List<String> arguments = command.length > 1 ? command.sublist(1) : <String>[];
      throw ProcessException(executable, arguments);
    }

    commands = command;
    return Future<Process>.value(processFactory(command));
  }
}

/// A process that exits successfully with no output and ignores all input.
class MockProcess extends Mock implements Process {
  MockProcess({
    this.pid = 1,
    Future<int> exitCode,
    Stream<List<int>> stdin,
    this.stdout = const Stream<List<int>>.empty(),
    this.stderr = const Stream<List<int>>.empty(),
  }) : exitCode = exitCode ?? Future<int>.value(0),
       stdin = stdin ?? MemoryIOSink();

  @override
  final int pid;

  @override
  final Future<int> exitCode;

  @override
  final io.IOSink stdin;

  @override
  final Stream<List<int>> stdout;

  @override
  final Stream<List<int>> stderr;
}

/// A fake process implemenation which can be provided all necessary values.
class FakeProcess implements Process {
  FakeProcess({
    this.pid = 1,
    Future<int> exitCode,
    Stream<List<int>> stdin,
    this.stdout = const Stream<List<int>>.empty(),
    this.stderr = const Stream<List<int>>.empty(),
  }) : exitCode = exitCode ?? Future<int>.value(0),
       stdin = stdin ?? MemoryIOSink();

  @override
  final int pid;

  @override
  final Future<int> exitCode;

  @override
  final io.IOSink stdin;

  @override
  final Stream<List<int>> stdout;

  @override
  final Stream<List<int>> stderr;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    return true;
  }
}

/// A process that prompts the user to proceed, then asynchronously writes
/// some lines to stdout before it exits.
class PromptingProcess implements Process {
  Future<void> showPrompt(String prompt, List<String> outputLines) async {
    _stdoutController.add(utf8.encode(prompt));
    final List<int> bytesOnStdin = await _stdin.future;
    // Echo stdin to stdout.
    _stdoutController.add(bytesOnStdin);
    if (bytesOnStdin[0] == utf8.encode('y')[0]) {
      for (final String line in outputLines)
        _stdoutController.add(utf8.encode('$line\n'));
    }
    await _stdoutController.close();
  }

  final StreamController<List<int>> _stdoutController = StreamController<List<int>>();
  final CompleterIOSink _stdin = CompleterIOSink();

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  IOSink get stdin => _stdin;

  @override
  Future<int> get exitCode async {
    await _stdoutController.done;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// An IOSink that completes a future with the first line written to it.
class CompleterIOSink extends MemoryIOSink {
  final Completer<List<int>> _completer = Completer<List<int>>();

  Future<List<int>> get future => _completer.future;

  @override
  void add(List<int> data) {
    if (!_completer.isCompleted)
      _completer.complete(data);
    super.add(data);
  }
}

/// An IOSink that collects whatever is written to it.
class MemoryIOSink implements IOSink {
  @override
  Encoding encoding = utf8;

  final List<List<int>> writes = <List<int>>[];

  @override
  void add(List<int> data) {
    writes.add(data);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    final Completer<void> completer = Completer<void>();
    stream.listen((List<int> data) {
      add(data);
    }).onDone(() => completer.complete());
    return completer.future;
  }

  @override
  void writeCharCode(int charCode) {
    add(<int>[charCode]);
  }

  @override
  void write(Object obj) {
    add(encoding.encode('$obj'));
  }

  @override
  void writeln([ Object obj = '' ]) {
    add(encoding.encode('$obj\n'));
  }

  @override
  void writeAll(Iterable<dynamic> objects, [ String separator = '' ]) {
    bool addSeparator = false;
    for (dynamic object in objects) {
      if (addSeparator) {
        write(separator);
      }
      write(object);
      addSeparator = true;
    }
  }

  @override
  void addError(dynamic error, [ StackTrace stackTrace ]) {
    throw UnimplementedError();
  }

  @override
  Future<void> get done => close();

  @override
  Future<void> close() async { }

  @override
  Future<void> flush() async { }
}

class MemoryStdout extends MemoryIOSink implements io.Stdout {
  @override
  bool get hasTerminal => _hasTerminal;
  set hasTerminal(bool value) {
    assert(value != null);
    _hasTerminal = value;
  }
  bool _hasTerminal = true;

  @override
  io.IOSink get nonBlocking => this;

  @override
  bool get supportsAnsiEscapes => _supportsAnsiEscapes;
  set supportsAnsiEscapes(bool value) {
    assert(value != null);
    _supportsAnsiEscapes = value;
  }
  bool _supportsAnsiEscapes = true;

  @override
  int get terminalColumns {
    if (_terminalColumns != null)
      return _terminalColumns;
    throw const io.StdoutException('unspecified mock value');
  }
  set terminalColumns(int value) => _terminalColumns = value;
  int _terminalColumns;

  @override
  int get terminalLines {
    if (_terminalLines != null)
      return _terminalLines;
    throw const io.StdoutException('unspecified mock value');
  }
  set terminalLines(int value) => _terminalLines = value;
  int _terminalLines;
}

/// A Stdio that collects stdout and supports simulated stdin.
class MockStdio extends Stdio {
  final MemoryStdout _stdout = MemoryStdout();
  final MemoryIOSink _stderr = MemoryIOSink();
  final StreamController<List<int>> _stdin = StreamController<List<int>>();

  @override
  MemoryStdout get stdout => _stdout;

  @override
  MemoryIOSink get stderr => _stderr;

  @override
  Stream<List<int>> get stdin => _stdin.stream;

  void simulateStdin(String line) {
    _stdin.add(utf8.encode('$line\n'));
  }

  List<String> get writtenToStdout =>
      _stdout.writes.map<String>(_stdout.encoding.decode).toList();
  List<String> get writtenToStderr =>
      _stderr.writes.map<String>(_stderr.encoding.decode).toList();
}
