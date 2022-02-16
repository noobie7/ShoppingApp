import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/http_exception.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class Auth with ChangeNotifier {
  String? _token = null;
  DateTime? _expiryDate = null;
  String? _userId = null;
  Timer? _authTimer = null;

  bool get isAuth {
    return _token != null;
  }

  String? get token {
    if (_expiryDate != null &&
        _expiryDate!.isAfter(DateTime.now()) &&
        _token != null) {
      return _token;
    }
    return null;
  }

  String? get userId {
    return _userId;
  }

  Future<void> authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.https(
      'identitytoolkit.googleapis.com',
      '/v1/accounts:$urlSegment',
      {
        "key": 'AIzaSyBSYd8sCK_yFlsR3zvKdKEr35lFw6MGo4g',
      },
    );
    print(url);
    try {
      final response = await http.post(
        url,
        body: json.encode(
          {
            "email": email,
            "password": password,
            "returnSecureToken": true,
          },
        ),
      );
      final responseData = json.decode(response.body);

      _token = responseData['idToken'];
      _userId = responseData['localId'];
      _expiryDate = DateTime.now().add(
        Duration(
          seconds: int.parse(responseData['expiresIn']),
        ),
      );
      _autoLogout();
      notifyListeners();
      final prefs = await SharedPreferences.getInstance();
      final userData = json.encode(
        {
          'token': _token,
          'userId': _userId,
          'expiryDate': _expiryDate!.toIso8601String()
        },
      );
      prefs.setString('userData', userData);
    } catch (e) {
      print('failing at authenticate');
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    return authenticate(email, password, 'signUp');
  }

  Future<void> logIn(String email, String password) async {
    return authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('userData')) {
      return false;
    }
    final extractedData = json.decode(prefs.getString('userData') as String)
        as Map<String, Object>;
    final expiryDate = DateTime.parse(extractedData['expiryDate'] as String);

    if (expiryDate.isBefore(DateTime.now())) {
      return false;
    }
    _token = extractedData['token'] as String;
    _userId = extractedData['userId'] as String;
    _expiryDate = expiryDate;
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _expiryDate = null;
    _userId = null;
    if (_authTimer != null) {
      _authTimer!.cancel();
      _authTimer = null;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  void _autoLogout() {
    if (_authTimer != null) {
      _authTimer!.cancel();
    }
    final timeToExpiry = _expiryDate!.difference(DateTime.now()).inSeconds;
    _authTimer = Timer(Duration(seconds: timeToExpiry), logout);
  }
}
