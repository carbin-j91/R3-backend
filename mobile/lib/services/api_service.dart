import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/models/user.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/models/post.dart';
import 'package:mobile/schemas/run_update_schema.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:mobile/models/stats.dart';

class ApiService {
  static const String _baseUrl = 'https://217a2560a337.ngrok-free.app';

  // --- 공통 헤더 ---
  static Future<Map<String, String>> _authHeaders({
    Map<String, String> extra = const {},
  }) async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');
    return {'Authorization': 'Bearer $token', ...extra};
  }

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
    final url = Uri.parse('$_baseUrl/api/v1/users/me');
    final response = await http.get(url, headers: await _authHeaders());
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
    final url = Uri.parse('$_baseUrl/api/v1/users/me');
    final Map<String, dynamic> body = {};
    if (nickname != null) body['nickname'] = nickname;
    if (height != null) body['height'] = height;
    if (weight != null) body['weight'] = weight;

    final response = await http.patch(
      url,
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      throw Exception('Failed to update profile');
    }
  }

  // --- 러닝 기록 관련 API ---

  static Future<Run> createRun({required bool isCourseCandidate}) async {
    final url = Uri.parse('$_baseUrl/api/v1/runs/');
    final response = await http.post(
      url,
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode({'is_course_candidate': isCourseCandidate}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Run.fromJson(data);
    } else {
      if (kDebugMode) {
        print('Failed to create run: ${response.body}');
      }
      throw Exception('Failed to create run');
    }
  }

  static Future<List<Run>> getRuns() async {
    final url = Uri.parse('$_baseUrl/api/v1/runs/');
    final response = await http.get(url, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Run.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load runs');
    }
  }

  static Future<Run> getRunDetail(String runId) async {
    final url = Uri.parse('$_baseUrl/api/v1/runs/$runId');
    final response = await http.get(url, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      // 서버가 chart_data/splits를 null로 줄 수도 있으니, 모델에서 방어하지만 여기서도 기본값 보강해 둡니다(무해).
      if (data is Map<String, dynamic>) {
        data.putIfAbsent('chart_data', () => data['chartData'] ?? []);
        data.putIfAbsent('splits', () => data['splits'] ?? []);
      }
      return Run.fromJson(data);
    } else {
      throw Exception('Failed to load run detail');
    }
  }

  static Future<Run> updateRun(String runId, RunUpdate runData) async {
    final url = Uri.parse('$_baseUrl/api/v1/runs/$runId');
    final response = await http.patch(
      url,
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
      body: jsonEncode(runData.toJson()),
    );

    if (response.statusCode == 200) {
      return Run.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    } else {
      if (kDebugMode) {
        print('Error Body: ${response.body}');
      }
      throw Exception('Failed to update run');
    }
  }

  static Future<void> deleteRun(String runId) async {
    final url = Uri.parse('$_baseUrl/api/v1/runs/$runId');
    final response = await http.delete(url, headers: await _authHeaders());
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
    final url = Uri.parse('$_baseUrl/api/v1/users/me/stats?period=$period');
    final response = await http.get(
      url,
      headers: await _authHeaders(extra: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return Stats.fromJson(data);
    } else {
      throw Exception('Failed to load stats');
    }
  }
}
