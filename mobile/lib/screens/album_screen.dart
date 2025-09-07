import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_strings.dart';
import 'package:mobile/screens/album/album_composer_screen.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final List<_LocalAlbumItem> _items = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.tabAlbum)),
      floatingActionButton: FloatingActionButton(
        onPressed: _openComposer,
        child: const Icon(Icons.add),
      ),
      body: _items.isEmpty
          ? const _EmptyAlbum()
          : Padding(
              padding: const EdgeInsets.all(8),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return GestureDetector(
                    onTap: () => _openPreview(item),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(item.localPath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _openComposer() async {
    // ⬇️ 결과를 String(저장된 PNG 경로)으로 받도록 간단화
    final resultPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const AlbumComposerScreen()),
    );
    if (resultPath != null && mounted) {
      setState(() {
        _items.insert(0, _LocalAlbumItem(localPath: resultPath));
      });
    }
  }

  void _openPreview(_LocalAlbumItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: InteractiveViewer(
            child: Image.file(File(item.localPath), fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _EmptyAlbum extends StatelessWidget {
  const _EmptyAlbum();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '아직 앨범 이미지가 없습니다.\n오른쪽 아래 + 버튼으로 만들어보세요!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }
}

class _LocalAlbumItem {
  final String localPath; // composed image path (PNG)
  _LocalAlbumItem({required this.localPath});
}

/// Composer가 반환할 결과(로컬 파일 경로 등)
class _ComposerResult {
  final String composedImagePath;
  const _ComposerResult(this.composedImagePath);
}
