import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/board_controller.dart';
import '../models/post_model.dart';
import 'package:bookit_app/shared/widgets/post_card.dart';


import '../../../core/router/app_router.dart';

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
    final recentPostsAsync = ref.watch(recentPostsProvider);
    final likedPostsAsync = ref.watch(likedPostsProvider);
    final myPostsAsync = ref.watch(myPostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '게시판',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_square, color: Colors.black, size: 24),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.writePost);
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
                KeepAlivePostList(asyncPosts: recentPostsAsync, emptyMsg: "등록된 글이 없습니다."),
                KeepAlivePostList(asyncPosts: likedPostsAsync, emptyMsg: "좋아요한 게시글이 없습니다."),
                KeepAlivePostList(asyncPosts: myPostsAsync, emptyMsg: "작성한 게시글이 없습니다."),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class KeepAlivePostList extends StatefulWidget {
  final AsyncValue<List<PostModel>> asyncPosts;
  final String emptyMsg;

  const KeepAlivePostList({
    super.key,
    required this.asyncPosts,
    required this.emptyMsg,
  });

  @override
  State<KeepAlivePostList> createState() => _KeepAlivePostListState();
}

class _KeepAlivePostListState extends State<KeepAlivePostList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return widget.asyncPosts.when(
      data: (posts) {
        if (posts.isEmpty) return Center(child: Text(widget.emptyMsg));
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