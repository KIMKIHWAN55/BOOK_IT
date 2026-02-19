import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../book/models/book_model.dart';

// 🌟 [1] 상태 클래스 (기존 유지)
class HomeState {
  final bool isLoading;
  final String userName;
  final List<BookModel> recommendedBooks;
  final List<BookModel> bestSellerBooks;

  HomeState({
    this.isLoading = false,
    this.userName = '사용자',
    this.recommendedBooks = const [],
    this.bestSellerBooks = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    String? userName,
    List<BookModel>? recommendedBooks,
    List<BookModel>? bestSellerBooks,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      userName: userName ?? this.userName,
      recommendedBooks: recommendedBooks ?? this.recommendedBooks,
      bestSellerBooks: bestSellerBooks ?? this.bestSellerBooks,
    );
  }
}

// 🌟 [2] Notifier: 로직 완벽 최적화
class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    // 💡 해결 1: build 과정이 완전히 끝난 직후에 데이터를 불러오도록 예약(Microtask)
    Future.microtask(() => fetchAllData());

    // 처음엔 무조건 로딩 상태로 반환
    return HomeState(isLoading: true);
  }

  Future<void> fetchAllData() async {
    try {
      // 💡 해결 2: 각 함수에서 상태를 직접 변경하지 않고, 데이터만 반환받아 한 번에 모음
      final results = await Future.wait([
        _fetchUserData(),
        _fetchRecommendedBooks(),
        _fetchBestSellerBooks(),
      ]);

      // 모든 데이터 로드가 완료되면 한 번에 안전하게 상태 업데이트! (덮어쓰기 방지)
      state = state.copyWith(
        userName: results[0] as String,
        recommendedBooks: results[1] as List<BookModel>,
        bestSellerBooks: results[2] as List<BookModel>,
        isLoading: false, // 로딩 끝!
      );

    } catch (e) {
      // 에러가 났을 경우 콘솔에 출력하고 무한 로딩 해제
      print("🚨 홈 화면 데이터 로드 에러: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  // 데이터만 리턴하도록 수정된 함수들
  Future<String> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['name'] ?? "사용자";
    }
    return "사용자";
  }

  Future<List<BookModel>> _fetchRecommendedBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('category', isEqualTo: 'recommend')
        .get();
    return snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
  }

  Future<List<BookModel>> _fetchBestSellerBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .orderBy('rank') // 여기서 권한이나 인덱스 에러가 나면 try-catch가 잡아냅니다.
        .get();

    return snapshot.docs
        .map((doc) => BookModel.fromFirestore(doc))
        .where((book) {
      int? r = int.tryParse(book.rank);
      return r != null && r >= 1 && r <= 9;
    }).toList();
  }
}

// 🌟 [3] Provider 생성
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(() {
  return HomeNotifier();
});

// 🌟 [4] 장바구니 개수 전용 Provider (기존 유지)
final cartCountProvider = StreamProvider<int>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('cart')
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});