import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bookit_app/features/auth/views/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. 비밀번호 변경 (재설정 이메일 발송 방식)
  Future<void> _changePassword() async {
    final user = _auth.currentUser;
    if (user != null && user.email != null) {
      try {
        await _auth.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.email}로 비밀번호 재설정 메일을 보냈습니다.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('메일 발송 실패: $e')),
          );
        }
      }
    }
  }

  // 2. 로그아웃
  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  // 3. 회원 탈퇴
  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 확인 다이얼로그
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("회원 탈퇴"),
        content: const Text("정말로 탈퇴하시겠습니까?\n모든 데이터가 삭제되며 복구할 수 없습니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("탈퇴", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // DB 데이터 삭제
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        // 계정 삭제
        await user.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원 탈퇴가 완료되었습니다.')),
          );
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        // 로그인한 지 오래된 경우 재인증 필요
        if (e.code == 'requires-recent-login') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('보안을 위해 다시 로그인한 후 탈퇴해주세요.')),
            );
            _logout(); // 로그아웃 시켜서 다시 로그인하게 유도
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('탈퇴 실패: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '설정',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20), // 상단 여백 (Frame 297 top: 80 - 32 = 48 -> approx 20 padding)

          // --- 앱 설정 섹션 ---
          _buildSectionHeader("앱 설정"),
          _buildSettingsItem(title: "잠금 설정", onTap: () {}), // 기능 미구현 (UI만)
          _buildSettingsItem(title: "알림 설정", onTap: () {}), // 기능 미구현 (UI만)

          const SizedBox(height: 20),

          // --- 계정 설정 섹션 ---
          _buildSectionHeader("계정 설정"),
          _buildSettingsItem(title: "비밀번호 변경", onTap: _changePassword),
          _buildSettingsItem(title: "로그 아웃", onTap: _logout),
          _buildSettingsItem(title: "회원 탈퇴", onTap: _deleteAccount, isLast: true),
        ],
      ),
    );
  }

  // 섹션 헤더 위젯 (회색 배경)
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      height: 42,
      color: const Color(0xFFF1F1F5), // CSS Background
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Color(0xFF222222),
        ),
      ),
    );
  }

  // 설정 항목 위젯 (흰색 배경)
  Widget _buildSettingsItem({required String title, required VoidCallback onTap, bool isLast = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          border: isLast
              ? null
              : const Border(
            bottom: BorderSide(
              color: Color(0xFFD1D1D1), // rgba(209, 209, 209, 0.5)
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF222222),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF222222)), // 화살표 아이콘
          ],
        ),
      ),
    );
  }
}