import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';

class AppLoadingOverlay {
  const AppLoadingOverlay._();

  static bool _isShowing = false;

  static Future<void> show(
    BuildContext context, {
    String message = 'Mohon tunggu...',
    String animationAssetPath = AppLoadingIndicator.defaultAnimationAssetPath,
    bool dismissible = false,
    bool asPopup = false,
  }) async {
    if (_isShowing || !context.mounted) {
      return;
    }

    _isShowing = true;

    if (asPopup) {
      await showDialog<void>(
        context: context,
        barrierDismissible: dismissible,
        builder: (dialogContext) {
          return PopScope(
            canPop: dismissible,
            child: Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: AppLoadingIndicator(
                  size: 130,
                  message: message,
                  showMessage: true,
                  animationAssetPath: animationAssetPath,
                ),
              ),
            ),
          );
        },
      ).whenComplete(() {
        _isShowing = false;
      });
    } else {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: dismissible,
        barrierLabel: 'App Loading',
        barrierColor: Colors.white,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return PopScope(
            canPop: dismissible,
            child: AppLoadingIndicator.fullScreen(
              message: message,
              animationAssetPath: animationAssetPath,
            ),
          );
        },
        transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      ).whenComplete(() {
        _isShowing = false;
      });
    }
  }

  static void hide(BuildContext context) {
    if (!_isShowing || !context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
  }
}
