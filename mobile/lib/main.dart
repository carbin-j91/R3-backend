import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'; // 카카오 SDK 임포트
import 'package:mobile/splash_screen.dart'; // 우리가 만든 로그인 화면을 가져옵니다.
import 'package:flutter_naver_map/flutter_naver_map.dart';

void main() async {
  // runApp()을 실행하기 전에 네이티브 코드를 초기화하기 위한 설정입니다.
  WidgetsFlutterBinding.ensureInitialized();

  // ----> 네이버 지도 SDK를 초기화합니다. <----
  await FlutterNaverMap().init(
    clientId: 'gx7qhot05b',
    onAuthFailed: (ex) {
      print("********* 네이버맵 인증오류 : $ex *********");
    },
  );

  KakaoSdk.init(nativeAppKey: '여기에 카카오 네이티브 앱 키를 붙여넣으세요');

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
