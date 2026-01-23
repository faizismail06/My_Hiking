import 'package:flutter/material.dart';
import 'package:myhiking/presentation/riwayat_page/riwayat_page.dart';
import 'package:myhiking/presentation/transaksi_page/transaksi_page.dart';
import '../presentation/app_navigation_screen/app_navigation_screen.dart';
import '../presentation/beranda_screen/beranda_screen.dart';
import '../presentation/booking_screen/booking_screen.dart';
import '../presentation/data_profile_screen/data_profile_screen.dart';
import '../presentation/detail_mountain_screen/detail_mountain_screen.dart';
import '../presentation/kode_verifikasi_screen/kode_verifikasi_screen.dart';
import '../presentation/landing_screen/landing_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/menunggu_verifikasi_screen/menunggu_verifikasi_screen.dart';
import '../presentation/pesanan_dibatalkan_screen/pesanan_dibatalkan_screen.dart';
import '../presentation/pilihan_bank_pembayaran_screen/pilihan_bank_pembayaran_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/regist_screen/regist_screen.dart';
import '../presentation/reset_kirim_email_screen/reset_kirim_email_screen.dart';
import '../presentation/reset_page_two_screen/reset_page_two_screen.dart';
import '../presentation/rincian_pembayaran_upload_screen/rincian_pembayaran_upload_screen.dart';
import '../presentation/route_screen/route_screen.dart';
import '../presentation/sukses_screen/sukses_screen.dart';
import '../presentation/tata_tertib_screen/tata_tertib_screen.dart';
import '../presentation/tiket_screen/tiket_screen.dart';

class AppRoutes {
  static const String landingScreen = '/landing_screen';
  static const String loginScreen = '/login_screen';
  static const String registScreen = '/regist_screen';
  static const String resetKirimEmailScreen = '/reset_kirim_email_screen';
  static const String kodeVerifikasiScreen = '/kode_verifikasi_screen';
  static const String resetPageTwoScreen = '/reset_page_two_screen';
  static const String bookingScreen = '/booking_screen';
  static const String pilihanBankPembayaranScreen =
      '/pilihan_bank_pembayaran_screen';
  static const String rincianPembayaranUploadScreen =
      '/rincian_pembayaran_upload_screen';
  static const String menungguVerifikasiScreen = '/menunggu_verifikasi_screen';
  static const String suksesScreen = '/sukses_screen';
  static const String pesananDibatalkanScreen = '/pesanan_dibatalkan_screen';
  static const String berandaScreen = '/beranda_screen';
  static const String berandaInitialPage = '/beranda_initial_page';
  static const String detailMountainScreen = '/detail_mountain_screen';
  static const String routeScreen = '/route_screen';
  static const String tataTertibScreen = '/tata_tertib_screen';
  static const String profileScreen = '/profile_screen';
  static const String dataProfileScreen = '/data_profile_screen';
  static const String transaksiPage = '/transaksi_page';
  static const String tiketScreen = '/tiket_screen';
  static const String riwayatPage = '/riwayat_page';
  static const String appNavigationScreen = '/app_navigation_screen';
  static const String initialRoute = '/initialRoute';

  static Map<String, WidgetBuilder> get routes => {
        landingScreen: LandingScreen.builder,
        loginScreen: LoginScreen.builder,
        registScreen: RegistScreen.builder,
        resetKirimEmailScreen: ResetKirimEmailScreen.builder,
        kodeVerifikasiScreen: KodeVerifikasiScreen.builder,
        resetPageTwoScreen: ResetPageTwoScreen.builder,
        menungguVerifikasiScreen: (context) {
          final pesananId = ModalRoute.of(context)?.settings.arguments as int?;

          if (pesananId == null) {
            return Scaffold(
              body: Center(child: Text("Pesanan ID is required")),
            );
          }

          return Builder(
            builder: (BuildContext context) {
              return MenungguVerifikasiScreen(
                // If MenungguVerifikasiScreen is a widget, pass required parameters
                pesananId: pesananId,
              );
            },
          );
        },
        suksesScreen: SuksesScreen.builder,
        pesananDibatalkanScreen: PesananDibatalkanScreen.builder,
        berandaScreen: BerandaScreen.builder,
        detailMountainScreen: (context) {
          // Periksa apakah arguments ada dan lakukan casting dengan aman
          final idGunung = ModalRoute.of(context)!.settings.arguments as int?;

          // Periksa jika idGunung null, bisa mengarahkan ke halaman lain atau memberikan nilai default
          if (idGunung == null) {
            // Jika idGunung null, kembalikan halaman error atau halaman lain
            return Scaffold(
              body: Center(child: Text("ID Gunung tidak ditemukan")),
            );
          }

          // Jika idGunung tidak null, lanjutkan dengan navigasi
          return DetailMountainScreen(idGunung: idGunung);
        },
        // routeScreen: RouteScreen.builder,
        // tataTertibScreen: TataTertibScreen.builder,
        profileScreen: ProfileScreen.builder,
        // dataProfileScreen: DataProfileScreen.builder,
        tiketScreen: (context) {
          final pesananId = ModalRoute.of(context)?.settings.arguments as int?;

          if (pesananId == null) {
            // Handle the case where pesananId is not provided or invalid
            return Scaffold(
              body: Center(child: Text("Pesanan ID is required")),
            );
          }
          return TiketScreen.builder(context, pesananId);
        },
        appNavigationScreen: AppNavigationScreen.builder,
        initialRoute: LandingScreen.builder,
        transaksiPage: TransaksiPage.builder,
        riwayatPage: RiwayatPage.builder
      };
}
