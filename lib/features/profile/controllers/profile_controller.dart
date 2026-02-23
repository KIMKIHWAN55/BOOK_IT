import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';
import '../../book/models/book_model.dart';
import '../models/user_model.dart';
import 'dart:io';

// -----------------------------------------------------------------------------
// 프로필 화면용 Controller
// -----------------------------------------------------------------------------

// 🌟 유저 정보 스트림 Provider (read 대신 watch 권장)
final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  return ref.watch(profileRepositoryProvider).getUserProfileStream();
});

// 🌟 [복구 확인] 좋아요한 책 목록 스트림 Provider
final likedBooksProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return ref.watch(profileRepositoryProvider).getLikedBooksStream();
});

// 액션 컨트롤러 Provider
final profileActionControllerProvider = Provider.autoDispose((ref) {
  return ProfileActionController(ref);
});

class ProfileActionController {
  final Ref ref;
  ProfileActionController(this.ref);

  // 리포지토리 접근 헬퍼
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  // ==========================================
  // 1. 프로필 업데이트 공통 로직 (중복 제거)
  // ==========================================
  // 🌟 setupProfile과 updateProfile이 내부적으로 동일한 로직을 쓰도록 통합 관리합니다.
  Future<void> _handleProfileSave({
    required String name,
    required String nickname,
    required String bio,
    File? imageFile,
    required bool isInitial,
  }) async {
    String? imageUrl;

    // 1. 이미지가 있다면 먼저 업로드 (공통 로직)
    if (imageFile != null) {
      imageUrl = await _repository.uploadProfileImage(imageFile);
    }

    // 2. 리포지토리의 통합된 updateProfile 호출
    await _repository.updateProfile(
      name: name,
      nickname: nickname,
      bio: bio,
      profileImageUrl: imageUrl,
      isInitialSetup: isInitial, // 최초 가입 여부 전달
    );
  }

  // [액션 1] 최초 프로필 설정 (회원가입 직후)
  Future<void> setupProfile({
    required String name,
    required String nickname,
    required String bio,
    File? imageFile,
  }) async {
    await _handleProfileSave(
      name: name,
      nickname: nickname,
      bio: bio,
      imageFile: imageFile,
      isInitial: true,
    );
  }

  // [액션 2] 마이페이지에서 프로필 수정
  Future<void> updateProfile({
    required String name,
    required String nickname,
    required String bio,
    File? imageFile,
  }) async {
    await _handleProfileSave(
      name: name,
      nickname: nickname,
      bio: bio,
      imageFile: imageFile,
      isInitial: false,
    );
  }

  // ==========================================
  // 2. 기타 기능 (기존 기능 100% 유지)
  // ==========================================

  // 책 상세정보 조회
  Future<BookModel?> getBookDetail(String bookId) async {
    return await _repository.getBookDetail(bookId);
  }

  // 닉네임 중복 체크
  Future<bool> checkNicknameDuplicate(String nickname) async {
    return await _repository.checkNicknameDuplicate(nickname);
  }

  // 로그아웃
  Future<void> logout() async {
    await _repository.logout();
  }

  // 초기 텍스트 필드 세팅용 데이터 로드
  Future<Map<String, dynamic>?> getRawProfileData() async {
    return await _repository.getRawProfileData();
  }

  // 비밀번호 재설정 이메일
  Future<void> sendPasswordResetEmail() async {
    await _repository.sendPasswordResetEmail();
  }

  // 회원 탈퇴
  Future<void> deleteAccount() async {
    await _repository.deleteAccount();
  }
}