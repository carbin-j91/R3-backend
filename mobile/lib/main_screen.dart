import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/screens/home_screen.dart';
import 'package:mobile/screens/explore_screen.dart';
import 'package:mobile/screens/record_screen.dart';
import 'package:mobile/screens/album_screen.dart';
import 'package:mobile/screens/map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _animationController;

  final iconList = <IconData>[
    Icons.home,
    Icons.explore,
    Icons.article_outlined,
    Icons.photo_album_outlined,
  ];

  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const ExploreScreen(),
    const RecordScreen(),
    const AlbumScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      // ----> 1. 애니메이션 초기값을 1.0(최대 크기)으로 설정합니다. <----
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    // 탭을 누를 때마다 아이콘이 살짝 커졌다가 돌아오는 효과
    _animationController.reverse().then((_) => _animationController.forward());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // body가 bottomNavigationBar 뒤로 확장되도록 함
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      // ----> 2. Stack을 사용하여 하단 바 위에 플로팅 버튼을 직접 배치합니다. <----
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 하단 바 배경
          BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _buildNavItem(icon: iconList[0], index: 0),
                _buildNavItem(icon: iconList[1], index: 1),
                const SizedBox(width: 60), // 중앙 버튼을 위한 공간
                _buildNavItem(icon: iconList[2], index: 2),
                _buildNavItem(icon: iconList[3], index: 3),
              ],
            ),
          ),
          // 중앙 퀵 스타트 버튼
          Positioned(
            // 3. 버튼의 높이를 하단 바와 거의 일치하도록 미세 조정합니다.
            right:
                MediaQuery.of(context).size.width / 2 -
                (60 / 2) -
                7, //예시: 중앙에서 10픽셀 우측으로 이동 (화면 너비 / 2) - (버튼 너비 / 2) + 이동량
            bottom: MediaQuery.of(context).padding.bottom + 15,
            child: _buildSpeedDial(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required int index}) {
    // 탭 라벨 목록
    const labels = [
      AppStrings.tabHome,
      AppStrings.tabExplore,
      AppStrings.tabRecord,
      AppStrings.tabAlbum,
    ];
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.1).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Curves.easeOut,
                ),
              ),
              child: Icon(
                icon,
                color: _selectedIndex == index
                    ? Colors.blueAccent
                    : Colors.grey,
                size: 28,
              ),
            ),
            Text(
              labels[index],
              style: TextStyle(
                color: _selectedIndex == index
                    ? Colors.blueAccent
                    : Colors.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedDial() {
    return SpeedDial(
      // ----> 2. 이 부분을 수정하여 버튼을 하단 바와 통합합니다. <----

      // 배경색과 그림자를 제거하여 떠 있는 느낌을 없앱니다.
      backgroundColor: Colors.transparent,
      elevation: 0,

      // 렌더링 박스를 제거하여 다른 위젯처럼 보이게 합니다.
      renderOverlay: false,

      // 아이콘과 이미지
      buttonSize: const Size(60.0, 60.0),
      activeChild: const Icon(Icons.close),

      // 펼쳐지는 하위 메뉴들 (이전과 동일)
      childrenButtonSize: const Size(60.0, 60.0),
      spacing: 12,
      children: [
        _buildSpeedDialChild(
          icon: Icons.edit,
          label: AppStrings.quickStartWritePost,
          onTap: () {
            /* TODO: 글쓰기 화면으로 이동 */
          },
        ),
        _buildSpeedDialChild(
          icon: Icons.book,
          label: AppStrings.quickStartWriteJournal,
          onTap: () {
            /* TODO: 일지쓰기 화면으로 이동 */
          },
        ),
        _buildSpeedDialChild(
          icon: Icons.photo_camera,
          label: AppStrings.quickStartSavePhoto,
          onTap: () {
            /* TODO: 사진저장 화면으로 이동 */
          },
        ),
        _buildSpeedDialChild(
          icon: Icons.directions_run,
          label: AppStrings.quickStartRun,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (context) => const MapScreen()));
          },
        ),
      ], // 버튼 크기
      child: ClipOval(
        child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
      ),
    );
  }

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
