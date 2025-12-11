// Widget tests for the Photo Contest app.
//
// These tests verify basic app structure and configuration.
// Note: Full integration tests requiring Supabase would need additional mocking.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:humble_photo_contest/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    test('lightTheme is configured', () {
      final theme = AppTheme.lightTheme;

      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.light);
    });

    test('darkTheme is configured', () {
      final theme = AppTheme.darkTheme;

      expect(theme, isNotNull);
      expect(theme.brightness, Brightness.dark);
    });

    test('Both themes use Material 3', () {
      expect(AppTheme.lightTheme.useMaterial3, true);
      expect(AppTheme.darkTheme.useMaterial3, true);
    });
  });
}
