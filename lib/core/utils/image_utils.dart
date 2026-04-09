bool isValidImageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return false;
  const ext = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'];
  return ext.any((e) => url.toLowerCase().endsWith(e));
}
