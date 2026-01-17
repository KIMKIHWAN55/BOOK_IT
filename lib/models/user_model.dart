import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' 또는 'user'
  final String? nickname; // 닉네임 추가
  final String? profileImage; // 프로필 이미지 추가

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.nickname,
    this.profileImage,
  });

  // 1. Firestore DocumentSnapshot에서 객체 생성 (권장)
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      nickname: data['nickname'], // Firestore 필드명 'nickname'
      profileImage: data['profileImage'], // Firestore 필드명 'profileImage'
    );
  }

  // 2. Map에서 객체 생성 (에러 해결을 위해 추가)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      // Map에는 uid가 없을 수 있으므로, 없을 경우 빈 문자열 처리
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      nickname: map['nickname'],
      profileImage: map['profileImage'],
    );
  }

  // 객체를 Map으로 변환 (데이터 저장 시 사용)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'nickname': nickname,
      'profileImage': profileImage,
    };
  }
}