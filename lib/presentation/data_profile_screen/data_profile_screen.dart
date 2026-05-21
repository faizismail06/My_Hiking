import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/api/api_service.dart';
import '../../core/app_export.dart';
import 'bloc/data_profile_bloc.dart';
import 'package:myhiking/widgets/custom_elevated_button.dart';
import '../../theme/custom_button_style.dart';
import 'package:file_picker/file_picker.dart';

// ignore_for_file: must_be_immutable
class DataProfileScreen extends StatefulWidget {
  final int userId;
  final bool redirectToHomeOnSave;

  const DataProfileScreen({
    super.key,
    required this.userId,
    this.redirectToHomeOnSave = true,
  });

  // static Widget builder(BuildContext context) {
  //   return BlocProvider<DataProfileBloc>(
  //     create: (context) => DataProfileBloc(
  //       apiService: context.read<ApiService>(), // Inject repository
  //     ),
  //     child: const DataProfileScreen(),
  //   );
  // }

  @override
  State<DataProfileScreen> createState() => _DataProfileScreenState();
}

class _DataProfileScreenState extends State<DataProfileScreen> {
  GlobalKey<NavigatorState> navigatorKey = GlobalKey();
  int userId1 = 0;
  String userName = '';
  String userEmail = '';
  String userPassword = '';
  bool isLoading = true;
  String? _fileNameIdentity; // Menyimpan nama file yang diunggah
  String? _filePathIdentity;
  Uint8List? _fileBytesIdentity;

  @override
  void initState() {
    super.initState();
    context
        .read<DataProfileBloc>()
        .add(FetchUserDataEvent(userId: widget.userId));
    _getUser();
  }

  Future<void> _getUser() async {
    final token = await ApiService().getToken();

    // Cek apakah token null atau kosong
    if (token == null || token.isEmpty) {
      // Jika token tidak tersedia, tampilkan pesan atau ambil tindakan lain
      // print("Token is null or empty");
      if (mounted) {
        setState(() {
          isLoading =
              false; // Menyelesaikan status loading jika token tidak ada
        });
      }
      return; // Keluar dari fungsi jika token tidak ada
    }

    // print("Token: $token"); // Debugging, pastikan token ada

    try {
      final response = await ApiService().getUser(token);
      if (response['success']) {
        if (mounted) {
          setState(() {
            userId1 = response['data']['id'];
            userName = response['data']['name'];
            userEmail = response['data']['email'];
            // userPassword = response['data']['password'];
            isLoading = false;
          });
        }
      } else {
        // Menangani error jika API gagal
        // print("Error: ${response['message']}");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      // Tangani error jaringan atau kesalahan lainnya
      // print("Error fetching user: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget build(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
        builder: (context, state) {
      return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          backgroundColor: appTheme.gray50,
          body: SizedBox(
            width: double.maxFinite,
            child: Column(
              children: [
                _buildProfileHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.maxFinite,
                      child: Padding(
                        padding:
                            EdgeInsets.only(left: 26.h, right: 14.h, top: 10.h),
                        child: Column(
                          children: [
                            SizedBox(
                              // height: 35.h,
                              width: 334.h,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "lbl_nama_lengkap".tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomTextStyles.bodyMediumGray50004
                                        .copyWith(
                                      height: 1.40,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  _buildFullNameInput(context),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "lbl_nik".tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomTextStyles.bodyMediumGray50003
                                        .copyWith(
                                      height: 1.40,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  _buildNikInput(context),
                                  SizedBox(height: 12.h),
                                  Text(
                                    "lbl_no_telepon".tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomTextStyles.bodyMediumGray50003
                                        .copyWith(
                                      height: 1.40,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  _buildPhoneNumberInput(context),
                                  SizedBox(height: 12.h),
                                  Text(
                                    "Tanggal Lahir".tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomTextStyles.bodyMediumGray50003
                                        .copyWith(
                                      height: 1.40,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  _buildDateOfBirthInput(context),
                                  SizedBox(height: 12.h),
                                  Text(
                                    "msg_no_telepon_darurat".tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomTextStyles.bodyMediumGray50003
                                        .copyWith(
                                      height: 1.40,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  _buildEmergencyContactInput(context),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "lbl_alamat".tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomTextStyles.bodyMediumGray50003
                                        .copyWith(
                                      height: 1.40,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  _buildAddressInput(context),
                                  SizedBox(height: 10.h),
                                  Text(
                                    "lbl_email2".tr,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CustomTextStyles.bodyMediumGray50003
                                        .copyWith(
                                      height: 1.40,
                                    ),
                                  ),
                                  SizedBox(height: 10.h),
                                  _buildEmailInput(context),
                                  SizedBox(height: 4.h),
                                  _buildIdentityUploadSection(context),
                                  CustomElevatedButton(
                                    margin: EdgeInsets.symmetric(vertical: 0.0),
                                    buttonStyle:
                                        CustomButtonStyles.fillPrimaryTL12,
                                    buttonTextStyle: CustomTextStyles
                                        .labelLargePrimarySemiBoldw,
                                    text: "Simpan".tr,
                                    alignment: Alignment.centerRight,
                                    onPressed: () async {
                                      await updateProfile(context, state);
                                    },
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      onTapTxtIdCounter(context);
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 8.h),
                                      child: Text(
                                        "Ubah Password",
                                        style: TextStyle(
                                          color: const Color.fromARGB(
                                              255, 4, 57, 101),
                                          fontSize: 15.fSize,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 45.h),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SizedBox(
            width: double.maxFinite,
            child: _buildBottomNavigation(context),
          ),
        ),
      );
    });
  }

  Future<void> updateProfile(
      BuildContext context, DataProfileState state) async {
    print("Button Simpan ditekan!");

    try {
      // Ambil data dari form
      final userId = userId1; // Ganti dengan ID pengguna yang sesuai
      final name = state.fullNameInputController?.text;
      final email = state.emailInputController?.text;
      // final password = state.passwordController.text.isEmpty
      //     ? null
      //     : state.passwordController.text;
      final address = state.addressInputController?.text;
      final nik = state.nikInputController?.text;
      final phone = state.phoneNumberInputController?.text;
      final emergencyPhone = state.emergencyContactInputController?.text;
      final dateOfBirth = state.dateOfBirthController?.text;
      final level = 1; // Contoh level default
      File? profilePicture;
      Uint8List? profilePictureBytes;
      String? profilePictureFileName;

      if (_fileBytesIdentity != null && _fileNameIdentity != null) {
        profilePictureBytes = _fileBytesIdentity;
        profilePictureFileName = _fileNameIdentity;
      } else if (_filePathIdentity != null && _fileNameIdentity != null) {
        profilePicture = File(_filePathIdentity!);
        profilePictureFileName = _fileNameIdentity;
      }

      print("Mengirim data ke API:");
      print("User ID: $userId");
      print("Name: $name");
      print("Email: $email");
      print("Address: $address");
      print("NIK: $nik");
      print("Phone: $phone");
      print("Emergency Phone: $emergencyPhone");
      print("Date of Birth: $dateOfBirth");
      print("Level: $level");
      print("Profile Picture Name: ${profilePictureFileName ?? '-'}");

      // Panggil fungsi API untuk memperbarui profil pengguna
      final response = await ApiService().updateUserProfile(
        userId: userId,
        name: name.toString(),
        email: email.toString(),
        // password: password,
        address: address,
        nik: nik,
        phone: phone,
        emergencyPhone: emergencyPhone,
        dateOfBirth: dateOfBirth,
        profilePicture: profilePicture,
        profilePictureBytes: profilePictureBytes,
        profilePictureFileName: profilePictureFileName,
        level: level,
      );

      print("Response API: $response");

      if (!mounted) return;

      // Jika berhasil, tampilkan dialog sukses
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 24.0),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60,
                ),
                SizedBox(height: 16),
                Text(
                  "Data Berhasil Disimpan",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (widget.redirectToHomeOnSave) {
                      Navigator.pushNamed(context, AppRoutes.homeScreen);
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 33, 117, 84),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    "Lanjut",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      // Cetak log error lebih detail
      print("Error saat mengupdate profil:");
      print(e);
      print(stackTrace);

      if (!mounted) return;

      // Tampilkan dialog error
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Terjadi Kesalahan"),
            content: Text("Gagal menyimpan data. Pesan error: $e"),
            actions: [
              ElevatedButton(
                child: Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> onTapTxtIdCounter(BuildContext context) async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool? isUpdated;

    try {
      isUpdated = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            title: Text("Ubah Password"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPasswordField("Password Lama", oldPasswordController),
                  _buildPasswordField("Password Baru", newPasswordController),
                  _buildPasswordField(
                      "Konfirmasi Password", confirmPasswordController),
                ],
              ),
            ),
            actions: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      child: Text("Batal"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                      ),
                      onPressed: () {
                        Navigator.of(dialogContext).pop(false);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      child: Text(
                        "Simpan",
                        textAlign: TextAlign.center,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 12),
                      ),
                      onPressed: () async {
                        try {
                          final response = await ApiService().updatePassword(
                            userId: userId1,
                            oldPassword: oldPasswordController.text,
                            newPassword: newPasswordController.text,
                            confirmPassword: confirmPasswordController.text,
                          );
                          print("$response");
                          Navigator.of(dialogContext).pop(true);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Gagal mengubah password: $e')),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    } finally {
      oldPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    }

    if (!mounted) return;

    if (isUpdated == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Icon(Icons.check_circle, color: Colors.green, size: 60),
          content: Text(
            "Password Berhasil Diubah",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            ElevatedButton(
              child: Text("OK"),
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildPasswordField(String label, TextEditingController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 14.0,
          ),
        ),
        obscureText: true,
      ),
    );
  }

  /// Section Widget
  Widget _buildProfileHeader(BuildContext context) {
    return Container(
      height: 164.h,
      width: double.maxFinite,
      margin: EdgeInsets.only(left: 10.h),
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 202.h,
            margin: EdgeInsets.only(bottom: 30.h),
            padding: EdgeInsets.symmetric(
              horizontal: 20.h,
              vertical: 28.h,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.7),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "lbl_data_profile".tr,
                  style: theme.textTheme.titleLarge,
                ),
              ],
            ),
          ),
          CustomImageView(
            imagePath: ImageConstant.imgUserProfileDetails,
            height: 164.h,
            width: 170.h,
            alignment: Alignment.centerLeft,
          ),
        ],
      ),
    );
  }

  /// Section Widget

  Widget _buildFullNameInput(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
      builder: (context, state) {
        // Tampilkan loading indicator saat sedang fetch data
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Logging dan menampilkan error message jika ada
        if (state.error.isNotEmpty) {
          // Debug print untuk logging error
          print('Error in _buildFullNameInput:');
          print('Error message: ${state.error}');
          print('Current state: $state');
          print('Controller state: ${state.fullNameInputController?.text}');

          // Stack trace untuk debugging
          try {
            throw Exception(state.error);
          } catch (e, stackTrace) {
            print('Stack trace:');
            print(stackTrace);
          }

          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(height: 8),
                Text(
                  state.error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: 334.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              TextField(
                controller: state.fullNameInputController,
                onChanged: (value) {
                  // Tambahkan log untuk tracking perubahan nilai
                  print('Full Name changed to: $value');
                  context
                      .read<DataProfileBloc>()
                      .add(FullNameChangedEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Masukkan Nama Lengkap',
                  hintStyle: CustomTextStyles.bodySmallGray50003Light,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.h),
                    borderSide: BorderSide(
                      color: appTheme.gray400,
                      width: 1.h,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 12.h,
                  ),
                ),
                style: CustomTextStyles.bodyMediumBlack900Light,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
              ),
              if (state.statusMessage?.isNotEmpty ?? false)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    state.statusMessage!,
                    style: CustomTextStyles.bodySmallBlack900,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateOfBirthInput(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
      builder: (context, state) {
        return SizedBox(
          width: 334.h, // Menyesuaikan ukuran sesuai referensi
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: () => onTapDateOfBirthInput(context),
                child: AbsorbPointer(
                  // Mencegah keyboard muncul saat mengetuk TextField
                  child: TextField(
                    controller: state.dateOfBirthController,
                    decoration: InputDecoration(
                      hintText: 'Pilih Tanggal Lahir',
                      hintStyle: CustomTextStyles.bodySmallGray50003Light,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.h),
                        borderSide: BorderSide(
                          color: appTheme.gray400,
                          width: 1.h,
                        ),
                      ),
                      suffixIcon: Icon(Icons.calendar_today, size: 20.h),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 14.h,
                        horizontal: 12.h,
                      ),
                    ),
                    style: CustomTextStyles.bodyMediumBlack900Light,
                    readOnly: true, // Membuat input hanya dapat dibaca
                  ),
                ),
              ),
              // Tampilkan pesan error jika ada
              if (state.statusMessage != null &&
                  state.statusMessage!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    state.statusMessage!,
                    style: CustomTextStyles.bodySmallBlack900.copyWith(
                      color: Colors.red, // Warna teks error
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void onTapDateOfBirthInput(BuildContext context) async {
    // Mendapatkan tanggal saat ini
    DateTime currentDate = DateTime.now();

    // Menampilkan date picker
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDate, // Tanggal saat ini sebagai tanggal awal
      firstDate: DateTime(
          1900), // Membatasi agar tidak bisa memilih sebelum tahun 1900
      lastDate: currentDate, // Membatasi hingga tanggal saat ini
    );

    if (pickedDate != null) {
      // Format tanggal menjadi 'yyyy-MM-dd'
      String dateOfBirth = DateFormat('yyyy-MM-dd').format(pickedDate);
      print('$dateOfBirth');

      // Dispatch event ke Bloc untuk memperbarui state
      BlocProvider.of<DataProfileBloc>(context)
          .add(DateOfBirthChangedEvent(dateOfBirth));
    } else {
      print("Pemilihan tanggal dibatalkan");
    }
  }

  Widget _buildNikInput(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
      builder: (context, state) {
        return SizedBox(
          width: 334.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              TextField(
                controller: state.nikInputController,
                onChanged: (value) {
                  context.read<DataProfileBloc>().add(NikChangedEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Masukkan NIK',
                  hintStyle: CustomTextStyles
                      .bodySmallGray50003Light, // Sesuai referensi gaya teks
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.h),
                    borderSide: BorderSide(
                      color: appTheme.gray400, // Warna border dari referensi
                      width: 1.h,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 12.h,
                  ),
                ),
                style:
                    CustomTextStyles.bodyMediumBlack900Light, // Gaya teks input
                keyboardType:
                    TextInputType.number, // Keyboard untuk NIK (angka)
                textInputAction:
                    TextInputAction.next, // Aksi next pada keyboard
              ),
              // Menampilkan pesan status jika ada
              if (state.statusMessage != null &&
                  state.statusMessage!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    state.statusMessage!,
                    style: CustomTextStyles.bodySmallBlack900,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoneNumberInput(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
      builder: (context, state) {
        return SizedBox(
          width: 334.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              TextField(
                controller: state.phoneNumberInputController,
                onChanged: (value) {
                  context
                      .read<DataProfileBloc>()
                      .add(PhoneNumberChangedEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Masukkan Nomor Telepon',
                  hintStyle: CustomTextStyles
                      .bodySmallGray50003Light, // Sesuai referensi gaya teks
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.h),
                    borderSide: BorderSide(
                      color: appTheme.gray400, // Warna border dari referensi
                      width: 1.h,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 12.h,
                  ),
                ),
                style:
                    CustomTextStyles.bodyMediumBlack900Light, // Gaya teks input
                keyboardType:
                    TextInputType.phone, // Keyboard untuk nomor telepon
                textInputAction:
                    TextInputAction.next, // Aksi next pada keyboard
              ),
              // Menampilkan pesan status jika ada
              if (state.statusMessage != null &&
                  state.statusMessage!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    state.statusMessage!,
                    style: CustomTextStyles.bodySmallBlack900,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmergencyContactInput(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
      builder: (context, state) {
        return SizedBox(
          width: 334.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              TextField(
                controller: state.emergencyContactInputController,
                onChanged: (value) {
                  context
                      .read<DataProfileBloc>()
                      .add(EmergencyContactChangedEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Masukkan Nomor Kontak Darurat',
                  hintStyle: CustomTextStyles
                      .bodySmallGray50003Light, // Sesuai referensi gaya teks
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.h),
                    borderSide: BorderSide(
                      color: appTheme.gray400, // Warna border dari referensi
                      width: 1.h,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 12.h,
                  ),
                ),
                style:
                    CustomTextStyles.bodyMediumBlack900Light, // Gaya teks input
                keyboardType:
                    TextInputType.phone, // Keyboard untuk nomor telepon
                textInputAction:
                    TextInputAction.next, // Aksi next pada keyboard
              ),
              // Menampilkan pesan status jika ada
              if (state.statusMessage != null &&
                  state.statusMessage!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    state.statusMessage!,
                    style: CustomTextStyles.bodySmallBlack900,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddressInput(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
      builder: (context, state) {
        return SizedBox(
          width: 334.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              TextField(
                controller: state.addressInputController,
                onChanged: (value) {
                  context
                      .read<DataProfileBloc>()
                      .add(AddressChangedEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Masukkan Alamat',
                  hintStyle: CustomTextStyles
                      .bodySmallGray50003Light, // Sesuai referensi gaya teks
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.h),
                    borderSide: BorderSide(
                      color: appTheme.gray400, // Warna border dari referensi
                      width: 1.h,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 12.h,
                  ),
                ),
                style:
                    CustomTextStyles.bodyMediumBlack900Light, // Gaya teks input
                keyboardType:
                    TextInputType.streetAddress, // Keyboard untuk alamat
                textInputAction:
                    TextInputAction.next, // Aksi next pada keyboard
                maxLines: null, // Mengizinkan input alamat dengan banyak baris
              ),
              // Menampilkan pesan status jika ada
              if (state.statusMessage != null &&
                  state.statusMessage!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(state.statusMessage!,
                      style: CustomTextStyles
                          .bodySmallBlack900 // Gaya teks pesan error
                      ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmailInput(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
      builder: (context, state) {
        return SizedBox(
          width: 334.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              TextField(
                controller: state.emailInputController,
                onChanged: (value) {
                  context.read<DataProfileBloc>().add(EmailChangedEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'Masukkan Email',
                  hintStyle: CustomTextStyles.bodySmallGray50003Light,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.h),
                    borderSide: BorderSide(
                      color: appTheme.gray400,
                      width: 1.h,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 12.h,
                  ),
                  errorText: state.isEmailValid
                      ? null
                      : 'Format email tidak valid', // Validasi email
                ),
                style: CustomTextStyles.bodyMediumBlack900Light,
                keyboardType: TextInputType.emailAddress, // Keyboard email
                textInputAction:
                    TextInputAction.done, // Aksi selesai di keyboard
              ),
              // Menampilkan pesan status jika ada
              if (state.statusMessage != null &&
                  state.statusMessage!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    state.statusMessage!,
                    style: CustomTextStyles
                        .bodySmallBlack900, // Gaya teks error/status
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Section Widget
  Widget _buildIdentityUploadSection(BuildContext context) {
    return SizedBox(
      height: 150.h,
      width: double.maxFinite,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8.h),
                Text(
                  "msg_unggah_kartu_identitas".tr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CustomTextStyles.bodyMediumGray50003.copyWith(
                    height: 1.40,
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.all(6.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadiusStyle.roundedBorder6,
                    border: Border.all(
                      color: appTheme.gray400,
                      width: 1.h,
                    ),
                  ),
                  width: double.maxFinite,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 4.h),
                          child: Text(
                            _fileNameIdentity ?? "msg_upload_file_jpeg".tr,
                            style: CustomTextStyles.bodySmallGray50003Light,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          FilePickerResult? result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['jpg', 'jpeg', 'png'],
                            withData: true,
                          );

                          if (result != null) {
                            PlatformFile file = result.files.first;

                            // Check file size (convert bytes to MB)
                            double fileSizeInMB = file.size / (1024 * 1024);

                            if (fileSizeInMB > 2) {
                              // Show popup dialog for file size exceed
                              await showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Column(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Colors.red,
                                          size: 48,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          "Ukuran File Terlalu Besar",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      "Ukuran file tidak boleh lebih dari 2MB. Silakan pilih file yang lebih kecil.",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                        height: 1.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    actions: [
                                      Container(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 12),
                                            backgroundColor:
                                                appTheme.blueGray10001,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: Text(
                                            "OK",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 20,
                                    ),
                                    actionsPadding: EdgeInsets.all(16),
                                  );
                                },
                              );
                            } else {
                              // File size is acceptable, proceed with update
                              final bytes = file.bytes;
                              setState(() {
                                _fileNameIdentity = file.name;
                                _filePathIdentity = kIsWeb ? null : file.path;
                                _fileBytesIdentity = bytes;
                              });
                              print('File dipilih: ${file.name}');
                              print('File bytes tersedia: ${bytes != null}');
                            }
                          } else {
                            print('Pemilihan file dibatalkan');
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.h),
                          decoration: BoxDecoration(
                            color: appTheme.blueGray10001,
                            borderRadius: BorderRadiusStyle.roundedBorder6,
                            border: Border.all(
                              color: appTheme.gray400,
                              width: 1.h,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "lbl_pilih_file".tr,
                                style: CustomTextStyles.bodySmallBlack900Light,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_fileNameIdentity != null) SizedBox(height: 8.h),
                if (_fileNameIdentity != null)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: _showIdentityPreview,
                          icon: const Icon(Icons.image_outlined, size: 18),
                          label: Text(
                            _fileNameIdentity!,
                            overflow: TextOverflow.ellipsis,
                            style: CustomTextStyles.bodySmallBlack900Light
                                .copyWith(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Hapus file',
                        onPressed: () {
                          setState(() {
                            _fileNameIdentity = null;
                            _filePathIdentity = null;
                            _fileBytesIdentity = null;
                          });
                        },
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _showIdentityPreview() async {
    if (_fileNameIdentity == null) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        Widget preview;

        if (_fileBytesIdentity != null) {
          preview = InteractiveViewer(
            child: Image.memory(_fileBytesIdentity!, fit: BoxFit.contain),
          );
        } else if (!kIsWeb && _filePathIdentity != null) {
          preview = InteractiveViewer(
            child: Image.file(File(_filePathIdentity!), fit: BoxFit.contain),
          );
        } else {
          preview = const Text('Preview tidak tersedia untuk file ini.');
        }

        return AlertDialog(
          title: Text(_fileNameIdentity!),
          content: SizedBox(
            width: 320,
            height: 320,
            child: Center(child: preview),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
              ),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return const SizedBox(
      width: double.maxFinite,
    );
  }
}
