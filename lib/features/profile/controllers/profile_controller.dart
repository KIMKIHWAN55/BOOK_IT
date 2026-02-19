import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';
import '../../book/models/book_model.dart';
import '../models/user_model.dart';
import 'dart:io';

// -----------------------------------------------------------------------------
// 프로필 화면용 Controller
// -----------------------------------------------------------------------------

// 🌟 [추가] 유저 정보 스트림 Provider
final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  return ref.read(profileRepositoryProvider).getUserProfileStream();
});

// 좋아요한 책 목록 스트림 Provider
final likedBooksProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return ref.read(profileRepositoryProvider).getLikedBooksStream();
});

// 액션 컨트롤러 (로그아웃, 상세정보 조회)
final profileActionControllerProvider = Provider.autoDispose((ref) {
  return ProfileActionController(ref);
});

class ProfileActionController {
  final Ref ref;
  ProfileActionController(this.ref);

  Future<BookModel?> getBookDetail(String bookId) async {
    return await ref.read(profileRepositoryProvider).getBookDetail(bookId);
  }

  // 🌟 [추가] 로그아웃 액션
  Future<void> logout() async {
    await ref.read(profileRepositoryProvider).logout();
  }

  // 기존 데이터 불러오기
  Future<Map<String, dynamic>?> getRawProfileData() async {
    return await ref.read(profileRepositoryProvider).getRawProfileData();
  }

  // 프로필 업데이트 (이미지 업로드 + DB 업데이트 묶음 처리)
  Future<void> updateProfile({required String name, required String nickname, required String bio, File? imageFile}) async {
    final repository = ref.read(profileRepositoryProvider);

    String? imageUrl;
    // 1. 이미지가 선택되었다면 먼저 Storage에 업로드
    if (imageFile != null) {
      imageUrl = await repository.uploadProfileImage(imageFile);
    }

    // 2. 확보된 URL과 텍스트 정보들로 DB 업데이트
    await repository.updateProfile(
      name: name,
      nickname: nickname,
      bio: bio,
      profileImageUrl: imageUrl,
    );
  }
  // 최초 프로필 설정 액션
  Future<void> setupProfile({
    required String name,
    required String nickname,
    required String bio,
    File? imageFile
  }) async {
    final repository = ref.read(profileRepositoryProvider);

    String? imageUrl;
    // 이미지가 있으면 Storage에 업로드 후 URL 받아오기 (EditScreen과 동일한 로직 재사용!)
    if (imageFile != null) {
      imageUrl = await repository.uploadProfileImage(imageFile);
    }

    // Firestore에 유저 기본 데이터 생성
    await repository.setupProfile(
      name: name,
      nickname: nickname,
      bio: bio,
      profileImageUrl: imageUrl,
    );
  }
  // 비밀번호 재설정 메일 발송
  Future<void> sendPasswordResetEmail() async {
    await ref.read(profileRepositoryProvider).sendPasswordResetEmail();
  }

  // 회원 탈퇴
  Future<void> deleteAccount() async {
    await ref.read(profileRepositoryProvider).deleteAccount();
  }
}