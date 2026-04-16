import 'package:flutter/widgets.dart';

@immutable
class PhotoViewImageState {
  const PhotoViewImageState({
    required this.isLoading,
    this.loadingProgress,
    this.imageSize,
    this.error,
    this.stackTrace,
  });

  const PhotoViewImageState.loading({
    this.loadingProgress,
  })  : isLoading = true,
        imageSize = null,
        error = null,
        stackTrace = null;

  const PhotoViewImageState.ready({
    required Size this.imageSize,
  })  : isLoading = false,
        loadingProgress = null,
        error = null,
        stackTrace = null;

  const PhotoViewImageState.error({
    required Object this.error,
    this.stackTrace,
  })  : isLoading = false,
        loadingProgress = null,
        imageSize = null;

  final bool isLoading;
  final ImageChunkEvent? loadingProgress;
  final Size? imageSize;
  final Object? error;
  final StackTrace? stackTrace;

  bool get hasError => error != null;
  bool get isReady => imageSize != null;

  PhotoViewImageState copyWith({
    bool? isLoading,
    ImageChunkEvent? loadingProgress,
    Size? imageSize,
    Object? error,
    StackTrace? stackTrace,
    bool clearError = false,
    bool clearImage = false,
  }) {
    return PhotoViewImageState(
      isLoading: isLoading ?? this.isLoading,
      loadingProgress: loadingProgress ?? this.loadingProgress,
      imageSize: clearImage ? null : imageSize ?? this.imageSize,
      error: clearError ? null : error ?? this.error,
      stackTrace: clearError ? null : stackTrace ?? this.stackTrace,
    );
  }
}
