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

  PhotoViewImageState get state => _state;

  void resolve({
    required ImageProvider imageProvider,
    required ImageConfiguration configuration,
  }) {
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
      _handleImageFrame,
      onChunk: _handleImageChunk,
      onError: _handleImageError,
    );
    _imageStream!.addListener(_imageStreamListener!);
  }

  void _handleImageChunk(ImageChunkEvent event) {
    _state = PhotoViewImageState.loading(
      loadingProgress: event,
    );
    notifyListeners();
  }

  void _handleImageFrame(ImageInfo info, bool synchronousCall) {
    _state = PhotoViewImageState.ready(
      imageSize: Size(
        info.image.width.toDouble(),
        info.image.height.toDouble(),
      ),
    );
    notifyListeners();
  }

  void _handleImageError(Object error, StackTrace? stackTrace) {
    _state = PhotoViewImageState.error(
      error: error,
      stackTrace: stackTrace,
    );
    notifyListeners();
  }

  void _detach() {
    if (_imageStreamListener != null) {
      _imageStream?.removeListener(_imageStreamListener!);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }
}
