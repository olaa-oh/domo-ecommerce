import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';

class SecurityUtils {
  static String hashPin(String pin) {
    final bytes = utf8.encode(pin); // Convert pin to bytes
    final hash = sha256.convert(bytes); // Create SHA256 hash
    return hash.toString();
  }

  static bool isValidPhoneNumber(String phone) {
    // Comprehensive phone validation regex
    // Allows formats: +XX XXXXXXXXX
    // X represents digits, allows spaces between groups
    return RegExp(r'^\+[1-9]\d{1,14}$').hasMatch(phone.replaceAll(' ', ''));
  }
}

// lib/core/utils/rate_limiter.dart
class RateLimiter {
  final GetStorage _storage = GetStorage();
  final int maxAttempts;
  final int windowMinutes;

  RateLimiter({
    this.maxAttempts = 5,
    this.windowMinutes = 30,
  });

  bool canAttempt(String identifier) {
    final key = 'rate_limit_$identifier';
    final attempts = _getAttempts(key);
    
    if (attempts.isEmpty) {
      _recordAttempt(key);
      return true;
    }

    // Remove attempts older than window
    attempts.removeWhere((timestamp) => 
      DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp)).inMinutes > windowMinutes
    );

    if (attempts.length >= maxAttempts) {
      return false;
    }

    _recordAttempt(key);
    return true;
  }

  List<int> _getAttempts(String key) {
    return (_storage.read(key) ?? <int>[]).cast<int>();
  }

  void _recordAttempt(String key) {
    final attempts = _getAttempts(key);
    attempts.add(DateTime.now().millisecondsSinceEpoch);
    _storage.write(key, attempts);
  }

  int remainingAttempts(String identifier) {
    final key = 'rate_limit_$identifier';
    final attempts = _getAttempts(key);
    attempts.removeWhere((timestamp) => 
      DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp)).inMinutes > windowMinutes
    );
    return maxAttempts - attempts.length;
  }

  Duration? timeToReset(String identifier) {
    final key = 'rate_limit_$identifier';
    final attempts = _getAttempts(key);
    if (attempts.isEmpty) return null;
    
    final oldestAttempt = DateTime.fromMillisecondsSinceEpoch(attempts.first);
    final resetTime = oldestAttempt.add(Duration(minutes: windowMinutes));
    final remaining = resetTime.difference(DateTime.now());
    
    return remaining.isNegative ? null : remaining;
  }
}