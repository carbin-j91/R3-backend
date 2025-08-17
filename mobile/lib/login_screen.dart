import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/services/api_service.dart'; // API 서비스 파일을 사용할 예정입니다.

// StatefulWidget으로 변경하여 입력값과 에러 메시지를 관리합니다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 입력 필드의 텍스트를 읽기 위한 컨트롤러
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  // 로그인 버튼을 눌렀을 때 실행될 함수
  Future<void> _handleEmailLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    // 간단한 유효성 검사
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = '이메일과 비밀번호를 모두 입력해주세요.';
      });
      return;
    }

    setState(() {
      _errorMessage = ''; // 이전 에러 메시지 초기화
    });

    try {
      // ApiService를 호출하여 로그인을 시도합니다.
      final token = await ApiService.emailLogin(email, password);

      print('============================================');
      print('R3 서버 토큰 발급 성공: $token');
      print('============================================');

      // TODO: 발급받은 토큰을 기기에 안전하게 저장하고 메인 화면으로 이동하기
    } catch (e) {
      print('로그인 실패: $e');
      setState(() {
        _errorMessage = '로그인에 실패했습니다. 계정 정보를 확인해주세요.';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                AppStrings.appName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                AppStrings.appSlogan,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // 이메일 입력 필드
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '이메일',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // 비밀번호 입력 필드
              TextField(
                controller: _passwordController,
                obscureText: true, // 비밀번호를 가려줍니다.
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // 에러 메시지 표시 영역
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),

              // 로그인 버튼
              ElevatedButton(
                onPressed: _handleEmailLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '로그인',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
