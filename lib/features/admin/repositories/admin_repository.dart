import 'dart:io';
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
}