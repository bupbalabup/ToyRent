import 'package:flutter/material.dart';

/// Extension methods for common operations

extension StringExtensions on String {
  /// Validate email format
  bool isValidEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is a valid password
  bool isValidPassword({int minLength = 6}) {
    return length >= minLength;
  }
}

extension BuildContextExtensions on BuildContext {
  /// Get device media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get device height
  double get height => mediaQuery.size.height;

  /// Get device width
  double get width => mediaQuery.size.width;

  /// Check if device is portrait
  bool get isPortrait => mediaQuery.orientation == Orientation.portrait;

  /// Check if device is landscape
  bool get isLandscape => mediaQuery.orientation == Orientation.landscape;

  /// Get keyboard height
  double get keyboardHeight => mediaQuery.viewInsets.bottom;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => keyboardHeight > 0;
}
