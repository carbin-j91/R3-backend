import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabAlbum)),
      body: const Center(child: Text('앨범 화면입니다.')),
    );
  }
}
