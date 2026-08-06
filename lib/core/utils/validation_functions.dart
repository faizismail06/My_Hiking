bool isValidEmail(String? inputString, {bool isRequired = false}) {
  bool isInputStringValid = false;

  if (!isRequired && (inputString == null ? true : inputString.isEmpty)) {
    isInputStringValid = true;
  }

  if (inputString != null && inputString.isNotEmpty) {
    const pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    final regExp = RegExp(pattern);
    isInputStringValid = regExp.hasMatch(inputString);
  }

  return isInputStringValid;
}

/// Validasi NIK Indonesia (16 Digit & Tanggal Lahir)
bool isValidNIK(String? nik, {DateTime? birthDate}) {
  if (nik == null || nik.isEmpty) return false;

  // Wajib 16 digit angka
  final regExp = RegExp(r'^[0-9]{16}$');
  if (!regExp.hasMatch(nik)) return false;

  // Ekstrak Tanggal, Bulan, Tahun dari NIK
  try {
    int rawDay = int.parse(nik.substring(6, 8));
    int month = int.parse(nik.substring(8, 10));

    // Wanita: tanggal lahir + 40
    int day = rawDay > 40 ? rawDay - 40 : rawDay;

    if (day < 1 || day > 31) return false;
    if (month < 1 || month > 12) return false;

    // Jika ada tanggal lahir pembanding dari form
    if (birthDate != null) {
      if (birthDate.day != day || birthDate.month != month) {
        return false;
      }
    }
  } catch (e) {
    return false;
  }

  return true;
}

/// Validasi Nomor HP Indonesia (+62 / 62 / 08...)
bool isValidIndonesianPhone(String? phone) {
  if (phone == null || phone.isEmpty) return false;
  final regExp = RegExp(r'^(?:\+62|62|0)8[1-9][0-9]{7,10}$');
  return regExp.hasMatch(phone);
}

/// Validasi Kontak Darurat (Wajib beda dengan nomor pribadi)
bool isValidEmergencyContact(String? userPhone, String? emergencyPhone) {
  if (!isValidIndonesianPhone(emergencyPhone)) return false;
  if (userPhone == null || userPhone.isEmpty) return true;

  // Normalize numbers (hilangkan +62 / 0)
  String normUser = userPhone.replaceAll(RegExp(r'^\+62|^62|^0'), '');
  String normEmergency = emergencyPhone!.replaceAll(RegExp(r'^\+62|^62|^0'), '');

  return normUser != normEmergency;
}
