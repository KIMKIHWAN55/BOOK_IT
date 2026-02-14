import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../book/models/book_model.dart';

// 🌟 [1] 상태 클래스 정의 (데이터를 담는 그릇)
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

  // 상태 복사본을 만드는 유틸리티 (데이터 불변성 유지)
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

// 🌟 [2] Notifier 정의 (ChangeNotifier 대신 사용)
class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    // 초기 상태 반환 및 데이터 로딩 시작
    fetchAllData();
    return HomeState(isLoading: true);
  }

  Future<void> fetchAllData() async {
    // 상태 업데이트: 로딩 시작
    state = state.copyWith(isLoading: true);

    try {
      await Future.wait([
        _fetchUserData(),
        _fetchRecommendedBooks(),
        _fetchBestSellerBooks(),
      ]);
    } finally {
      // 상태 업데이트: 로딩 끝 (데이터는 아래 함수들에서 이미 채워짐)
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final name = doc.data()?['name'] ?? "사용자";
      state = state.copyWith(userName: name);
    }
  }

  Future<void> _fetchRecommendedBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('category', isEqualTo: 'recommend')
        .get();
    final books = snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
    state = state.copyWith(recommendedBooks: books);
  }

  Future<void> _fetchBestSellerBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .orderBy('rank')
        .get();

    final books = snapshot.docs
        .map((doc) => BookModel.fromFirestore(doc))
        .where((book) {
      int? r = int.tryParse(book.rank);
      return r != null && r >= 1 && r <= 9;
    })
        .toList();
    state = state.copyWith(bestSellerBooks: books);
  }
}

// 🌟 [3] Provider 생성 (이 변수를 통해 어디서든 접근 가능)
final homeProvider = NotifierProvider<HomeNotifier, HomeState>(() {
  return HomeNotifier();
});

// 🌟 [4] 장바구니 개수 전용 Provider (StreamProvider 사용)
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