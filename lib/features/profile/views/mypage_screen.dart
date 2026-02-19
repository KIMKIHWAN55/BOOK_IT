import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/views/login_screen.dart';
import '../../admin/views/admin_book_list_screen.dart';
import '../../admin/views/admin_add_book_screen.dart';
import '../models/user_model.dart';
import '../controllers/profile_controller.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';
import 'liked_books_screen.dart';
import '../../board/controllers/board_controller.dart';
import 'package:bookit_app/shared/widgets/post_card.dart';

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

// 탭 컨트롤러를 유지해야 하므로 ConsumerStatefulWidget 사용
class _MyPageScreenState extends ConsumerState<MyPageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 로그아웃 처리
  Future<void> _handleLogout() async {
    await ref.read(profileActionControllerProvider).logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 실시간 유저 정보 구독 (Riverpod)
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (userModel) {
        if (userModel == null) {
          return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
        }

        // 관리자 권한 확인
        final bool isAdmin = userModel.role == 'admin';

        if (isAdmin) {
          return _buildAdminLayout(userModel);
        }
        return _buildUserLayout(userModel);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text("사용자 정보를 불러오지 못했습니다.\n$e"))),
    );
  }

  // ============================================================
  //  1. 관리자(Admin) 레이아웃
  // ============================================================
  Widget _buildAdminLayout(UserModel userModel) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: _buildAppBar(title: "관리자 페이지"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildInfoCard(
              child: Row(
                children: [
                  _buildProfileImage(userModel, size: 50),
                  const SizedBox(width: 14),
                  const Text(
                    '관리자',
                    style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddBookScreen())),
              child: _buildInfoCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('도서 등록', style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                    Icon(Icons.chevron_right, size: 24, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookListScreen())),
              child: _buildInfoCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('도서 수정', style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                    Icon(Icons.chevron_right, size: 24, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  2. 일반 사용자(User) 레이아웃
  // ============================================================
  Widget _buildUserLayout(UserModel userModel) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: _buildAppBar(title: "내 정보"),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        // 수정 페이지에서 돌아와도 StreamProvider가 자동으로 최신화해 줌
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                        );
                      },
                      child: _buildInfoCard(
                        child: Row(
                          children: [
                            _buildProfileImage(userModel, size: 50),
                            const SizedBox(width: 14),
                            Text(
                              userModel.nickname,
                              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222)),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "안녕 나는 ${userModel.nickname}이야 반가워",
                            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF222222)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "# SF # 추리 # 로맨스 장르 좋아해",
                            style: TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF196DF8)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF000000),
                  unselectedLabelColor: const Color(0xFF767676),
                  indicatorColor: const Color(0xFFED7777),
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: "좋아요한 책"),
                    Tab(text: "좋아요한 피드"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLikedBooksList(), // 좋아요한 책 스트림 위젯
            _buildLikedFeedsList(), // 피드 목록
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar({required String title}) {
    return AppBar(
      backgroundColor: const Color(0xFFF1F1F5),
      elevation: 0,
      centerTitle: true,
      title: Text(title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 17)),
      leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
      actions: [
        IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.black),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(1, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfileImage(UserModel userModel, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        shape: BoxShape.circle,
        image: userModel.profileImage != null && userModel.profileImage!.isNotEmpty
            ? DecorationImage(image: NetworkImage(userModel.profileImage!), fit: BoxFit.cover)
            : null,
      ),
      child: userModel.profileImage == null || userModel.profileImage!.isEmpty
          ? Icon(Icons.person, size: size * 0.6, color: Colors.grey)
          : null,
    );
  }

  // 🌟 [수정] 좋아요한 책 리스트: Riverpod 구독
  Widget _buildLikedBooksList() {
    final likedBooksAsync = ref.watch(likedBooksProvider);

    return likedBooksAsync.when(
      data: (snapshot) {
        final docs = snapshot.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("좋아요한 책이 없습니다.", style: TextStyle(color: Colors.grey)));
        }

        final bool hasMore = docs.length > 4;
        final int displayCount = hasMore ? 4 : docs.length;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: hasMore ? displayCount + 1 : displayCount,
          itemBuilder: (context, index) {
            // 더보기 버튼
            if (hasMore && index == displayCount) {
              return Container(
                margin: const EdgeInsets.only(top: 10),
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LikedBooksScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("더보기", style: TextStyle(color: Color(0xFF767676), fontSize: 14)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF767676)),
                    ],
                  ),
                ),
              );
            }

            // 책 아이템
            var book = docs[index].data() as Map<String, dynamic>;
            return Container(
              height: 136,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: const Color(0xFFD1D1D1).withOpacity(0.5), width: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(
                  children: [
                    Container(
                      width: 73,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.grey[200],
                        image: DecorationImage(
                          image: NetworkImage(book['imageUrl'] ?? ''),
                          fit: BoxFit.cover,
                          onError: (e, s) {},
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            book['title'] ?? '제목 없음',
                            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.5),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book['author'] ?? '저자 미상',
                            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFF777777), letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: const [
                              Icon(Icons.star, size: 14, color: Color(0xFFFBBC05)),
                              SizedBox(width: 2),
                              Text("4.7", style: TextStyle(fontFamily: 'Pretendard', fontSize: 12, fontWeight: FontWeight.w400)),
                              SizedBox(width: 4),
                              Text("(13)", style: TextStyle(fontFamily: 'Pretendard', fontSize: 12, color: Color(0xFF777777))),
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text("데이터를 불러오는 중 오류가 발생했습니다.")),
    );
  }

  Widget _buildLikedFeedsList() {
    final likedPostsAsync = ref.watch(likedPostsProvider);

    return likedPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Text("좋아요한 피드가 없습니다.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.separated(
          // 카드 주변 간격 여백 설정
          padding: const EdgeInsets.only(top: 16, bottom: 20, left: 16, right: 16),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            // 게시판에서 쓰던 디자인(PostCard) 그대로 렌더링
            return PostCard(post: posts[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("오류가 발생했습니다.\n$e")),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: _handleLogout,
      child: const Text("로그아웃", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF1F1F5),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}