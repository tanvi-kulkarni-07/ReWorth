import 'package:flutter/material.dart';

class ReWorthUI {
  static const Color accentGreen = Color(0xFF00C853);
  static const Color accentBlue = Color(0xFF0091EA);

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [accentGreen, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(30),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static ButtonStyle actionButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF0091EA),
    minimumSize: const Size(280, 56),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    elevation: 4,
    shadowColor: Colors.black26,
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    ),
  );

  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF0091EA)),
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0091EA), width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
    );
  }
}
