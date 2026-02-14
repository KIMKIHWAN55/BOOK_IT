import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🌟 Riverpod 추가
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🌟 [Riverpod] 서비스 Provider 생성
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 🌟 [Riverpod] 인증 상태 감지 Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==========================================
  // 1. 로그인 관련 로직
  // ==========================================

  // 이메일/비밀번호 로그인
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // 구글 로그인 (요청하신 대로 원본 코드 유지)
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      return await _auth.signInWithPopup(provider);
    } else {
      await _googleSignIn.initialize(
        serverClientId: '318946402557-h2ub52o8ltcj0cqssgfnk0pn4sscbash.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null; // 사용자가 로그인 취소함

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    }
  }

  // 로그아웃 (편의상 추가)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ==========================================
  // 2. 회원가입 및 본인 인증 관련 로직
  // ==========================================

  // 이메일 인증 코드 발송
  Future<void> sendEmailVerificationCode(String email) async {
    final url = Uri.parse('https://sendverificationcode-o4apuahgma-uc.a.run.app');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email.trim().toLowerCase()}),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  // 인증 코드 재전송
  Future<void> resendVerificationCode(String email) async {
    final url = Uri.parse('https://sendverificationcode-o4apuahgma-uc.a.run.app');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email.trim().toLowerCase()}),
    );

    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  // 인증 코드 확인 및 최종 회원가입 처리
  Future<int> verifyCodeAndFinalizeSignup({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String code,
  }) async {
    final url = Uri.parse('https://verifycodeandfinalizesignup-o4apuahgma-uc.a.run.app');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email.trim().toLowerCase(),
        'password': password,
        'name': name,
        'nickname': nickname,
        'code': code,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 409) {
      return response.statusCode;
    } else {
      throw Exception(response.body);
    }
  }

  // ==========================================
  // 3. 사용자 정보 DB 관리 로직
  // ==========================================

  // Firestore에 유저 기본 정보 저장
  Future<void> saveUserToFirestore({
    required String uid,
    required String email,
    required String name,
    required String nickname,
    required String phone,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'email': email,
      'role': 'user',
      'name': name,
      'nickname': nickname,
      'phone': phone,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // 4. 아이디 찾기 (보안 적용)
  // ==========================================
  Future<String?> findUserId({required String name, required String phone}) async {
    final snapshot = await _firestore.collection('users')
        .where('name', isEqualTo: name)
        .where('phone', isEqualTo: phone)
        .limit(1) // 🌟 [보안] Firestore 규칙(limit <= 1) 통과를 위해 필수
        .get();

    if (snapshot.docs.isNotEmpty) return snapshot.docs.first.get('email');
    return null;
  }

  // ==========================================
  // 5. 비밀번호 찾기 (보안 적용)
  // ==========================================
  Future<bool> checkUserExists({required String name, required String email}) async {
    final snapshot = await _firestore.collection('users')
        .where('name', isEqualTo: name)
        .where('email', isEqualTo: email)
        .limit(1) // 🌟 [보안]
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==========================================
  // 6. 회원가입 중복 검사 (보안 적용)
  // ==========================================
  Future<bool> isEmailDuplicate(String email) async {
    final snap = await _firestore.collection('users')
        .where('email', isEqualTo: email)
        .limit(1) // 🌟 [보안]
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> isNicknameDuplicate(String nickname) async {
    final snap = await _firestore.collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1) // 🌟 [보안]
        .get();
    return snap.docs.isNotEmpty;
  }
}