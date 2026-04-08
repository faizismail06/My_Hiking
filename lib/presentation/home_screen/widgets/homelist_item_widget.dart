import 'package:flutter/material.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/presentation/detail_mountain_screen/bloc/detail_mountain_bloc.dart';
import 'package:myhiking/presentation/detail_mountain_screen/detail_mountain_screen.dart';
import '../../../core/app_export.dart';
import '../models/homelist_item_model.dart';

// ignore_for_file: must_be_immutable
class HomelistItemWidget extends StatelessWidget {
  HomelistItemWidget(
    this.homelistItemModelObj, {
    super.key,
    this.isRecommended = false,
  });

  HomelistItemModel homelistItemModelObj;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {

    String imageUrl = (homelistItemModelObj.gambar ??
        ''); // Menggabungkan base URL dengan nama gambar



    final recommendation = homelistItemModelObj.dss;

    return Card(
      color: isRecommended ? const Color(0xFFF2FBF7) : Colors.grey[100],
      elevation: isRecommended ? 3 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isRecommended
              ? const Color(0xFF1B8A5A).withOpacity(0.35)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.all(10.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRecommended)
              Container(
                margin: EdgeInsets.only(bottom: 8.h, left: 4.h),
                padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8A5A).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999.h),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: const Color(0xFF1B8A5A), size: 14.h),
                    SizedBox(width: 6.h),
                    Text(
                      'Direkomendasikan DSS',
                      style: TextStyle(
                        color: const Color(0xFF1B8A5A),
                        fontSize: 11.fSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 4.h),
            SizedBox(
              height: 172.h,
              width: double.maxFinite,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      onTapImgGunung(context, homelistItemModelObj);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        imageUrl,
                        height: 172.h,
                        width: double.maxFinite,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 172.h,
                            width: double.maxFinite,
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text('Gambar tidak tersedia'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),
            Padding(
              padding: EdgeInsets.only(left: 4.h),
              child: Text(
                homelistItemModelObj.namaGunung!,
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 4.h),
              child: Text(
                homelistItemModelObj.province?.name ??
                    'Provinsi Tidak Tersedia',
                style: CustomTextStyles.bodyMediumGray600,
              ),
            ),
            if (isRecommended && recommendation != null) ...[
              SizedBox(height: 8.h),
              Padding(
                padding: EdgeInsets.only(left: 4.h, right: 4.h),
                child: Text(
                  'Risk: ${recommendation.riskLevel.toUpperCase()}',
                  style: CustomTextStyles.bodySmallGray800,
                ),
              ),
            ],
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }
}

// onTapImgSlamet(BuildContext context) {
//   NavigatorService.pushNamed(AppRoutes.detailMountainScreen);
// }
// Future<void> onTapImgGunung(
//     BuildContext context, HomelistItemModel homelistItemModelObj) async {
//   final idGunung = homelistItemModelObj.id;

//   if (idGunung != null) {
//     final token = await ApiService().getToken();

//     if (token == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Silahkan login terlebih dahulu')),
//       );
//       return;
//     }

//     try {
//       final response = await ApiService().getUser(token);

//       if (response['success']) {
//         final userData = response['data'];
//         final userId = userData['id'];

//         if (userData['nik'] == null ||
//             userData['phone'] == null ||
//             userData['emergency_phone'] == null ||
//             userData['address'] == null ||
//             userData['nik'].toString().isEmpty ||
//             userData['phone'].toString().isEmpty ||
//             userData['emergency_phone'].toString().isEmpty ||
//             userData['address'].toString().isEmpty) {
//           showDialog(
//             context: context,
//             barrierDismissible: true,
//             builder: (_) => Dialog(
//               insetPadding: EdgeInsets.symmetric(horizontal: 40.h),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(14),
//               ),
//               child: PopUpLengkapiDataDiriDialog(
//                 userId: userData['id'],
//               ),
//             ),
//           );
//           return;
//         }
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => BlocProvider(
//               create: (context) => DetailMountainBloc(apiService: ApiService())
//                 ..add(DetailMountainInitialEvent(idGunung)),
//               child: DetailMountainScreen(idGunung: idGunung),
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       print('Error getting user data: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Terjadi kesalahan saat mengambil data user')),
//       );
//     }
//   } else {
//     print('Mountain ID tidak ditemukan');
//   }
// }

Future<void> onTapImgGunung(
    BuildContext context, HomelistItemModel homelistItemModelObj) async {
  final idGunung = homelistItemModelObj.id;

  if (idGunung != null) {
    // Langsung pindah ke halaman Detail Mountain tanpa cek NIK, Token, dll.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => DetailMountainBloc(apiService: ApiService())
            ..add(DetailMountainInitialEvent(idGunung)),
          child: DetailMountainScreen(idGunung: idGunung),
        ),
      ),
    );
  } else {
    print('Mountain ID tidak ditemukan');
    // Opsional: beri tahu user jika ID kosong
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data gunung tidak valid')),
    );
  }
}