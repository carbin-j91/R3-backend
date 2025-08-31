import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/models/user.dart'; // 1. User 모델을 가져옵니다.
import 'package:mobile/services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final User user; // 2. 이제 String이 아닌 User 객체 전체를 받습니다.

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // 3. 키와 몸무게를 위한 컨트롤러를 추가합니다.
  late final TextEditingController _nicknameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.user.nickname);
    _heightController = TextEditingController(
      text: widget.user.height?.toString(),
    );
    _weightController = TextEditingController(
      text: widget.user.weight?.toString(),
    );
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 4. ApiService에 모든 데이터를 전달합니다.
      await ApiService.updateUserProfile(
        nickname: _nicknameController.text,
        height: double.tryParse(_heightController.text),
        weight: double.tryParse(_weightController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profileUpdateSuccess)),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profileUpdateFailed)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfileTitle)),
      body: SingleChildScrollView(
        // 키보드가 올라올 때 화면이 깨지지 않도록
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: AppStrings.profileNickname,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // 5. 키, 몸무게 입력 필드를 추가합니다.
            TextField(
              controller: _heightController,
              decoration: const InputDecoration(
                labelText: AppStrings.profileHeight,
                hintText: AppStrings.heightHint,
                border: OutlineInputBorder(),
                suffixText: 'cm',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(
                labelText: AppStrings.profileWeight,
                hintText: AppStrings.weightHint,
                border: OutlineInputBorder(),
                suffixText: 'kg',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text(AppStrings.saveChanges),
                  ),
          ],
        ),
      ),
    );
  }
}
