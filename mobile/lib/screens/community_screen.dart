// screens/community_screen.dart

import 'package:flutter/material.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 탭의 개수
      child: Scaffold(
        // 1. appBar 프로퍼티를 제거합니다.
        // appBar: AppBar(...),

        // 2. body를 Column으로 변경하여 UI를 수직으로 배치합니다.
        body: Column(
          children: [
            // 3. SafeArea를 사용하여 상단 노치 영역을 피합니다.
            SafeArea(
              child: TabBar(
                tabs: [
                  Tab(text: '자유게시판'),
                  Tab(text: '크루원게시판'),
                  Tab(text: '나만의게시판'),
                ],
                // 기본 꾸밈 속성 추가 (선택 사항)
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
              ),
            ),
            // 4. Expanded를 사용하여 TabBarView가 남은 공간을 모두 차지하게 합니다.
            const Expanded(
              child: TabBarView(
                children: [
                  Center(child: Text('자유게시판 피드')),
                  Center(child: Text('크루원게시판 피드')),
                  Center(child: Text('나만의게시판 피드')),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            /* TODO: 글쓰기 화면으로 이동 */
          },
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}
