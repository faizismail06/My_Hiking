import 'package:flutter/material.dart';
import 'package:myhiking/presentation/profile_screen/profile_screen.dart';
import '../../core/app_export.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../tiket_saya_page/tiket_saya_page.dart';
import 'home_initial_page.dart';
import 'bloc/home_bloc.dart';
import 'models/home_model.dart';

// ignore_for_file: must_be_immutable
class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  GlobalKey<NavigatorState> navigatorKey = GlobalKey();

  static Widget builder(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (context) => HomeBloc(
        HomeState(homeModelObj: const HomeModel()),
      )..add(HomeInitialEvent()),
      child: HomeScreen(),
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
                  initialRoute: AppRoutes.homeInitialPage,
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
        // Floating Action Button untuk Chatbot
        floatingActionButton: _buildChatbotFAB(context),
        bottomNavigationBar: SizedBox(
          width: double.maxFinite,
          child: _buildBottomNavigation(context),
        ),
      ),
    );
  }

  /// Widget untuk Chatbot FAB
  Widget _buildChatbotFAB(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: FloatingActionButton(
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pushNamed(
            AppRoutes.chatbotScreen,
          );
        },
        backgroundColor: theme.colorScheme.primary,
        elevation: 6,
        child: Container(
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 28.h,
          ),
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
        return AppRoutes.homeInitialPage;
      case BottomBarEnum.Iconmap:
        return AppRoutes.tiketSayaPage;
      case BottomBarEnum.Iconprofile:
        return AppRoutes.profileScreen;
      default:
        return "/";
    }
  }

  /// Handling page based on route
  Widget getCurrentPage(BuildContext context, String currentRoute) {
    switch (currentRoute) {
      case AppRoutes.homeInitialPage:
        return HomeInitialPage.builder(context);
      case AppRoutes.tiketSayaPage:
        return TiketSayaPage.builder(context);
      case AppRoutes.profileScreen:
        return ProfileScreen.builder(context);
      default:
        return const DefaultWidget();
    }
  }
}
