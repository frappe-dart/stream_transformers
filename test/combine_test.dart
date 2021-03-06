library combine_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'util.dart';

void main() => describe("Combine", () {
  describe("with a single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with a broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController providerA()) {
  StreamController controllerA;
  StreamController controllerB;

  beforeEach(() {
    controllerA = providerA();
    controllerB = new StreamController();
  });

  afterEach(() {
    controllerA.close();
    controllerB.close();
  });

  it("combine when both streams have an event", () {
    return testStream(controllerA.stream.transform(new Combine(controllerB.stream, (a, b) => a + b)),
        behavior: () {
          controllerA.add(1);
          controllerB.add(1);
        },
        expectation: (values) => expect(values).toEqual([2]));
  });

  it("combines always after both streams have an event", () {
    return testStream(controllerA.stream.transform(new Combine(controllerB.stream, (a, b) => a + b)),
        behavior: () {
          controllerA.add(1);
          controllerB.add(1);

          controllerB.add(2);
        },
        expectation: (values) => expect(values).toEqual([2, 3]));
  });

  it("returned stream closes when both streams are done", () {
    return testStream(controllerA.stream.transform(new Combine(controllerB.stream, (a, b) => a + b)),
        behavior: () {
          controllerA.close();
          controllerB.close();
        },
        expectation: (values) => expect(values).toEqual([]));
  });

  it("cancels input streams when source streams are closed", () {
    var completerA = new Completer();
    var completerB = new Completer();
    var controllerA = new StreamController(onCancel: completerA.complete);
    var controllerB = new StreamController(onCancel: completerB.complete);

    return testStream(
        controllerA.stream.transform(new Combine(controllerB.stream, (a, b) => a + b)),
        behavior: () {
          controllerA.close();
          controllerB.close();
        },
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });

  it("cancels input streams when source stream is cancelled", () {
    var completerA = new Completer();
    var completerB = new Completer();
    var controllerA = new StreamController(onCancel: completerA.complete);
    var controllerB = new StreamController(onCancel: completerB.complete);

    return testStream(
        controllerA.stream.transform(new Combine(controllerB.stream, (a, b) => a + b)),
        expectation: (_) => Future.wait([completerA.future, completerB.future]));
  });

  it("forwards errors from either source stream", () {
    return testErrorsAreForwarded(
        controllerA.stream.transform(new Combine(controllerB.stream, (a, b) => a + b)),
        behavior: () {
          controllerA.addError(1);
          controllerB.addError(2);
        },
        expectation: (errors) => expect(errors).toEqual([1, 2]));
  });

  it("returns a stream of the same type", () {
    var stream = controllerA.stream.transform(new Combine(controllerB.stream, (a, b) => a + b));
    expect(stream.isBroadcast).toBe(controllerA.stream.isBroadcast);
  });
}