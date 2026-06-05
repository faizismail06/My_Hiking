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
  }) async {
    if (_isShowing || !context.mounted) {
      return;
    }

    _isShowing = true;

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

  static void hide(BuildContext context) {
    if (!_isShowing || !context.mounted) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop();
  }
}
