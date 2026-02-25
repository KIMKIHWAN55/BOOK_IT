import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';

// 1. Repository Provider 정의
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ------------------------------------------------------------------------
  // 🔹 Create & Update (책 등록 및 수정)
  // ------------------------------------------------------------------------

  // 1. 이미지 업로드 (Storage)
  Future<String> uploadImage(File imageFile) async {
    try {
      // 파일명 중복 방지를 위해 현재 시간(밀리초) 사용
      String fileName = '${DateTime.now().millisecondsSinceEpoch}_book_cover.jpg';
      Reference ref = _storage.ref().child('book_covers/$fileName');

      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('이미지 업로드 실패: $e');
    }
  }

  // 2. 책 데이터 등록 (Firestore)
  Future<void> addBook(BookModel book) async {
    try {
      await _firestore.collection('books').add(book.toMap());
    } catch (e) {
      throw Exception('책 등록 실패: $e');
    }
  }

  // 3. 책 데이터 수정 (Firestore)
  Future<void> updateBook(BookModel book) async {
    try {
      await _firestore.collection('books').doc(book.id).update(book.toMap());
    } catch (e) {
      throw Exception('책 수정 실패: $e');
    }
  }

  // ------------------------------------------------------------------------
  // 🔹 Read & Delete (책 목록 조회 및 삭제)
  // ------------------------------------------------------------------------

  // 4. 책 목록 실시간 스트림 가져오기
  Stream<List<BookModel>> getBooksStream() {
    return _firestore.collection('books').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BookModel.fromFirestore(doc)).toList();
    });
  }

// 5. 책 삭제하기 (연쇄 삭제 및 스토리지 이미지 검증 포함)
  Future<void> deleteBook(String docId, String imageUrl) async {
    try {
      // 1. Storage 이미지 삭제
      //  카카오 API 이미지(http)가 아닌, 파이어베이스 스토리지에 직접 올린 사진일 때만 지우도록 방어 로직
      if (imageUrl.isNotEmpty && imageUrl.contains('firebasestorage.googleapis.com')) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('이미지 삭제 실패 (무시됨): $e');
        }
      }

      // 2. 일괄 처리(Batch) 장바구니 생성
      final batch = _firestore.batch();

      //  원본 책 데이터 삭제 추가
      final bookRef = _firestore.collection('books').doc(docId);
      batch.delete(bookRef);

      // 주간 추천 배열에서 이 책의 ID만 쏙 빼기 (배열 요소 삭제)
      final promoRef = _firestore.collection('promotions').doc('weekly_recommend');
      batch.update(promoRef, {
        'bookIds': FieldValue.arrayRemove([docId])
      });

      //  좋아요(likes) 컬렉션 연쇄 삭제
      final likesSnapshot = await _firestore.collection('likes')
          .where('bookId', isEqualTo: docId)
          .get();
      for (var doc in likesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      //  게시판 연쇄 삭제
      final boardSnapshot = await _firestore.collection('board')
          .where('bookId', isEqualTo: docId)
          .get();
      for (var doc in boardSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // 3. 장바구니에 담은 모든 삭제/수정 명령을 한 번에 실행
      await batch.commit();

    } catch (e) {
      throw Exception('책 연쇄 삭제 실패: $e');
    }
  }

  //  주간 추천 도서 업데이트
  Future<void> updateWeeklyRecommend(List<String> bookIds) async {
    await _firestore.collection('promotions').doc('weekly_recommend').set({
      'bookIds': bookIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ====================================================================
  //   카카오 책 검색 API 연동
  // ====================================================================
  Future<Map<String, dynamic>?> searchBookFromKakao(String query) async {
    // 💡 테스트용 임시 카카오 REST API 키입니다. (나중에 직접 발급받은 키로 교체하세요!)
    const String kakaoRestApiKey = '0a0c99ec9771b7cbb9be4a33b572180e';

    final url = Uri.parse('https://dapi.kakao.com/v3/search/book?query=$query');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
      );

      if (response.statusCode == 200) {
        //  한글 데이터 깨짐 방지를 위해 utf8 적용
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['documents'] != null && data['documents'].isNotEmpty) {
          return data['documents'][0]; // 가장 정확도가 높은 첫 번째 검색 결과 반환
        }
      }
    } catch (e) {
      print('카카오 API 검색 실패: $e');
    }
    return null;
  }
}