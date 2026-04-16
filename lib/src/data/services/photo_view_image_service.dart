import 'package:flutter/widgets.dart';

class PhotoViewImageService {
  const PhotoViewImageService();

  ImageStream resolve({
    required ImageProvider imageProvider,
    required ImageConfiguration configuration,
  }) {
    return imageProvider.resolve(configuration);
  }
}
