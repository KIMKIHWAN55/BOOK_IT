import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bookit_app/features/auth/views/login_screen.dart';
import '../controllers/profile_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  // 비밀번호 변경
  Future<void> _changePassword() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(profileActionControllerProvider).sendPasswordResetEmail();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('비밀번호 재설정 메일을 보냈습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메일 발송 실패: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 로그아웃
  Future<void> _logout() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(profileActionControllerProvider).logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃에 실패했습니다.')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // 회원 탈퇴
  Future<void> _deleteAccount() async {
    if (_isLoading) return;

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
      setState(() => _isLoading = true);

      try {
        await ref.read(profileActionControllerProvider).deleteAccount();

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
      } catch (e) {
        final errorMsg = e.toString();
        if (errorMsg.contains('requires-recent-login')) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('보안을 위해 다시 로그인한 후 탈퇴해주세요.')),
            );
            _logout();
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('탈퇴 실패: ${errorMsg.replaceAll("Exception: ", "")}')),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),

              _buildSectionHeader("앱 설정"),
              _buildSettingsItem(title: "잠금 설정", onTap: () {}),
              _buildSettingsItem(title: "알림 설정", onTap: () {}),

              const SizedBox(height: 20),

              _buildSectionHeader("계정 설정"),
              _buildSettingsItem(title: "비밀번호 변경", onTap: _changePassword),
              _buildSettingsItem(title: "로그 아웃", onTap: _logout),
              _buildSettingsItem(title: "회원 탈퇴", onTap: _deleteAccount, isLast: true),
            ],
          ),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFFD45858)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      height: 42,
      color: const Color(0xFFF1F1F5),
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
              color: Color(0xFFD1D1D1),
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
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF222222)),
          ],
        ),
      ),
    );
  }
}