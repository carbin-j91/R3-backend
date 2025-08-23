import 'package:flutter/material.dart';
import 'package:mobile/main_screen.dart'; // HomeScreen import는 삭제해도 됩니다.
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
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    final token = await SecureStorageService().readToken();
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      if (token != null) {
        // ----> 목적지를 MainScreen으로 수정! <----
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
