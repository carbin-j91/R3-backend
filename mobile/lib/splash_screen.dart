import 'package:flutter/material.dart';
import 'package:mobile/home_screen.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/services/secure_storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 위젯이 생성될 때 딱 한 번만 실행됩니다.
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    // 안전한 금고에서 토큰을 읽어옵니다.
    final token = await SecureStorageService().readToken();

    // 잠시 기다려서 로딩 화면을 보여주는 효과를 줍니다 (선택사항).
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      // 위젯이 화면에 아직 있는지 확인 (중요)
      if (token != null) {
        // 토큰이 있으면 HomeScreen으로 이동합니다.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // 토큰이 없으면 LoginScreen으로 이동합니다.
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중임을 나타내는 간단한 화면입니다.
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
