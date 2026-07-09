import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Couleurs principales
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFFEFF6FF);
  static const Color successGreen = Color(0xFF10B981);
  static const Color textDark = Color(0xFF1F2937);
  static const Color textGray = Color(0xFF6B7280);
  static const Color textLight = Color(0xFF9CA3AF);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color backgroundColor = Color(0xFFF9FAFB);

  // Police Nova Flat pour les titres
  static TextStyle novaFlat({
    double fontSize = 24,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.novaFlat(
      fontSize: fontSize,
      color: color ?? textDark,
      fontWeight: fontWeight,
    );
  }

  // Police Inter pour le texte courant
  static TextStyle inter({
    double fontSize = 16,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      color: color ?? textDark,
      fontWeight: fontWeight,
    );
  }
}