import 'dart:async';
import 'dart:ui';

import 'package:flutter/widgets.dart' show VoidCallback;
import 'package:photo_view_plus/src/domain/models/models.dart';
import 'package:photo_view_plus/src/shared/foundation/ignorable_change_notifier.dart';

typedef ScaleStateListener = void Function(double prevScale, double nextScale);

class PhotoViewScaleStateController {
  late final IgnorableValueNotifier<PhotoViewScaleState> _scaleStateNotifier =
      IgnorableValueNotifier(PhotoViewScaleState.initial)
        ..addListener(_scaleStateChangeListener);
  final StreamController<PhotoViewScaleState> _outputScaleStateCtrl =
      StreamController<PhotoViewScaleState>.broadcast()
        ..sink.add(PhotoViewScaleState.initial);

  Stream<PhotoViewScaleState> get outputScaleStateStream =>
      _outputScaleStateCtrl.stream;

  PhotoViewScaleState prevScaleState = PhotoViewScaleState.initial;

  PhotoViewScaleState get scaleState => _scaleStateNotifier.value;

  set scaleState(PhotoViewScaleState newValue) {
    if (_scaleStateNotifier.value == newValue) {
      return;
    }

    prevScaleState = _scaleStateNotifier.value;
    _scaleStateNotifier.value = newValue;
  }

  bool get hasChanged => prevScaleState != scaleState;

  bool get isZooming =>
      scaleState == PhotoViewScaleState.zoomedIn ||
      scaleState == PhotoViewScaleState.zoomedOut;

  void reset() {
    prevScaleState = scaleState;
    scaleState = PhotoViewScaleState.initial;
  }

  void dispose() {
    _outputScaleStateCtrl.close();
    _scaleStateNotifier.dispose();
  }

  void setInvisibly(PhotoViewScaleState newValue) {
    if (_scaleStateNotifier.value == newValue) {
      return;
    }
    prevScaleState = _scaleStateNotifier.value;
    _scaleStateNotifier.updateIgnoring(newValue);
  }

  void _scaleStateChangeListener() {
    _outputScaleStateCtrl.sink.add(scaleState);
  }

  void addIgnorableListener(VoidCallback callback) {
    _scaleStateNotifier.addIgnorableListener(callback);
  }

  void removeIgnorableListener(VoidCallback callback) {
    _scaleStateNotifier.removeIgnorableListener(callback);
  }
}
