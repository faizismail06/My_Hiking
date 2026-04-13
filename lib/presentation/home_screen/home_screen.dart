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
        backgroundColor: theme.colorScheme.onPrimary, // Pastikan background bersih
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
                    transitionDuration: const Duration(milliseconds: 200), // Sedikit transisi agar lebih smooth
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                ),
              ),
              SizedBox(height: 8.h)
            ],
          ),
        ),
        // Floating Action Button untuk Chatbot yang dimodernisasi
        floatingActionButton: _buildChatbotFAB(context),
        bottomNavigationBar: SizedBox(
          width: double.maxFinite,
          child: _buildBottomNavigation(context),
        ),
      ),
    );
  }

  /// Widget untuk Chatbot FAB Modern (Glowing effect)
  Widget _buildChatbotFAB(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.4),
              blurRadius: 16.h,
              spreadRadius: 2.h,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              AppRoutes.chatbotScreen,
            );
          },
          backgroundColor: Colors.transparent, // Transparan agar gradient box terlihat
          elevation: 0, // Matikan default elevation untuk custom shadow
          child: Container(
            width: double.maxFinite,
            height: double.maxFinite,
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.9),
                  const Color(0xFF1B8A5A),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              color: Colors.white,
              size: 26.h,
            ),
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