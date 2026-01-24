import 'package:flutter/material.dart';

class FormControl extends StatelessWidget {
  final String label;
  final String? hintText;
  final bool obscureText;
  final TextEditingController? controller;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const FormControl({
    Key? key,
    required this.label,
    this.hintText,
    this.obscureText = false,
    this.controller,
    this.prefix,
    this.suffix,
    this.keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefix,
            suffixIcon: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
