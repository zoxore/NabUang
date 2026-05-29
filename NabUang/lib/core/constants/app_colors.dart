import 'package:flutter/material.dart';

class AppColors {
  // ─── Dark Theme ───────────────────────────────────────────
  static const Color primary = Color(0xFF00C896);
  static const Color primaryContainer = Color(0xFF003D2E);
  static const Color primaryLight = Color(0xFF4DFFC3);

  static const Color secondary = Color(0xFF5B8DEF);
  static const Color secondaryContainer = Color(0xFF1A2E5A);

  static const Color background = Color(0xFF0A0F1E);
  static const Color surface = Color(0xFF141928);
  static const Color surfaceVariant = Color(0xFF1E2538);
  static const Color surfaceHighlight = Color(0xFF252C3F);

  static const Color onSurface = Color(0xFFB8BFD8);
  static const Color onSurfaceDim = Color(0xFF6B738F);

  // ─── Light Theme ──────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F7FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFEEF1FB);
  static const Color lightSurfaceHighlight = Color(0xFFE3E8F7);

  static const Color lightOnSurface = Color(0xFF4A5578);
  static const Color lightOnSurfaceDim = Color(0xFF9AA3C0);

  static const Color lightPrimary = Color(0xFF00A87E);
  static const Color lightPrimaryContainer = Color(0xFFD0FFF0);

  // ─── Semantic (shared) ────────────────────────────────────
  static const Color income = Color(0xFF00C896);
  static const Color expense = Color(0xFFFF6B6B);
  static const Color transfer = Color(0xFF5B8DEF);
  static const Color error = Color(0xFFFF6B6B);

  // ─── Gradients ────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00C896), Color(0xFF0087FF)],
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0D1631), Color(0xFF0A0F1E)],
  );

  // Alias untuk backward compatibility
  static const LinearGradient backgroundGradient = darkBgGradient;

  static const LinearGradient lightBgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFECF0FF), Color(0xFFF5F7FF)],
  );
}
