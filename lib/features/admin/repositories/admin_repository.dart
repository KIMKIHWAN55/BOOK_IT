import 'dart:io';
import 'dart:convert'; // 🌟 json 파싱을 위해 추가
import 'package:http/http.dart' as http; // 🌟 HTTP 통신을 위해 추가
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

  // 5. 책 삭제하기 (Firestore 문서 + Storage 이미지)
  Future<void> deleteBook(String docId, String imageUrl) async {
    try {
      // (1) Firestore 문서 삭제
      await _firestore.collection('books').doc(docId).delete();

      // (2) Storage 이미지 삭제 (이미지가 존재할 경우만)
      if (imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          // 이미지가 이미 없거나 삭제 실패 시, 문서 삭제는 성공했으므로 로그만 남기고 무시
          print('이미지 삭제 실패 (무시됨): $e');
        }
      }
    } catch (e) {
      throw Exception('책 삭제 실패: $e');
    }
  }

  // 🌟 주간 추천 도서(promotions) 업데이트
  Future<void> updateWeeklyRecommend(List<String> bookIds) async {
    await _firestore.collection('promotions').doc('weekly_recommend').set({
      'bookIds': bookIds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ====================================================================
  // 🌟 [핵심 추가] 카카오 책 검색 API 연동 (클래스 닫히기 직전 위치!)
  // ====================================================================
  Future<Map<String, dynamic>?> searchBookFromKakao(String query) async {
    // 💡 테스트용 임시 카카오 REST API 키입니다. (나중에 직접 발급받은 키로 교체하세요!)
    const String kakaoRestApiKey = '0a0c99ec9771b7cbb9be4a33b572180e'; // 임시 예시 키

    final url = Uri.parse('https://dapi.kakao.com/v3/search/book?query=$query');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'KakaoAK $kakaoRestApiKey'},
      );

      if (response.statusCode == 200) {
        // 🌟 한글 데이터 깨짐 방지를 위해 utf8.decode 적용
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