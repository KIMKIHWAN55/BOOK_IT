import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🌟 Riverpod 추가

import '../controllers/find_pw_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

// 🌟 StatefulWidget ➡️ ConsumerStatefulWidget
class FindPwScreen extends ConsumerStatefulWidget {
  const FindPwScreen({super.key});

  @override
  ConsumerState<FindPwScreen> createState() => _FindPwScreenState();
}

class _FindPwScreenState extends ConsumerState<FindPwScreen> {
  // _controller 인스턴스 삭제

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    // 🌟 ref.read로 컨트롤러 함수 호출
    final error = await ref.read(findPwControllerProvider.notifier).sendResetLink(
        _nameController.text.trim(),
        _emailController.text.trim()
    );

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이메일로 비밀번호 재설정 링크가 발송되었습니다. 확인해주세요!")));
      Navigator.pop(context); // 성공 시 뒤로가기
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 로딩 상태 감지 (bool 값)
    final isLoading = ref.watch(findPwControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
        title: const Text("비밀번호 찾기", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textMain)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 44),
                  const Text("가입하신 이름과 이메일을 입력하시면\n비밀번호 재설정 링크를 보내드립니다.", style: TextStyle(fontSize: 16, color: AppColors.textMain, height: 1.4)),
                  const SizedBox(height: 30),

                  CustomTextField(label: "이름", hint: "이름을 입력해주세요", controller: _nameController),
                  CustomTextField(label: "이메일", hint: "이메일을 입력해주세요", icon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress),

                  const Spacer(),
                  // 🌟 isLoading 변수 연결
                  PrimaryButton(text: "재설정 링크 발송", onPressed: _handleSendResetLink, isLoading: isLoading),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (isLoading) // 🌟 로딩 화면 조건
            Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: AppColors.primary))),
        ],
      ),
    );
  }
}