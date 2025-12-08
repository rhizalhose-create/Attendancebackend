import 'dart:js_util' as js_util;
import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;

/// Web implementation that calls the global `executeRecaptcha(action)` JS
/// helper defined in `web/index.html`. Adds simple retry/backoff to handle
/// timing issues where grecaptcha may not be ready immediately.
import 'package:flutter/material.dart';

Future<String?> getRecaptchaToken(BuildContext? context, String action) async {
  const int maxAttempts = 3;
  const Duration backoff = Duration(milliseconds: 700);

  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      final promise = js_util.callMethod(js_util.globalThis, 'executeRecaptcha', [action]);
      final token = await js_util.promiseToFuture<String?>(promise);
      if (kDebugMode) debugPrint('getRecaptchaToken: attempt $attempt token=${token != null}');
      if (token != null && token.isNotEmpty) return token;
    } catch (e) {
      if (kDebugMode) debugPrint('getRecaptchaToken: attempt $attempt error: $e');
    }

    if (attempt < maxAttempts) {
      await Future.delayed(backoff * attempt);
    }
  }

  return null;
}
