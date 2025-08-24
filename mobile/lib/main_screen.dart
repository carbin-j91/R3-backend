import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mobile/l10n/app_strings.dart';

// 필요한 모든 스크린들을 가져옵니다.
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/explore_screen.dart';
import 'package:mobile/screens/record_screen.dart';
import 'package:mobile/screens/album_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // final이 아닌 일반 변수로 변경하여 값을 바꿀 수 있게 합니다.
  int _selectedIndex = 0;

  // 하단 탭과 연결될 4개의 메인 화면 목록입니다.
  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    RecordScreen(),
    AlbumScreen(),
  ];

  // 탭을 눌렀을 때 _selectedIndex 값을 변경하여 화면을 전환하는 함수입니다.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        activeIcon: Icons.close,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        children: [
          _buildSpeedDialChild(
            icon: Icons.photo_camera,
            label: AppStrings.savePhoto,
            onTap: () {
              /* 사진저장 로직 */
            },
          ),
          _buildSpeedDialChild(
            icon: Icons.book,
            label: AppStrings.createJournal,
            onTap: () {
              /* 일지쓰기 로직 */
            },
          ),
          _buildSpeedDialChild(
            icon: Icons.edit,
            label: AppStrings.createPost,
            onTap: () {
              /* 글쓰기 로직 */
            },
          ),
          _buildSpeedDialChild(
            icon: Icons.directions_run,
            label: AppStrings.createRun,
            onTap: () {
              /* 러닝 로직 */
            },
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
              icon: Icons.home,
              label: AppStrings.tabHome,
              index: 0,
            ),
            _buildNavItem(
              icon: Icons.explore,
              label: AppStrings.tabExplore,
              index: 1,
            ),
            const SizedBox(width: 48), // 플로팅 버튼을 위한 중앙의 빈 공간
            _buildNavItem(
              icon: Icons.article_outlined,
              label: AppStrings.tabRecord,
              index: 2,
            ),
            _buildNavItem(
              icon: Icons.photo_album_outlined,
              label: AppStrings.tabAlbum,
              index: 3,
            ),
          ],
        ),
      ),
    );
  }

  // 하단 탭 아이템을 만드는 위젯
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: _selectedIndex == index ? Colors.blueAccent : Colors.grey,
        size: 28,
      ),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }

  // 스피드 다이얼 자식 버튼을 만드는 위젯
  SpeedDialChild _buildSpeedDialChild({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SpeedDialChild(
      child: Icon(icon),
      label: label,
      onTap: onTap,
      backgroundColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
    );
  }
}
