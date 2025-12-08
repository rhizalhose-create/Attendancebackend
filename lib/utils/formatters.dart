String formatDate(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String formatTime(DateTime? dt) {
  if (dt == null) return '-';
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime? dt) {
  if (dt == null) return '-';
  return '${formatDate(dt)} ${formatTime(dt)}';
}
