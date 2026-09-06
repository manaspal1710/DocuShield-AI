import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static String _customBaseUrl = '';

  static void setBaseUrl(String url) {
    _customBaseUrl = url.trim();
    if (_customBaseUrl.endsWith('/')) {
      _customBaseUrl = _customBaseUrl.substring(0, _customBaseUrl.length - 1);
    }
  }

  static String get baseUrl {
    if (_customBaseUrl.isNotEmpty) {
      return _customBaseUrl;
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Default to public HTTPS tunnel so app works on any Wi-Fi or mobile data
      return 'https://hunt-composite-relatively-boc.trycloudflare.com';
    } else {
      return 'http://localhost:8000';
    }
  }
  
  static const String verify = '/api/v1/verify';
  static const String ocr = '/api/v1/ocr';
  static const String tampering = '/api/v1/tampering';
  static const String face = '/api/v1/face';
}
