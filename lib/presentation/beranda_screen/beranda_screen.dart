import 'package:flutter/material.dart';
import 'package:myhiking/presentation/profile_screen/profile_screen.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../riwayat_page/riwayat_page.dart';
import 'beranda_initial_page.dart';
import 'bloc/beranda_bloc.dart';
import 'models/beranda_model.dart';

// ignore_for_file: must_be_immutable
class BerandaScreen extends StatelessWidget {
  BerandaScreen({super.key});

  GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  static Widget builder(BuildContext context) {
    return BlocProvider<BerandaBloc>(
      create: (context) => BerandaBloc(
        BerandaState(berandaModelObj: const BerandaModel()),
      )..add(BerandaInitialEvent()),
      child: BerandaScreen(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            color: theme.colorScheme.onPrimary,
          ),
          child: Column(
            children: [
              Expanded(
                child: Navigator(
                  key: navigatorKey,
                  initialRoute: AppRoutes.berandaInitialPage,
                  onGenerateRoute: (routeSetting) => PageRouteBuilder(
                    pageBuilder: (ctx, ani, ani1) =>
                        getCurrentPage(context, routeSetting.name!),
                    transitionDuration: const Duration(seconds: 0),
                  ),
                ),
              ),
              SizedBox(height: 8.h)
            ],
          ),
        ),
        bottomNavigationBar: SizedBox(
          width: double.maxFinite,
          child: _buildBottomNavigation(context),
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildBottomNavigation(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: CustomBottomBar(
        onChanged: (BottomBarEnum type) {
          Navigator.pushNamed(
              navigatorKey.currentContext!, getCurrentRoute(type));
        },
      ),
    );
  }

  /// Handling route based on bottom click actions
  String getCurrentRoute(BottomBarEnum type) {
    switch (type) {
      case BottomBarEnum.Favorite:
        return AppRoutes.berandaInitialPage;
      case BottomBarEnum.Iconmap:
        return AppRoutes.riwayatPage;
      case BottomBarEnum.Iconprofile:
        return AppRoutes.profileScreen;
      default:
        return "/";
    }
  }

  /// Handling page based on route
  Widget getCurrentPage(BuildContext context, String currentRoute) {
    switch (currentRoute) {
      case AppRoutes.berandaInitialPage:
        return BerandaInitialPage.builder(context);
      case AppRoutes.riwayatPage:
        return RiwayatPage.builder(context);
      case AppRoutes.profileScreen:
        return ProfileScreen.builder(context);
      default:
        return const DefaultWidget();
    }
  }
}
