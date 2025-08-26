import 'dart:convert'; // 1. 'package:json' 대신 'dart:convert'를 가져옵니다.
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/services/api_service.dart'; // 2. ApiService를 가져옵니다.

class EditProfileScreen extends StatefulWidget {
  final String currentNickname;

  const EditProfileScreen({super.key, required this.currentNickname});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nicknameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.currentNickname);
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nicknameController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ApiService.updateUserProfile(_nicknameController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.profileUpdateSuccess)),
        );
        // 성공 시 이전 화면으로 돌아가면서 true 값을 전달
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: AppStrings.profileNickname,
                hintText: AppStrings.nicknameHint,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
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
