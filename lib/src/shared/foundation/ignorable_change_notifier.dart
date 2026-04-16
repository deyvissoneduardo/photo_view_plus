import 'package:flutter/foundation.dart';

class IgnorableChangeNotifier extends ChangeNotifier {
  ObserverList<VoidCallback>? _ignorableListeners =
      ObserverList<VoidCallback>();

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_ignorableListeners == null) {
        AssertionError([
          'A $runtimeType was used after being disposed.',
          'Once you have called dispose() on a $runtimeType, it can no longer be used.'
        ]);
      }
      return true;
    }());
    return true;
  }

  @override
  bool get hasListeners {
    return super.hasListeners || (_ignorableListeners?.isNotEmpty ?? false);
  }

  void addIgnorableListener(listener) {
    assert(_debugAssertNotDisposed());
    _ignorableListeners!.add(listener);
  }

  void removeIgnorableListener(listener) {
    assert(_debugAssertNotDisposed());
    _ignorableListeners!.remove(listener);
  }

  @override
  void dispose() {
    _ignorableListeners = null;
    super.dispose();
  }

  @protected
  @override
  @visibleForTesting
  void notifyListeners() {
    super.notifyListeners();
    if (_ignorableListeners != null) {
      final List<VoidCallback> localListeners =
          List<VoidCallback>.from(_ignorableListeners!);
      for (VoidCallback listener in localListeners) {
        try {
          if (_ignorableListeners!.contains(listener)) {
            listener();
          }
        } catch (exception, stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: exception,
              stack: stack,
              library: 'Photoview library',
            ),
          );
        }
      }
    }
  }

  @protected
  void notifySomeListeners() {
    super.notifyListeners();
  }
}

class IgnorableValueNotifier<T> extends IgnorableChangeNotifier
    implements ValueListenable<T> {
  IgnorableValueNotifier(this._value);

  @override
  T get value => _value;
  T _value;

  set value(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifyListeners();
  }

  void updateIgnoring(T newValue) {
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    notifySomeListeners();
  }

  @override
  String toString() => '${describeIdentity(this)}($value)';
}
