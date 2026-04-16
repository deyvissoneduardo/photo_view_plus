import 'package:flutter/widgets.dart';
import 'package:photo_view_plus/src/ui/coordinators/photo_view_controller_delegate.dart'
    show PhotoViewControllerDelegate;

mixin HitCornersDetector on PhotoViewControllerDelegate {
  bool shouldMove(Offset move, Axis mainAxis) {
    return layoutMetrics().shouldMove(move, mainAxis);
  }
}
