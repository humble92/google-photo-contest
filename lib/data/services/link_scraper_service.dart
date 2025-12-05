import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

class LinkScraperService {
  /// Scrapes a public Google Photos shared link and returns a list of image URLs.
  ///
  /// This works by fetching the HTML and looking for the JSON blob that contains
  /// the media items. This is a reverse-engineered approach and may break if
  /// Google changes their frontend structure.
  Future<List<String>> scrapePhotos(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch URL: ${response.statusCode}');
    }

    final document = parser.parse(response.body);

    // The data is usually embedded in a script tag with a specific callback.
    // We look for "AF_initDataCallback" which contains the initial data.
    // There are multiple callbacks, we need the one with the key 'ds:0' or similar
    // that contains the media items.

    // Heuristic: The script usually starts with "AF_initDataCallback".
    // We regex for the JSON content.

    final scriptTags = document.getElementsByTagName('script');
    String? dataScript;

    for (final script in scriptTags) {
      if (script.text.contains('AF_initDataCallback') &&
          script.text.contains('ds:0')) {
        // ds:0 often contains the main album data
        dataScript = script.text;
        break;
      }
    }

    if (dataScript == null) {
      // Fallback: Try to find any script with a large array of URLs
      // Or maybe the key changed.
      throw Exception('Could not find photo data in the page.');
    }

    // Extract the JSON part
    // Format: AF_initDataCallback({key: 'ds:0', hash: '...', data: [...] ...});
    // We want the 'data' array.

    // Regex to capture the data array: data: (.*), sideChannel:
    final regex = RegExp(r'data: (.*), sideChannel:');
    final match = regex.firstMatch(dataScript);

    if (match == null || match.groupCount < 1) {
      throw Exception('Could not parse JSON data.');
    }

    final jsonString = match.group(1)!;

    try {
      final List<dynamic> data = json.decode(jsonString);

      // The structure is deeply nested.
      // data[1] is usually the list of media items.
      final List<dynamic> mediaItems = data[1];

      final List<String> imageUrls = [];

      for (final item in mediaItems) {
        // item[1][0] is usually the URL
        // item[0] is the ID
        if (item is List && item.length > 1) {
          final url = item[1][0] as String;
          imageUrls.add(url);
        }
      }

      return imageUrls;
    } catch (e) {
      throw Exception('Failed to parse internal JSON structure: $e');
    }
  }
}
