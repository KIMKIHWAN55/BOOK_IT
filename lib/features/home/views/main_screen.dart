import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'home_screen.dart';
import '../../book/views/library_screen.dart';
import '../../chat/views/intro_chat_screen.dart';
import '../../profile/views/mypage_screen.dart';
import '../../../shared/widgets/custom_bottom_nav_bar.dart';

class MainNavNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void changeIndex(int index) {
    state = index;
  }
}

final mainNavProvider = NotifierProvider<MainNavNotifier, int>(() {
  return MainNavNotifier();
});

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainNavProvider);

    final List<Widget> screens = const [
      HomeScreen(),        // 홈
      IntroChatScreen(),   // 채팅
      LibraryScreen(),     // 서재
      MyPageScreen(),      // 마이페이지
    ];

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

        bottomNavigationBar: const CustomBottomNavBar(),
      ),
    );
  }
}