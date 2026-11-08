/// Masks the local part of an email so a screen can say where a recovery code
/// went without printing the address in full.
///
/// `pratama.inc12@gmail.com` -> `p***@gmail.com`
String maskEmail(String email) {
  final trimmed = email.trim();
  final atIndex = trimmed.lastIndexOf('@');

  // Not an address: never echo the raw value back to the screen.
  if (atIndex <= 0 || atIndex == trimmed.length - 1) {
    return '***';
  }

  final local = trimmed.substring(0, atIndex);
  final domain = trimmed.substring(atIndex);

  return '${local[0]}***$domain';
}

