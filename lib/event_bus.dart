class EventBus {
  static EventBus _instance = EventBus._();

  factory EventBus() => _instance ??= EventBus._();

  EventBus._();

  Map<Type, List<Function>> _listeners = {};

  void fireEvent<T>(T event) {
    var type = T;
    if (_listeners.containsKey(type)) {
      _listeners[type]?.forEach((listener) {
        listener(event);
      });
    }
  }

  void addListener<T>(Function(T) listener) {
    var type = T;
    _listeners[type] ??= [];
    _listeners[type]?.add(listener);
  }

  void removeListener<T>(Function(T) listener) {
    var type = T;
    if (_listeners.containsKey(type)) {
      _listeners[type]?.remove(listener);
    }
  }
}
