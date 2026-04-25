import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:myhiking/core/app_export.dart';

class AppLoadingIndicator extends StatelessWidget {
  static const String defaultAnimationAssetPath =
      'assets/lottie/sandy_loading.json';

  const AppLoadingIndicator({
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.valueColor,
    this.message,
    this.showMessage = false,
    this.isFullScreen = false,
    this.fit = BoxFit.contain,
    this.animationAssetPath = defaultAnimationAssetPath,
  });

  const AppLoadingIndicator.adaptive({
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
    this.valueColor,
    this.message,
    this.showMessage = false,
    this.isFullScreen = false,
    this.fit = BoxFit.contain,
    this.animationAssetPath = defaultAnimationAssetPath,
  });

  const AppLoadingIndicator.fullScreen({
    super.key,
    this.message,
    this.fit = BoxFit.contain,
    this.animationAssetPath = defaultAnimationAssetPath,
  })  : size = 180,
        color = null,
        strokeWidth = null,
        valueColor = null,
        showMessage = true,
        isFullScreen = true;

  final double? size;
  final Color? color;
  final double? strokeWidth;
  final Animation<Color?>? valueColor;
  final String? message;
  final bool showMessage;
  final bool isFullScreen;
  final BoxFit fit;
  final String animationAssetPath;

  double _resolveSize(BoxConstraints constraints) {
    if (size != null && size! > 0) {
      return size!;
    }

    final candidates = <double>[];
    if (constraints.hasBoundedWidth && constraints.maxWidth.isFinite) {
      candidates.add(constraints.maxWidth);
    }
    if (constraints.hasBoundedHeight && constraints.maxHeight.isFinite) {
      candidates.add(constraints.maxHeight);
    }

    if (candidates.isEmpty) {
      return 56;
    }

    final boundedSize = candidates.reduce(math.min);
    return boundedSize <= 0 ? 56 : boundedSize;
  }

  @override
  Widget build(BuildContext context) {
    final loadingMessage = message ?? 'Mohon tunggu...';

    if (isFullScreen) {
      return Material(
        color: Colors.white,
        child: SafeArea(
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomImageView(
                  imagePath: ImageConstant.imgNn,
                  height: 56.h,
                  width: 70.h,
                ),
                SizedBox(height: 14.h),
                Text(
                  'MyHiking',
                  style: theme.textTheme.headlineLarge,
                ),
                SizedBox(height: 26.h),
                SizedBox(
                  height: 180.h,
                  width: 180.h,
                  child: Lottie.asset(
                    animationAssetPath,
                    repeat: true,
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 34.h),
                  child: Text(
                    loadingMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final indicatorSize = _resolveSize(constraints);

        final animation = SizedBox(
          width: indicatorSize,
          height: indicatorSize,
          child: Lottie.asset(
            animationAssetPath,
            repeat: true,
            fit: fit,
          ),
        );

        if (!showMessage) {
          return animation;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            animation,
            const SizedBox(height: 12),
            Text(
              loadingMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
    );
  }
}
