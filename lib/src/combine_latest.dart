part of stream_transformers;

/// Combines the latest values of two streams into a List.
/// The combining will not be called until each stream delivers its
/// first value. After the first value of each stream is delivered, a List of length 2,
/// containing the latest values from both streams is returned.
/// The element at position 0 is from the first stream, the element at position 2 is from the second.
/// Errors occurring on the streams will be forwarded to the transformed
/// stream. If the source stream is a broadcast stream, then the transformed
/// stream will also be a broadcast stream.
///
/// **Example:**
///
///     var controller1 = new StreamController();
///     var controller2 = new StreamController();
///
///     var combinedLatest = controller1.stream.transform(new CombineLatest(controller2.stream));
///
///     combined.listen(print);
///
///     controller1.add(1);
///     controller2.add(1); // Prints: [1, 1]
///     controller1.add(2); // Prints: [2, 1]
///     controller2.add(2); // Prints: [2, 2]
class CombineLatest<A, B, R extends Iterable> implements StreamTransformer<A, A> {
  
  final Stream<B> _other;

  CombineLatest(Stream<B> other) : _other = other;

  Stream<A> bind(Stream<A> stream) => stream.transform(new Combine(_other, (A a, B b) => [a, b]));
}