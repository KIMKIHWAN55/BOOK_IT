import 'package:flutter/material.dart';
import '../controllers/find_pw_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class FindPwScreen extends StatefulWidget {
  const FindPwScreen({super.key});

  @override
  State<FindPwScreen> createState() => _FindPwScreenState();
}

class _FindPwScreenState extends State<FindPwScreen> {
  final FindPwController _controller = FindPwController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  Future<void> _handleSendResetLink() async {
    final error = await _controller.sendResetLink(_nameController.text.trim(), _emailController.text.trim());

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      // 🌟 성공 시 알림 띄우고 바로 로그인 화면으로 쫓아냄
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이메일로 비밀번호 재설정 링크가 발송되었습니다. 확인해주세요!")));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain), onPressed: () => Navigator.pop(context)),
        title: const Text("비밀번호 찾기", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textMain)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return Stack(
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
                        PrimaryButton(text: "재설정 링크 발송", onPressed: _handleSendResetLink, isLoading: _controller.isLoading),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                if (_controller.isLoading) Container(color: Colors.black26, child: const Center(child: CircularProgressIndicator(color: AppColors.primary))),
              ],
            );
          }
      ),
    );
  }
}