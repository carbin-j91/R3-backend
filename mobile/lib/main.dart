import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 카카오 SDK 임포트
import 'package:mobile/splash_screen.dart'; // 우리가 만든 로그인 화면을 가져옵니다.

void main() {
  // main 함수 시작 전에 카카오 SDK를 초기화합니다.
  KakaoSdk.init(nativeAppKey: '{30ec72a3186ed5a187a10dc4810acb03}');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'R3 App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      debugShowCheckedModeBanner: false,
      // 앱의 첫 화면을 LoginScreen으로 지정합니다.
      home: const SplashScreen(),
    );
  }
}
