import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  // 싱글톤 패턴: 앱 전체에서 단 하나의 인스턴스만 사용하도록 합니다.
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage();
  static const _keyAccessToken = 'r3_access_token';

  // 토큰 저장하기
  Future<void> saveToken(String token) async {
    await _storage.write(key: _keyAccessToken, value: token);
  }

  // 토큰 읽어오기
  Future<String?> readToken() async {
    return await _storage.read(key: _keyAccessToken);
  }

  // 토큰 삭제하기 (로그아웃 시 사용)
  Future<void> deleteToken() async {
    await _storage.delete(key: _keyAccessToken);
  }
}
