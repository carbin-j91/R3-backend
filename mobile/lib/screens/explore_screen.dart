import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold > DefaultTabController 순서로 감싸서 앱바 없는 탭바를 구현합니다.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        // AppBar를 제거하고, body에서부터 시작합니다.
        body: SafeArea(
          child: Column(
            children: [
              // 1. 커스텀 탭바
              const TabBar(
                tabs: [
                  Tab(text: AppStrings.exploreTabCourses),
                  Tab(text: AppStrings.exploreTabHotplace),
                  Tab(text: AppStrings.exploreTabTips),
                ],
                labelColor: Colors.blueAccent,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blueAccent,
              ),
              // 2. 탭바 아래의 내용
              Expanded(
                child: TabBarView(
                  children: [
                    // '도전 코스' 탭 (임시)
                    Center(child: Text('사용자들이 만든 코스 목록이 표시될 화면입니다.')),
                    // '러닝 핫플' 탭 (임시)
                    Center(child: Text('러닝하기 좋은 장소 추천 글이 표시될 화면입니다.')),
                    // '러닝 팁' 탭 (임시)
                    Center(child: Text('러닝 팁 관련 글이 표시될 화면입니다.')),
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
