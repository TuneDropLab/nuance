import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GeoContext {
  final String city;
  final String country;
  final String countryCode;
  final String source;

  const GeoContext({
    required this.city,
    required this.country,
    required this.countryCode,
    required this.source,
  });

  @override
  String toString() => '$city, $country ($countryCode) [$source]';
}

class GeoService {
  static final GeoService _instance = GeoService._internal();
  factory GeoService() => _instance;
  GeoService._internal();

  GeoContext? _cachedContext;

  Future<GeoContext> resolveContext() async {
    if (_cachedContext != null) {
      return _cachedContext!;
    }

    // Tier 1 & 2: Query public lightweight HTTPS geo service (zero permissions, zero prompts)
    try {
      final response = await http
          .get(Uri.parse('https://ipwho.is/'))
          .timeout(const Duration(milliseconds: 2500));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          final city = (data['city'] ?? '').toString();
          final country = (data['country'] ?? '').toString();
          final code = (data['country_code'] ?? '').toString();

          _cachedContext = GeoContext(
            city: city.isNotEmpty ? city : 'Local',
            country: country.isNotEmpty ? country : 'Global',
            countryCode: code.isNotEmpty ? code : 'US',
            source: 'ip_lookup',
          );
          return _cachedContext!;
        }
      }
    } catch (e) {
      debugPrint('GeoService Tier 2 ipwho.is fallback: $e');
    }

    // Tier 2b fallback: ipapi.co
    try {
      final response = await http
          .get(Uri.parse('https://ipapi.co/json/'))
          .timeout(const Duration(milliseconds: 2000));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final city = (data['city'] ?? '').toString();
        final country = (data['country_name'] ?? '').toString();
        final code = (data['country_code'] ?? '').toString();

        _cachedContext = GeoContext(
          city: city.isNotEmpty ? city : 'Local',
          country: country.isNotEmpty ? country : 'Global',
          countryCode: code.isNotEmpty ? code : 'US',
          source: 'ipapi_fallback',
        );
        return _cachedContext!;
      }
    } catch (e) {
      debugPrint('GeoService Tier 2b ipapi fallback: $e');
    }

    // Tier 3: Cross-platform device locale fallback (zero network, zero permissions)
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final countryCode = locale.countryCode?.toUpperCase() ?? 'US';
    final countryName = _mapCountryCode(countryCode);

    _cachedContext = GeoContext(
      city: 'Local',
      country: countryName,
      countryCode: countryCode,
      source: 'device_locale',
    );
    return _cachedContext!;
  }

  static String _mapCountryCode(String code) {
    const map = {
      'US': 'United States',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'NG': 'Nigeria',
      'GH': 'Ghana',
      'KE': 'Kenya',
      'ZA': 'South Africa',
      'FR': 'France',
      'DE': 'Germany',
      'JP': 'Japan',
      'BR': 'Brazil',
      'AU': 'Australia',
      'IN': 'India',
    };
    return map[code] ?? 'Global';
  }
}
