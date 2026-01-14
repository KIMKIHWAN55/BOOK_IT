import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_add_book_screen.dart';
import 'login_screen.dart'; // 로그인 화면 import

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  // 🔹 관리자 여부 확인 (Firestore의 users 컬렉션에서 role 필드 확인)
  Future<void> _checkAdmin() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        // 'role' 필드가 'admin'이면 관리자로 간주
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        if (data['role'] == 'admin') {
          setState(() {
            isAdmin = true;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 정보"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if(!mounted) return;
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 프로필 섹션
            Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('assets/images/boogi_final.png'), // 기본 이미지
                  backgroundColor: Colors.grey,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.email ?? "게스트",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text("독서하기 좋은 날이네요! 📚", style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
            const SizedBox(height: 30),
            const Divider(),

            // 2. 일반 메뉴 (예시)
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text("찜한 목록"),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("대출 기록"),
              onTap: () {},
            ),

            // 3. 👑 관리자 전용 메뉴 (isAdmin이 true일 때만 보임)
            if (isAdmin) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text("관리자 메뉴", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ),
              ListTile(
                leading: const Icon(Icons.add_box, color: Colors.red),
                title: const Text("책 등록 & 상세정보 관리"),
                subtitle: const Text("새로운 도서를 등록합니다."),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminAddBookScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}