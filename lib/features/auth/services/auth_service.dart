import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http; // 🌟 API 통신용 추가
import 'dart:convert'; // 🌟 JSON 변환용 추가
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 Firestore 추가

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore 인스턴스

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

  // 구글 로그인
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

  // ==========================================
  // 2. 회원가입 및 본인 인증 관련 로직
  // ==========================================

  // 이메일 인증 코드 발송 (회원가입 첫 화면)
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

  // 인증 코드 재전송 (인증 화면)
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

  // 인증 코드 확인 및 최종 회원가입 처리 (인증 화면)
  // 반환값: 200(성공), 409(중복), 그 외 예외
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

  // Firestore에 유저 기본 정보 저장 (인증 및 가입 완료 후 실행)
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
// 4. [수정됨] 아이디 찾기 (이름 + 휴대폰 번호)
  // ==========================================
  Future<String?> findUserId({required String name, required String phone}) async {
    final snapshot = await _firestore.collection('users')
        .where('name', isEqualTo: name)
        .where('phone', isEqualTo: phone) // 🌟 이메일 대신 휴대폰 번호로 검색
        .get();

    if (snapshot.docs.isNotEmpty) return snapshot.docs.first.get('email');
    return null;
  }

  // ==========================================
  // 5. [수정됨] 비밀번호 찾기 (Firebase 재설정 링크)
  // ==========================================
  // 먼저 해당 유저(이름+이메일)가 DB에 진짜 있는지 확인
  Future<bool> checkUserExists({required String name, required String email}) async {
    final snapshot = await _firestore.collection('users')
        .where('name', isEqualTo: name)
        .where('email', isEqualTo: email)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Firebase에서 제공하는 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ==========================================
  // 6. [신규] 회원가입 중복 검사
  // ==========================================
  Future<bool> isEmailDuplicate(String email) async {
    final snap = await _firestore.collection('users').where('email', isEqualTo: email).get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> isNicknameDuplicate(String nickname) async {
    final snap = await _firestore.collection('users').where('nickname', isEqualTo: nickname).get();
    return snap.docs.isNotEmpty;
  }
}