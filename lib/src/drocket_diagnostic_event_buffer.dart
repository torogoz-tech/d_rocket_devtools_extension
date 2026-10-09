/// Bounded event storage shared by the DevTools snapshot and live stream.
///
/// Reusing the same buffer for every VM Service subscription makes reconnects
/// idempotent: an event already received before a disconnect is not inserted
/// again when the stream is subscribed again.
class DrocketDiagnosticEventBuffer {
  DrocketDiagnosticEventBuffer({this.capacity = 500}) : assert(capacity > 0);

  final int capacity;
  final List<Map<String, Object?>> _items = <Map<String, Object?>>[];

  List<Map<String, Object?>> get items =>
      List<Map<String, Object?>>.unmodifiable(_items);

  bool contains(Map<String, Object?> event) {
    final id = event['id'];
    return id != null && _items.any((item) => item['id'] == id);
  }

  bool add(Map<String, Object?> event) {
    if (contains(event)) return false;
    _items.add(event);
    _sort();
    if (_items.length > capacity) {
      _items.removeRange(capacity, _items.length);
    }
    return true;
  }

  void replaceAll(Iterable<Map<String, Object?>> events) {
    _items
      ..clear()
      ..addAll(events);
    _sort();
    if (_items.length > capacity) {
      _items.removeRange(capacity, _items.length);
    }
  }

  void clear() => _items.clear();

  void _sort() {
    _items.sort((left, right) {
      final leftTime = DateTime.tryParse('${left['startedAt']}');
      final rightTime = DateTime.tryParse('${right['startedAt']}');
      if (leftTime == null && rightTime == null) return 0;
      if (leftTime == null) return 1;
      if (rightTime == null) return -1;
      return rightTime.compareTo(leftTime);
    });
  }
}
