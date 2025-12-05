import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class LinkScraperService {
  /// Scrapes a public Google Photos shared link and returns a list of image URLs.
  ///
  /// This works by fetching the HTML and looking for the JSON blob that contains
  /// the media items. This is a reverse-engineered approach and may break if
  /// Google changes their frontend structure.
  Future<List<String>> scrapePhotos(String url) async {
    debugPrint('LinkScraper: Fetching URL: $url');

    // Follow redirects for shortened URLs
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 10; Pixel 4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch URL: ${response.statusCode}');
    }

    debugPrint(
      'LinkScraper: Response received (${response.body.length} bytes), parsing HTML...',
    );

    // Log a sample of the response for debugging
    if (kDebugMode) {
      final sample = response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body;
      debugPrint('LinkScraper: HTML sample: $sample');
    }

    final document = parser.parse(response.body);

    // Try multiple approaches to find image URLs

    // Approach 1: Look for script tags with AF_initDataCallback
    final scriptTags = document.getElementsByTagName('script');
    debugPrint('LinkScraper: Found ${scriptTags.length} script tags');

    // Approach 2: Try to find ANY googleusercontent.com URLs in the entire page
    final allUrls = <String>{};
    final urlPattern = RegExp(
      r'https://lh3\.googleusercontent\.com/[^\s"<>\\]+',
      multiLine: true,
    );

    // Search in the entire response body
    final matches = urlPattern.allMatches(response.body);
    debugPrint(
      'LinkScraper: Found ${matches.length} total URL matches in HTML',
    );

    for (final match in matches) {
      var url = match.group(0)!;
      // Clean up the URL
      url = url.split('\\').first.split('"').first.split("'").first;

      // Filter out thumbnails and small images
      if (url.contains('=')) {
        // Skip small thumbnails
        if (url.contains('=s64') ||
            url.contains('=s96') ||
            url.contains('=s128') ||
            url.contains('=s48')) {
          continue;
        }
        allUrls.add(url);
      }
    }

    debugPrint(
      'LinkScraper: Found ${allUrls.length} potential image URLs after filtering',
    );

    // Approach 3: Look for meta tags with og:image
    final metaTags = document.getElementsByTagName('meta');
    for (final meta in metaTags) {
      final property = meta.attributes['property'];
      final content = meta.attributes['content'];
      if (property == 'og:image' &&
          content != null &&
          content.contains('googleusercontent')) {
        debugPrint('LinkScraper: Found og:image: $content');
        allUrls.add(content);
      }
    }

    if (allUrls.isEmpty) {
      // Last resort: check if this is actually a valid Google Photos link
      if (!url.contains('photos.google.com') &&
          !url.contains('photos.app.goo.gl')) {
        throw Exception(
          'Invalid Google Photos link. '
          'Please use a link from photos.google.com or photos.app.goo.gl',
        );
      }

      throw Exception(
        'Could not find any photos in the page. This may happen if:\n'
        '1. The album link is not set to public/shared\n'
        '2. The album is empty\n'
        '3. Google has changed their page structure\n\n'
        'Please ensure you:\n'
        '1. Created a shared link in Google Photos\n'
        '2. Set sharing to "Anyone with the link"\n'
        '3. The album contains photos',
      );
    }

    debugPrint('LinkScraper: Returning ${allUrls.length} image URLs');
    return allUrls.toList();
  }
}
