import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/screens/my_info_screen.dart';
import 'package:mobile/screens/map_screen.dart'; // 1. running_screen 대신 map_screen을 가져옵니다.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.appName),
          leading: IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyInfoScreen()),
              );
            },
          ),
          bottom: const TabBar(
            tabs: [
              Tab(text: AppStrings.homeTabMain),
              Tab(text: AppStrings.homeTabRanking),
              Tab(text: AppStrings.homeTabAds),
            ],
          ),
        ),
        body: const TabBarView(children: [MainTab(), RankingTab(), AdsTab()]),
      ),
    );
  }
}

// -- 각 탭의 내용을 구성하는 위젯들 --

class MainTab extends StatelessWidget {
  const MainTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions_run, size: 28),
              label: const Text(
                AppStrings.startRunning, // app_strings.dart에 정의된 텍스트 사용
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                // 2. 목적지를 RunningScreen 대신 MapScreen으로 변경합니다.
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
            ),
          ),
        ),
        const Expanded(child: Center(child: Text(AppStrings.noticeArea))),
      ],
    );
  }
}

class RankingTab extends StatelessWidget {
  const RankingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text(AppStrings.rankingArea));
  }
}

class AdsTab extends StatelessWidget {
  const AdsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text(AppStrings.adsArea));
  }
}
