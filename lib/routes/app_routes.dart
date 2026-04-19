import 'package:flutter/material.dart';
import 'package:myhiking/presentation/history_page/history_page.dart';
import 'package:myhiking/presentation/transaction_page/transaction_page.dart';
import 'package:myhiking/presentation/tiket_saya_page/tiket_saya_page.dart';
import 'package:myhiking/presentation/riwayat_transaksi_page/riwayat_transaksi_page.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/booking_screen/booking_screen.dart';
import '../presentation/data_profile_screen/data_profile_screen.dart';
import '../presentation/detail_mountain_screen/detail_mountain_screen.dart';
import '../presentation/kode_verifikasi_screen/kode_verifikasi_screen.dart';
import '../presentation/landing_screen/landing_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/pending_verification_screen/pending_verification_screen.dart';
import '../presentation/order_cancelled_screen/order_cancelled_screen.dart';
import '../presentation/payment_method_screen/payment_method_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/regist_screen/regist_screen.dart';
import '../presentation/reset_kirim_email_screen/reset_kirim_email_screen.dart';
import '../presentation/reset_page_two_screen/reset_page_two_screen.dart';
import '../presentation/payment_upload_screen/payment_upload_screen.dart';
import '../presentation/trail_screen/trail_screen.dart';
import '../presentation/experience_onboarding_screen/experience_onboarding_screen.dart';
import '../presentation/success_screen/success_screen.dart';
import '../presentation/rules_screen/rules_screen.dart';
import '../presentation/ticket_screen/ticket_screen.dart';
import '../presentation/ticket_action_screen/ticket_action_screen.dart';
import '../presentation/friend_screen/friend_screen.dart';
import '../presentation/chatbot_screen/chatbot_screen.dart';
import '../presentation/refund_request_page/refund_request_page.dart';
import '../presentation/refund_request_result_page/refund_request_result_page.dart';

class AppRoutes {
  static const String landingScreen = '/landing_screen';
  static const String root = '/';
  static const String loginScreen = '/login_screen';
  static const String registScreen = '/regist_screen';
  static const String resetKirimEmailScreen = '/reset_kirim_email_screen';
  static const String kodeVerifikasiScreen = '/kode_verifikasi_screen';
  static const String resetPageTwoScreen = '/reset_page_two_screen';
  static const String bookingScreen = '/booking_screen';
  static const String paymentMethodScreen = '/payment_method_screen';
  static const String paymentUploadScreen = '/payment_upload_screen';
  static const String pendingVerificationScreen = '/pending_verification_screen';
  static const String successScreen = '/success_screen';
  static const String orderCancelledScreen = '/order_cancelled_screen';
  static const String homeScreen = '/home_screen';
  static const String homeInitialPage = '/home_initial_page';
  static const String detailMountainScreen = '/detail_mountain_screen';
  static const String trailScreen = '/trail_screen';
  static const String rulesScreen = '/rules_screen';
  static const String profileScreen = '/profile_screen';
  static const String dataProfileScreen = '/data_profile_screen';
  static const String transactionPage = '/transaction_page';
  static const String ticketScreen = '/ticket_screen';
  static const String ticketActionScreen = '/ticket_action_screen';
  static const String historyPage = '/history_page';
  static const String tiketSayaPage = '/tiket_saya_page';
  static const String riwayatTransaksiPage = '/riwayat_transaksi_page';
  static const String friendScreen = '/friend_screen';
  static const String chatbotScreen = '/chatbot_screen';
  static const String refundRequestPage = '/refund_request_page';
  static const String refundRequestResultPage = '/refund_request_result_page';
  static const String experienceOnboardingScreen = '/experience_onboarding_screen';
  static const String appNavigationScreen = '/app_navigation_screen';
  static const String initialRoute = root;

  // Legacy route aliases for backward compatibility
  static const String berandaScreen = homeScreen;
  static const String berandaInitialPage = homeInitialPage;
  static const String pilihanBankPembayaranScreen = paymentMethodScreen;
  static const String rincianPembayaranUploadScreen = paymentUploadScreen;
  static const String menungguVerifikasiScreen = pendingVerificationScreen;
  static const String suksesScreen = successScreen;
  static const String pesananDibatalkanScreen = orderCancelledScreen;
  static const String routeScreen = trailScreen;
  static const String tataTertibScreen = rulesScreen;
  static const String transaksiPage = transactionPage;
  static const String tiketScreen = ticketScreen;
  static const String riwayatPage = historyPage;

  static Map<String, WidgetBuilder> get routes => {
      root: LandingScreen.builder,
        landingScreen: LandingScreen.builder,
        loginScreen: LoginScreen.builder,
        registScreen: RegistScreen.builder,
        resetKirimEmailScreen: ResetKirimEmailScreen.builder,
        kodeVerifikasiScreen: KodeVerifikasiScreen.builder,
        resetPageTwoScreen: ResetPageTwoScreen.builder,
        pendingVerificationScreen: (context) {
          final orderId = ModalRoute.of(context)?.settings.arguments as int?;

          if (orderId == null) {
            return Scaffold(
              body: Center(child: Text("Order ID is required")),
            );
          }

          return Builder(
            builder: (BuildContext context) {
              return PendingVerificationScreen(
                orderId: orderId,
              );
            },
          );
        },
        successScreen: SuccessScreen.builder,
        orderCancelledScreen: OrderCancelledScreen.builder,
        homeScreen: HomeScreen.builder,
        detailMountainScreen: (context) {
          final mountainId = ModalRoute.of(context)!.settings.arguments as int?;

          if (mountainId == null) {
            return Scaffold(
              body: Center(child: Text("Mountain ID not found")),
            );
          }

          return DetailMountainScreen(idGunung: mountainId);
        },
        profileScreen: ProfileScreen.builder,
        ticketScreen: (context) {
          final orderId = ModalRoute.of(context)?.settings.arguments as int?;

          if (orderId == null) {
            return Scaffold(
              body: Center(child: Text("Order ID is required")),
            );
          }
          return TicketScreen.builder(context, orderId);
        },
        ticketActionScreen: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            return Scaffold(
              body: Center(child: Text("Arguments are required")),
            );
          }
          return TicketActionScreen(
            orderId: args['orderId'] as int,
            status: args['status'] as String,
            mountainName: args['mountainName'] as String,
            hikingDate: args['hikingDate'] as String,
          );
        },
        appNavigationScreen: AppNavigationScreen.builder,
        transactionPage: TransactionPage.builder,
        historyPage: HistoryPage.builder,
        tiketSayaPage: TiketSayaPage.builder,
        riwayatTransaksiPage: RiwayatTransaksiPage.builder,
        friendScreen: (context) {
          final userId = ModalRoute.of(context)?.settings.arguments as int?;

          if (userId == null) {
            return Scaffold(
              body: Center(child: Text("User ID is required")),
            );
          }

          return FriendScreen.builder(context, userId);
        },
        chatbotScreen: ChatbotScreen.builder,
        refundRequestPage: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            return Scaffold(
              body: Center(child: Text("Arguments are required")),
            );
          }

          return RefundRequestPage(
            orderId: args['orderId'] as int,
            mountainName: args['mountainName'] as String? ?? 'Gunung',
            hikingDate: args['hikingDate'] as String? ?? '-',
          );
        },
        refundRequestResultPage: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          if (args == null) {
            return Scaffold(
              body: Center(child: Text("Arguments are required")),
            );
          }

          return RefundRequestResultPage(
            orderId: args['orderId'] as int,
            mountainName: args['mountainName'] as String? ?? 'Gunung',
            hikingDate: args['hikingDate'] as String? ?? '-',
          );
        },
        experienceOnboardingScreen: (context) => const ExperienceOnboardingScreen(),
      };
}
