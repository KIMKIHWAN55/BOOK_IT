import 'package:flutter/material.dart';

// -----------------------------------------------------------------------------
// 1. Auth (인증) 화면
// -----------------------------------------------------------------------------
import '../../features/auth/views/app_intro_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/signup_screen.dart';
import '../../features/auth/views/find_id_screen.dart';
import '../../features/auth/views/find_pw_screen.dart';
import '../../features/auth/views/verification_screen.dart';
import '../../features/auth/views/signup_complete_screen.dart';

// -----------------------------------------------------------------------------
// 2. Home & Main 화면
// -----------------------------------------------------------------------------
import '../../features/home/views/main_screen.dart';

// -----------------------------------------------------------------------------
// 3. Book (도서) 화면
// -----------------------------------------------------------------------------
import '../../features/book/models/book_model.dart';
import '../../features/book/views/book_detail_screen.dart';
import '../../features/book/views/search_screen.dart';
import '../../features/book/views/category_screen.dart';
import '../../features/book/views/category_result_screen.dart';

// -----------------------------------------------------------------------------
// 4. Cart (장바구니/결제) 화면
// -----------------------------------------------------------------------------
import '../../features/cart/views/cart_screen.dart';
import '../../features/cart/views/payment_screen.dart';

// -----------------------------------------------------------------------------
// 5. Profile (마이페이지/설정) 화면
// -----------------------------------------------------------------------------
import '../../features/profile/views/profile_setup_screen.dart';
import '../../features/profile/views/profile_edit_screen.dart';
import '../../features/profile/views/settings_screen.dart';
import '../../features/profile/views/liked_books_screen.dart';

// -----------------------------------------------------------------------------
// 6. Admin (관리자) 화면
// -----------------------------------------------------------------------------
import '../../features/admin/views/admin_add_book_screen.dart';
import '../../features/admin/views/admin_book_list_screen.dart';

class AppRouter {
  // ===========================================================================
  // 1. 라우트 이름(경로) 상수화 (오타 방지용)
  // ===========================================================================
  // Auth
  static const String intro = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String findId = '/find_id';
  static const String findPw = '/find_pw';
  static const String verification = '/verification';
  static const String signupComplete = '/signup_complete';

  // Home
  static const String main = '/main';

  // Book
  static const String bookDetail = '/book_detail';
  static const String search = '/search';
  static const String category = '/category';
  static const String categoryResult = '/category_result';

  // Cart & Payment
  static const String cart = '/cart';
  static const String payment = '/payment';

  // Profile
  static const String profileSetup = '/profile_setup';
  static const String profileEdit = '/profile_edit';
  static const String settings = '/settings'; // 🔥 에러 났던 부분 (상수명)
  static const String likedBooks = '/liked_books';

  // Admin
  static const String adminAddBook = '/admin_add_book';
  static const String adminBookList = '/admin_book_list';

  // ===========================================================================
  // 2. 경로에 따라 화면을 매칭해주는 함수
  // ===========================================================================
  // 🌟 해결: 매개변수 이름을 settings -> routeSettings 로 변경
  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
    // -----------------------------------------------------
    // [인증 관련]
    // -----------------------------------------------------
      case intro:
        return MaterialPageRoute(builder: (_) => const AppIntroScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (_) => const SignUpScreen());
      case findId:
        return MaterialPageRoute(builder: (_) => const FindIdScreen());
      case findPw:
        return MaterialPageRoute(builder: (_) => const FindPwScreen());
      case signupComplete:
        return MaterialPageRoute(builder: (_) => const SignupCompleteScreen());
      case verification:
        final args = routeSettings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => VerificationScreen(
            email: args['email'],
            password: args['password'],
            name: args['name'],
            nickname: args['nickname'],
            phone: args['phone'],
          ),
        );

    // -----------------------------------------------------
    // [메인 탭 화면]
    // -----------------------------------------------------
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());

    // -----------------------------------------------------
    // [도서 관련]
    // -----------------------------------------------------
      case search:
        return MaterialPageRoute(builder: (_) => const SearchScreen());
      case category:
        return MaterialPageRoute(builder: (_) => const CategoryScreen());
      case categoryResult:
        final categoryName = routeSettings.arguments as String;
        return MaterialPageRoute(builder: (_) => CategoryResultScreen(category: categoryName));
      case bookDetail:
        final book = routeSettings.arguments as BookModel;
        return MaterialPageRoute(builder: (_) => BookDetailScreen(book: book));

    // -----------------------------------------------------
    // [장바구니 및 결제 관련]
    // -----------------------------------------------------
      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());
      case payment:
        final args = routeSettings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => PaymentScreen(
            items: args['items'] as List<Map<String, dynamic>>,
            totalPrice: args['totalPrice'] as int,
          ),
        );

    // -----------------------------------------------------
    // [프로필 및 설정 관련]
    // -----------------------------------------------------
      case profileSetup:
        return MaterialPageRoute(builder: (_) => const ProfileSetupScreen());
      case profileEdit:
        return MaterialPageRoute(builder: (_) => const ProfileEditScreen());
      case settings: // 🔥 이제 변수명 충돌 없이 상수로 정상 인식됩니다.
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case likedBooks:
        return MaterialPageRoute(builder: (_) => const LikedBooksScreen());

    // -----------------------------------------------------
    // [관리자 관련]
    // -----------------------------------------------------
      case adminAddBook:
        return MaterialPageRoute(builder: (_) => const AdminAddBookScreen());
      case adminBookList:
        return MaterialPageRoute(builder: (_) => const AdminBookListScreen());

    // -----------------------------------------------------
    // [예외 처리] 등록되지 않은 경로
    // -----------------------------------------------------
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('경로를 찾을 수 없습니다: ${routeSettings.name}')),
          ),
        );
    }
  }
}