import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humble_photo_contest/data/services/link_scraper_service.dart';

final linkScraperServiceProvider = Provider<LinkScraperService>((ref) {
  return LinkScraperService();
});
