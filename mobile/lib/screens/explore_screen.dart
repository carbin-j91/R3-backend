import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/post.dart'; // Post 모델을 곧 만들 예정입니다.
import 'package:mobile/services/api_service.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  Future<List<Post>>? _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = ApiService.getPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = ApiService.getPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('탐색')),
      body: FutureBuilder<List<Post>>(
        future: _postsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('게시글을 불러오는데 실패했습니다: ${snapshot.error}'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _refreshPosts,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }
          if (snapshot.hasData) {
            final posts = snapshot.data!;
            if (posts.isEmpty) {
              return const Center(
                child: Text(
                  '아직 게시글이 없습니다.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostListItem(post: posts[index]);
              },
            );
          }
          return const Center(child: Text('게시글을 불러올 수 없습니다.'));
        },
      ),
    );
  }
}

// 하나의 게시글을 목록에 표시하는 위젯
class PostListItem extends StatelessWidget {
  final Post post;
  const PostListItem({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          post.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '작성자: ${post.author?.nickname ?? '알 수 없음'}\n작성일: ${DateFormat('yyyy-MM-dd').format(post.createdAt.toLocal())}',
        ),
        onTap: () {
          // TODO: 게시글 상세 페이지로 이동
        },
      ),
    );
  }
}
