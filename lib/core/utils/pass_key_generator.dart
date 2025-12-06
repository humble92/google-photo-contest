import 'dart:math';

/// Utility class for generating secure pass keys for private contests
class PassKeyGenerator {
  /// Generates a random alphanumeric pass key
  ///
  /// [length] The length of the pass key (default: 8)
  /// Returns a string containing random uppercase, lowercase letters and digits
  /// Excludes confusing characters like 0, O, 1, I, l
  static String generate({int length = 8}) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
