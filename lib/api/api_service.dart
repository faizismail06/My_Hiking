import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:myhiking/models/bookingModel.dart';
import 'package:myhiking/models/model.dart';
import 'package:myhiking/presentation/home_screen/models/recommendation_model.dart';
import 'package:myhiking/presentation/data_profile_screen/models/res_user.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000/api',
);

const String chatbotBaseUrl = String.fromEnvironment(
  'CHATBOT_BASE_URL',
  defaultValue: 'http://127.0.0.1:5000/api',
);

class ApiActionException implements Exception {
  final String code;
  final String message;
  final int statusCode;
  final String? nextStep;
  final Map<String, dynamic>? data;

  ApiActionException({
    required this.code,
    required this.message,
    required this.statusCode,
    this.nextStep,
    this.data,
  });

  factory ApiActionException.fromHttp(Response response) {
    Map<String, dynamic> parsed = {};
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        parsed = body;
      }
    } catch (_) {
      parsed = {};
    }

    return ApiActionException(
      code: (parsed['code'] ?? 'UNKNOWN_ERROR').toString(),
      message:
          (parsed['message'] ?? 'Terjadi kesalahan pada server.').toString(),
      statusCode: response.statusCode,
      nextStep: parsed['next_step']?.toString(),
      data: parsed,
    );
  }

  @override
  String toString() {
    return 'ApiActionException(code: $code, status: $statusCode, message: $message)';
  }
}

class BookingDecisionResult {
  final ModelBooking booking;
  final Map<String, dynamic>? dss;
  final Map<String, dynamic>? warning;

  BookingDecisionResult({
    required this.booking,
    this.dss,
    this.warning,
  });
}

class ApiService {
  static const String _homeFeedCachePrefix = 'home_feed_cache_v2_';

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<String?> _resolveHomeFeedCacheKey() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return null;
    }
    return '$_homeFeedCachePrefix${token.hashCode}';
  }

  Future<bool> hasHomeFeedCache() async {
    final key = await _resolveHomeFeedCacheKey();
    if (key == null) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) != null;
  }

  Future<Map<String, dynamic>?> getCachedHomeFeed() async {
    final key = await _resolveHomeFeedCacheKey();
    if (key == null) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(key);
    if (cached == null || cached.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(cached);
      if (decoded is Map<String, dynamic>) {
        if (decoded['payload'] is Map<String, dynamic>) {
          return decoded['payload'] as Map<String, dynamic>;
        }
        return decoded;
      }

      if (decoded is Map) {
        final converted = Map<String, dynamic>.from(decoded);
        if (converted['payload'] is Map) {
          return Map<String, dynamic>.from(converted['payload'] as Map);
        }
        return converted;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Future<void> cacheHomeFeed(Map<String, dynamic> payload) async {
    final key = await _resolveHomeFeedCacheKey();
    if (key == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'cached_at': DateTime.now().toIso8601String(),
        'payload': payload,
      }),
    );
  }

  Future<Map<String, dynamic>> fetchHomeFeedFromServer() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/mountains/home-feed'),
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memuat home feed. Status: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }

    throw Exception('Format home feed tidak valid.');
  }

  Future<Map<String, dynamic>> warmHomeFeedCache() async {
    final payload = await fetchHomeFeedFromServer();
    await cacheHomeFeed(payload);
    return payload;
  }

  Future<List<RecommendationModel>> fetchRecommendations({
    int limit = 3,
  }) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/recommendations?limit=$limit');

    final response = await http.get(
      uri,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal memuat rekomendasi TOPSIS. Status: ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    final payload = decoded is Map<String, dynamic>
        ? decoded
        : decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};

    final rawItems = payload['recommendations'];
    final List<dynamic> items = rawItems is List ? rawItems : const [];

    final parsed = <RecommendationModel>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is Map<String, dynamic>) {
        parsed.add(RecommendationModel.fromJson(item, fallbackRank: i + 1));
      } else if (item is Map) {
        parsed.add(
          RecommendationModel.fromJson(
            Map<String, dynamic>.from(item),
            fallbackRank: i + 1,
          ),
        );
      }
    }

    return parsed;
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final url = Uri.parse('$baseUrl/auth/google');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'id_token': idToken}),
    );

    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return responseData;
    }

    throw Exception(
      responseData['message']?.toString() ??
          'Gagal autentikasi menggunakan Google.',
    );
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

  Future<Map<String, dynamic>> getOnboardingExperienceStatus(
      String token) async {
    final url = Uri.parse('$baseUrl/onboarding/experience/status');
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
        'data': responseData['data'] ?? {},
      };
    }

    if ([401, 403, 409, 422].contains(response.statusCode)) {
      throw ApiActionException.fromHttp(response);
    }

    throw Exception(
      'Gagal mengambil status onboarding. Kode status: ${response.statusCode}',
    );
  }

  Future<Map<String, dynamic>> submitOnboardingExperience({
    required int jumlahPendakian,
    required int jumlahSummit,
    List<Map<String, dynamic>>? questionnaireAnswers,
    int? totalWeightedScore,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw ApiActionException(
        code: 'UNAUTHORIZED',
        message: 'Silakan login terlebih dahulu.',
        statusCode: 401,
      );
    }

    final url = Uri.parse('$baseUrl/onboarding/experience');
    final payload = {
      'jumlah_pendakian': jumlahPendakian,
      'jumlah_summit': jumlahSummit,
      if (questionnaireAnswers != null)
        'questionnaire_answers': questionnaireAnswers,
      if (totalWeightedScore != null) 'weighted_score': totalWeightedScore,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'data': responseData['data'] ?? {},
        'message': responseData['message'] ?? 'Onboarding berhasil disimpan.',
      };
    }

    if ([401, 403, 409, 422].contains(response.statusCode)) {
      throw ApiActionException.fromHttp(response);
    }

    throw Exception(
      'Gagal menyimpan onboarding experience. Kode status: ${response.statusCode}',
    );
  }

  Future<ModelBooking?> createBooking(
    int idGunung,
    int jalurId,
    int userId,
    String formattedDate,
    String tanggalTurun,
    int totalHargaTiket, {
    List<int>? anggotaIds, // Parameter opsional untuk anggota
    bool forceContinue = false,
  }) async {
    final result = await createBookingWithDecision(
      idGunung,
      jalurId,
      userId,
      formattedDate,
      tanggalTurun,
      totalHargaTiket,
      anggotaIds: anggotaIds,
      forceContinue: forceContinue,
    );

    return result.booking;
  }

  Future<BookingDecisionResult> createBookingWithDecision(
    int idGunung,
    int jalurId,
    int userId,
    String formattedDate,
    String tanggalTurun,
    int totalHargaTiket, {
    List<int>? anggotaIds,
    bool forceContinue = false,
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
      if (forceContinue) {
        requestBody["force_continue"] = true;
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
        final orderId =
            jsonResponse['order']['id']; // Using jsonResponse, not response
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
        return BookingDecisionResult(
          booking: ModelBooking.fromJson(jsonResponse['order']),
          dss: jsonResponse['dss'] is Map<String, dynamic>
              ? jsonResponse['dss'] as Map<String, dynamic>
              : null,
          warning: jsonResponse['warning'] is Map<String, dynamic>
              ? jsonResponse['warning'] as Map<String, dynamic>
              : null,
        );
      } else if ([403, 409, 422].contains(response.statusCode)) {
        throw ApiActionException.fromHttp(response);
      } else if (response.statusCode == 302) {
        throw Exception('Redirect terjadi. Periksa konfigurasi backend.');
      } else {
        throw Exception(
            'Gagal membuat booking. Kode status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      if (e is ApiActionException) {
        rethrow;
      }
      print('Terjadi kesalahan saat membuat booking: $e');
      throw Exception('Terjadi kesalahan saat membuat booking: $e');
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

  Future<Map<String, dynamic>> fetchTrailBookingAvailability({
    required int mountainId,
    required int trailId,
    required String tanggalNaik,
    required String tanggalTurun,
  }) async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse(
        '$baseUrl/mountains/$mountainId/trails/$trailId/booking'
        '?tanggal_naik=$tanggalNaik&tanggal_turun=$tanggalTurun',
      ),
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final decoded = jsonDecode(response.body);
    final responseData = decoded is Map<String, dynamic>
        ? decoded
        : decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};

    if (response.statusCode == 200) {
      return responseData;
    }

    throw Exception(
      responseData['message']?.toString() ??
          'Gagal memuat kuota pendaki. Status ${response.statusCode}',
    );
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

  Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/orders/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      Map<String, dynamic> responseData = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          responseData = decoded;
        } else if (decoded is Map) {
          responseData = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        responseData = {};
      }

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message']?.toString() ??
              'Pesanan berhasil dibatalkan.',
        };
      }

      return {
        'success': false,
        'message': responseData['message']?.toString() ??
            'Gagal membatalkan pesanan (status ${response.statusCode}).',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getRefundPreview(int orderId) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/refund-preview/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) is Map<String, dynamic>
              ? jsonDecode(response.body) as Map<String, dynamic>
              : <String, dynamic>{};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message']?.toString() ??
              'Preview refund berhasil diambil.',
          'data': responseData['data'] ?? <String, dynamic>{},
        };
      }

      return {
        'success': false,
        'message': responseData['message']?.toString() ??
            'Gagal mengambil preview refund.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> submitRefundRequest({
    required int orderId,
    required String cancelReason,
    required String refundMethod,
    String? bankName,
    String? accountNumber,
    String? accountHolder,
    String? phoneNumber,
  }) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login ulang.',
        };
      }

      final payload = <String, dynamic>{
        'order_id': orderId,
        'cancel_reason': cancelReason,
        'refund_method': refundMethod,
      };

      if (refundMethod == 'Bank Transfer') {
        payload['bank_name'] = bankName;
        payload['account_number'] = accountNumber;
        payload['account_holder'] = accountHolder;
      } else {
        payload['phone_number'] = phoneNumber;
        if (accountHolder != null && accountHolder.trim().isNotEmpty) {
          payload['account_holder'] = accountHolder;
        }
      }

      final response = await http.post(
        Uri.parse('$baseUrl/refund-requests'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final Map<String, dynamic> responseData =
          jsonDecode(response.body) is Map<String, dynamic>
              ? jsonDecode(response.body) as Map<String, dynamic>
              : <String, dynamic>{};

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message']?.toString() ??
              'Permintaan refund berhasil diajukan.',
          'data': responseData['data'] ?? <String, dynamic>{},
        };
      }

      return {
        'success': false,
        'message': responseData['message']?.toString() ??
            'Gagal mengajukan refund request.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getRefundRequestResultByOrder(
      int orderId) async {
    try {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Token tidak ditemukan. Silakan login ulang.',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/refund-requests/order/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final decoded = jsonDecode(response.body);
      final Map<String, dynamic> responseData = decoded is Map<String, dynamic>
          ? decoded
          : decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'] ?? <String, dynamic>{},
        };
      }

      return {
        'success': false,
        'message': responseData['message']?.toString() ??
            'Gagal mengambil hasil refund request.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  Future<Map<String, dynamic>> fetchTrailPreview({
    required int mountainId,
    required int trailId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/mountains/$mountainId/trails/$trailId/preview'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Gagal mengambil preview jalur. Kode status: ${response.statusCode}',
    );
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
    Uint8List? profilePictureBytes,
    String? profilePictureFileName,
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
      if (profilePictureBytes != null && profilePictureFileName != null) {
        final multipartFile = http.MultipartFile.fromBytes(
          'profile_picture',
          profilePictureBytes,
          filename: profilePictureFileName,
        );

        request.files.add(multipartFile);
      } else if (profilePicture != null) {
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

  Future<TransactionResponseModel> createTransaction(int orderId) async {
    try {
      print("Api order id: $orderId");

      // Build request body
      Map<String, dynamic> requestBody = {
        'id_pesanan': orderId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/transactions/store'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        print('Transaction created successfully');
        print('Response body: ${response.body}');
        return TransactionResponseModel.fromJson(json.decode(response.body));
      } else {
        final errorBody = json.decode(response.body);
        print('Failed to create transaction');
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
            'Failed to create transaction: ${errorBody['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
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
  Future<Map<String, dynamic>> searchUsers(
      String query, int currentUserId) async {
    try {
      final response = await http.get(
        Uri.parse(
            '$baseUrl/friends/search?query=$query&user_id=$currentUserId'),
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
  Future<Map<String, dynamic>> acceptFriend(
      int friendshipId, int userId) async {
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
  Future<Map<String, dynamic>> rejectFriend(
      int friendshipId, int userId) async {
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
  Future<Map<String, dynamic>> removeFriend(
      int friendshipId, int userId) async {
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
  Future<Map<String, dynamic>> getCurrentWeather(
      double latitude, double longitude) async {
    try {
      final url =
          Uri.parse('$baseUrl/weather/current?lat=$latitude&lng=$longitude');

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        return {
          'success': payload['success'] == true,
          'data': payload['data'] ?? {},
        };
      } else {
        String message = 'Failed to fetch weather data';
        try {
          final payload = jsonDecode(response.body);
          if (payload is Map<String, dynamic>) {
            message =
                (payload['message'] ?? payload['error'] ?? message).toString();
          }
        } catch (_) {}

        return {
          'success': false,
          'message': message,
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
  Future<Map<String, dynamic>> getWeatherForecast(
      double latitude, double longitude) async {
    try {
      final url =
          Uri.parse('$baseUrl/weather/forecast?lat=$latitude&lng=$longitude');

      final response = await http.get(url, headers: {
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body);
        return {
          'success': payload['success'] == true,
          'data': payload['data'] ?? {},
        };
      } else {
        String message = 'Failed to fetch weather forecast';
        try {
          final payload = jsonDecode(response.body);
          if (payload is Map<String, dynamic>) {
            message =
                (payload['message'] ?? payload['error'] ?? message).toString();
          }
        } catch (_) {}

        return {
          'success': false,
          'message': message,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Send a panic/emergency request
  Future<Map<String, dynamic>> sendPanicRequest({
    required int userId,
    required int orderId,
    required double latitude,
    required double longitude,
    required String emergencyType,
    String? description,
  }) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/panic');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'order_id': orderId,
          'latitude': latitude,
          'longitude': longitude,
          'emergency_type': emergencyType,
          'description': description,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Gagal mengirim permintaan darurat',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Get panic request status by order ID
  Future<Map<String, dynamic>> getPanicStatus(int orderId) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/panic/order/$orderId');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mendapatkan status panic',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Cancel a panic request
  Future<Map<String, dynamic>> cancelPanicRequest(
      int panicId, int userId) async {
    try {
      final token = await getToken();
      final url = Uri.parse('$baseUrl/panic/$panicId/cancel');
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal membatalkan permintaan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // ============================================
  // CHATBOT METHODS
  // ============================================

  /// Send message to chatbot and get response
  Future<Map<String, dynamic>> sendChatMessage({
    required String message,
    List<Map<String, dynamic>>? history,
    String role = 'pendaki',
    int? userId,
    List<int>? selectedMemberIds,
    List<String>? selectedMemberNames,
  }) async {
    try {
      final url = Uri.parse('$chatbotBaseUrl/chat');
      final authToken = await getToken();

      Map<String, dynamic> body = {
        'message': message,
        'history': history ?? [],
        'role': role,
      };

      if (authToken != null && authToken.isNotEmpty) {
        body['auth_token'] = authToken;
      }

      if (userId != null) {
        body['user_id'] = userId;
      }

      if (selectedMemberIds != null && selectedMemberIds.isNotEmpty) {
        body['selected_member_ids'] = selectedMemberIds;
      }

      if (selectedMemberNames != null && selectedMemberNames.isNotEmpty) {
        body['selected_member_names'] = selectedMemberNames;
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null && authToken.isNotEmpty)
            'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? 'Tidak ada respons',
          'code': responseData['code'],
          'next_step': responseData['next_step'],
          'download_url': responseData['download_url'],
          'payment_url': responseData['payment_url'],
          'transaction_id': responseData['transaction_id'],
          'order_id': responseData['order_id'],
          'payment_method': responseData['payment_method'],
          'total_payment': responseData['total_payment'],
          'transaction_created_at': responseData['transaction_created_at'],
          'payment_code': responseData['payment_code'],
          'payment_code_label': responseData['payment_code_label'],
          'payment_instruction': responseData['payment_instruction'],
          'deeplink_url': responseData['deeplink_url'],
          'qr_code_url': responseData['qr_code_url'],
          'qr_string': responseData['qr_string'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Gagal mengirim pesan ke chatbot',
        };
      }
    } catch (e) {
      print('Chatbot Error: $e');
      return {
        'success': false,
        'message':
            'Tidak dapat terhubung ke chatbot. Pastikan server chatbot berjalan.',
      };
    }
  }

  /// Get chatbot info and available data
  Future<Map<String, dynamic>> getChatbotInfo() async {
    try {
      final url = Uri.parse('$chatbotBaseUrl/chat/info');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mendapatkan info chatbot',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke chatbot server',
      };
    }
  }

  /// Lookup user by exact ID for member selection validation.
  Future<Map<String, dynamic>> getUserById(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-data/$userId'),
        headers: {
          'Accept': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      }

      return {
        'success': false,
        'message': responseData['message'] ?? 'User tidak ditemukan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal memeriksa user ID',
      };
    }
  }

  // ==================== CHAT HISTORY API METHODS ====================

  /// Get list of chat histories for a user
  Future<Map<String, dynamic>> getChatHistories({
    required int userId,
    String role = 'pendaki',
  }) async {
    try {
      final url =
          Uri.parse('$chatbotBaseUrl/chat/history?user_id=$userId&role=$role');
      final response = await http.get(url);
      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Gagal memuat riwayat chat'};
    }
  }

  /// Get a specific chat history by ID
  Future<Map<String, dynamic>> getChatHistory(int historyId) async {
    try {
      final url = Uri.parse('$chatbotBaseUrl/chat/history/$historyId');
      final response = await http.get(url);
      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      return {'success': false, 'message': 'Gagal memuat riwayat chat'};
    }
  }

  /// Save or update chat history
  Future<Map<String, dynamic>> saveChatHistory({
    required int userId,
    required String role,
    required List<Map<String, dynamic>> messages,
    int? historyId,
    String? title,
  }) async {
    try {
      final url = Uri.parse('$chatbotBaseUrl/chat/history');
      final body = {
        'user_id': userId,
        'role': role,
        'messages': messages,
      };
      if (historyId != null) body['history_id'] = historyId;
      if (title != null) body['title'] = title;

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal menyimpan riwayat chat'};
    }
  }

  /// Delete a chat history
  Future<Map<String, dynamic>> deleteChatHistory(int historyId,
      {int? userId}) async {
    try {
      String urlStr = '$chatbotBaseUrl/chat/history/$historyId';
      if (userId != null) urlStr += '?user_id=$userId';
      final url = Uri.parse(urlStr);
      final response = await http.delete(url);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus riwayat chat'};
    }
  }

  /// Check chatbot server health
  Future<bool> isChatbotServerHealthy() async {
    try {
      final url = Uri.parse('$chatbotBaseUrl/health');
      final response = await http.get(url).timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('', 408),
          );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // ==================== MIDTRANS PAYMENT API METHODS ====================

  /// Get available Midtrans payment methods
  Future<Map<String, dynamic>> getMidtransPaymentMethods() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payment-methods'),
        headers: {
          'Accept': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Gagal memuat metode pembayaran',
        };
      }
    } catch (e) {
      print('Payment Methods Error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server',
      };
    }
  }

  /// Create Midtrans payment and get Snap token
  Future<Map<String, dynamic>> createMidtransPayment(
    int orderId, {
    String? paymentMethod,
    bool reuseIfPending = false,
  }) async {
    try {
      String? token = await getToken();

      Map<String, dynamic> requestBody = {
        'order_id': orderId,
      };

      if (paymentMethod != null) {
        requestBody['payment_method'] = paymentMethod;
      }

      if (reuseIfPending) {
        requestBody['reuse_if_pending'] = true;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/midtrans/create-payment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = responseData['data'] ?? responseData;
        return {
          'success': true,
          'snap_token': data['snap_token'],
          'redirect_url': data['redirect_url'],
          'order_id': data['order_id'] ?? orderId,
          'midtrans_order_id': data['midtrans_order_id'],
          'transaction_id': data['transaction_id'],
          'total_payment': data['total_payment'] ?? data['total_amount'],
          'payment_method': data['payment_method'],
          'payment_type': data['payment_type'],
          'transaction_created_at':
              data['transaction_created_at'] ?? data['transaction_time'],
          'payment_expires_at': data['payment_expires_at'],
          'payment_code': data['payment_code'],
          'payment_code_label': data['payment_code_label'],
          'payment_instruction': data['payment_instruction'],
          'deeplink_url': data['deeplink_url'],
          'qr_code_url': data['qr_code_url'],
          'qr_string': data['qr_string'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal membuat pembayaran',
        };
      }
    } catch (e) {
      print('Midtrans Payment Error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server pembayaran',
      };
    }
  }

  /// Get Midtrans configuration (client key and snap URL)
  Future<Map<String, dynamic>> getMidtransConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/midtrans/config'),
        headers: {
          'Accept': 'application/json',
        },
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'client_key': responseData['client_key'],
          'snap_url': responseData['snap_url'],
          'is_production': responseData['is_production'],
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal mendapatkan konfigurasi Midtrans',
        };
      }
    } catch (e) {
      print('Midtrans Config Error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server',
      };
    }
  }

  /// Check Midtrans payment status
  Future<Map<String, dynamic>> checkMidtransStatus(String orderId) async {
    try {
      String? token = await getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/midtrans/status/$orderId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(Duration(seconds: 15)); // Add timeout to prevent hanging

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Gagal mengecek status pembayaran',
        };
      }
    } catch (e) {
      print('Midtrans Status Error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server',
      };
    }
  }

  /// Poll payment status using order ID (or Midtrans order reference).
  Future<Map<String, dynamic>> getPaymentStatus(String orderId) async {
    try {
      String? token = await getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/payment/status/$orderId'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData,
        };
      }

      return {
        'success': false,
        'message':
            responseData['message'] ?? 'Gagal mengambil status pembayaran',
      };
    } catch (e) {
      print('Payment Status Error: $e');
      return {
        'success': false,
        'message': 'Tidak dapat terhubung ke server',
      };
    }
  }
}
