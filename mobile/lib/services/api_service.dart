import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // kIsWeb을 사용하기 위해 필요합니다.

class ApiService {
  //  static const String _baseUrl = 'http://192.168.219.101:8000';
  static final String _baseUrl = kIsWeb
      ? 'http://localhost:8000' // 웹에서는 localhost
      : 'http://10.0.2.2:8000'; // 에뮬레이터에서는 10.0.2.2
  // 이메일/비밀번호 로그인 함수
  static Future<String> emailLogin(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/v1/token');

    // /token 엔드포인트는 JSON이 아닌 form 데이터를 기대합니다.
    final response = await http.post(
      url,
      headers: {
        // Content-Type을 반드시 'application/x-www-form-urlencoded'로 설정해야 합니다.
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      // body에는 Map 형태의 데이터를 전달합니다.
      body: {'username': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)); // 한글 깨짐 방지
      return data['access_token'];
    } else {
      // 백엔드가 보내주는 구체적인 에러 메시지를 사용합니다.
      final errorData = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(errorData['detail'] ?? 'Failed to login');
    }
  }
}
