// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:bookit_app/screens/home_screen.dart';
import 'package:bookit_app/features/chat/views/intro_chat_screen.dart';
import 'package:bookit_app/features/board/views/post_board_screen.dart';
import 'package:bookit_app/features/book/views/library_screen.dart';
import 'package:bookit_app/features/profile/views/mypage_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // 탭별 화면 리스트
  final List<Widget> _pages = [
    const HomeScreen(),        // 0: 홈
    const IntroChatScreen(),   // 1: 검색(부기 인트로)
    const PostBoardScreen(),   // 2: 글쓰기(게시판)
    const LibraryScreen(),     // 3: 서재
    const MyPageScreen(),      // 4: 내정보 (관리자 메뉴 포함)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack을 사용하면 탭 이동 시 기존 화면의 상태가 유지됩니다.
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFFB8B8B8),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_outlined), label: '글쓰기'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: '서재'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '내정보'),
        ],
      ),
    );
  }
}