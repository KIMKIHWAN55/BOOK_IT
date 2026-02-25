import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../book/models/book_model.dart';

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

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    Future.microtask(() => fetchAllData());
    return HomeState(isLoading: true);
  }

  Future<void> fetchAllData() async {
    try {
      final results = await Future.wait([
        _fetchUserData(),
        _fetchRecommendedBooks(),
        _fetchBestSellerBooks(),
      ]);

      state = state.copyWith(
        userName: results[0] as String,
        recommendedBooks: results[1] as List<BookModel>,
        bestSellerBooks: results[2] as List<BookModel>,
        isLoading: false,
      );
    } catch (e) {
      print("🚨 홈 화면 데이터 로드 에러: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  Future<String> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(
          user.uid).get();
      return doc.data()?['name'] ?? "사용자";
    }
    return "사용자";
  }

  Future<List<BookModel>> _fetchRecommendedBooks() async {
    // 프로모션 컬렉션에서 이번 주 추천 문서 가져오기
    final promoDoc = await FirebaseFirestore.instance
        .collection('promotions')
        .doc('weekly_recommend')
        .get();

    if (!promoDoc.exists) return [];

    List<dynamic> bookIds = promoDoc.data()?['bookIds'] ?? [];
    if (bookIds.isEmpty) return [];

    // ID 배열을 이용해 책 세부 정보 가져오기
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where(FieldPath.documentId, whereIn: bookIds)
        .get();

    // 관리자가 체크한 순서대로 정렬해서 리스트에 담기
    List<BookModel> recommendedBooks = [];
    for (String id in bookIds) {
      final doc = snapshot.docs
          .where((d) => d.id == id)
          .firstOrNull;
      if (doc != null) {
        recommendedBooks.add(BookModel.fromFirestore(doc));
      }
    }

    return recommendedBooks;
  }

  Future<List<BookModel>> _fetchBestSellerBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where('rank', isGreaterThan: 0)
        .orderBy('rank', descending: false)
        .limit(30)
        .get();

    // 1위부터 15위까지의 책만 걸러냄
    var books = snapshot.docs
        .map((doc) => BookModel.fromFirestore(doc))
        .where((book) => book.rank >= 1 && book.rank <= 15)
        .toList();

    //  DB에 과거 문자형/숫자형 데이터가 섞여 있어도 무시하고, 앱에서 무조건 강제정렬
    books.sort((a, b) => a.rank.compareTo(b.rank));

    // 정렬된 상태에서 최종적으로 15개만 잘라서 화면에 전달
    return books.take(15).toList();
  }
}


final homeProvider = NotifierProvider<HomeNotifier, HomeState>(() {
  return HomeNotifier();
});

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