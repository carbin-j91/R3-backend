import 'package:flutter/material.dart';

class AppIconButton extends StatelessWidget {
  final double size; // 아이콘 크기를 조절할 수 있도록

  const AppIconButton({super.key, this.size = 40.0}); // 기본 크기 40

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/app_icon.png', // 앱 아이콘 이미지 경로
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
