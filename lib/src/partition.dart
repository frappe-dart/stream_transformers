part of stream_transformers;

/// Splits the events of a stream into 2 partitions.
/// The predicate acts as a switch to determine in which partition the values go.
/// If the predicate yields true, the value goes into the first partition.
/// If the predicate yields false, the value goes into the second partition.
/// The returned stream is a List containing both partitions.
/// 
/// **Example:**
///
///     var source = new Stream.fromIterable([1, 2, 3, 4, 5]);
///     var stream = source.transform(new Partition((int value) => value % 2 == 0));
///     stream.listen(print);
///
///     // [], [1]
///     // [2], [1]
///     // [2], [1, 3]
///     // [2, 4], [1, 3]
///     // [2, 4], [1, 3, 5]
class Partition<T> implements StreamTransformer<T, T> {
  final Function _predicate;
  final Function _inversePredicate;

  Partition(bool predicate(T value)) :
    _predicate = predicate,
    _inversePredicate = ((T value) => !predicate(value));

  Stream<T> bind(Stream<T> stream) {

    return _bindStream(like: stream, onListen: (EventSink<T> sink) {
      List<T> predicateTrueList = <T>[];
      List<T> predicateFalseList = <T>[];
      
      return stream
        .transform(new FlatMapLatest((T value) {
          if (_predicate(value)) predicateTrueList.add(value);
          else predicateFalseList.add(value);
          
          return new Stream.fromIterable(<List<List<T>>>[<List<T>>[predicateTrueList.toList(growable: false), predicateFalseList.toList(growable: false)]]);
        }))
        .listen(sink.add, onError: sink.addError, onDone: sink.close);
    });
  }
}