import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// True for a plain `name@domain.tld` address (used by optional email fields).
bool isValidEmailAddress(String text) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text.trim());

/// True for a structurally valid 15-character Indian GSTIN.
bool isValidGstin(String text) => RegExp(
  r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$',
).hasMatch(text.trim().toUpperCase());

/// Small caps heading that groups fields inside add/edit sheets.
class FormSectionTitle extends StatelessWidget {
  final String text;

  const FormSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Literata',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppColors.mutedText(context),
        ),
      ),
    );
  }
}

/// Shared look for form fields on the supplier / company / product sheets.
InputDecoration masterFieldDecoration(
  BuildContext context,
  String labelText,
  IconData? icon, {
  String? prefixText,
  bool readOnly = false,
}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(color: AppTheme.grey600, fontFamily: 'Literata'),
    prefixText: prefixText,
    prefixIcon: icon == null ? null : Icon(icon, color: AppTheme.grey600),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.grey300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppTheme.grey300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.accent(context), width: 2),
    ),
    filled: true,
    fillColor: readOnly
        ? AppColors.chipFill(context)
        : AppColors.scaffold(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    counterText: '',
  );
}

/// One muted icon + text line used on list cards (email, GST number, ...).
class CardInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const CardInfoLine({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.mutedText(context)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.secondaryText(context),
              fontFamily: 'Literata',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
