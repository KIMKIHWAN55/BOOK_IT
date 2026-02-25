import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String name;
  final String nickname;
  final String bio;
  final String? profileImage;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.nickname,
    required this.bio,
    this.profileImage,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user',
      name: data['name'] ?? '',
      nickname: data['nickname'] ?? '사용자',
      bio: data['bio'] ?? '',
      profileImage: data['profileImage'],
    );
  }

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