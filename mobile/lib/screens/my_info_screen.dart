import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/models/user.dart'; // User 모델을 가져옵니다.
import 'package:mobile/screens/my_profile_screen.dart';
import 'package:mobile/services/api_service.dart'; // ApiService를 가져옵니다.
import 'package:mobile/services/secure_storage_service.dart';

// Drawer의 내용물이 동적으로 변해야 하므로 StatefulWidget으로 변경합니다.
class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  Future<User>? _userProfileFuture;

  @override
  void initState() {
    super.initState();
    // 서랍이 열릴 때마다 사용자 정보를 새로고침할 수 있도록 initState에서 호출
    _userProfileFuture = ApiService.getUserProfile();
  }

  Future<void> _handleLogout(BuildContext context) async {
    await SecureStorageService().deleteToken();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Drawer 위젯으로 전체를 감싸 서랍임을 명시합니다.
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero, // 상단 여백 제거
        children: [
          // 1. 사용자 프로필 정보를 보여주는 헤더
          FutureBuilder<User>(
            future: _userProfileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final user = snapshot.data!;
                return UserAccountsDrawerHeader(
                  accountName: Text(
                    user.nickname ?? 'Nickname',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  accountEmail: Text(user.email ?? 'email@example.com'),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.blueAccent,
                    ),
                  ),
                  decoration: const BoxDecoration(color: Colors.blueAccent),
                );
              }
              // 로딩 중이거나 에러 발생 시 기본 헤더 표시
              return const UserAccountsDrawerHeader(
                accountName: Text('Loading...'),
                accountEmail: Text(''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: CircularProgressIndicator(),
                ),
                decoration: BoxDecoration(color: Colors.blueAccent),
              );
            },
          ),

          // 2. 메뉴 목록
          _buildMenuTile(
            context,
            icon: Icons.person_outline,
            title: AppStrings.myProfile,
            onTap: () {
              Navigator.of(context).pop(); // 서랍을 먼저 닫습니다.
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
              /* TODO: 나의 글 페이지로 이동 */
            },
          ),
          const Divider(),
          _buildMenuTile(
            context,
            icon: Icons.logout,
            title: '로그아웃',
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}
