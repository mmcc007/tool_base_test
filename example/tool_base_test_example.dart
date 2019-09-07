import 'package:test/test.dart';
import 'package:tool_base_test/tool_base_test.dart';

import 'context_runner.dart';

main() {
  testUsingContext('test in context', () {
    expect(true, isTrue);
  });

  testUsingContext('test in app context', () {
    expect(true, isTrue);
  }, runInAppContext: runInContext);
}
