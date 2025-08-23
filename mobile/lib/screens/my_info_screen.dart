import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/screens/my_runs_screen.dart';
import 'package:mobile/screens/my_profile_screen.dart';

class MyInfoScreen extends StatelessWidget {
  const MyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabMyInfo)),
      // ----> body 부분을 아래와 같이 수정합니다. <----
      body: ListView(
        children: [
          _buildMenuTile(
            context,
            icon: Icons.person_outline,
            title: AppStrings.myProfile,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyProfileScreen(),
                ),
              );
            },
          ),
          // '러닝 기록'과 '내 앨범' 메뉴는 RecordScreen으로 이동했으므로 삭제합니다.
          _buildMenuTile(
            context,
            icon: Icons.article_outlined,
            title: AppStrings.myPosts,
            onTap: () {
              // TODO: 나의 글 페이지로 이동
            },
          ),
        ],
      ),
    );
  }

  // 메뉴 타일을 만드는 공통 위젯
  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
