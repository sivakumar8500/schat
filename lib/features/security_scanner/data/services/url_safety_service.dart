import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class UrlSafetyService {
  final RegExp _urlRegExp = RegExp(
    r'(https?:\/\/[^\s\/$.?#].[^\s]*)',
    caseSensitive: false,
  );

  final List<String> _knownPhishingKeywords = [
    'bit.ly',
    'tinyurl.com',
    'verify-account',
    'login-secure',
    'bank-update',
    'security-alert',
    'account-recovery',
    'phishing-test',
    'free-gift',
    'crypto-claim',
  ];

  /// Extracts all URLs from local cached chat messages.
  Future<List<String>> extractChatUrls() async {
    final List<String> urls = [];
    try {
      if (Hive.isBoxOpen('cached_messages')) {
        final box = Hive.box('cached_messages');
        for (var key in box.keys) {
          final List<dynamic>? msgList = box.get(key);
          if (msgList != null) {
            for (var msg in msgList) {
              if (msg is Map) {
                final content = msg['content']?.toString() ?? '';
                final matches = _urlRegExp.allMatches(content);
                for (var match in matches) {
                  final url = match.group(0);
                  if (url != null && !urls.contains(url)) {
                    urls.add(url);
                  }
                }
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('UrlSafetyService: Error extracting chat URLs: $e');
    }

    // Default sample links for scan testing if no chat URLs found
    if (urls.isEmpty) {
      urls.addAll([
        'https://schat.app/welcome',
        'https://flutter.dev/docs',
      ]);
    }

    return urls;
  }

  /// Checks if a single URL is suspicious/phishing.
  bool isPhishingUrl(String url) {
    final lower = url.toLowerCase();
    return _knownPhishingKeywords.any((kw) => lower.contains(kw));
  }

  /// Performs full scan of all extracted URLs.
  Future<({List<String> scannedUrls, List<String> phishingUrls})> scanAllChatUrls() async {
    final urls = await extractChatUrls();
    final List<String> phishing = [];

    for (final url in urls) {
      if (isPhishingUrl(url)) {
        phishing.add(url);
      }
    }

    return (scannedUrls: urls, phishingUrls: phishing);
  }
}
