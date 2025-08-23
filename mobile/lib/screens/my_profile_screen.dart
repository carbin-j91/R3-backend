import 'package:flutter/material.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/l10n/app_strings.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  Future<User>? _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _userProfileFuture = ApiService.getUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 2. 모든 하드코딩된 텍스트를 AppStrings로 교체합니다.
        title: const Text(AppStrings.profileTitle),
      ),
      body: FutureBuilder<User>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('정보를 불러오는 데 실패했습니다: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            final user = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.profileInfo,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 32),
                  _buildProfileInfoRow(
                    AppStrings.profileNickname,
                    user.nickname ?? AppStrings.profileNotSet,
                  ),
                  const SizedBox(height: 16),
                  _buildProfileInfoRow(AppStrings.profileEmail, user.email),
                  const SizedBox(height: 16),
                  _buildProfileInfoRow(
                    AppStrings.profileJoinDate,
                    user.createdAt.toLocal().toString().substring(0, 10),
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('사용자 정보를 찾을 수 없습니다.'));
        },
      ),
    );
  }

  Widget _buildProfileInfoRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18)),
      ],
    );
  }
}
