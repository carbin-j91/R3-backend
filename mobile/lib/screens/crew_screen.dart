import 'package:flutter/material.dart';

class CrewScreen extends StatelessWidget {
  const CrewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('크루')),
      body: const Center(child: Text('크루 화면입니다.')),
    );
  }
}
