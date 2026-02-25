import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/book/views/category_screen.dart';
import '../../features/book/views/search_screen.dart';
import '../../features/profile/views/settings_screen.dart';
import '../../features/home/controllers/home_controller.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool isTransparent;
  final bool showCart;
  final Color? backgroundColor;
  final bool showSearch;

  const CustomAppBar({
    super.key,
    this.title,
    this.isTransparent = false,
    this.showCart = false,
    this.backgroundColor,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? (isTransparent ? Colors.transparent : const Color(0xFFF1F1F5));
    final iconColor = isTransparent ? Colors.white : Colors.black;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      centerTitle: true,
      title: title != null
          ? Text(title!, style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 17))
          : null,

      // 메뉴
      leading: IconButton(
        icon: Icon(Icons.menu, color: iconColor),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoryScreen()));
        },
      ),

      actions: [
        if (showSearch)
          IconButton(
              icon: Icon(Icons.search, color: iconColor),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen()))
          ),

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

        IconButton(icon: Icon(Icons.notifications_none, color: iconColor), onPressed: () {}),

        // 설정
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