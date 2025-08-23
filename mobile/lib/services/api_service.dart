import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// 필요한 모든 모델들을 가져옵니다.
import 'package:mobile/models/user.dart';
import 'package:mobile/models/run.dart';
import 'package:mobile/models/post.dart';

import 'package:mobile/services/secure_storage_service.dart';

class ApiService {
  static final String _baseUrl = kIsWeb
      ? 'http://localhost:8000'
      : 'http://10.0.2.2:8000'; // 실제 기기 테스트 시에는 컴퓨터의 로컬 IP로 변경해야 합니다.

  // 이메일/비밀번호 로그인 함수
  static Future<String> emailLogin(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/v1/token');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['access_token'];
    } else {
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Failed to login');
    }
  }

  // 내 정보 조회 함수
  static Future<User> getUserProfile() async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');

    final url = Uri.parse('$_baseUrl/api/v1/users/me');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // 러닝 기록 목록 조회 함수
  static Future<List<Run>> getRuns() async {
    final token = await SecureStorageService().readToken();
    if (token == null) throw Exception('Token not found');

    final url = Uri.parse('$_baseUrl/api/v1/runs/');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Run.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load runs');
    }
  }

  // 게시글 목록 조회 함수 (딱 한 번만 정의됩니다)
  static Future<List<Post>> getPosts() async {
    final url = Uri.parse('$_baseUrl/api/v1/posts/');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Post.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load posts');
    }
  }
}
