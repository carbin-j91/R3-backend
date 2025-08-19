import 'package:flutter/material.dart';
import 'package:mobile/login_screen.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/secure_storage_service.dart';

// StatefulWidget으로 변경하여 API 로딩 상태를 관리합니다.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Future<User>? 타입으로 변경하여 비동기 데이터를 다룹니다.
  Future<User>? _userProfileFuture;

  @override
  void initState() {
    super.initState();
    // 위젯이 생성될 때 '내 정보' API를 호출합니다.
    _userProfileFuture = ApiService.getUserProfile();
  }

  Future<void> _handleLogout(BuildContext context) async {
    await SecureStorageService().deleteToken();
    // context.mounted 체크를 추가하여 위젯이 여전히 화면에 있는지 확인합니다.
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
        title: const Text('R3 메인 화면'),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      // FutureBuilder를 사용하여 비동기 데이터의 상태에 따라 다른 화면을 보여줍니다.
      body: FutureBuilder<User>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          // 1. 로딩 중일 때
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 2. 에러가 발생했을 때
          if (snapshot.hasError) {
            return Center(child: Text('에러 발생: ${snapshot.error}'));
          }
          // 3. 데이터가 성공적으로 로드되었을 때
          if (snapshot.hasData) {
            final user = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${user.nickname ?? user.email.split('@')[0]}님, 환영합니다!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '이메일: ${user.email}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      '가입일: ${user.createdAt.toLocal()}',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            );
          }
          // 4. 데이터가 없을 때 (이 경우는 거의 발생하지 않음)
          return const Center(child: Text('사용자 정보를 불러올 수 없습니다.'));
        },
      ),
    );
  }
}
