import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../models/user_model.dart'; // 🌟 UserModel import 추가
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

final profileRepositoryProvider = Provider.autoDispose((ref) => ProfileRepository());

class ProfileRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // 🌟 [추가] 유저 정보 스트림 (프로필 수정 시 실시간 자동 반영)
  Stream<UserModel?> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    });
  }

  // 좋아요한 책 목록 가져오기 (Stream)
  Stream<QuerySnapshot> getLikedBooksStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('liked_books')
        .orderBy('likedAt', descending: true)
        .snapshots();
  }

  // 책 ID로 상세 정보 가져오기
  Future<BookModel?> getBookDetail(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (doc.exists) return BookModel.fromFirestore(doc);
    return null;
  }

  // 🌟 [추가] 로그아웃
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 초기 텍스트 필드 채우기용 원본 데이터 가져오기
  Future<Map<String, dynamic>?> getRawProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // Storage에 프로필 이미지 업로드 후 URL 반환
  Future<String?> uploadProfileImage(File imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('user_profile')
        .child('${user.uid}.jpg');

    await storageRef.putFile(imageFile);
    return await storageRef.getDownloadURL();
  }

  // Firestore 사용자 정보 업데이트
  Future<void> updateProfile({required String name, required String nickname, required String bio, String? profileImageUrl}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final data = {
      'name': name,
      'nickname': nickname,
      'bio': bio,
    };

    if (profileImageUrl != null) {
      data['profileImage'] = profileImageUrl;
    }

    await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
  }
  // 최초 프로필 설정 (회원가입 직후)
  Future<void> setupProfile({
    required String name,
    required String nickname,
    required String bio,
    String? profileImageUrl
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final data = {
      'name': name,
      'nickname': nickname,
      'bio': bio,
      'profileImage': profileImageUrl ?? '', // 🌟 다른 화면과 필드명 통일!
      'role': 'user',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
  }
  // 비밀번호 재설정 메일 발송
  Future<void> sendPasswordResetEmail() async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      await _auth.sendPasswordResetEmail(email: user.email!);
    } else {
      throw Exception("사용자 이메일 정보를 찾을 수 없습니다.");
    }
  }

  // 회원 탈퇴
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    // DB 데이터 삭제
    await _firestore.collection('users').doc(user.uid).delete();
    // 계정 삭제
    await user.delete();
  }
}