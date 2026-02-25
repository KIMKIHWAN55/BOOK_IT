import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:email_otp/email_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //  로그인 관련 로직
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = '로그인 중 오류가 발생했습니다.';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = '가입되지 않은 이메일입니다.';
          break;
        case 'wrong-password':
          errorMessage = '비밀번호가 일치하지 않습니다.';
          break;
        case 'invalid-email':
          errorMessage = '잘못된 이메일 형식입니다.';
          break;
        case 'user-disabled':
          errorMessage = '정지된 계정입니다. 고객센터에 문의해주세요.';
          break;
        case 'too-many-requests':
          errorMessage = '로그인 시도가 너무 많습니다. 잠시 후 다시 시도해주세요.';
          break;
        case 'invalid-credential': // 💡 최신 파이어베이스 보안 정책 대응 (이메일/비번 오류 통합)
          errorMessage = '이메일 또는 비밀번호가 일치하지 않습니다.';
          break;
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }

// 구글 로그인 + Firestore 자동 저장 로직
  Future<UserCredential?> signInWithGoogle() async {
    UserCredential? credential;
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      credential = await _auth.signInWithPopup(provider);
    } else {
      await _googleSignIn.initialize(
        serverClientId: '318946402557-h2ub52o8ltcj0cqssgfnk0pn4sscbash.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential authCredential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      credential = await _auth.signInWithCredential(authCredential);
    }

    // 로그인 성공 시 Firestore에 유저 정보가 없으면 저장
    if (credential != null && credential.user != null) {
      await _syncGoogleUserToFirestore(credential.user!);
    }

    return credential;
  }

  // 구글 유저 전용 DB 동기화 함수
  Future<void> _syncGoogleUserToFirestore(User user) async {
    final userDoc = await _firestore.collection('users').doc(user.uid).get();

    if (!userDoc.exists) {
      // 처음 로그인한 유저라면 문서를 생성
      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': 'user', // 기본 권한
        'name': user.displayName ?? '이름 없음',
        'nickname': user.displayName ?? '익명', // 구글 이름을 기본 닉네임으로
        'phone': user.phoneNumber ?? '', // 구글은 보통 번호가 null일 수 있음
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // 이미 있는 유저라면 로그인 시간이나 프로필 사진 정도만 업데이트
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': user.photoURL,
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 2. 회원가입 및 본인 인증 관련 로직
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

  // 사용자 정보 DB 관리 로직
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

  // 아이디 찾기 (보안 적용)
  Future<String?> findUserId({required String name, required String phone}) async {
    final snapshot = await _firestore.collection('users')
        .where('name', isEqualTo: name)
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) return snapshot.docs.first.get('email');
    return null;
  }

  //  비밀번호 찾기
  Future<bool> checkUserExists({required String name, required String email}) async {
    final snapshot = await _firestore.collection('users')
        .where('name', isEqualTo: name)
        .where('email', isEqualTo: email)
        .limit(1) //
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // 비밀번호 재설정 이메일 발송
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('가입되지 않은 이메일입니다.');
      } else if (e.code == 'invalid-email') {
        throw Exception('잘못된 이메일 형식입니다.');
      }
      throw Exception('이메일 발송 중 오류가 발생했습니다.');
    } catch (e) {
      throw Exception('알 수 없는 오류가 발생했습니다.');
    }
  }

  //  회원가입 중복 검사
  Future<bool> isEmailDuplicate(String email) async {
    final snap = await _firestore.collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<bool> isNicknameDuplicate(String nickname) async {
    final snap = await _firestore.collection('users')
        .where('nickname', isEqualTo: nickname)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }
}