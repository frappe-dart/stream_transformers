library partition_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("Partition", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;

  beforeEach(() {
    controller = provider();
  });

  afterEach(() {
    controller.close();
  });

  it("partitions get filled with correct values", () {
    return testStream(controller.stream.transform(new Partition((int value) => value % 2 == 0, nameWhenTrue: 'evens', nameWhenFalse: 'odds')), // even, odd
        behavior: () {
          controller.add(1);
          controller.add(2);
          controller.add(3);
          controller.add(4);
          controller.add(5);
        },
        expectation: (values) => expect(values).toEqual([
          {'evens': null, 'odds': 1}, // controller.add(1) => evens [] odds [1]
          {'evens': 2, 'odds': 1},    // controller.add(1) => evens [2] odds [1]
          {'evens': 2, 'odds': 3},    // controller.add(1) => evens [2] odds [1, 3]
          {'evens': 4, 'odds': 3},    // controller.add(1) => evens [2, 4] odds [1, 3]
          {'evens': 4, 'odds': 5}     // controller.add(1) => evens [2, 4] odds [1, 3, 5]
        ]));
  });

  it("forwards errors from source and toggle stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new Partition((int value) => value % 2 == 0)),
        behavior: () {
          controller.addError(1);
        },
        expectation: (errors) => expect(errors).toEqual([1]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new Partition((int value) => value % 2 == 0));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}