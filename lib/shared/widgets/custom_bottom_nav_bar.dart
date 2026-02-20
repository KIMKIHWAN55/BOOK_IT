import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart'; // 🌟 이동을 위해 추가
import '../../features/home/views/main_screen.dart';

class CustomBottomNavBar extends ConsumerWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavProvider);

    return BottomAppBar(
      // 🌟 가운데 파이는 효과(Notch) 삭제
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround, // 5개를 일정한 간격으로 배치
          children: [
            // 1. 홈
            _buildTabItem(
              ref: ref,
              index: 0,
              currentIndex: currentIndex,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: '홈',
            ),

            // 2. 채팅
            _buildTabItem(
              ref: ref,
              index: 1,
              currentIndex: currentIndex,
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: '채팅',
            ),

            // 🌟 3. 중앙 글쓰기 버튼 (일반 탭과 동일한 디자인 적용)
            InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                // 탭이 바뀌는 게 아니라 게시판(글쓰기) 화면으로 Push 됨
                Navigator.pushNamed(context, AppRouter.postBoard);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_outlined, // CSS와 어울리는 연필 아이콘
                    color: AppColors.textSub, // 기본 회색 유지
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '게시판', // 또는 '글쓰기'
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),

            // 4. 서재
            _buildTabItem(
              ref: ref,
              index: 2, // 탭 인덱스는 기존과 동일하게 2번 유지 (서재 화면)
              currentIndex: currentIndex,
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book,
              label: '서재',
            ),

            // 5. 마이페이지
            _buildTabItem(
              ref: ref,
              index: 3, // 탭 인덱스는 기존과 동일하게 3번 유지 (마이페이지)
              currentIndex: currentIndex,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: '마이',
            ),
          ],
        ),
      ),
    );
  }

  // 🌟 하단 탭 버튼 UI 공통 함수
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
      highlightColor: Colors.transparent,
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