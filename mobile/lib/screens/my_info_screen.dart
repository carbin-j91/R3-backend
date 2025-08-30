import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/login_screen.dart'; // 로그인 화면을 가져옵니다.
import 'package:mobile/screens/my_profile_screen.dart';
import 'package:mobile/services/secure_storage_service.dart'; // 보안 저장소 서비스를 가져옵니다.

class MyInfoScreen extends StatelessWidget {
  const MyInfoScreen({super.key});

  // 1. 로그아웃 버튼을 눌렀을 때 실행될 함수를 추가합니다.
  Future<void> _handleLogout(BuildContext context) async {
    // 안전한 금고에서 토큰을 삭제합니다.
    await SecureStorageService().deleteToken();

    // 로그인 화면으로 이동시키고, 이전의 모든 화면 기록을 삭제합니다.
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.tabMyInfo),
        // ----> 2. AppBar 오른쪽에 actions를 추가하여 로그아웃 버튼을 만듭니다. <----
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context), // 로그아웃 함수 호출
            tooltip: '로그아웃',
          ),
        ],
      ),
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
