import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:atmos_frontend/core/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple in-memory auth state manager.
class AuthState extends ChangeNotifier {
  static final AuthState _instance = AuthState._internal();
  factory AuthState() => _instance;
  AuthState._internal();

  bool _isSignedIn = false;
  String? _uid;
  String? _userEmail;
  String? _displayName;
  String? _base64ProfileImage;

  // Global Settings preferences
  String _theme = 'Light Mode';
  String _units = '°C, mm, km, kmph, hPa, 12 h';
  String _notification = 'On';
  bool _acceptedTerms = false;

  bool get isSignedIn => _isSignedIn;
  String? get uid => _uid;
  String? get userEmail => _userEmail;
  String? get displayName => _displayName;
  String? get base64ProfileImage => _base64ProfileImage;

  String get theme => _theme;
  String get units => _units;
  String get notification => _notification;
  bool get acceptedTerms => _acceptedTerms;

  Future<void> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    _isSignedIn = prefs.getBool('isSignedIn') ?? false;
    _uid = prefs.getString('uid');
    _userEmail = prefs.getString('userEmail');
    _displayName = prefs.getString('displayName');
    _base64ProfileImage = prefs.getString('base64ProfileImage');
    
    _theme = prefs.getString('theme') ?? 'Light Mode';
    _units = prefs.getString('units') ?? '°C, mm, km, kmph, hPa, 12 h';
    _notification = prefs.getString('notification') ?? 'On';
    _acceptedTerms = prefs.getBool('acceptedTerms') ?? false;
    notifyListeners();
  }

  Future<void> signIn(String email, {String? displayName, String? uid, String? photoUrl, String? notification, String? theme}) async {
    _isSignedIn = true;
    _userEmail = email;
    if (uid != null && uid.isNotEmpty) _uid = uid;
    if (displayName != null && displayName.isNotEmpty) _displayName = displayName;
    if (photoUrl != null && photoUrl.isNotEmpty) _base64ProfileImage = photoUrl;
    if (notification != null && notification.isNotEmpty) _notification = notification;
    if (theme != null && theme.isNotEmpty) _theme = theme;
    
    await _persistAuth();
    notifyListeners();
  }

  Future<void> updateProfile({String? name, String? email, String? base64Image}) async {
    if (name != null) _displayName = name;
    if (email != null) _userEmail = email;
    if (base64Image != null) _base64ProfileImage = base64Image;
    await _persistAuth();
    notifyListeners();
  }
  
  Future<void> updateSettingTheme(String setting) async {
    _theme = setting;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', setting);
    notifyListeners();

    if (_isSignedIn && _uid != null) {
      try {
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$_uid'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'theme': setting}),
        );
      } catch (_) {}
    }
  }
  
  Future<void> updateSettingUnits(String setting) async {
    _units = setting;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('units', setting);
    notifyListeners();
  }
  
  Future<void> updateSettingNotification(String setting) async {
    _notification = setting;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notification', setting);
    notifyListeners();

    if (_isSignedIn && _uid != null) {
      try {
        await http.put(
          Uri.parse('${ApiConfig.baseUrl}/api/admin/users/$_uid'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'notification': setting}),
        );
      } catch (_) {}
    }
  }

  Future<void> acceptTerms() async {
    _acceptedTerms = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', true);
    notifyListeners();
  }

  Future<void> revokeTerms() async {
    _acceptedTerms = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('acceptedTerms', false);
    notifyListeners();
  }

  Future<void> _persistAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSignedIn', _isSignedIn);
    if (_uid != null) await prefs.setString('uid', _uid!);
    if (_userEmail != null) await prefs.setString('userEmail', _userEmail!);
    if (_displayName != null) await prefs.setString('displayName', _displayName!);
    if (_base64ProfileImage != null) await prefs.setString('base64ProfileImage', _base64ProfileImage!);
  }

  Future<void> signOut() async {
    _isSignedIn = false;
    _uid = null;
    _userEmail = null;
    _displayName = null;
    _base64ProfileImage = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isSignedIn');
    await prefs.remove('uid');
    await prefs.remove('userEmail');
    await prefs.remove('displayName');
    await prefs.remove('base64ProfileImage');
    // keep settings/terms intact locally, just sign out user
    notifyListeners();
  }
}
