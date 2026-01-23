import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:myhiking/models/bookingModel.dart';
import 'package:myhiking/models/model.dart';
import 'package:myhiking/presentation/data_profile_screen/models/res_user.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/tata_tertib_screen/models/tata_tertib_model.dart';

// Gunakan URL yang sesuai dengan platform
// Untuk development lokal, gunakan localhost
// Untuk production, ganti ke domain yang sebenarnya
String get baseUrl {
  // Jika menjalankan di web browser (Flutter Web)
  if (kIsWeb) {
    return 'http://127.0.0.1:8000/api';
  }
  // Jika menjalankan di Android Emulator, gunakan 10.0.2.2
  // Jika menjalankan di device fisik, gunakan IP komputer Anda
  // return 'http://10.0.2.2:8000/api'; // Untuk Android Emulator
  return 'http://127.0.0.1:8000/api'; // Untuk testing lokal / iOS Simulator
}

class ApiService {
  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<Map<String, dynamic>> getUser(String token) async {
    final url = Uri.parse('$baseUrl/user');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'data': responseData,
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {'success': false, 'errors': errorData};
    }
  }

  Future<List<Gunung>> fetchGunung() async {
    final response = await http.get(Uri.parse('$baseUrl/gunung'));

    if (response.statusCode == 200) {
      List jsonResponse = json.decode(response.body);
      return jsonResponse.map((data) => Gunung.fromJson(data)).toList();
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = Uri.parse('$baseUrl/user');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'data': responseData,
      };
    } else {
      final errorData = jsonDecode(response.body);
      return {'success': false, 'errors': errorData};
    }
  }

  Future<ModelBooking?> createBooking(
    int idGunung,
    int jalurId,
    int userId,
    String formattedDate,
    String tanggalTurun,
    int totalHargaTiket, {
    List<int>? anggotaIds, // Parameter opsional untuk anggota
  }) async {
    try {
      // print('$anggotaIds');
      String? token = await getToken();
      print('Token yang ditemukan: $token');

      // Periksa apakah token ada dan benar
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      // Membuat body request
      Map<String, dynamic> requestBody = {
        "id_gunung": idGunung,
        "id_jalur": jalurId,
        "id_user": userId,
        "tanggal_naik": formattedDate, // Gunakan formattedDate di sini
        "tanggal_turun": tanggalTurun,
        "total_harga_tiket": totalHargaTiket,
      };

      // Menambahkan anggotaIds ke requestBody jika ada
      if (anggotaIds != null && anggotaIds.isNotEmpty) {
        requestBody["anggota_ids"] = anggotaIds;
      }
      print("Anggota Ids: {$anggotaIds}");
      final response = await http.post(
        Uri.parse("$baseUrl/pesanan"),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      // Menambahkan log untuk memeriksa respons
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');
      print('Headers: ${response.headers}');

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        final pesananId = jsonResponse['pesanan']
            ['id']; // Menggunakan jsonResponse, bukan response
        // Cek apakah anggota ada atau tidak dalam response

        if (jsonResponse['pesanan']['anggota'] != null) {
          // Pastikan anggota berupa List
          if (jsonResponse['pesanan']['anggota'] is List) {
            List anggotaData = jsonResponse['pesanan']['anggota'];
            print("Data Anggota: $anggotaData");
          } else {
            print("Data anggota tidak dalam format List yang diharapkan.");
          }
        } else {
          print("Anggota tidak ditemukan");
        }

        print(
            "Pesanan berhasil dibuat! Pesanan ID: ${jsonResponse['pesanan']['id']}");

        getPesananDetail(pesananId);
        return ModelBooking.fromJson(jsonResponse['pesanan']);
      } else if (response.statusCode == 302) {
        throw Exception('Redirect terjadi. Periksa konfigurasi backend.');
      } else {
        throw Exception(
            'Gagal membuat booking. Kode status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('Terjadi kesalahan saat membuat booking: $e');
      return null;
    }
  }

  Future<void> getPesananDetail(int pesananId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pesanan/$pesananId'),
      headers: {
        'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final anggota = responseJson['pesanan']['anggota'];

      print('Data Anggota: $anggota');

      // Lakukan sesuatu dengan data anggota
      if (anggota != null && anggota.isNotEmpty) {
        // Anggota ada, proses sesuai kebutuhan
      }
    } else {
      print('Gagal mendapatkan detail pesanan');
    }
  }

  Future<Map<String, dynamic>> fetchTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch transactions');
    }
  }

  // Fungsi untuk mengambil data Pesanan berdasarkan ID
  Future<Map<String, dynamic>> fetchPesanan(int pesananId) async {
    final response = await http.get(Uri.parse('$baseUrl/pesanan/$pesananId'));
    print(response);
    if (response.statusCode == 200) {
      // Debug: Print the response body to check
      print('Response Body: ${response.body}');
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load pesanan');
    }
  }

  Future<ResUser> updateUserProfile({
    required int userId,
    required String name,
    required String email,
    String? password,
    String? address,
    String? nik,
    String? phone,
    String? emergencyPhone,
    String? dateOfBirth,
    File? profilePicture,
    int? level,
  }) async {
    try {
      // Endpoint API
      final url = Uri.parse('$baseUrl/users/$userId');

      // Buat request multipart
      final request = http.MultipartRequest('POST', url);

      // Tambahkan headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Menambahkan data fields ke dalam request
      request.fields['name'] = name;
      request.fields['email'] = email;
      if (password != null) request.fields['password'] = password;
      if (address != null) request.fields['address'] = address;
      if (nik != null) request.fields['nik'] = nik;
      if (phone != null) request.fields['phone'] = phone;
      if (emergencyPhone != null)
        request.fields['emergency_phone'] = emergencyPhone;
      if (dateOfBirth != null) request.fields['date_of_birth'] = dateOfBirth;
      if (level != null) request.fields['level'] = level.toString();

      // Menambahkan file profile_picture jika ada
      if (profilePicture != null) {
        final profilePictureStream = http.ByteStream(profilePicture.openRead());
        final profilePictureLength = await profilePicture.length();

        final multipartFile = http.MultipartFile(
          'profile_picture',
          profilePictureStream,
          profilePictureLength,
          filename: profilePicture.path.split('/').last,
        );

        request.files.add(multipartFile);
      }

      // Kirim request dan tunggu respon
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Periksa status kode HTTP
      if (response.statusCode == 200) {
        // Parse respon body
        final responseData = jsonDecode(response.body);

        if (responseData['data'] != null) {
          final userData = responseData['data'];
          return ResUser.fromJson(userData);
        } else {
          print("Respon tidak valid: ${response.body}");
          throw Exception('Respon tidak valid');
        }
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
        throw Exception('Gagal memperbarui profil');
      }
    } catch (e) {
      print("Exception: $e");
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  Future<Map<String, dynamic>> updatePassword({
    required int userId,
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      String? token = await getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/update-password/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
          'confirm_password': confirmPassword,
        }),
      );

      final Map<String, dynamic> data = json.decode(response.body);
      if (response.statusCode == 200) {
        return data;
      } else {
        throw Exception(data['message'] ?? 'Gagal mengupdate password');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<TransactionResponseModel> createTransaction(
    int pesananId,
    int id,
  ) async {
    try {
      print("Api pesanan id, payment id: $pesananId, $id");
      final response = await http.post(
        Uri.parse('$baseUrl/transaksi/store'),
        headers: {
          'Content-Type': 'application/json',
          // Tambahkan header Authorization jika diperlukan:
          // 'Authorization': 'Bearer your_token_here',
        },
        body: json.encode({
          'id_pesanan': pesananId,
          'payment_id': id,
        }),
      );

      if (response.statusCode == 201) {
        // Parsing respons JSON jika sukses
        print('Transaction created successfully');
        print('Response body: ${response.body}');
        return TransactionResponseModel.fromJson(json.decode(response.body));
      } else {
        // Tangani error dari server
        final errorBody = json.decode(response.body);
        print('Failed to create transaction');
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Failed to create transaction: ${errorBody['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      // Tangani kesalahan lain (misalnya kesalahan jaringan atau parsing)
      print('Error creating transaction: $e');
      throw Exception('Failed to create transaction. Please try again.');
    }
  }

  Future<void> uploadBuktiPembayaran(
      String idTransaksi, String filePath) async {
    try {
      // Endpoint API
      final url =
          Uri.parse('$baseUrl/transaksi/update-pembayaran/$idTransaksi');

      // Buat request multipart
      final request = http.MultipartRequest('POST', url);

      // Tambahkan headers
      request.headers.addAll({
        'Accept': 'application/json',
      });

      // Tambahkan waktu_pembayaran ke dalam request fields
      request.fields['waktu_pembayaran'] = DateTime.now().toIso8601String();

      // Tambahkan file ke dalam request
      final file = await http.MultipartFile.fromPath('bukti', filePath);
      request.files.add(file);

      // Kirim request dan tunggu respon
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Periksa status kode HTTP
      if (response.statusCode == 200) {
        // Parse respon body
        final responseData = jsonDecode(response.body);

        if (responseData['message'] != null) {
          print(responseData['message']); // Cetak pesan sukses
          final transaksi = responseData['transaksi']; // Ambil data transaksi
          print("Detail Transaksi: $transaksi");

          // Tampilkan data yang relevan ke user
          print("Bukti: ${transaksi['bukti']}");
        } else {
          print("Respon tidak valid: ${response.body}");
        }
      } else {
        print("Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }
}
