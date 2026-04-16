import 'package:flutter/widgets.dart';
import 'package:photo_view/src/data/models/photo_view_image_state.dart';
import 'package:photo_view/src/data/services/photo_view_image_service.dart';

class PhotoViewImageRepository extends ChangeNotifier {
  PhotoViewImageRepository({
    PhotoViewImageService? imageService,
  }) : _imageService = imageService ?? const PhotoViewImageService();

  final PhotoViewImageService _imageService;

  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;
  PhotoViewImageState _state = const PhotoViewImageState.loading();
  int _resolveVersion = 0;

  PhotoViewImageState get state => _state;

  void resolve({
    required ImageProvider imageProvider,
    required ImageConfiguration configuration,
  }) {
    final nextVersion = ++_resolveVersion;
    final ImageStream newStream = _imageService.resolve(
      imageProvider: imageProvider,
      configuration: configuration,
    );

    if (_imageStream?.key == newStream.key) {
      return;
    }

    _detach();
    _state = const PhotoViewImageState.loading();
    notifyListeners();

    _imageStream = newStream;
    _imageStreamListener = ImageStreamListener(
      (info, synchronousCall) =>
          _handleImageFrame(nextVersion, newStream, info, synchronousCall),
      onChunk: (event) => _handleImageChunk(nextVersion, newStream, event),
      onError: (error, stackTrace) =>
          _handleImageError(nextVersion, newStream, error, stackTrace),
    );
    _imageStream!.addListener(_imageStreamListener!);
  }

  void _handleImageChunk(
    int version,
    ImageStream stream,
    ImageChunkEvent event,
  ) {
    if (!_isCurrent(version, stream)) {
      return;
    }

    _state = PhotoViewImageState.loading(
      loadingProgress: event,
    );
    notifyListeners();
  }

  void _handleImageFrame(
    int version,
    ImageStream stream,
    ImageInfo info,
    bool synchronousCall,
  ) {
    if (!_isCurrent(version, stream)) {
      return;
    }

    _state = PhotoViewImageState.ready(
      imageSize: Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ),
    );
    notifyListeners();
    _detach();
    _imageStream = null;
  }

  void _handleImageError(
    int version,
    ImageStream stream,
    Object error,
    StackTrace? stackTrace,
  ) {
    if (!_isCurrent(version, stream)) {
      return;
    }

    _state = PhotoViewImageState.error(
      error: error,
      stackTrace: stackTrace,
    );
    notifyListeners();
    _detach();
    _imageStream = null;
  }

  bool _isCurrent(int version, ImageStream stream) {
    return version == _resolveVersion &&
        _imageStream != null &&
        identical(_imageStream!.key, stream.key);
  }

  void _detach() {
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }
    _imageStreamListener = null;
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }
}
