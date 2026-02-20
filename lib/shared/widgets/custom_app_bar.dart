import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 이동할 화면들 Import
import '../../features/book/views/category_screen.dart';
import '../../features/book/views/search_screen.dart';
import '../../features/profile/views/settings_screen.dart';
// 장바구니 카운트를 불러오기 위해 추가
import '../../features/home/controllers/home_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title; // 홈 화면은 타이틀이 없으므로 null 허용
  final bool isTransparent; // 투명 모드 여부
  final bool showCart; // 장바구니 아이콘 표시 여부
  final Color? backgroundColor;
  final bool showSearch;

  const CustomAppBar({
    super.key,
    this.title,
    this.isTransparent = false, // 기본값: 불투명 (마이페이지 등)
    this.showCart = false, // 기본값: 장바구니 안 보임
    this.backgroundColor,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    // 🌟 투명 모드에 따라 배경색과 아이콘 색상을 자동으로 바꿔줍니다.
    final bgColor = backgroundColor ?? (isTransparent ? Colors.transparent : const Color(0xFFF1F1F5));
    final iconColor = isTransparent ? Colors.white : Colors.black;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      centerTitle: true,
      title: title != null
          ? Text(title!, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 17))
          : null,

      // 메뉴 (카테고리)
      leading: IconButton(
        icon: Icon(Icons.menu, color: iconColor),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
        },
      ),

      actions: [
// 🌟 2. showSearch가 true일 때만 검색 버튼 렌더링
        if (showSearch)
          IconButton(
              icon: Icon(Icons.search, color: iconColor),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()))
          ),

        // 🌟 장바구니 (showCart가 true일 때만 표시)
        if (showCart)
          Consumer(
            builder: (context, ref, child) {
              final cartCountAsync = ref.watch(cartCountProvider);
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                    icon: Icon(Icons.shopping_cart_outlined, color: iconColor),
                  ),
                  cartCountAsync.when(
                    data: (count) => count > 0
                        ? Positioned(
                      top: 10, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFFEA4335), shape: BoxShape.circle),
                        child: Text(count.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
                    )
                        : const SizedBox(),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ],
              );
            },
          ),

        // 알림
        IconButton(icon: Icon(Icons.notifications_none, color: iconColor), onPressed: () {}),

        // 🌟 설정 (홈 화면이 아닐 때만 표시)
        if (!showCart)
          IconButton(
            icon: Icon(Icons.settings_outlined, color: iconColor),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}