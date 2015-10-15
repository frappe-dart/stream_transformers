part of stream_transformers;

/// Returns the value of a specified nested property 
/// from all elements in the sequence. An onError function can be passed
/// to yield a default value if the property couldn't be resolved.
///
/// **Example:**
///
///     var source = new Stream.fromIterable([{'foo': {'bar': {'baz': 'plucked!'}}}]);
///     var stream = source.transform(new Pluck('foo.bar.baz'));
///     stream.listen(print);
///
///     // 'plucked!'
class Pluck<T> implements StreamTransformer<T, T> {
  
  final String _path;
  final List<String> _segments;
  final Function _onError;
  
  Pluck(String path, {T onError(dynamic data)}) :
    _path = path,
    _segments = path.split('.'),
    _onError = onError;
  
  Stream<T> bind(Stream<T> stream) {
    return _bindStream(like: stream, onListen: (EventSink<T> sink) {

      void onData(dynamic data) {
        bool hasFailedToResolve = false;
        dynamic currentValue = data;
        
        for (int i=0, len=_segments.length; i<len; i++) {
          try {
            currentValue = currentValue[_segments[i]];
          } catch (error) {
            if (_onError != null) {
              sink.add(_onError(data));
              hasFailedToResolve = true;
              break;
            }
            else sink.addError(new ArgumentError('Unable to resolve "$_path"'));
          }
        }
        
        if (!hasFailedToResolve) sink.add(currentValue);
      }

      return stream.listen(onData, onError: sink.addError, onDone: sink.close);
    });
  }
  
}