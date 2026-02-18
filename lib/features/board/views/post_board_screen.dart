import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/board_controller.dart';
import '../models/post_model.dart';
import 'write_post_screen.dart';
import 'package:bookit_app/shared/widgets/post_card.dart';

class PostBoardScreen extends ConsumerStatefulWidget {
  const PostBoardScreen({super.key});

  @override
  ConsumerState<PostBoardScreen> createState() => _PostBoardScreenState();
}

class _PostBoardScreenState extends ConsumerState<PostBoardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 각 탭에 해당하는 데이터 구독
    final recentPostsAsync = ref.watch(recentPostsProvider);
    final likedPostsAsync = ref.watch(likedPostsProvider);
    final myPostsAsync = ref.watch(myPostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.black, size: 24),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WritePostScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            height: 60,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFD45858),
              labelColor: const Color(0xFFD45858),
              unselectedLabelColor: Colors.black,
              tabs: const [
                Tab(text: "최근 소식"),
                Tab(text: "좋아요"),
                Tab(text: "나의 글"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(recentPostsAsync, "등록된 글이 없습니다."),
                _buildList(likedPostsAsync, "좋아요한 게시글이 없습니다."),
                _buildList(myPostsAsync, "작성한 게시글이 없습니다."),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 공통 리스트 빌더 (AsyncValue 처리)
  Widget _buildList(AsyncValue<List<PostModel>> asyncValue, String emptyMsg) {
    return asyncValue.when(
      data: (posts) {
        if (posts.isEmpty) return Center(child: Text(emptyMsg));
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) => PostCard(post: posts[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text("오류 발생: $err")),
    );
  }
}