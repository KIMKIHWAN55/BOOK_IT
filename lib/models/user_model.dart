import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role; // 🔸 'admin' 또는 'user'

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
  });

  // Firestore 데이터를 객체로 변환
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'user', // 기본값은 일반 유저
    );
  }
}