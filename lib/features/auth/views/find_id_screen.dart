import 'package:flutter/material.dart';
import '../controllers/find_id_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class FindIdScreen extends StatefulWidget {
  const FindIdScreen({super.key});

  @override
  State<FindIdScreen> createState() => _FindIdScreenState();
}

class _FindIdScreenState extends State<FindIdScreen> {
  final FindIdController _controller = FindIdController();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _controller.dispose();
    super.dispose();
  }

  // 폰트 스타일 공통 적용 함수 유지
  TextStyle _ptStyle({required double size, required FontWeight weight, required Color color, double height = 1.4}) {
    return TextStyle(fontFamily: 'Pretendard', fontSize: size, fontWeight: weight, color: color, height: height, letterSpacing: size * -0.025);
  }

  Future<void> _handleSearchId() async {
    final errorMessage = await _controller.requestSearchId(
      _nameController.text.trim(),
      _phoneController.text.trim(),
    );
    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textMain, size: 24), onPressed: () => Navigator.pop(context)),
        title: Text("아이디 찾기", style: _ptStyle(size: 20, weight: FontWeight.w600, color: AppColors.textMain)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
          listenable: _controller,
          builder: (context, child) {
            return SafeArea(
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: _buildBodyByStep(),
                  ),
                  if (_controller.isLoading)
                    Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator(color: AppColors.primary))),
                ],
              ),
            );
          }
      ),
    );
  }

  Widget _buildBodyByStep() {
    if (_controller.currentStep == 1) return _step1Input();
    return _step3Result();
  }

  // [1단계] 입력 화면
  Widget _step1Input() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 44),
        Text("회원가입시 입력한 정보로\n아이디를 찾을 수 있습니다", style: _ptStyle(size: 16, weight: FontWeight.w400, color: AppColors.textMain)),
        const SizedBox(height: 30),

        CustomTextField(
          label: '이름',
          hint: '이름을 입력해주세요',
          controller: _nameController,
        ),
        CustomTextField(
          label: '휴대폰 번호',
          hint: '휴대폰 번호를 입력해주세요 (- 제외)',
          icon: Icons.phone_iphone_outlined,
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),

        const Spacer(),
        // 🌟 버튼 텍스트 변경: "인증 번호 발송" -> "아이디 찾기"
        PrimaryButton(
          text: "아이디 찾기",
          onPressed: _handleSearchId,
          isLoading: _controller.isLoading,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // [3단계] 결과 화면
  Widget _step3Result() {
    return Column(
      children: [
        const Spacer(flex: 2),
        Center(
          child: Container(
            width: 50, height: 38,
            decoration: const BoxDecoration(color: Color(0xFF34A853)),
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ),
        const SizedBox(height: 40),
        Text("${_controller.userName}님의 아이디는", style: _ptStyle(size: 24, weight: FontWeight.w500, color: AppColors.textMain)),
        const SizedBox(height: 4),
        RichText(text: TextSpan(style: _ptStyle(size: 24, weight: FontWeight.w500, color: AppColors.textMain),
            children: [
              TextSpan(text: _controller.foundId, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              const TextSpan(text: " 입니다."),
            ])),
        const Spacer(flex: 3),
        PrimaryButton(
          text: "계속 로그인",
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}