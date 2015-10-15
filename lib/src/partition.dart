part of stream_transformers;

/// Splits the events of a stream into 2 partitions.
/// The predicate acts as a switch to determine in which partition the values go.
/// If the predicate yields true, the value goes into the first partition.
/// If the predicate yields false, the value goes into the second partition.
/// The returned stream is a Map containing both partitions.
/// The keys of the Map, representing the true and false partitions, can be passed via named arguments.
/// 
/// **Example:**
///
///     var source = new Stream.fromIterable([1, 2, 3, 4, 5]);
///     var stream = source.transform(new Partition((int value) => value % 2 == 0, 'evens', 'odds'));
///     stream.listen(print);
///
///     // {evens: null, odds: 1}
///     // {evens: 2, odds: 1}
///     // {evens: 2, odds: 3}
///     // {evens: 4, odds: 3}
///     // {evens: 4, odds: 5}
class Partition<T> implements StreamTransformer<T, T> {
  final Function _predicate;
  final String _nameWhenTrue, _nameWhenFalse;

  Partition(bool predicate(T value), {String nameWhenTrue: 'predicateTrue', String nameWhenFalse: 'predicateFalse'}) :
    _predicate = predicate,
    _nameWhenTrue = nameWhenTrue,
    _nameWhenFalse = nameWhenFalse;

  Stream<T> bind(Stream<T> stream) {

    return _bindStream(like: stream, onListen: (EventSink<T> sink) {
      T predicateTrueValue, predicateFalseValue;
      
      return stream
        .transform(new FlatMapLatest((T value) {
          if (_predicate(value)) predicateTrueValue = value;
          else predicateFalseValue = value;
          
          return new Stream.fromIterable(<Map<String, T>>[<String, T>{_nameWhenTrue: predicateTrueValue, _nameWhenFalse: predicateFalseValue}]);
        }))
        .listen(sink.add, onError: sink.addError, onDone: sink.close);
    });
  }
}