import 'package:flutter/material.dart';
import '../core/app_export.dart';

enum BottomBarEnum { Favorite, Iconmap, Iconprofile }

class CustomBottomBar extends StatefulWidget {
  CustomBottomBar({
    super.key,
    this.onChanged,
    this.initialIndex = 0,
  });

  final int initialIndex;
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
  void initState() {
    super.initState();
    selectedIndex =
        widget.initialIndex.clamp(0, bottomMenuList.length - 1).toInt();
  }

  @override
  void didUpdateWidget(covariant CustomBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIndex =
        widget.initialIndex.clamp(0, bottomMenuList.length - 1).toInt();
    if (nextIndex != selectedIndex) {
      setState(() {
        selectedIndex = nextIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68.h,
      decoration: BoxDecoration(
        color: const Color(0XFFFFFFFF),
        borderRadius: BorderRadius.circular(10.h),
        boxShadow: [
          BoxShadow(
            color: const Color(0X3F000000),
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(0, -1),
          )
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
            icon: CustomImageView(
              imagePath: bottomMenuList[index].icon,
              height: _getIconHeight(index), // Set ukuran ikon
              width: _getIconWidth(index), // Set ukuran ikon
              color: const Color(0XFFCAD8EA),
            ),
            activeIcon: CustomImageView(
              imagePath: bottomMenuList[index].activeIcon,
              height: _getIconHeight(index), // Set ukuran ikon aktif
              width: _getIconWidth(index), // Set ukuran ikon aktif
              color: const Color(0XFF127857),
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
