import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import 'home_screen.dart';
import '../../book/views/library_screen.dart';
import '../../chat/views/intro_chat_screen.dart';
import '../../profile/views/mypage_screen.dart';
import '../../../core/router/app_router.dart';

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

    // 🌟 화면 리스트
    // 기획안(홈 -> 채팅 -> [글쓰기] -> 서재 -> 마이) 순서에 맞춰 화면 배열 수정
    final List<Widget> screens = const [
      HomeScreen(),        // 0번: 홈
      IntroChatScreen(),   // 1번: 채팅
      LibraryScreen(),     // 2번: 서재
      MyPageScreen(),      // 3번: 마이페이지
    ];

    // 🌟 [4] PopScope: 뒤로가기 버튼 제어
    return PopScope(
      canPop: currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          ref.read(mainNavProvider.notifier).changeIndex(0);
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: currentIndex,
          children: screens,
        ),

        // 🌟 [추가 1] 기획안의 가운데 둥근 글쓰기 플로팅 버튼
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // 🌟 수정됨: writePost(글쓰기)가 아니라 postBoard(게시판)으로 이동!
            Navigator.pushNamed(context, AppRouter.postBoard);
          },
          backgroundColor: const Color(0xFF222222), // 다크 그레이/블랙 톤
          shape: const CircleBorder(), // 완벽한 원형
          elevation: 4,
          child: const Icon(Icons.edit, color: Colors.white), // 연필 아이콘
        ),

        // 플로팅 버튼을 하단 바 중앙에 걸치도록 위치 지정
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // 🌟 [추가 2] 가운데가 파인 디자인의 커스텀 BottomAppBar
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(), // 버튼 들어갈 자리 파이게 만들기
          notchMargin: 8.0, // 파이는 여백 크기
          color: Colors.white,
          elevation: 10,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 좌측 메뉴 2개 (홈, 채팅)
                _buildTabItem(
                  ref: ref,
                  index: 0,
                  currentIndex: currentIndex,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: '홈',
                ),
                _buildTabItem(
                  ref: ref,
                  index: 1,
                  currentIndex: currentIndex,
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: '채팅',
                ),

                // 중앙 플로팅 버튼을 위한 여백 공간
                const SizedBox(width: 48),

                // 우측 메뉴 2개 (서재, 마이)
                _buildTabItem(
                  ref: ref,
                  index: 2,
                  currentIndex: currentIndex,
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: '서재',
                ),
                _buildTabItem(
                  ref: ref,
                  index: 3,
                  currentIndex: currentIndex,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: '마이',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🌟 하단 탭 버튼 UI를 만들어주는 공통 헬퍼 위젯
  Widget _buildTabItem({
    required WidgetRef ref,
    required int index,
    required int currentIndex,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      highlightColor: Colors.transparent, // 클릭 시 번짐 효과 제거 (깔끔하게)
      splashColor: Colors.transparent,
      onTap: () => ref.read(mainNavProvider.notifier).changeIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.primary : AppColors.textSub,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.primary : AppColors.textSub,
            ),
          ),
        ],
      ),
    );
  }
}