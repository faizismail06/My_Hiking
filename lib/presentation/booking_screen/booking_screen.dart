import 'dart:io';

import 'package:flutter/material.dart';
import 'package:another_stepper/dto/stepper_data.dart';
import 'package:another_stepper/widgets/another_stepper.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/models/bookingModel.dart';
import 'package:myhiking/models/jalurmodel.dart';
import 'package:myhiking/presentation/pilihan_bank_pembayaran_screen/bloc/pilihan_bank_pembayaran_bloc.dart';
import 'package:myhiking/presentation/pilihan_bank_pembayaran_screen/pilihan_bank_pembayaran_screen.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/app_bar/appbar_subtitle.dart';
import '../../widgets/app_bar/custom_app_bar.dart';
import '../../widgets/custom_outlined_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/booking_bloc.dart';
import 'models/booking_model.dart';

class BookingScreen extends StatefulWidget {
  final int? jalurId;
  final int? idGunung;
  const BookingScreen(
      {super.key, required this.jalurId, required this.idGunung});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late String imageUrl; // Deklarasi imageUrl
  String userName = '';
  String userId = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getUserProfile();
    if (widget.idGunung != null && widget.jalurId != null) {
      BlocProvider.of<BookingBloc>(context).add(BookingInitialEvent(
        idGunung: widget.idGunung!,
        jalurId: widget.jalurId!,
      ));
      print(
          "Navigating with idGunung: ${widget.idGunung} and jalurId: ${widget.jalurId},");
    }
  }

  Future<void> _getUserProfile() async {
    final token = await ApiService().getToken();
    if (token != null) {
      final response = await ApiService().getUserProfile(token);
      if (response['success']) {
        setState(() {
          userId = response['data']['id'].toString();
        });
      }
    }
    print("Navigating with $userId");
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
        create: (context) => BookingBloc(apiService: ApiService())
          ..add(BookingInitialEvent(
            idGunung: widget.idGunung!,
            jalurId: widget.jalurId!,
          )),
        child: Scaffold(
          // Add Scaffold
          appBar: _buildAppbar(context), // Add the AppBar here
          body: BlocBuilder<BookingBloc, BookingState>(
            builder: (context, state) {
              if (state.isLoading) {
                return Center(child: CircularProgressIndicator());
              }
              if (state.jalur == null || state.gunung == null) {
                return Center(
                    child: Text('Data jalur atau gunung tidak tersedia.'));
              }

              final resDetailRouteCentres = ResJalurModel(
                status: true,
                message: "Success",
                //error disini
                jalur: state.jalur!,
              );

              final jalurModel =
                  BookingModel.resJalurModelFromJson(resDetailRouteCentres);

              return SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Container(
                    width: double.maxFinite,
                    padding: EdgeInsets.symmetric(horizontal: 12.h),
                    child: Column(
                      children: [
                        SizedBox(height: 4.h),
                        _buildProgressSection(context),
                        SizedBox(height: 28.h),
                        _buildHotelCard(context, jalurModel),
                        SizedBox(height: 28.h),
                        Container(
                          width: double.maxFinite,
                          margin: EdgeInsets.only(
                            left: 4.h,
                            right: 6.h,
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.maxFinite,
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadiusStyle.roundedBorder20,
                                  border: Border.all(
                                    color: theme.colorScheme.primaryContainer,
                                    width: 2.h,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Align(
                                      alignment: Alignment.center,
                                      child: Text(
                                        "FORM PESANAN".tr,
                                        style:
                                            CustomTextStyles.titleMediumManrope,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    SizedBox(
                                      width: double.maxFinite,
                                      child: Divider(
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(height: 24.h),
                                    Padding(
                                      padding: EdgeInsets.only(left: 24.h),
                                      child: Text(
                                        "msg_tanggal_pemesanan"
                                            .tr
                                            .toUpperCase(),
                                        style:
                                            CustomTextStyles.labelLargePrimary,
                                      ),
                                    ),
                                    SizedBox(height: 10.h),
                                    _buildBookingDateField(context),
                                    SizedBox(height: 14.h),
                                    Padding(
                                      padding: EdgeInsets.only(left: 24.h),
                                      child: Text(
                                        "lbl_tambah_anggota".tr.toUpperCase(),
                                        style:
                                            CustomTextStyles.labelLargePrimary,
                                      ),
                                    ),
                                    SizedBox(height: 14.h),
                                    _buildMemberIdField(context),
                                    SizedBox(height: 75.h),
                                  ],
                                ),
                              ),
                              SizedBox(height: 22.h),
                              _buildContinueButton(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ));
  }

  PreferredSizeWidget _buildAppbar(BuildContext context) {
    return CustomAppBar(
      height: 40.h,
      title: Container(
        width: double.maxFinite,
        margin:
            EdgeInsets.symmetric(horizontal: 13.h), // Adjust margins as needed
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween, // Space between items
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back
              },
              padding: EdgeInsets.only(right: 16.h), // Adjust padding as needed
            ),
            SizedBox(width: 20.h),
            Expanded(
              child: Center(
                child: AppbarSubtitleOne(
                  text: "lbl_booking".tr,
                ),
              ),
            ),
            // Placeholder for spacing, adjust if needed
            SizedBox(width: 50.h), // You can adjust this width
          ],
        ),
      ),
    );
  }

  /// Section Widget
  Widget _buildProgressSection(BuildContext context) {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(
        left: 10.h,
        right: 2.h,
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.maxFinite,
            child: AnotherStepper(
              iconHeight: 26,
              iconWidth: 26,
              stepperDirection: Axis.horizontal,
              activeIndex: 0,
              barThickness: 4,
              inverted: true,
              stepperList: [
                StepperData(
                  iconWidget: Container(
                    height: 26.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadiusStyle.roundedBorder14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "lbl_1".tr,
                          style: CustomTextStyles.titleSmallOnPrimaryMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                StepperData(
                  iconWidget: Container(
                    height: 26.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      // color: appTheme.gray5001,
                      borderRadius: BorderRadius.circular(12.h),
                      border: Border.all(
                        color: appTheme.blueGray100,
                        width: 2.h,
                      ),
                    ),
                  ),
                ),
                StepperData(
                  iconWidget: Container(
                    height: 26.h,
                    width: 26.h,
                    decoration: BoxDecoration(
                      color: appTheme.gray5001,
                      borderRadius: BorderRadius.circular(12.h),
                      border: Border.all(
                        color: appTheme.blueGray100,
                        width: 2.h,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildHotelCard(BuildContext context, BookingModel jalur) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.h,
        vertical: 10.h,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadiusStyle.roundedBorder14,
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.04),
            spreadRadius: 2.h,
            blurRadius: 2.h,
            offset: const Offset(
              0,
              2,
            ),
          ),
        ],
      ),
      width: double.maxFinite,
      child: Row(
        children: [
          CustomImageView(
            imagePath: jalur.gambar,
            height: 110.h,
            width: 146.h,
            radius: BorderRadius.circular(10.h),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16.h),
                    child: Text(
                      jalur.name ?? 'Nama Jalur',
                      style: CustomTextStyles.titleSmallGray900,
                    ),
                  ),
                  SizedBox(height: 58.h),
                  SizedBox(
                    width: double.maxFinite,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          " ${NumberFormat('#,##0', 'id_ID').format(jalur.biaya)}",
                          style: CustomTextStyles.titleSmallPrimary,
                        ),
                        Text(
                          "lbl_org".tr,
                          style: CustomTextStyles.titleSmallBluegray400,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildBookingDateField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24.h),
      child: BlocSelector<BookingBloc, BookingState, TextEditingController?>(
        selector: (state) => state.bookingDateFieldController,
        builder: (context, bookingDateFieldController) {
          return CustomTextFormField(
            readOnly: true,
            width: 130.h,
            controller: bookingDateFieldController,
            hintText: "Pilih Tanggal".tr,
            textInputAction: TextInputAction.done,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 12.h,
            ),
            borderDecoration: TextFormFieldStyleHelper.outlineBlueGrayTL14,
            onTap: () {
              onTapBookingDateInput(context);
            },
          );
        },
      ),
    );
  }

  /// Section Widget
  Widget _buildMemberIdField(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 24.h),
      child: BlocSelector<BookingBloc, BookingState, TextEditingController?>(
        selector: (state) => state.memberIdFieldController,
        builder: (context, memberIdFieldController) {
          return CustomTextFormField(
            width: 280.h,
            controller: memberIdFieldController,
            hintText: "Masukkan ID anggota".tr,
            textInputAction: TextInputAction.done,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.h,
              vertical: 12.h,
            ),
            onChanged: (value) {
              // Mengupdate state dengan ID anggota yang baru
              context.read<BookingBloc>().add(UpdateMemberIdField(value));
            },
          );
        },
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return CustomOutlinedButton(
      height: 42.h,
      text: "lbl_lanjut2".tr,
      margin: EdgeInsets.only(
        left: 4.h,
        right: 4.h,
      ),
      buttonStyle: CustomButtonStyles.fillPrimary,
      buttonTextStyle: CustomTextStyles.labelLarge13,
      onPressed: () async {
        try {
          // Pastikan userId sudah terisi
          if (userId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Data pengguna belum tersedia. Harap tunggu sebentar."),
              ),
            );
            return;
          }

          // Mengambil state dari BookingBloc
          final bookingBloc = BlocProvider.of<BookingBloc>(context);
          final state = bookingBloc.state;
          print('${state.memberIdFieldController}');

          // Ambil data dari state
          final anggotaBooking = state.memberIdFieldController?.text;
          final bookingDate = state.bookingDateFieldController?.text;
          final idGunung = state.gunung?.id;
          final jalurId = state.jalur?.id;
          final biaya = state.jalur?.biaya;
          final userIdInt = int.tryParse(userId);

          // Format tanggal sebelum digunakan
          String formatTanggal(String bookingDate) {
            try {
              final DateTime dateTime = DateTime.parse(bookingDate);
              final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
              return dateFormat.format(dateTime);
            } catch (e) {
              return "Format tanggal tidak valid";
            }
          }

          final formattedDate =
              bookingDate != null ? formatTanggal(bookingDate) : null;
          final tanggalTurun = formattedDate != null
              ? DateTime.parse(formattedDate)
                  .add(Duration(days: 1))
                  .toString() // Tanggal turun 1 hari setelah tanggal naik
              : null;
          print(
              "Tanggal naik : {$formattedDate, $biaya, $jalurId, $idGunung, $anggotaBooking, $userIdInt, $tanggalTurun}");

          // Menangani anggotaBooking yang berupa string dan mengonversinya menjadi List<int> jika valid
          List<int>? anggotaIds;

          if (anggotaBooking != null && anggotaBooking.isNotEmpty) {
            try {
              anggotaIds = anggotaBooking
                  .split(
                      ',') // Memisahkan ID anggota jika berupa daftar yang dipisahkan koma
                  .map((id) => int.tryParse(
                      id.trim())) // Mengubah setiap item menjadi integer
                  .where(
                      (id) => id != null) // Menghilangkan ID yang tidak valid
                  .cast<int>() // Memastikan menjadi List<int>
                  .toList();
            } catch (e) {
              // Jika terjadi kesalahan saat parsing, bisa menampilkan error atau menggunakan list kosong
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Format anggota tidak valid.")),
              );
              anggotaIds =
                  []; // Menetapkan list kosong jika terjadi kesalahan parsing
            }
          }

          print("anggota Ids {$anggotaIds}");

          // Jika anggotaIds kosong, biarkan null atau kosongkan list
          if (formattedDate != null &&
              idGunung != null &&
              jalurId != null &&
              userIdInt != null &&
              tanggalTurun != null &&
              biaya != null) {
            // Memanggil API untuk membuat booking
            ModelBooking? booking = await ApiService().createBooking(
              idGunung,
              jalurId,
              userIdInt,
              formattedDate,
              tanggalTurun, // Tanggal turunnya
              biaya.toInt(),
              anggotaIds: anggotaIds?.isNotEmpty == true
                  ? anggotaIds
                  : null, // Safely handle null
            );
            if (booking != null) {
              // Menampilkan ID pesanan di SnackBar
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking berhasil dibuat!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider<PilihanBankPembayaranBloc>(
                    create: (context) => PilihanBankPembayaranBloc(),
                    child: PilihanBankPembayaranScreen(pesananId: booking.id),
                  ),
                ),
              ).then((_) {
                // Jika perlu melakukan sesuatu setelah layar baru dimulai, Anda bisa melakukannya di sini.
              });
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Gagal membuat booking. Coba lagi.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Harap lengkapi data pemesanan.")),
            );
          }
        } catch (e) {
          // Tangani kesalahan
          String errorMessage;
          if (e is FormatException) {
            errorMessage = "Format tanggal tidak valid.";
          } else if (e is SocketException) {
            errorMessage = "Terjadi masalah dengan koneksi internet.";
          } else if (e is HttpException) {
            errorMessage = "Terjadi kesalahan saat menghubungi server.";
          } else {
            errorMessage = "Terjadi kesalahan yang tidak terduga.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      },
    );
  }

  void onTapBookingDateInput(BuildContext context) async {
    // Get current date
    DateTime currentDate = DateTime.now();

    // Show date picker
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: currentDate,
      // Changed to allow selection up to 2 years ahead
      lastDate: DateTime(
        currentDate.year + 2,
        currentDate.month,
        currentDate.day,
      ),
    );

    if (pickedDate != null && pickedDate != currentDate) {
      // Format the selected date to yyyy-MM-dd
      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);

      // Dispatch UpdateBookingDateEvent with the new date format
      BlocProvider.of<BookingBloc>(context)
          .add(UpdateBookingDateEvent(formattedDate));
    }
  }
}
