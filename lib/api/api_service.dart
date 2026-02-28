import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:myhiking/models/bookingModel.dart';
import 'package:myhiking/models/model.dart';
import 'package:myhiking/presentation/data_profile_screen/models/res_user.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../presentation/rules_screen/models/rule_model.dart';

const String baseUrl = 'http://127.0.0.1:8000/api';

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
    final response = await http.get(Uri.parse('$baseUrl/mountains'));

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
        Uri.parse("$baseUrl/orders"),
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
        final orderId = jsonResponse['order']
            ['id']; // Using jsonResponse, not response
        // Check if members exist in response

        if (jsonResponse['order']['members'] != null) {
          // Ensure members is a List
          if (jsonResponse['order']['members'] is List) {
            List membersData = jsonResponse['order']['members'];
            print("Members Data: $membersData");
          } else {
            print("Members data not in expected List format.");
          }
        } else {
          print("Members not found");
        }

        print(
            "Order created successfully! Order ID: ${jsonResponse['order']['id']}");

        getOrderDetail(orderId);
        return ModelBooking.fromJson(jsonResponse['order']);
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

  Future<void> getOrderDetail(int orderId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/$orderId'),
      headers: {
        'Authorization': 'Bearer YOUR_TOKEN',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final members = responseJson['order']['members'];

      print('Members Data: $members');

      // Process members data
      if (members != null && members.isNotEmpty) {
        // Members exist, process as needed
      }
    } else {
      print('Failed to get order detail');
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
  Future<Map<String, dynamic>> fetchPesanan(int orderId) async {
    final response = await http.get(Uri.parse('$baseUrl/orders/$orderId'));
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
    int orderId,
    int id,
  ) async {
    try {
      print("Api order id, payment id: $orderId, $id");
      final response = await http.post(
        Uri.parse('$baseUrl/transactions/store'),
        headers: {
          'Content-Type': 'application/json',
          // Tambahkan header Authorization jika diperlukan:
          // 'Authorization': 'Bearer your_token_here',
        },
        body: json.encode({
          'id_pesanan': orderId,
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
      String transactionId, String filePath) async {
    try {
      // Endpoint API
      final url =
          Uri.parse('$baseUrl/transactions/update-payment/$transactionId');

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

  // ==================== FRIEND API METHODS ====================

  /// Get all friends for a user
  Future<Map<String, dynamic>> getFriends(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch friends',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get pending friend requests
  Future<Map<String, dynamic>> getPendingRequests(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends/pending?user_id=$userId'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch pending requests',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Search users
  Future<Map<String, dynamic>> searchUsers(String query, int currentUserId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/friends/search?query=$query&user_id=$currentUserId'),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        return {
          'success': false,
          'message': 'Failed to search users',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Send friend request
  Future<Map<String, dynamic>> addFriend(int userId, int friendId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/friends/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'friend_id': friendId,
        }),
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Accept friend request
  Future<Map<String, dynamic>> acceptFriend(int friendshipId, int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/friends/$friendshipId/accept'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Reject friend request
  Future<Map<String, dynamic>> rejectFriend(int friendshipId, int userId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/friends/$friendshipId/reject'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Remove friend
  Future<Map<String, dynamic>> removeFriend(int friendshipId, int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/friends/$friendshipId?user_id=$userId'),
      );

      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get current weather from Open-Meteo API
  Future<Map<String, dynamic>> getCurrentWeather(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code&timezone=auto'
      );
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch weather data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get weather forecast from Open-Meteo API (7 days with hourly data)
  Future<Map<String, dynamic>> getWeatherForecast(double latitude, double longitude) async {
    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude'
        '&daily=temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,sunrise,sunset'
        '&hourly=temperature_2m,weather_code,relative_humidity_2m,precipitation_probability,wind_speed_10m'
        '&timezone=auto&forecast_days=7'
      );
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch weather forecast',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
