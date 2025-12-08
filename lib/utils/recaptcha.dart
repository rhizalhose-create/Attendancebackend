// Conditional export: use the web implementation when running on the web,
// otherwise use the safe stub.
export 'recaptcha_stub.dart'
  if (dart.library.html) 'recaptcha_web.dart';
