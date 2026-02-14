import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'home_screen.dart';
import '../../book/views/library_screen.dart';
import '../../chat/views/intro_chat_screen.dart';
import '../../profile/views/mypage_screen.dart';

// 🌟 [1] Notifier 정의 (상태 관리 로직 클래스화)
class MainNavNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // 초기값 (홈 탭)
  }

  // 탭 변경 함수 (외부에서 호출)
  void changeIndex(int index) {
    state = index;
  }
}

// 🌟 [2] Provider 생성 (NotifierProvider 사용)
final mainNavProvider = NotifierProvider<MainNavNotifier, int>(() {
  return MainNavNotifier();
});

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 [3] 현재 선택된 인덱스 구독
    final currentIndex = ref.watch(mainNavProvider);

    // 화면 리스트
    final List<Widget> screens = const [
      HomeScreen(),
      LibraryScreen(),
      IntroChatScreen(),
      MyPageScreen(),
    ];

    // 🌟 [4] PopScope: 뒤로가기 버튼 제어
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          // 🌟 상태 변경 시 함수 호출 방식으로 변경
          ref.read(mainNavProvider.notifier).changeIndex(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,

          // 🌟 상태 변경 시 함수 호출 방식으로 변경
          onTap: (index) => ref.read(mainNavProvider.notifier).changeIndex(index),

          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSub,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: '서재',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: '채팅',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }
}