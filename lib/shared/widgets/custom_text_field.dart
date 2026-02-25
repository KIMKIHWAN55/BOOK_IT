import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final String? label;
  final String hint;
  final TextEditingController controller;
  final IconData? icon;
  final bool isObscure;
  final TextInputType keyboardType;
  final Widget? suffixButton;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.isObscure = false,
    this.keyboardType = TextInputType.text,
    this.suffixButton,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: const TextStyle(color: AppColors.textSub, fontSize: 14)),
            const SizedBox(height: 8),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: TextField(
                    controller: controller,
                    obscureText: isObscure,
                    keyboardType: keyboardType,
                    onChanged: onChanged,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      prefixIcon: icon != null ? Icon(icon, color: AppColors.textSub) : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                ),
              ),
              if (suffixButton != null) ...[
                const SizedBox(width: 8),
                SizedBox(height: 52, child: suffixButton!),
              ]
            ],
          ),
        ],
      ),
    );
  }
}