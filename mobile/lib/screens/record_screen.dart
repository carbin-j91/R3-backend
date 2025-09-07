import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/tabs/activity_tab.dart';
import 'package:mobile/tabs/run_diary_tab.dart';

class RecordScreen extends StatelessWidget {
  const RecordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // 2. AppStrings를 사용하여 탭바를 구성합니다.
              const TabBar(
                tabs: [
                  Tab(text: AppStrings.recordTabRunDiary),
                  Tab(text: AppStrings.recordTabActivity),
                  Tab(text: AppStrings.recordTabAchievements),
                  Tab(text: AppStrings.recordTabGoals),
                ],
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blueAccent,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    const RunDiaryTab(),
                    const ActivityTab(),
                    const Center(child: Text('달성기록 화면입니다 (향후 구현).')),
                    const Center(child: Text('목표 설정 화면입니다 (향후 구현).')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
