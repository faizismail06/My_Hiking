import 'package:flutter/material.dart';
import 'package:myhiking/core/utils/navigator_service.dart';

class ProgressDialogUtils {
  static bool isProgressVisible = false;

  /// Common method for showing progress dialog
  static void showProgressDialog({
    BuildContext? context,
    bool isCancellable = false,
  }) async {
    if (!isProgressVisible &&
        NavigatorService.navigatorKey.currentState?.overlay?.context != null) {
      showDialog(
        barrierDismissible: isCancellable,
        context: NavigatorService.navigatorKey.currentState!.overlay!.context,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white,
              ),
            ),
          );
        },
      );
      isProgressVisible = true;
    }
  }

  /// Common method for hiding progress dialog
  static void hideProgressDialog() {
    if (isProgressVisible) {
      final overlayContext = NavigatorService.navigatorKey.currentState?.overlay?.context;
      if (overlayContext != null) {
        final navigator = Navigator.of(overlayContext, rootNavigator: true);
        if (navigator.canPop()) {
          navigator.pop();
        }
      }
      isProgressVisible = false;
    }
  }
}
