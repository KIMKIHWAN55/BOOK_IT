import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../models/user_model.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

final profileRepositoryProvider = Provider.autoDispose((ref) => ProfileRepository());

class ProfileRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ==========================================
  // 1. 유저 정보 관리 (실시간 및 초기값)
  // ==========================================

  // 유저 정보 스트림 (실시간 반영)
  Stream<UserModel?> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    });
  }

  // 초기 텍스트 필드 채우기용 원본 데이터
  Future<Map<String, dynamic>?> getRawProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // ==========================================
  // 2. 좋아요 및 라이브러리 기능 (사용자님 핵심 기능)
  // ==========================================

  // 🌟 [복구] 좋아요한 책 목록 가져오기 (마이페이지용)
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

  // 책 상세 정보 가져오기
  Future<BookModel?> getBookDetail(String bookId) async {
    final doc = await _firestore.collection('books').doc(bookId).get();
    if (doc.exists) return BookModel.fromFirestore(doc);
    return null;
  }

  // ==========================================
  // 3. 프로필 업데이트 및 설정
  // ==========================================

  // Storage에 이미지 업로드
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

  // 프로필 정보 업데이트 (최초 설정 및 수정 공용)
  Future<void> updateProfile({
    required String name,
    required String nickname,
    required String bio,
    String? profileImageUrl,
    bool isInitialSetup = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final Map<String, dynamic> data = {
      'name': name,
      'nickname': nickname,
      'bio': bio,
      if (isInitialSetup) 'isProfileSetupComplete': true,
    };

    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      data['profileImage'] = profileImageUrl; // 필드명 일관성 유지
    }

    // merge: true를 사용하여 가입 시 입력된 이메일 등을 보존합니다.
    await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
  }

  // 닉네임 중복 검사
  Future<bool> checkNicknameDuplicate(String nickname) async {
    final user = _auth.currentUser;
    final query = await _firestore.collection('users').where('nickname', isEqualTo: nickname).get();

    for (var doc in query.docs) {
      if (doc.id != user?.uid) return true;
    }
    return false;
  }

  // ==========================================
  // 4. 계정 및 인증 관리
  // ==========================================

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail() async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      await _auth.sendPasswordResetEmail(email: user.email!);
    } else {
      throw Exception("사용자 이메일 정보를 찾을 수 없습니다.");
    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");
    await _firestore.collection('users').doc(user.uid).delete();
    await user.delete();
  }
}