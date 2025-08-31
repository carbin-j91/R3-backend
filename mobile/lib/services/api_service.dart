import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/models/user.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/models/post.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/services/secure_storage_service.dart';

class ApiService {
  static const String _baseUrl = 'https://327cd56ed4ac.ngrok-free.app';

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

  // ----> updateRun 함수를 이 하나의 버전으로 최종 통일합니다. <----
  static Future<Run> updateRun(String runId, RunUpdate runData) async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');

    final url = Uri.parse('$_baseUrl/api/v1/runs/$runId');
    final payload = runData.toJson();

    debugPrint('[RUN PATCH] /runs/$runId');
    debugPrint('[RUN PATCH PAYLOAD] ${jsonEncode(payload)}');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    debugPrint('[RUN PATCH RES] code=${response.statusCode}');
    debugPrint('[RUN PATCH RES BODY] ${response.body}');

    if (response.statusCode == 200) {
      return Run.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update run: ${response.statusCode}');
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
}
