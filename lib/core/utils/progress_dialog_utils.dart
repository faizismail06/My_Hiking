import 'package:flutter/material.dart';
import 'package:myhiking/core/utils/navigator_service.dart';

class ProgressDialogUtils {
  static bool isProgressVisible = false;
  static BuildContext? _progressDialogContext;

  /// Common method for showing progress dialog
  static void showProgressDialog({
    BuildContext? context,
    bool isCancellable = false,
  }) async {
    if (!isProgressVisible &&
        NavigatorService.navigatorKey.currentState?.overlay?.context != null) {
      showDialog(
        useRootNavigator: true,
        barrierDismissible: isCancellable,
        context: NavigatorService.navigatorKey.currentState!.overlay!.context,
        builder: (BuildContext dialogContext) {
          _progressDialogContext = dialogContext;
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
      final dialogContext = _progressDialogContext;
      if (dialogContext != null) {
        try {
          Navigator.of(dialogContext, rootNavigator: true).pop();
        } catch (_) {
          // Ignore when dialog context is no longer active.
        }
      }
      _progressDialogContext = null;
      isProgressVisible = false;
    }
  }
}
