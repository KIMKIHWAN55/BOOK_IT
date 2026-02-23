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
    // build 과정이 완전히 끝난 직후에 데이터를 불러오도록 예약
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

      // 모든 데이터 로드가 완료되면 한 번에 안전하게 상태 업데이트!
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

  // 🌟🌟🌟 [핵심 수정 1] 관리자가 등록한 promotions 컬렉션에서 가져오기
  Future<List<BookModel>> _fetchRecommendedBooks() async {
    // 1. 프로모션 컬렉션에서 '이번 주 추천' 문서 가져오기
    final promoDoc = await FirebaseFirestore.instance
        .collection('promotions')
        .doc('weekly_recommend')
        .get();

    if (!promoDoc.exists) return [];

    List<dynamic> bookIds = promoDoc.data()?['bookIds'] ?? [];
    if (bookIds.isEmpty) return [];

    // 2. ID 배열을 이용해 책 세부 정보 가져오기
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .where(FieldPath.documentId, whereIn: bookIds)
        .get();

    // 3. 관리자가 체크한 '순서대로' 정렬해서 리스트에 담기
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

  // ====================================================================
  // 🌟🌟🌟 [핵심 수정 2] 완벽한 오름차순 정렬 보장 및 안전한 데이터 필터링
  // ====================================================================
  Future<List<BookModel>> _fetchBestSellerBooks() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('books')
        .orderBy('rank', descending: false) // 1. DB에서 오름차순 정렬 1차 요청
        .limit(50) // 2. 순위가 없는(rank: 0) 책이 상단을 차지할 경우를 대비해 넉넉히 50권 호출
        .get();

    // 3. 1위부터 9위까지의 책만 걸러냄
    var books = snapshot.docs
        .map((doc) => BookModel.fromFirestore(doc))
        .where((book) => book.rank >= 1 && book.rank <= 9)
        .toList();

    // 4. 🌟 [가장 중요] DB에 과거 문자형/숫자형 데이터가 섞여 있어도 무시하고, 앱에서 무조건 1, 2, 3 순서로 강제 정렬!
    books.sort((a, b) => a.rank.compareTo(b.rank));

    // 5. 정렬된 상태에서 최종적으로 9개만 잘라서 화면에 전달
    return books.take(9).toList();
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