import 'package:flutter/widgets.dart';
import 'package:photo_view/src/data/models/photo_view_image_state.dart';
import 'package:photo_view/src/data/repositories/photo_view_image_repository.dart';

class PhotoViewImageViewModel extends ChangeNotifier {
  PhotoViewImageViewModel({
    required PhotoViewImageRepository repository,
  }) : _repository = repository {
    _repository.addListener(_repositoryListener);
  }

  final PhotoViewImageRepository _repository;

  PhotoViewImageState get state => _repository.state;

  void resolveImage({
    required ImageProvider imageProvider,
    required ImageConfiguration configuration,
  }) {
    _repository.resolve(
      imageProvider: imageProvider,
      configuration: configuration,
    );
  }

  void _repositoryListener() {
    notifyListeners();
  }

  @override
  void dispose() {
    _repository.removeListener(_repositoryListener);
    super.dispose();
  }
}
