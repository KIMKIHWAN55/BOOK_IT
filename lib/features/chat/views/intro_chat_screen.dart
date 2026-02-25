import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../shared/widgets/custom_app_bar.dart';

class IntroChatScreen extends StatelessWidget {
  const IntroChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2ECFF),

      appBar: const CustomAppBar(
        showCart: true,
        backgroundColor: Color(0xFFEDE5FE),
      ),

      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 76,
            child: Container(color: const Color(0xFFEDE5FE)),
          ),

          Positioned(
            top: 58,
            left: 16,
            child: Transform.rotate(
              angle: -17.95 * (math.pi / 180),
              child: Container(
                width: 89.6,
                height: 97.34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBC05),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          Positioned(
            top: 10,
            left: 237,
            child: Transform.rotate(
              angle: 18.6 * (math.pi / 180),
              child: Container(
                width: 106,
                height: 113,
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          Positioned(
            top: 399,
            left: 257,
            child: Container(
              width: 116,
              height: 95,
              decoration: BoxDecoration(
                color: const Color(0xFF50B0A1),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            top: 447,
            left: 25,
            child: Transform.rotate(
              angle: -94.5 * (math.pi / 180),
              child: Container(
                width: 200,
                height: 197,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4CCCC),
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),
          ),

          // 부기 캐릭터
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Image.asset(
                'assets/images/boogi_final.png',
                width: 280,
                height: 280,
              ),
            ),
          ),

          // 말풍선 및 텍스트
          Positioned(
            top: 40,
            left: 32,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  )
                ],
              ),
              child: const Text(
                '안녕! 난 부기야\n만나서 반가워',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Maplestory',
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF222222),
                  height: 1.4,
                ),
              ),
            ),
          ),

          // 부기와 대화 하러 가기 버튼
          Positioned(
            bottom: 106,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 326,
                height: 56,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    )
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9854E0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '부기와 대화 하러 가기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.45,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}