import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../book/models/book_model.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show File;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

final profileRepositoryProvider = Provider.autoDispose((ref) => ProfileRepository());

class ProfileRepository {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Stream<UserModel?> getUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromFirestore(doc);
      return null;
    });
  }

  // 초기 텍스트 필드 원본 데이터
  Future<Map<String, dynamic>?> getRawProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // 좋아요 및 라이브러리 기능

  // 좋아요한 책 목록 가져오기
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

  // 프로필 업데이트 및 설정
  Future<String?> uploadProfileImage(XFile imageFile) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('user_profile')
        .child('${user.uid}.jpg');

    // kisWeb 플랫폼에 따라 업로드 방식을 다르게 처리
    if (kIsWeb) {
      //  웹 환경: 파일을 바이트로 변환하여 putData로 업로드
      final bytes = await imageFile.readAsBytes();
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
    } else {
      // 모바일 환경: XFile.path로 File 변환 후 putFile 업로드
      await storageRef.putFile(File(imageFile.path));
    }

    return await storageRef.getDownloadURL();
  }

  // 프로필 정보 업데이트
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

  // 계정 및 인증 관리

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<void> sendPasswordResetEmail() async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      //구글로 로그인한 유저인지 체크
      final isGoogleUser = user.providerData.any((info) => info.providerId == 'google.com');

      if (isGoogleUser) {
        throw Exception("구글 로그인 사용자는 비밀번호를 변경할 수 없습니다.");
      }

      // 이메일/비밀번호 가입자인 경우 발송 및 에러 구체화
      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'invalid-email') {
          throw Exception('잘못된 이메일 형식입니다.');
        } else if (e.code == 'user-not-found') {
          throw Exception('가입되지 않은 이메일입니다.');
        } else {
          throw Exception('이메일 발송 실패 (${e.code})');
        }
      } catch (e) {
        throw Exception('알 수 없는 오류가 발생했습니다.');
      }

    }
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    final uid = user.uid;
    final userRef = _firestore.collection('users').doc(uid);

    // 서브컬렉션 일괄 삭제
    final subcollections = ['cart', 'liked_books', 'liked_feeds', 'purchased_books'];
    for (final sub in subcollections) {
      final snapshot = await userRef.collection(sub).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      if (snapshot.docs.isNotEmpty) await batch.commit();
    }

    // users 문서 삭제
    await userRef.delete();

    // Firebase Auth 계정 삭제
    await user.delete();
  }
}