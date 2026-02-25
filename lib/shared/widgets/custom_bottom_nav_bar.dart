import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../features/home/views/main_screen.dart';

class CustomBottomNavBar extends ConsumerWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavProvider);

    return BottomAppBar(
      color: Colors.white,
      elevation: 10,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 홈
            _buildTabItem(
              ref: ref,
              index: 0,
              currentIndex: currentIndex,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: '홈',
            ),

            // 채팅
            _buildTabItem(
              ref: ref,
              index: 1,
              currentIndex: currentIndex,
              icon: Icons.chat_bubble_outline,
              activeIcon: Icons.chat_bubble,
              label: '채팅',
            ),

            InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                Navigator.pushNamed(context, AppRouter.postBoard);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.edit_outlined,
                    color: AppColors.textSub,
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '게시판',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),

            // 서재
            _buildTabItem(
              ref: ref,
              index: 2,
              currentIndex: currentIndex,
              icon: Icons.menu_book_outlined,
              activeIcon: Icons.menu_book,
              label: '서재',
            ),

            //마이페이지
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
    );
  }

  // 하단 탭 버튼
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