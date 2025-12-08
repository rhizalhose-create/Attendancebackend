import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

/// Mobile WebView implementation: loads `assets/recaptcha.html`, injects the
/// requested `action`, and reads `document.title` (set to 'rc|<token>') or
/// listens for a JS postMessage to get the token. Returns `null` on timeout.
Future<String?> getRecaptchaToken(BuildContext? context, String action) async {
  final html = await rootBundle.loadString('assets/recaptcha.html');

  // Replace the in-page action detection with a fixed action so the data URI
  // will use the desired action.
  final safeAction = action.replaceAll("'", "\\'");
  final modified = html.replaceFirst(
    "var action = (new URL(location.href)).searchParams.get('action') || 'login';",
    "var action = '$safeAction';",
  );

  final dataUri = Uri.dataFromString(modified, mimeType: 'text/html', encoding: utf8).toString();

  final controller = WebViewController();
  controller.setJavaScriptMode(JavaScriptMode.unrestricted);
  controller.loadRequest(Uri.parse(dataUri));

  final completer = Completer<String?>();

  // Show dialog with WebView. We'll poll document.title for the token.
  if (context == null || !Navigator.canPop(context)) {
    // If no context or can't show dialog, still try to load and poll silently.
  }

  // Display dialog if context provided
  if (context != null) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            width: 360,
            height: 480,
            child: WebViewWidget(controller: controller),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!completer.isCompleted) completer.complete(null);
                Navigator.of(ctx).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Poll for document.title change for up to 15 seconds
  final timeout = DateTime.now().add(Duration(seconds: 15));
  while (DateTime.now().isBefore(timeout) && !completer.isCompleted) {
    try {
      final result = await controller.runJavaScriptReturningResult('document.title');
      if (result != null) {
        // The JS result may be returned as a quoted string depending on platform
        String title = result is String ? result : result.toString();
        title = title.replaceAll('"', '');
        if (title.startsWith('rc|') && title.length > 3) {
          final token = title.substring(3);
          if (!completer.isCompleted) completer.complete(token);
          break;
        }
      }
    } catch (_) {
      // ignore JS errors while grecaptcha initializes
    }
    await Future.delayed(Duration(milliseconds: 500));
  }

  if (!completer.isCompleted) completer.complete(null);

  final token = await completer.future;

  // Close dialog if still open
  if (context != null) {
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {}
  }

  return token;
}
