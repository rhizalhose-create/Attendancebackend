import 'dart:js_util' as js_util;
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/material.dart';

/// Web implementation for reCAPTCHA v2 (checkbox).
/// Shows the checkbox modal when token is requested, waits for user to complete
/// the challenge, then returns the token.
Future<String?> getRecaptchaToken(BuildContext? context, String action) async {
  // reCAPTCHA temporarily disabled
  return null;
}
