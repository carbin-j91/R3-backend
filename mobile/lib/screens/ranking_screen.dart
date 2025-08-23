import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('랭킹')),
      body: const Center(child: Text('랭킹 화면입니다.')),
    );
  }
}
