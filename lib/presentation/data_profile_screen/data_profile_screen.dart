import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myhiking/api/api_service.dart';
import 'package:myhiking/core/utils/ktp_ocr_parser.dart';
import 'package:myhiking/presentation/data_profile_screen/widgets/ktp_frame_border_painter.dart';
import 'package:myhiking/presentation/face_registration_screen/face_registration_screen.dart';
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
  bool isPhoneVerified = false;
  bool isEmergencyPhoneVerified = false;
  bool isFaceVerified = false;
  String? facePhotoUrl;
  String? ktpPhotoUrl;
  bool _hasPromptedFaceVerification = false;

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

    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await ApiService().getUser(token);
      if (response['success'] == true) {
        if (mounted) {
          final data = response['data'];
          final bool verified = data['is_face_verified'] == true || 
                                 data['is_face_verified'] == 1 || 
                                 data['is_face_verified'].toString() == '1' || 
                                 data['is_face_verified'].toString() == 'true';
          final bool phoneVerified = data['is_phone_verified'] == true ||
                                     data['is_phone_verified'] == 1 ||
                                     data['is_phone_verified'].toString() == '1' ||
                                     data['phone_verified_at'] != null;
          final bool emergencyVerified = data['is_emergency_phone_verified'] == true ||
                                      data['is_emergency_phone_verified'] == 1 ||
                                      data['is_emergency_phone_verified'].toString() == '1';

          setState(() {
            userId1 = data['id'] != null ? (data['id'] is int ? data['id'] : int.tryParse(data['id'].toString()) ?? widget.userId) : widget.userId;
            userName = data['name'] ?? '';
            userEmail = data['email'] ?? '';
            isFaceVerified = verified;
            isPhoneVerified = phoneVerified;
            isEmergencyPhoneVerified = emergencyVerified;
            if (data['face_photo_path'] != null) {
              facePhotoUrl = '${baseUrl.replaceAll('/api', '')}/storage/${data['face_photo_path']}';
            }
            if (data['profile_picture'] != null && data['profile_picture'].toString().isNotEmpty && data['profile_picture'].toString() != 'null') {
              final String path = data['profile_picture'].toString();
              ktpPhotoUrl = path.startsWith('http') ? path : '${baseUrl.replaceAll('/api', '')}/storage/$path';
            }
            isLoading = false;
          });

          // Cek Pop-up Verifikasi Wajib
          final bool hasEmptyKtp = _fileNameIdentity == null &&
                                   _filePathIdentity == null &&
                                   _fileBytesIdentity == null &&
                                   (data['profile_picture'] == null || data['profile_picture'].toString().isEmpty || data['profile_picture'].toString() == 'null') &&
                                   (data['nik'] == null || data['nik'].toString().isEmpty || data['nik'].toString() == 'null');

          if (!_hasPromptedFaceVerification) {
            if (!verified) {
              _hasPromptedFaceVerification = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showMandatoryFaceVerificationDialog();
              });
            } else if (hasEmptyKtp) {
              _hasPromptedFaceVerification = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showMandatoryKtpUploadDialog();
              });
            }
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMandatoryFaceVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User wajib memproses atau membatalkan
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Centered Icon Container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.face_retouching_natural_rounded,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verifikasi Wajah (eKYC) Wajib',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sebelum melengkapi data diri pendaki, Anda diwajibkan melakukan Verifikasi Wajah (eKYC) terlebih dahulu. Verifikasi ini hanya dilakukan 1 KALI SAJA demi keamanan identitas pendakian Anda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context); // Kembali jika tidak ingin verifikasi sekarang
                        },
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final bool? isSuccess = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FaceRegistrationScreen(),
                            ),
                          );
                          if (isSuccess == true && mounted) {
                            setState(() {
                              isFaceVerified = true;
                              _hasPromptedFaceVerification = false; // Allow checking for KTP empty popup
                            });
                            ApiService().clearUserCache();
                            await _getUser();
                          }
                        },
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Verifikasi Wajah Sekarang',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMandatoryKtpUploadDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.green.shade200, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: Colors.green,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Unggah Foto KTP Wajib',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Verifikasi wajah telah selesai! ✅\nSilakan unggah foto KTP Anda pada bingkai untuk membaca NIK, Tanggal Lahir, & Alamat secara otomatis oleh AI OCR.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Nanti', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _pickKtpFile();
                        },
                        child: const Text('Unggah KTP', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
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
                                  _buildEkycStatusBanner(context),
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

  Widget _buildEkycStatusBanner(BuildContext context) {
    if (isFaceVerified) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 28.h),
          SizedBox(width: 10.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Verifikasi Wajah Diperlukan ⚠️",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                    fontSize: 12.fSize,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  "Wajib sebelum isi data pendaki.",
                  style: TextStyle(
                    fontSize: 10.fSize,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 6.h),
            ),
            onPressed: _showMandatoryFaceVerificationDialog,
            child: const Text("Verifikasi", style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Future<void> updateProfile(
      BuildContext context, DataProfileState state) async {
    print("Button Simpan ditekan!");

    try {
      // Ambil data dari form
      final userId = (userId1 != 0) ? userId1 : widget.userId;
      final name = state.fullNameInputController?.text;
      final email = state.emailInputController?.text;
      // final password = state.passwordController.text.isEmpty
      //     ? null
      //     : state.passwordController.text;
      final address = state.addressInputController?.text;
      final nik = state.nikInputController?.text;
      final phone = state.phoneNumberInputController?.text;
      final emergencyPhone = state.emergencyContactInputController?.text;
      final dateOfBirthRaw = state.dateOfBirthController?.text;
      String? dateOfBirth;
      if (dateOfBirthRaw != null && dateOfBirthRaw.trim().isNotEmpty) {
        final parts = dateOfBirthRaw.trim().split(RegExp(r'[-/\.]'));
        if (parts.length == 3 && parts[0].length == 2 && parts[2].length == 4) {
          dateOfBirth = '${parts[2]}-${parts[1]}-${parts[0]}'; // Convert DD-MM-YYYY to YYYY-MM-DD for backend
        } else {
          dateOfBirth = dateOfBirthRaw;
        }
      }
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
      // Format tanggal untuk Tampilan UI menjadi 'dd-MM-yyyy' (misal: 18-02-1986)
      String dateOfBirth = DateFormat('dd-MM-yyyy').format(pickedDate);
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
        final bool isNikFilled = state.nikInputController?.text.isNotEmpty == true;
        return SizedBox(
          width: 334.h,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8.h),
              TextField(
                controller: state.nikInputController,
                readOnly: isNikFilled, // NIK tidak dapat diedit jika sudah terisi dari OCR / database
                onChanged: (value) {
                  context.read<DataProfileBloc>().add(NikChangedEvent(value));
                },
                decoration: InputDecoration(
                  hintText: 'NIK Terisi Otomatis dari KTP',
                  hintStyle: CustomTextStyles.bodySmallGray50003Light,
                  fillColor: isNikFilled ? Colors.grey.shade100 : Colors.white,
                  filled: isNikFilled,
                  suffixIcon: isNikFilled
                      ? Icon(Icons.lock_outline, size: 20.h, color: Colors.green.shade700)
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.h),
                    borderSide: BorderSide(
                      color: isNikFilled ? Colors.green.shade300 : appTheme.gray400,
                      width: 1.h,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.h,
                    horizontal: 12.h,
                  ),
                ),
                style: TextStyle(
                  fontSize: 13.fSize,
                  fontWeight: isNikFilled ? FontWeight.bold : FontWeight.normal,
                  color: isNikFilled ? Colors.green.shade900 : Colors.black87,
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              if (isNikFilled)
                Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    "🔒 NIK dikunci otomatis dari KTP demi keamanan identitas.",
                    style: TextStyle(
                      fontSize: 10.fSize,
                      color: Colors.green.shade800,
                    ),
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
        final phone = state.phoneNumberInputController?.text ?? '';
        return SizedBox(
          width: 334.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kolom Input Nomor HP (3/4 Lebar)
              Expanded(
                flex: 3,
                child: TextField(
                  controller: state.phoneNumberInputController,
                  onChanged: (value) {
                    context
                        .read<DataProfileBloc>()
                        .add(PhoneNumberChangedEvent(value));
                  },
                  decoration: InputDecoration(
                    hintText: 'Masukkan Nomor Telepon',
                    hintStyle: CustomTextStyles.bodySmallGray50003Light,
                    suffixIcon: Tooltip(
                      message: isPhoneVerified ? 'Nomor Terverifikasi' : 'Belum Diverifikasi',
                      child: Icon(
                        isPhoneVerified
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        color: isPhoneVerified ? Colors.green.shade600 : Colors.amber.shade800,
                        size: 20.h,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.h),
                      borderSide: BorderSide(
                        color: isPhoneVerified ? Colors.green.shade400 : appTheme.gray400,
                        width: 1.h,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.h),
                      borderSide: BorderSide(
                        color: isPhoneVerified ? Colors.green.shade400 : appTheme.gray400,
                        width: 1.h,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.h),
                      borderSide: BorderSide(
                        color: isPhoneVerified ? Colors.green.shade600 : theme.colorScheme.primary,
                        width: 1.5.h,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14.h,
                      horizontal: 12.h,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 13.fSize,
                    color: Colors.black87,
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(width: 8.h),
              // Tombol Verifikasi WA OTP (1/4 Lebar)
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isPhoneVerified
                          ? Colors.green.shade50
                          : Colors.green.shade700,
                      foregroundColor: isPhoneVerified
                          ? Colors.green.shade800
                          : Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.h),
                        side: BorderSide(
                          color: isPhoneVerified
                              ? Colors.green.shade300
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    onPressed: isPhoneVerified
                        ? null
                        : () {
                            final currentPhone = state.phoneNumberInputController?.text ?? '';
                            _startPhoneOtpVerification(context, currentPhone);
                          },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPhoneVerified
                                ? Icons.check_circle_rounded
                                : Icons.chat_rounded,
                            size: 16.h,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            isPhoneVerified ? "Terverif" : "Verif WA",
                            style: TextStyle(
                              fontSize: 10.fSize,
                              fontWeight: FontWeight.bold,
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
        );
      },
    );
  }

  Future<void> _startPhoneOtpVerification(BuildContext context, String phone, {bool isEmergency = false}) async {
    if (phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan masukkan nomor ${isEmergency ? "kontak darurat" : "telepon"} Anda terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );

    final res = await ApiService().sendPhoneOtp(phone.trim());

    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('💬 Kode OTP WhatsApp telah dikirimkan ke $phone! Cek pesan WA Anda.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );

      _showPhoneOtpDialog(phone.trim(), isEmergency: isEmergency);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal mengirimkan OTP.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPhoneOtpDialog(String phone, {bool isEmergency = false}) {
    final TextEditingController otpController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.h)),
              child: Padding(
                padding: EdgeInsets.all(24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60.h,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green.shade300, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.mark_chat_read_rounded, color: Colors.green, size: 32),
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Text(
                      isEmergency ? 'Verifikasi WA Nomor Darurat' : 'Verifikasi WA OTP Pendaki',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Masukkan 4 digit kode OTP yang dikirimkan ke WhatsApp nomor $phone',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.fSize, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 4,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22.fSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 10.h,
                        color: Colors.green.shade900,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '• • • •',
                        hintStyle: TextStyle(letterSpacing: 10.h, color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.h),
                          borderSide: BorderSide(color: Colors.green.shade400),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        SizedBox(width: 8.h),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.h)),
                            ),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (otpController.text.length != 4) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Masukkan 4 digit kode OTP.')),
                                      );
                                      return;
                                    }
                                    setDialogState(() => isSubmitting = true);
                                    final res = await ApiService().verifyPhoneOtp(phone, otpController.text.trim());
                                    setDialogState(() => isSubmitting = false);

                                    if (res['success'] == true) {
                                      Navigator.pop(dialogContext);
                                      setState(() {
                                        if (isEmergency) {
                                          isEmergencyPhoneVerified = true;
                                        } else {
                                          isPhoneVerified = true;
                                        }
                                      });
                                      ApiService().clearUserCache();
                                      _getUser();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Nomor ${isEmergency ? "Kontak Darurat" : "Telepon Pendaki"} Berhasil Diverifikasi! ✅'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(res['message'] ?? 'Kode OTP salah.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            child: isSubmitting
                                ? SizedBox(
                                    height: 18.h,
                                    width: 18.h,
                                    child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text('Verifikasi OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmergencyContactInput(BuildContext context) {
    return BlocBuilder<DataProfileBloc, DataProfileState>(
      builder: (context, state) {
        final emergencyPhone = state.emergencyContactInputController?.text ?? '';
        return SizedBox(
          width: 334.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Kolom Input Nomor Darurat (3/4 Lebar)
              Expanded(
                flex: 3,
                child: TextField(
                  controller: state.emergencyContactInputController,
                  onChanged: (value) {
                    context
                        .read<DataProfileBloc>()
                        .add(EmergencyContactChangedEvent(value));
                  },
                  decoration: InputDecoration(
                    hintText: 'Masukkan Nomor Kontak Darurat',
                    hintStyle: CustomTextStyles.bodySmallGray50003Light,
                    suffixIcon: Tooltip(
                      message: isEmergencyPhoneVerified ? 'Nomor Darurat Terverifikasi' : 'Belum Diverifikasi',
                      child: Icon(
                        isEmergencyPhoneVerified
                            ? Icons.verified_rounded
                            : Icons.warning_amber_rounded,
                        color: isEmergencyPhoneVerified ? Colors.green.shade600 : Colors.amber.shade800,
                        size: 20.h,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.h),
                      borderSide: BorderSide(
                        color: isEmergencyPhoneVerified ? Colors.green.shade400 : appTheme.gray400,
                        width: 1.h,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.h),
                      borderSide: BorderSide(
                        color: isEmergencyPhoneVerified ? Colors.green.shade400 : appTheme.gray400,
                        width: 1.h,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.h),
                      borderSide: BorderSide(
                        color: isEmergencyPhoneVerified ? Colors.green.shade600 : theme.colorScheme.primary,
                        width: 1.5.h,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 14.h,
                      horizontal: 12.h,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 13.fSize,
                    color: Colors.black87,
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                ),
              ),
              SizedBox(width: 8.h),
              // Tombol Verifikasi WA OTP (1/4 Lebar)
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 48.h,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEmergencyPhoneVerified
                          ? Colors.green.shade50
                          : Colors.green.shade700,
                      foregroundColor: isEmergencyPhoneVerified
                          ? Colors.green.shade800
                          : Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.h),
                        side: BorderSide(
                          color: isEmergencyPhoneVerified
                              ? Colors.green.shade300
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    onPressed: isEmergencyPhoneVerified
                        ? null
                        : () {
                            final currentPhone = state.emergencyContactInputController?.text ?? '';
                            _startPhoneOtpVerification(context, currentPhone, isEmergency: true);
                          },
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEmergencyPhoneVerified
                                ? Icons.check_circle_rounded
                                : Icons.chat_rounded,
                            size: 16.h,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            isEmergencyPhoneVerified ? "Terverif" : "Verif WA",
                            style: TextStyle(
                              fontSize: 10.fSize,
                              fontWeight: FontWeight.bold,
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

  /// Section Widget - Aesthetic KTP ID Card Frame
  Widget _buildIdentityUploadSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Foto KTP / Kartu Identitas",
              style: CustomTextStyles.bodyMediumGray50003.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_fileNameIdentity != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6.h),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.green, size: 12),
                    SizedBox(width: 4.h),
                    Text(
                      "Terbaca AI OCR ✨",
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontSize: 10.fSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        GestureDetector(
          onTap: _pickKtpFile,
          child: AspectRatio(
            aspectRatio: 1.58, // Rasio resmi KTP (85.6mm x 54mm)
            child: CustomPaint(
              painter: KtpFrameBorderPainter(
                color: _fileNameIdentity != null ? Colors.green : Colors.grey.shade400,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.h),
                child: Container(
                  color: _fileNameIdentity != null ? Colors.black.withOpacity(0.02) : Colors.green.withOpacity(0.03),
                  child: _buildKtpFrameContent(),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 16.h),
      ],
    );
  }

  Widget _buildKtpFrameContent() {
    Widget? imageWidget;

    if (_filePathIdentity != null && File(_filePathIdentity!).existsSync()) {
      imageWidget = Image.file(
        File(_filePathIdentity!),
        fit: BoxFit.cover,
      );
    } else if (_fileBytesIdentity != null) {
      imageWidget = Image.memory(
        _fileBytesIdentity!,
        fit: BoxFit.cover,
      );
    } else if (ktpPhotoUrl != null && ktpPhotoUrl!.isNotEmpty) {
      imageWidget = Image.network(
        ktpPhotoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.grey.shade400, size: 40.h),
            SizedBox(height: 4.h),
            Text("Gagal memuat foto KTP", style: TextStyle(fontSize: 11.fSize, color: Colors.grey)),
          ],
        ),
      );
    }

    if (imageWidget != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          // Tombol Silang (X) di Pojok Kanan Atas
          Positioned(
            top: 8.h,
            right: 8.h,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _fileNameIdentity = null;
                  _filePathIdentity = null;
                  _fileBytesIdentity = null;
                  ktpPhotoUrl = null;
                });
              },
              child: Container(
                padding: EdgeInsets.all(6.h),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white70, width: 1.5),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16.h,
                ),
              ),
            ),
          ),
          // Badge "Ganti Foto KTP" di Pojok Kanan Bawah
          Positioned(
            bottom: 8.h,
            right: 8.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.h, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8.h),
              ),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: Colors.white, size: 14.h),
                  SizedBox(width: 4.h),
                  Text(
                    "Ganti Foto KTP",
                    style: TextStyle(color: Colors.white, fontSize: 11.fSize),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.credit_card_rounded,
            color: Colors.green.shade700,
            size: 36.h,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          "Posisikan Foto KTP di Dalam Bingkai",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
            fontSize: 13.fSize,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          "Ketuk untuk Unggah & Scan NIK, Tanggal Lahir, & Alamat",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 11.fSize,
          ),
        ),
      ],
    );
  }

  Future<void> _pickKtpFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      withData: true,
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      double fileSizeInMB = file.size / (1024 * 1024);

      if (fileSizeInMB > 2) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Ukuran File Terlalu Besar"),
            content: const Text("Ukuran file tidak boleh lebih dari 2MB."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _fileNameIdentity = file.name;
        _filePathIdentity = kIsWeb ? null : file.path;
        _fileBytesIdentity = file.bytes;
        ktpPhotoUrl = null;
      });

      if (!kIsWeb && file.path != null) {
        // Show Loading Dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.h),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.green),
                    SizedBox(height: 16.h),
                    const Text(
                      "Membaca & Mengisi Data KTP",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      "Memproses AI OCR untuk membaca NIK, Tanggal Lahir, & Alamat...",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12.fSize),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        final ocrResult = await KtpOcrParser.parseKtpImage(File(file.path!));

        // Dismiss Loading Dialog
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }

        if (mounted) {
          final bloc = context.read<DataProfileBloc>();
          final state = bloc.state;
          int filledCount = 0;

          if (ocrResult.nik != null && ocrResult.nik!.isNotEmpty) {
            state.nikInputController?.text = ocrResult.nik!;
            bloc.add(NikChangedEvent(ocrResult.nik!));
            filledCount++;
          }

          if (ocrResult.dateOfBirth != null && ocrResult.dateOfBirth!.isNotEmpty) {
            state.dateOfBirthController?.text = ocrResult.dateOfBirth!;
            bloc.add(DateOfBirthChangedEvent(ocrResult.dateOfBirth!));
            filledCount++;
          }

          if (ocrResult.address != null && ocrResult.address!.isNotEmpty) {
            state.addressInputController?.text = ocrResult.address!;
            bloc.add(AddressChangedEvent(ocrResult.address!));
            filledCount++;
          }

          setState(() {});

          if (filledCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Berhasil mengisi otomatis $filledCount data KTP (NIK, Tanggal Lahir, & Alamat)! ✨'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Foto KTP terbaca. Teks raw: ${ocrResult.rawText != null && ocrResult.rawText!.isNotEmpty ? ocrResult.rawText!.replaceAll('\n', ' ') : "Teks KTP kabur, silakan isi manual"}'),
                backgroundColor: Colors.amber.shade900,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      }
    }
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
