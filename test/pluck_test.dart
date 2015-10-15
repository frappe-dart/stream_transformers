library pluck_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("Pluck", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  String expectedValue = 'plucked!';
  Map targetData = {'foo': {'bar': {'baz': expectedValue}}};
  String pathThatResolves = 'foo.bar.baz';
  String pathThatFails = 'foo.nonExistingProp.baz';
  StreamController controller;

  beforeEach(() {
    controller = provider();
  });

  afterEach(() {
    controller.close();
  });

  it("resolves the value using a path from the source stream", () {
    return testStream(controller.stream.transform(new Pluck<String>(pathThatResolves)),
        behavior: () => controller.add(targetData),
        expectation: (values) {
          expect(values).toEqual([expectedValue]);
        });
  });
  
  it("yields null if it fails to resolve the value using a path from the source stream", () {
    return testStream(controller.stream.transform(new Pluck(pathThatFails, onError: (_) => null)),
        behavior: () => controller.add(targetData),
        expectation: (values) {
          expect(values).toEqual([null]);
        });
  });
  
  it("forwards errors from source stream if onError is not defined, and resolving the path fails", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new Pluck(pathThatFails)),
        behavior: () => controller.add(targetData),
        expectation: (errors) => expect(errors.first).toBeAnInstanceOf(ArgumentError));
  });

  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new Pluck(pathThatResolves));
    var result = stream.toList();
    controller..add(targetData)..close();
    return result.then((values) {
      expect(values).toEqual([expectedValue]);
    });
  });

  it("cancels input stream when transformed stream is cancelled", () {
    var completerA = new Completer();
    var controller = new StreamController(onCancel: completerA.complete);

    return testStream(
        controller.stream.transform(new Pluck(pathThatResolves)),
        expectation: (_) => completerA.future);
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new Pluck(pathThatResolves));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}
