import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/profile_repository.dart';
import '../../book/models/book_model.dart';
import '../models/user_model.dart';
import 'dart:io';

final userProfileProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  return ref.watch(profileRepositoryProvider).getUserProfileStream();
});

final likedBooksProvider = StreamProvider.autoDispose<QuerySnapshot>((ref) {
  return ref.watch(profileRepositoryProvider).getLikedBooksStream();
});

final profileActionControllerProvider = Provider.autoDispose((ref) {
  return ProfileActionController(ref);
});

class ProfileActionController {
  final Ref ref;
  ProfileActionController(this.ref);

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  // 프로필 업데이트 공통 로직
  Future<void> _handleProfileSave({
    required String name,
    required String nickname,
    required String bio,
    File? imageFile,
    required bool isInitial,
  }) async {
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await _repository.uploadProfileImage(imageFile);
    }

    await _repository.updateProfile(
      name: name,
      nickname: nickname,
      bio: bio,
      profileImageUrl: imageUrl,
      isInitialSetup: isInitial,
    );
  }

  // 최초 프로필 설정
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

  // 마이페이지에서 프로필 수정
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