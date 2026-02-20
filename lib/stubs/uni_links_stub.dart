// Stub for uni_links2 compatibility
class UniLinks {
  static Stream<String?> uriLinkStream = Stream.empty();
  static Future<String?> getInitialLink() async => null;
}

// Export as uni_links for compatibility
final uriLinkStream = UniLinks.uriLinkStream;
Future<String?> getInitialLink() => UniLinks.getInitialLink();
