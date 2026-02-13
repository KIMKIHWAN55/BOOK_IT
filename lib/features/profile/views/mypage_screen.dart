import 'package:bookit_app/features/profile/views/profile_edit_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookit_app/features/auth/views/login_screen.dart';
import 'package:bookit_app/features/admin/views/admin_book_list_screen.dart';
import 'package:bookit_app/features/admin/views/admin_add_book_screen.dart';
import 'package:bookit_app/features/profile/models/user_model.dart';
import 'package:bookit_app/features/profile/views/settings_screen.dart';
import 'liked_books_screen.dart'; // ★ 새로 만든 전체보기 화면 import

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> with SingleTickerProviderStateMixin {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;
  UserModel? _userModel;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdmin();
    _fetchUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 관리자 여부 확인
  Future<void> _checkAdmin() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists && doc.data() != null && doc.data()!['role'] == 'admin') {
        if (mounted) setState(() => _isAdmin = true);
      }
    }
  }

  // 사용자 정보 불러오기
  Future<void> _fetchUserData() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        if (mounted) {
          setState(() {
            _userModel = UserModel.fromFirestore(doc);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));

    // ★ 관리자(Admin) UI
    if (_isAdmin) return _buildAdminLayout();

    // ★ 일반 사용자(User) UI
    return _buildUserLayout();
  }

  // ============================================================
  //  1. 관리자(Admin) 레이아웃
  // ============================================================
  Widget _buildAdminLayout() {
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
                  _buildProfileImage(size: 50),
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
  Widget _buildUserLayout() {
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                        ).then((_) => _fetchUserData());
                      },
                      child: _buildInfoCard(
                        child: Row(
                          children: [
                            _buildProfileImage(size: 50),
                            const SizedBox(width: 14),
                            Text(
                              _userModel?.nickname ?? '사용자',
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
                            "안녕 나는 ${_userModel?.nickname ?? '사용자'}이야 반가워",
                            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF222222)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "# SF # 추리 #로맨스 장르 좋아해",
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
            _buildLikedBooksList(), // 책 목록 (수정됨)
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
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

  Widget _buildProfileImage({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        shape: BoxShape.circle,
        image: _userModel?.profileImage != null && _userModel!.profileImage!.isNotEmpty
            ? DecorationImage(image: NetworkImage(_userModel!.profileImage!), fit: BoxFit.cover)
            : null,
      ),
      child: _userModel?.profileImage == null || _userModel!.profileImage!.isEmpty
          ? Icon(Icons.person, size: size * 0.6, color: Colors.grey)
          : null,
    );
  }

  // ★ [수정] 좋아요한 책 리스트: 4개까지만 표시 + 더보기 버튼
  Widget _buildLikedBooksList() {
    return StreamBuilder<QuerySnapshot>(
      // 기존 코드의 컬렉션명(liked_books) 유지
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('liked_books')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("좋아요한 책이 없습니다.", style: TextStyle(color: Colors.grey)));
        }

        // 4개 초과 여부 확인
        final bool hasMore = docs.length > 4;
        final int displayCount = hasMore ? 4 : docs.length;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          // 아이템 개수: 4개 이하 + (더보기 버튼이 필요하면 1개 추가)
          itemCount: hasMore ? displayCount + 1 : displayCount,
          itemBuilder: (context, index) {
            // 더보기 버튼을 그릴 순서인지 확인 (마지막 항목)
            if (hasMore && index == displayCount) {
              return Container(
                margin: const EdgeInsets.only(top: 10),
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    // 전체보기 화면으로 이동
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

            // 일반 책 아이템 그리기
            var book = docs[index];
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
                    // 책 표지
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
                    // 책 정보
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
    );
  }

  Widget _buildLikedFeedsList() {
    return const Center(child: Text("좋아요한 피드 목록 준비 중", style: TextStyle(color: Colors.grey)));
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: _handleLogout,
      child: const Text("로그아웃", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
    );
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
    }
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