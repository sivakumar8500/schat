import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

class LinkMetadata {
  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? faviconUrl;
  final String domain;

  const LinkMetadata({
    required this.url,
    required this.domain,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.faviconUrl,
  });

  bool get hasContent =>
      (title != null && title!.trim().isNotEmpty) ||
      (description != null && description!.trim().isNotEmpty) ||
      (imageUrl != null && imageUrl!.trim().isNotEmpty);

  @override
  String toString() =>
      'LinkMetadata(url: $url, title: $title, image: $imageUrl, domain: $domain)';
}

class LinkMetadataService {
  LinkMetadataService._();
  static final LinkMetadataService instance = LinkMetadataService._();

  final Map<String, LinkMetadata> _cache = {};
  final Map<String, Future<LinkMetadata?>> _inFlight = {};

  static final RegExp urlRegex = RegExp(
    r'(?:https?:\/\/|www\.)[^\s<>"{}|\^`]+',
    caseSensitive: false,
  );

  /// Extracts the first valid web URL found in the given text.
  static String? extractFirstUrl(String text) {
    if (text.isEmpty) return null;
    final match = urlRegex.firstMatch(text);
    if (match == null) return null;
    var url = match.group(0)!;
    // Clean trailing punctuation like ., ), ], >, ,, ;
    url = url.replaceAll(RegExp(r'[.,)>\];]+$'), '');
    return url;
  }

  /// Normalizes a URL ensuring it has http/https scheme.
  static String normalizeUrl(String rawUrl) {
    var trimmed = rawUrl.trim();
    if (!trimmed.toLowerCase().startsWith('http://') &&
        !trimmed.toLowerCase().startsWith('https://')) {
      trimmed = 'https://$trimmed';
    }
    return trimmed;
  }

  /// Fetches metadata for a given URL with in-memory caching and request deduplication.
  Future<LinkMetadata?> fetchMetadata(String rawUrl) async {
    final normalized = normalizeUrl(rawUrl);
    if (_cache.containsKey(normalized)) {
      return _cache[normalized];
    }

    if (_inFlight.containsKey(normalized)) {
      return await _inFlight[normalized];
    }

    final future = _fetchMetadataInternal(normalized);
    _inFlight[normalized] = future;

    try {
      final result = await future;
      if (result != null) {
        _cache[normalized] = result;
      }
      return result;
    } finally {
      _inFlight.remove(normalized);
    }
  }

  Future<LinkMetadata?> _fetchMetadataInternal(String urlStr) async {
    try {
      final uri = Uri.tryParse(urlStr);
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        return null;
      }

      final domain = uri.host.replaceFirst(RegExp(r'^www\.'), '');

      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Language': 'en-US,en;q=0.9',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode < 200 || response.statusCode >= 400) {
        return _fallbackMetadata(urlStr, domain, uri);
      }

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.toLowerCase().contains('text/html') &&
          !contentType.toLowerCase().contains('application/xhtml+xml')) {
        // Direct media link or other document
        if (contentType.toLowerCase().startsWith('image/')) {
          return LinkMetadata(
            url: urlStr,
            domain: domain,
            title: domain,
            imageUrl: urlStr,
          );
        }
        return _fallbackMetadata(urlStr, domain, uri);
      }

      final document = html_parser.parse(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );

      String? title;
      String? description;
      String? imageUrl;
      String? siteName;
      String? faviconUrl;

      // Extract title: og:title -> twitter:title -> <title>
      final metaOgTitle = document
          .querySelector('meta[property="og:title"]')
          ?.attributes['content'];
      final metaTwTitle = document
          .querySelector('meta[name="twitter:title"]')
          ?.attributes['content'];
      final docTitle = document.querySelector('title')?.text;
      title = metaOgTitle ?? metaTwTitle ?? docTitle;

      // Extract description: og:description -> twitter:description -> meta description
      final metaOgDesc = document
          .querySelector('meta[property="og:description"]')
          ?.attributes['content'];
      final metaTwDesc = document
          .querySelector('meta[name="twitter:description"]')
          ?.attributes['content'];
      final metaDesc = document
          .querySelector('meta[name="description"]')
          ?.attributes['content'];
      description = metaOgDesc ?? metaTwDesc ?? metaDesc;

      // Extract site name: og:site_name
      siteName = document
          .querySelector('meta[property="og:site_name"]')
          ?.attributes['content'];

      // Extract image: og:image -> twitter:image -> meta image
      final metaOgImg = document
          .querySelector('meta[property="og:image"]')
          ?.attributes['content'];
      final metaTwImg = document
          .querySelector('meta[name="twitter:image"]')
          ?.attributes['content'];
      final metaImg = document
          .querySelector('meta[name="image"]')
          ?.attributes['content'];
      final linkImg = document
          .querySelector('link[rel="image_src"]')
          ?.attributes['href'];
      imageUrl = metaOgImg ?? metaTwImg ?? metaImg ?? linkImg;

      // Resolve relative image URL
      if (imageUrl != null && imageUrl.isNotEmpty) {
        imageUrl = _resolveUrl(uri, imageUrl);
      }

      // Extract favicon: link[rel="icon"] -> link[rel="shortcut icon"]
      final favElem = document.querySelector('link[rel~="icon"]') ??
          document.querySelector('link[rel="shortcut icon"]');
      final rawFav = favElem?.attributes['href'];
      if (rawFav != null && rawFav.isNotEmpty) {
        faviconUrl = _resolveUrl(uri, rawFav);
      } else {
        faviconUrl = '${uri.scheme}://${uri.host}/favicon.ico';
      }

      title = title?.trim();
      description = description?.trim();

      // Clean up common HTML entities or newlines
      if (title != null) {
        title = title.replaceAll(RegExp(r'\s+'), ' ');
      }
      if (description != null) {
        description = description.replaceAll(RegExp(r'\s+'), ' ');
      }

      final metadata = LinkMetadata(
        url: urlStr,
        domain: domain,
        title: (title != null && title.isNotEmpty) ? title : domain,
        description: description,
        imageUrl: imageUrl,
        siteName: siteName ?? domain,
        faviconUrl: faviconUrl,
      );

      return metadata;
    } catch (e) {
      debugPrint('LinkMetadataService error for $urlStr: $e');
      final uri = Uri.tryParse(urlStr);
      final domain = uri?.host.replaceFirst(RegExp(r'^www\.'), '') ?? urlStr;
      return _fallbackMetadata(urlStr, domain, uri);
    }
  }

  String _resolveUrl(Uri baseUri, String relativeOrAbsolute) {
    final trimmed = relativeOrAbsolute.trim();
    if (trimmed.startsWith('//')) {
      return '${baseUri.scheme}:$trimmed';
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }
    return baseUri.resolve(trimmed).toString();
  }

  LinkMetadata _fallbackMetadata(String urlStr, String domain, Uri? uri) {
    return LinkMetadata(
      url: urlStr,
      domain: domain.isNotEmpty ? domain : urlStr,
      title: domain.isNotEmpty ? domain : urlStr,
      faviconUrl: (uri != null && uri.hasScheme && uri.host.isNotEmpty)
          ? '${uri.scheme}://${uri.host}/favicon.ico'
          : null,
    );
  }
}
