import 'package:flutter/material.dart';
import '../../core/app_export.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.height,
    this.leadingWidth,
    this.leading,
    this.title,
    this.centerTitle,
    this.actions,
    this.useGradient = true,
  });

  final double? height;
  final double? leadingWidth;
  final Widget? leading;
  final Widget? title;
  final bool? centerTitle;
  final List<Widget>? actions;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: useGradient
          ? BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1, -1),
                end: const Alignment(1, 1),
                colors: [
                  const Color(0XFF1DB854),
                  const Color(0XFF0D7E4A),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: appTheme.green600.withOpacity(0.2),
                  spreadRadius: 0,
                  blurRadius: 12.h,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : null,
      child: AppBar(
        elevation: 0,
        toolbarHeight: height ?? 56.h,
        automaticallyImplyLeading: false,
        backgroundColor: useGradient ? Colors.transparent : Colors.transparent,
        leadingWidth: leadingWidth ?? 0,
        leading: leading,
        title: title,
        titleSpacing: 0,
        centerTitle: centerTitle ?? false,
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => Size(
        SizeUtils.width,
        height ?? 56.h,
      );
}
