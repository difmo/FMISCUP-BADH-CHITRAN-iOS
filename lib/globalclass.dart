import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class GlobalClass {
  static Future<bool?> customToast(String message) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black54,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static Future<bool> checkInternet() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none);
  }

  static void logRequest(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    print('--- HTTP REQUEST ---');
    print('URL: $url');
    if (headers != null) print('Headers: ${jsonEncode(headers)}');
    if (body != null) print('Body: ${jsonEncode(body)}');
    print('--------------------');
  }

  static void logResponse(String url, int statusCode, String body) {
    print('--- HTTP RESPONSE ---');
    print('URL: $url');
    print('Status Code: $statusCode');
    try {
      final decodedBody = jsonDecode(body);
      final prettyBody = JsonEncoder.withIndent('  ').convert(decodedBody);
      print('Body: $prettyBody');
    } catch (_) {
      print('Body: $body');
    }
    print('---------------------');
  }
}
