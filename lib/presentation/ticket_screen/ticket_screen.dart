import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/presentation/ticket_screen/models/ticket_model.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg_provider/flutter_svg_provider.dart' as fs;
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import 'package:dotted_line/dotted_line.dart';
import '../../widgets/app_bar/appbar_title.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/ticket_bloc.dart';

// Main Ticket Screen
class TicketScreen extends StatefulWidget {
  final int orderId;

  const TicketScreen({super.key, required this.orderId});

  static Widget builder(BuildContext context, int orderId) {
    return BlocProvider<TicketBloc>(
      create: (context) =>
          TicketBloc()..add(TicketLoadDataEvent(pesananId: orderId)),
      child: TicketScreen(orderId: orderId),
    );
  }

  @override
  _TicketScreenState createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen> {
  static final GlobalKey _globalKey = GlobalKey();

  Future<bool> downloadTicket(TicketModel ticketModel) async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (status.isDenied) {
          status = await Permission.storage.request();
        }
        if (status.isPermanentlyDenied) {
          var manageStatus = await Permission.manageExternalStorage.status;
          if (manageStatus.isDenied) {
            await Permission.manageExternalStorage.request();
          }
        }
      }

      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List? imageBytes = byteData?.buffer.asUint8List();

      if (imageBytes == null) throw 'Failed to capture widget';

      final now = DateFormat('ddMMyyyy_HHmmss').format(DateTime.now());

      String directoryPath = '/storage/emulated/0/Download';
      Directory targetDir = Directory(directoryPath);
      if (!await targetDir.exists()) {
        try {
          await targetDir.create(recursive: true);
        } catch (_) {
          directoryPath = '/storage/emulated/0/DCIM';
          targetDir = Directory(directoryPath);
          if (!await targetDir.exists()) {
            await targetDir.create(recursive: true);
          }
        }
      }

      final filePath = '$directoryPath/ticket_${ticketModel.id}_$now.png';
      final file = File(filePath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsBytes(imageBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bukti booking berhasil diunduh'),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengunduh bukti booking: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TicketBloc, TicketState>(
      builder: (context, state) {
        if (state is TicketLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TicketErrorState) {
          return Center(child: Text(state.message));
        } else if (state is TicketLoadedState) {
          final ticket = state.ticketModel;
          return SafeArea(
            child: WillPopScope(
              onWillPop: () async {
                onTapIconarrowone(context);
                return false;
              },
              child: Scaffold(
                body: Stack(
                  children: [
                    // Latar belakang tetap
                    _buildIconArrowColumn(context),

                    // Konten yang bisa digulir
                    SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: 100.h),
                          // Memberi jarak untuk konten
                          RepaintBoundary(
                            key: _globalKey,
                            child: Container(
                              width: double.maxFinite,
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.h,
                                vertical: 20.h,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius:
                                    BorderRadiusStyle.roundedBorder20,
                                boxShadow: [
                                  BoxShadow(
                                    color: appTheme.gray40019,
                                    spreadRadius: 2.h,
                                    blurRadius: 2.h,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(height: 4.h),
                                  Container(
                                    width: double.maxFinite,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 18.h,
                                      vertical: 20.h,
                                    ),
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: fs.Svg(
                                          ImageConstant.imgETickets,
                                        ),
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Align(
                                          alignment: Alignment.center,
                                          child: Container(
                                            padding: EdgeInsets.all(16.h),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20.h),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey
                                                      .withOpacity(0.4),
                                                  spreadRadius: 4,
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize
                                                  .min,
                                              children: [
                                                Image.asset(
                                                  'assets/images/myhikinglogo.png',
                                                  height: 70.h,
                                                  width: 70.h,
                                                ),
                                                SizedBox(width: 10.h),
                                                QrImageView(
                                                  data: '${widget.orderId}',
                                                  size: 150.h,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 14.h),
                                        const SizedBox(
                                          width: double.maxFinite,
                                          child: DottedLine(
                                            direction: Axis.horizontal,
                                            lineLength: double.infinity,
                                            lineThickness: 1.0,
                                            dashLength: 4.0,
                                            dashColor: Colors.grey,
                                            dashRadius: 0.0,
                                            dashGapLength: 4.0,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          "ID Pemesanan",
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text('${ticket.id}'.tr,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: CustomTextStyles
                                                .titleMediumBlack900),
                                        SizedBox(height: 14.h),
                                        Text(
                                          "lbl_nama_ketua".tr,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text('${ticket.pemesanName}'.tr,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: CustomTextStyles
                                                .titleMediumBlack900),
                                        SizedBox(height: 14.h),
                                        Text("lbl_booking2".tr,
                                            style: theme.textTheme.bodyLarge),
                                        SizedBox(height: 4.h),
                                        Text(
                                            '${ticket.gunungName} via ${ticket.jalurName}'
                                                .tr,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: CustomTextStyles
                                                .titleMediumBlack900),
                                        SizedBox(height: 12.h),
                                        Text(
                                          "Tanggal Naik",
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text('${ticket.tanggalNaik}'.tr,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: CustomTextStyles
                                                .titleMediumBlack900),
                                        SizedBox(height: 12.h),
                                        Text(
                                          "Tanggal Turun",
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        SizedBox(height: 4.h),
                                        Text('${ticket.tanggalTurun}'.tr,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: CustomTextStyles
                                                .titleMediumBlack900),
                                        SizedBox(height: 12.h),
                                        Text(
                                          "lbl_anggota".tr,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                        SizedBox(height: 2.h),
                                        for (var anggota in ticket.anggota)
                                          Text(
                                            '- ${anggota.name}'.tr,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                            style: CustomTextStyles
                                                .titleSmallBlack900_1
                                                .copyWith(
                                              height: 1.71,
                                            ),
                                          ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          "msg_ticket_yang_sudah".tr,
                                          style: theme.textTheme.bodySmall,
                                        ),
                                        SizedBox(height: 6.h),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.h),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                minimumSize:
                                    Size(double.infinity, 50.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                if (!ticket.canPrintTicket) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Tiket belum bisa dicetak. Silakan lunasi pembayaran terlebih dahulu.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                try {
                                  await downloadTicket(
                                      state.ticketModel);
                                } catch (e) {
                                  print('Error: $e');
                                }
                              },
                              child: Text(
                                ticket.canPrintTicket
                                    ? "Download Tiket".tr
                                    : "Bayar Dulu",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Manrope',
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 24.h),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 35.h,
                      left: 16.h,
                      child: GestureDetector(
                        onTap: () => onTapIconarrowone(context),
                        child: Container(
                          padding: EdgeInsets.all(8.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            size: 24.h,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildIconArrowColumn(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: double.maxFinite,
        padding: EdgeInsets.symmetric(vertical: 40.h),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              ImageConstant.imgGroup51,
            ),
            fit: BoxFit.fill,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppbarTitle(
              text: "msg_booking_berhasil".tr,
              margin: EdgeInsets.only(left: 150.h),
            ),
          ],
        ),
      ),
    );
  }

  onTapIconarrowone(BuildContext context) {
    NavigatorService.pushNamedAndRemoveUntil(
      AppRoutes.homeScreen,
      arguments: {
        'initialInnerRoute': AppRoutes.tiketSayaPage,
      },
    );
  }
}
