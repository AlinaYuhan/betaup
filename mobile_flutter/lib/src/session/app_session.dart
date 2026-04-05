import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api_client.dart';
import '../data/models.dart';

class AppSession extends ChangeNotifier {
  AppSession() {
    api = ApiClient(readToken: () => _token);
  }

  late final ApiClient api;

  static const _storageKey = "betaup.auth";

  String? _token;
  UserProfile? _user;
  bool _isInitializing = true;

  bool get isInitializing => _isInitializing;
  bool get isAuthenticated =>
      (_token?.isNotEmpty ?? false) && _user != null;
  String? get token => _token;
  UserProfile? get user => _user;

  Future<void> initialize() async {
    _isInitializing = true;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    final storedAuth = preferences.getString(_storageKey);

    if (storedAuth == null || storedAuth.isEmpty) {
      _isInitializing = false;
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(storedAuth) as Map<String, dynamic>;
      _token = decoded["token"] as String?;
      if (_token == null || _token!.isEmpty) {
        await preferences.remove(_storageKey);
      } else {
        _user = UserProfile.fromJson(
          Map<String, dynamic>.from(decoded["user"] as Map),
        );
        _user = await api.fetchCurrentUser();
        await _persist();
      }
    } catch (_) {
      await preferences.remove(_storageKey);
      _token = null;
      _user = null;
    }

    _isInitializing = false;
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final auth = await api.login(email: email, password: password);
    _token = auth.token;
    _user = auth.user;
    await _persist();
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final auth = await api.register(
      name: name,
      email: email,
      password: password,
      role: role,
    );
    _token = auth.token;
    _user = auth.user;
    await _persist();
    notifyListeners();
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_token == null || _token!.isEmpty || _user == null) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode({
        "token": _token,
        "user": _user!.toJson(),
      }),
    );
  }
}

class SessionScope extends InheritedNotifier<AppSession> {
  const SessionScope({
    required AppSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, "SessionScope not found in widget tree.");
    return scope!.notifier!;
  }
}
