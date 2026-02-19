import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 'admin' 또는 'user'
  final String name; // 🌟 추가됨: 이름
  final String nickname; // 🌟 변경됨: null 허용(?) 제거, 기본값 처리
  final String bio; // 🌟 추가됨: 소개글
  final String? profileImage; // 프로필 이미지는 없을 수 있으므로 nullable 유지

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.nickname,
    required this.bio,
    this.profileImage,
  });

  // 1. Firestore DocumentSnapshot에서 객체 생성 (권장)
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    // data()가 null일 경우를 대비하여 빈 Map 반환
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      name: data['name'] ?? '', // DB에 없으면 빈 문자열
      nickname: data['nickname'] ?? '사용자', // 기본 닉네임 설정
      bio: data['bio'] ?? '', // DB에 없으면 빈 문자열
      profileImage: data['profileImage'], // Firestore 필드명 통일됨
    );
  }

  // 2. Map에서 객체 생성 (기타 로컬 변환용)
  factory UserModel.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserModel(
      uid: uid ?? map['uid'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'user',
      name: map['name'] ?? '',
      nickname: map['nickname'] ?? '사용자',
      bio: map['bio'] ?? '',
      profileImage: map['profileImage'],
    );
  }

  // 3. 객체를 Map으로 변환 (데이터 저장 시 사용)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'name': name,
      'nickname': nickname,
      'bio': bio,
      'profileImage': profileImage,
    };
  }

  // 4. 🌟 [추가] Riverpod 상태 관리를 위한 copyWith 메서드
  // 기존 객체는 유지하되, 특정 필드값만 바꾼 새로운 객체를 생성할 때 사용합니다.
  UserModel copyWith({
    String? uid,
    String? email,
    String? role,
    String? name,
    String? nickname,
    String? bio,
    String? profileImage,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}