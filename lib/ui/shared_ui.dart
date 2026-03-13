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
        borderSide: const BorderSide(color: accentGreen, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: accentGreen, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0091EA), width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black54),
    );
  }
}

/// A wrapper that adds a gradient border around a widget and switches to a solid
/// accent blue border when the child is focused.
class GradientOutline extends StatefulWidget {
  const GradientOutline({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.borderWidth = 2,
    this.focusedBorderColor = ReWorthUI.accentBlue,
    this.gradient = ReWorthUI.backgroundGradient,
  });

  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final Color focusedBorderColor;
  final Gradient gradient;

  @override
  State<GradientOutline> createState() => _GradientOutlineState();
}

class _GradientOutlineState extends State<GradientOutline> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        if (hasFocus != _focused) {
          setState(() {
            _focused = hasFocus;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(widget.borderWidth),
        decoration: BoxDecoration(
          color: _focused ? Colors.transparent : null,
          gradient: _focused ? null : widget.gradient,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: _focused
              ? Border.all(
                  color: widget.focusedBorderColor,
                  width: widget.borderWidth,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            widget.borderRadius - widget.borderWidth,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
