import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/models/user.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/models/post.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:mobile/models/stats.dart';
import 'package:mobile/models/stats.dart';

class ApiService {
  static const String _baseUrl = 'https://cea149b2cf0d.ngrok-free.app';

  // --- 사용자 관련 API ---

  static Future<String> emailLogin(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/v1/token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes))['access_token'];
    } else {
      throw Exception(
        jsonDecode(utf8.decode(response.bodyBytes))['detail'] ??
            'Failed to login',
      );
    }
  }

  static Future<User> getUserProfile() async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');
    final url = Uri.parse('$_baseUrl/api/v1/users/me');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  static Future<User> updateUserProfile({
    String? nickname,
    double? height,
    double? weight,
  }) async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');
    final url = Uri.parse('$_baseUrl/api/v1/users/me');
    final Map<String, dynamic> body = {};
    if (nickname != null) body['nickname'] = nickname;
    if (height != null) body['height'] = height;
    if (weight != null) body['weight'] = weight;
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // --- 러닝 기록 관련 API ---

  static Future<Run> createRun() async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');
    final url = Uri.parse('$_baseUrl/api/v1/runs/');
    final response = await http.post(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Run.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to create run');
    }
  }

  static Future<List<Run>> getRuns() async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');
    final url = Uri.parse('$_baseUrl/api/v1/runs/');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Run.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load runs');
    }
  }

  static Future<Run> getRunDetail(String runId) async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');
    final url = Uri.parse('$_baseUrl/api/v1/runs/$runId');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Run.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to load run detail');
    }
  }

  static Future<Run> updateRun(String runId, RunUpdate runData) async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');

    final url = Uri.parse('$_baseUrl/api/v1/runs/$runId');
    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(runData.toJson()),
    );

    if (response.statusCode == 200) {
      return Run.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      print('Error Body: ${response.body}');
      throw Exception('Failed to update run');
    }
  }

  static Future<void> deleteRun(String runId) async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');
    final url = Uri.parse('$_baseUrl/api/v1/runs/$runId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete run');
    }
  }

  // --- 게시글 관련 API ---

  Future<List<Post>> getPosts() async {
    final url = Uri.parse('$_baseUrl/api/v1/posts/');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }

  static Future<Stats> getUserStats(String period) async {
    final token = await SecureStorageService().readToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    // URL에 쿼리 파라미터로 period를 추가합니다.
    final url = Uri.parse('$_baseUrl/api/v1/users/me/stats?period=$period');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Stats.fromJson(data);
    } else {
      throw Exception('Failed to load stats');
    }
  }
}
