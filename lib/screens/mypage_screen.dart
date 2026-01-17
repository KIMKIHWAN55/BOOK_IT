import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookit_app/screens/login_screen.dart';
import 'package:bookit_app/screens/admin_book_list_screen.dart';
import 'package:bookit_app/screens/admin_add_book_screen.dart';
import 'package:bookit_app/screens/profile_edit_screen.dart';
import 'package:bookit_app/models/user_model.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final User? _user = FirebaseAuth.instance.currentUser;
  bool _isAdmin = false;
  UserModel? _userModel;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
    _fetchUserData();
  }

  // 관리자 여부 확인
  Future<void> _checkAdmin() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists && doc.data()!['role'] == 'admin') {
        setState(() => _isAdmin = true);
      }
    }
  }

  // 사용자 정보 가져오기
  Future<void> _fetchUserData() async {
    if (_user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
      if (doc.exists) {
        setState(() {
          _userModel = UserModel.fromMap(doc.data()!);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로그인 안 된 상태 처리
    if (_user == null) {
      return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
    }

    // ★ 1. 관리자(Admin) 전용 화면
    if (_isAdmin) {
      return DefaultTabController(
        length: 2, // 탭 개수: 등록, 수정
        child: Scaffold(
          appBar: AppBar(
            title: const Text('관리자 페이지', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            actions: [
              // 로그아웃 버튼
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.grey),
                onPressed: _handleLogout,
              ),
            ],
            bottom: const TabBar(
              labelColor: Color(0xFFD45858),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFD45858),
              tabs: [
                Tab(text: "도서 등록"),
                Tab(text: "도서 수정/관리"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              // 탭 1: 도서 등록 화면
              AdminAddBookScreen(),
              // 탭 2: 도서 리스트 (수정/삭제) 화면
              AdminBookListScreen(),
            ],
          ),
        ),
      );
    }

    // ★ 2. 일반 사용자 화면 (기존 코드 유지 + 프로필 편집 기능)
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('내 정보', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // 프로필 영역 (일반 사용자만 보임)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                ).then((_) => _fetchUserData());
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _userModel?.profileImage != null && _userModel!.profileImage!.isNotEmpty
                        ? NetworkImage(_userModel!.profileImage!)
                        : null,
                    child: _userModel?.profileImage == null || _userModel!.profileImage!.isEmpty
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _userModel?.nickname ?? '사용자',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.edit, size: 16, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 탭 바 (좋아요 목록)
            const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFD45858),
              tabs: [
                Tab(text: "좋아요한 책"),
                Tab(text: "좋아요한 피드"),
              ],
            ),

            // 탭 내용
            Expanded(
              child: TabBarView(
                children: [
                  _buildLikedBooks(),
                  _buildLikedFeeds(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로그아웃 로직 분리
  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  // 좋아요한 책 리스트 (일반 사용자용)
  Widget _buildLikedBooks() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('liked_books')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("좋아요한 책이 없습니다.", style: TextStyle(color: Colors.grey)));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var book = snapshot.data!.docs[index];
            return Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book['imageUrl'] ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(book['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              ],
            );
          },
        );
      },
    );
  }

  // 좋아요한 피드 리스트 (일반 사용자용)
  Widget _buildLikedFeeds() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .collection('liked_feeds')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("좋아요한 피드가 없습니다.", style: TextStyle(color: Colors.grey)));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            var feed = snapshot.data!.docs[index];
            return ListTile(
              title: Text(feed['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(feed['bookTitle'] ?? ''),
              trailing: const Icon(Icons.favorite, color: Colors.red),
            );
          },
        );
      },
    );
  }
}