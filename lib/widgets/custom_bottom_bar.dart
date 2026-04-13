import 'package:flutter/material.dart';
import '../core/app_export.dart';

enum BottomBarEnum { Favorite, Iconmap, Iconprofile }

class CustomBottomBar extends StatefulWidget {
  CustomBottomBar({super.key, this.onChanged});
  Function(BottomBarEnum)? onChanged;

  @override
  CustomBottomBarState createState() => CustomBottomBarState();
}

class CustomBottomBarState extends State<CustomBottomBar> {
  int selectedIndex = 0;
  List<BottomMenuModel> bottomMenuList = [
    BottomMenuModel(
      icon: ImageConstant.imgFavorite,
      activeIcon: ImageConstant.imgFavorite,
      type: BottomBarEnum.Favorite,
    ),
    BottomMenuModel(
      icon: ImageConstant.imgIconMap,
      activeIcon: ImageConstant.imgIconMap,
      type: BottomBarEnum.Iconmap,
    ),
    BottomMenuModel(
      icon: ImageConstant.imgLockBlueGray10002,
      activeIcon: ImageConstant.imgLockBlueGray10002,
      type: BottomBarEnum.Iconprofile,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72.h,
      margin: EdgeInsets.only(bottom: 12.h, left: 12.h, right: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.green600.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 16.h,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: appTheme.black900.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 2.h,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedFontSize: 0,
        elevation: 0,
        currentIndex: selectedIndex,
        type: BottomNavigationBarType.fixed,
        items: List.generate(bottomMenuList.length, (index) {
          return BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Container(
                decoration: selectedIndex == index
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          begin: const Alignment(-1, 0),
                          end: const Alignment(1, 0),
                          colors: [
                            appTheme.green600,
                            appTheme.emerald400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.h),
                      )
                    : null,
                padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 8.h),
                child: CustomImageView(
                  imagePath: bottomMenuList[index].icon,
                  height: _getIconHeight(index),
                  width: _getIconWidth(index),
                  color: selectedIndex == index
                      ? Colors.white
                      : const Color(0XFFCAD8EA),
                ),
              ),
            ),
            activeIcon: Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: const Alignment(-1, 0),
                    end: const Alignment(1, 0),
                    colors: [
                      appTheme.green600,
                      appTheme.emerald400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.h),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.h, vertical: 8.h),
                child: CustomImageView(
                  imagePath: bottomMenuList[index].activeIcon,
                  height: _getIconHeight(index),
                  width: _getIconWidth(index),
                  color: Colors.white,
                ),
              ),
            ),
            label: '',
          );
        }),
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
          widget.onChanged?.call(bottomMenuList[index].type);
        },
      ),
    );
  }

  // Function untuk menentukan tinggi ikon berdasarkan indeks
  double _getIconHeight(int index) {
    if (index == 0) {
      return 36.h; // Ukuran untuk Favorite
    } else if (index == 1) {
      return 33.h; // Ukuran untuk Iconmap
    } else {
      return 28.h; // Ukuran untuk Iconprofile
    }
  }

  // Function untuk menentukan lebar ikon berdasarkan indeks
  double _getIconWidth(int index) {
    if (index == 0) {
      return 36.h; // Ukuran untuk Favorite
    } else if (index == 1) {
      return 33.h; // Ukuran untuk Iconmap
    } else {
      return 30.h; // Ukuran untuk Iconprofile
    }
  }
}

class BottomMenuModel {
  BottomMenuModel(
      {required this.icon, required this.activeIcon, required this.type});
  String icon;
  String activeIcon;
  BottomBarEnum type;
}

class DefaultWidget extends StatelessWidget {
  const DefaultWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffffffff),
      padding: const EdgeInsets.all(10),
      child: const Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Please replace the respective Widget here',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
