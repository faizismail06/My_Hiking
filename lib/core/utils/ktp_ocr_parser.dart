import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class KtpOcrResult {
  final String? nik;
  final String? dateOfBirth; // DD-MM-YYYY untuk Tampilan UI
  final String? address;
  final String? rawText;

  KtpOcrResult({
    this.nik,
    this.dateOfBirth,
    this.address,
    this.rawText,
  });

  @override
  String toString() {
    return 'KtpOcrResult(nik: $nik, dateOfBirth: $dateOfBirth, address: $address)';
  }
}

class KtpOcrParser {
  static Future<KtpOcrResult> parseKtpImage(File imageFile) async {
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      final String fullText = recognizedText.text;
      debugPrint('========================================');
      debugPrint('--- RAW OCR KTP TEXT FROM ML KIT ---');
      debugPrint(fullText);
      debugPrint('========================================');

      final List<String> lines = _extractAllLines(recognizedText);

      final String? nik = _extractNik(lines, fullText);
      final String? dateOfBirth = _extractDateOfBirth(lines, fullText, nik);
      final String? address = _extractAddress(lines, fullText);

      debugPrint('--- PARSED KTP FINAL RESULT ---');
      debugPrint('NIK: $nik');
      debugPrint('DOB: $dateOfBirth');
      debugPrint('ADDRESS: $address');
      debugPrint('========================================');

      return KtpOcrResult(
        nik: nik,
        dateOfBirth: dateOfBirth,
        address: address,
        rawText: fullText,
      );
    } catch (e) {
      debugPrint('Error running KTP OCR: $e');
      return KtpOcrResult();
    } finally {
      textRecognizer.close();
    }
  }

  /// Memecah seluruh blok & baris teks menjadi List<String>
  static List<String> _extractAllLines(RecognizedText recognizedText) {
    List<String> lines = [];
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String clean = line.text.trim();
        if (clean.isNotEmpty) {
          lines.add(clean);
        }
      }
    }
    if (lines.isEmpty && recognizedText.text.isNotEmpty) {
      lines = recognizedText.text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    }
    return lines;
  }

  /// 1. Ekstraksi 16-Digit NIK dari Teks KTP
  static String? _extractNik(List<String> lines, String fullText) {
    String cleanLineDigits(String line) {
      String normalized = line
          .replaceAll(RegExp(r'[oO]'), '0')
          .replaceAll(RegExp(r'[iIl|]'), '1')
          .replaceAll(RegExp(r'[zZ]'), '2')
          .replaceAll(RegExp(r'[aA]'), '4')
          .replaceAll(RegExp(r'[sS]'), '5')
          .replaceAll(RegExp(r'[gG]'), '6')
          .replaceAll(RegExp(r'[bB]'), '8');
      return normalized.replaceAll(RegExp(r'[^0-9]'), '');
    }

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.toLowerCase().contains('nik') || line.toLowerCase().contains('n i k')) {
        String digits = cleanLineDigits(line);
        if (digits.length >= 16) {
          return digits.substring(0, 16);
        }
        if (i + 1 < lines.length) {
          String nextDigits = cleanLineDigits(lines[i + 1]);
          if (nextDigits.length >= 16) {
            return nextDigits.substring(0, 16);
          }
        }
      }
    }

    for (String line in lines) {
      String digits = cleanLineDigits(line);
      if (digits.length == 16) {
        return digits;
      }
    }

    final match = RegExp(r'\b([0-9]{16})\b').firstMatch(cleanLineDigits(fullText));
    if (match != null) {
      return match.group(1);
    }

    return null;
  }

  /// 2. Ekstraksi Tanggal Lahir (Format Tampilan UI: DD-MM-YYYY)
  static String? _extractDateOfBirth(List<String> lines, String fullText, String? nik) {
    for (String line in lines) {
      if (line.toLowerCase().contains('lahir') || line.toLowerCase().contains('tgl')) {
        final match = RegExp(r'(\d{2})[-/\s\.](\d{2})[-/\s\.](\d{4})').firstMatch(line);
        if (match != null) {
          String day = match.group(1)!;
          String month = match.group(2)!;
          String year = match.group(3)!;
          int iDay = int.tryParse(day) ?? 0;
          int iMonth = int.tryParse(month) ?? 0;
          if (iDay >= 1 && iDay <= 31 && iMonth >= 1 && iMonth <= 12) {
            return '$day-$month-$year';
          }
        }
      }
    }

    final allMatches = RegExp(r'(\d{2})[-/\s\.](\d{2})[-/\s\.](\d{4})').allMatches(fullText);
    for (final match in allMatches) {
      String day = match.group(1)!;
      String month = match.group(2)!;
      String year = match.group(3)!;
      int iDay = int.tryParse(day) ?? 0;
      int iMonth = int.tryParse(month) ?? 0;
      int iYear = int.tryParse(year) ?? 0;
      if (iDay >= 1 && iDay <= 31 && iMonth >= 1 && iMonth <= 12 && iYear >= 1940 && iYear <= 2015) {
        return '$day-$month-$year';
      }
    }

    if (nik != null && nik.length == 16) {
      try {
        int rawDay = int.parse(nik.substring(6, 8));
        int month = int.parse(nik.substring(8, 10));
        int rawYear = int.parse(nik.substring(10, 12));

        int day = rawDay > 40 ? rawDay - 40 : rawDay;
        int currentYearShort = DateTime.now().year % 100;
        int year = rawYear > currentYearShort ? 1900 + rawYear : 2000 + rawYear;

        if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 1940 && year <= 2015) {
          String strDay = day.toString().padLeft(2, '0');
          String strMonth = month.toString().padLeft(2, '0');
          return '$strDay-$strMonth-$year';
        }
      } catch (e) {
        debugPrint('Error parsing DOB from NIK: $e');
      }
    }

    return null;
  }

  /// 3. Ekstraksi Alamat Lengkap Presisi Kompatibel untuk Tata Letak Kolom HP Android
  static String? _extractAddress(List<String> lines, String fullText) {
    String? street;
    String? rtrw;
    String? desa;
    String? kecamatan;

    // Bersihkan titik dua di awal baris (misal `: JL. PASTI CEPAT` -> `JL. PASTI CEPAT`)
    List<String> cleanLines = lines.map((l) {
      return l.replaceAll(RegExp(r'^[:\s\-\.]+\s*'), '').trim();
    }).where((l) => l.isNotEmpty).toList();

    // Word filter untuk mendeteksi kata kunci label KTP
    bool isLabelText(String text) {
      String l = text.toLowerCase();
      return l == 'alamat' || l == 'rt/rw' || l == 'kel/desa' || l == 'kecamatan' ||
             l == 'agama' || l == 'status perkawinan' || l == 'pekerjaan' || l == 'kewarganegaraan' ||
             l == 'jenis kelamin' || l == 'gol. darah';
    }

    // A. Cari RT/RW (misal `007/008` atau `RT/RW 007/008`)
    int rtrwLineIndex = -1;
    for (int i = 0; i < cleanLines.length; i++) {
      String line = cleanLines[i];
      final match = RegExp(r'(\d{2,3}\s*/\s*\d{2,3})').firstMatch(line);
      if (match != null) {
        rtrw = 'RT/RW ${match.group(1)!.replaceAll(' ', '')}';
        rtrwLineIndex = i;
        break;
      }
    }

    // B. Cari Desa & Kecamatan dari Baris yang Mengikuti RT/RW (Khusus Tata Letak Kolom Nilai)
    if (rtrwLineIndex != -1) {
      // Baris tepat setelah RT/RW biasanya adalah nama Desa (misal `PEGADUNGAN`)
      if (rtrwLineIndex + 1 < cleanLines.length) {
        String candidateDesa = cleanLines[rtrwLineIndex + 1];
        candidateDesa = candidateDesa.replaceAll(RegExp(r'.*(?:Kel/Desa|Kelurahan|Desa)\s*:?\s*', caseSensitive: false), '').trim();
        if (candidateDesa.isNotEmpty && !isLabelText(candidateDesa) && !candidateDesa.toLowerCase().contains('kecamatan')) {
          desa = 'Desa $candidateDesa';
        }
      }

      // Baris kedua setelah RT/RW biasanya adalah nama Kecamatan (misal `KALIDERES`)
      if (rtrwLineIndex + 2 < cleanLines.length) {
        String candidateKec = cleanLines[rtrwLineIndex + 2];
        candidateKec = candidateKec.replaceAll(RegExp(r'.*Kec(?:amatan|\.)?\s*:?\s*', caseSensitive: false), '').trim();
        if (candidateKec.isNotEmpty && !isLabelText(candidateKec) && !candidateKec.toLowerCase().contains('agama')) {
          kecamatan = 'Kec. $candidateKec';
        }
      }
    }

    // Fallback: Cari Desa & Kecamatan dari teks label langsung jika belum ketemu
    if (desa == null) {
      for (String line in cleanLines) {
        String lower = line.toLowerCase();
        if (lower.contains('kelamin')) continue;
        if (lower.contains('kel/desa') || lower.contains('kelurahan') || lower.contains('desa')) {
          String val = line.replaceAll(RegExp(r'.*(?:Kel/Desa|Kelurahan|Desa)\s*:?\s*', caseSensitive: false), '').trim();
          if (val.isNotEmpty && !isLabelText(val)) {
            desa = 'Desa $val';
            break;
          }
        }
      }
    }

    if (kecamatan == null) {
      for (String line in cleanLines) {
        String lower = line.toLowerCase();
        if (lower.contains('kecamatan') || lower.contains('kec.')) {
          String val = line.replaceAll(RegExp(r'.*Kec(?:amatan|\.)?\s*:?\s*', caseSensitive: false), '').trim();
          if (val.isNotEmpty && !isLabelText(val)) {
            kecamatan = 'Kec. $val';
            break;
          }
        }
      }
    }

    // C. Cari Nama Jalan (Alamat Utama)
    for (int i = 0; i < cleanLines.length; i++) {
      String line = cleanLines[i];
      String lower = line.toLowerCase();

      if (lower.contains('alamat')) {
        String cleaned = line.replaceAll(RegExp(r'.*Ala?m[a1]st?\s*:?\s*', caseSensitive: false), '').trim();
        cleaned = cleaned.replaceAll(RegExp(r'RT/RW.*', caseSensitive: false), '').trim();
        if (cleaned.isNotEmpty && !isLabelText(cleaned)) {
          street = cleaned;
          break;
        }
        if (i + 1 < cleanLines.length) {
          String nextLine = cleanLines[i + 1];
          if (!isLabelText(nextLine) && !RegExp(r'\d{2,3}/\d{2,3}').hasMatch(nextLine)) {
            street = nextLine;
            break;
          }
        }
      }

      if (RegExp(r'^(JL|JALAN|GG|GANG|DUSUN|KP|KAMPUNG|BLOK|PASTI)\b', caseSensitive: false).hasMatch(line)) {
        String clean = line.replaceAll(RegExp(r'RT/RW.*', caseSensitive: false), '').trim();
        if (clean.length >= 3 && !isLabelText(clean)) {
          street = clean;
          break;
        }
      }
    }

    // Fallback Jalan: Baris sebelum RT/RW jika RT/RW ditemukan
    if (street == null && rtrwLineIndex > 0) {
      String candidateStreet = cleanLines[rtrwLineIndex - 1];
      if (!isLabelText(candidateStreet) && candidateStreet.length >= 3) {
        street = candidateStreet;
      }
    }

    // Gabungkan komponen alamat menjadi satu alamat lengkap utuh
    List<String> parts = [];
    if (street != null && street.isNotEmpty) parts.add(street);
    if (rtrw != null && rtrw.isNotEmpty) parts.add(rtrw);
    if (desa != null && desa.isNotEmpty) parts.add(desa);
    if (kecamatan != null && kecamatan.isNotEmpty) parts.add(kecamatan);

    if (parts.isNotEmpty) {
      return parts.join(', ');
    }

    return null;
  }
}
