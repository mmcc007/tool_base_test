[![Build Status](https://travis-ci.com/mmcc007/tool_base_test.svg?branch=master)](https://travis-ci.com/mmcc007/tool_base_test)

A library for Dart developers.

## Usage

A simple usage example:

```dart
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

```

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: http://example.com/issues/replaceme
