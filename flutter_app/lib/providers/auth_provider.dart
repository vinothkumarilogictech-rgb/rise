import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/user_model.dart';

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();
  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;
  bool _isOnboarded = false;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isOnboarded => _isOnboarded;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isOnboarded = prefs.getBool('is_onboarded') ?? false;

    final token = await _api.getToken();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final res = await _api.get('/auth/me');
      final prefsRes = await _api.get('/preferences').catchError((_) => null);
      _user = UserModel.fromJson(res, prefs: prefsRes);
      _status = AuthStatus.authenticated;
    } catch (e) {
      if (e is ApiException && e.statusCode == 401) {
        await _api.clearToken();
        _user = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return;
      }
      // Offline fallback: if network error, allow cached offline state
      final cachedName = prefs.getString('cached_user_name') ?? 'Climber';
      final cachedUsername = prefs.getString('cached_user_username') ?? 'climber';
      final cachedId = prefs.getString('cached_user_id') ?? 'offline_user';
      _user = UserModel(id: cachedId, username: cachedUsername, displayName: cachedName);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String username,
    required String password,
    String? displayName,
    int? availableDailyMinutes,
    String? planningStyle,
    String? reminderTime,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanUsername = username.trim().toLowerCase();
      final cleanDisplayName = displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : username.trim();

      final res = await _api.post('/auth/register', body: {
        'username': cleanUsername,
        'password': password,
        'display_name': cleanDisplayName,
        'available_daily_minutes': availableDailyMinutes ?? 120,
        'planning_style': planningStyle ?? 'balanced',
        'reminder_time': reminderTime ?? '08:00',
      });

      final token = res['access_token'];
      await _api.setToken(token);

      final userJson = res['user'];
      _user = UserModel.fromJson(userJson);
      _status = AuthStatus.authenticated;
      _isOnboarded = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);
      await prefs.setString('cached_user_name', _user!.displayName);
      await prefs.setString('cached_user_username', _user!.username);
      await prefs.setString('cached_user_id', _user!.id);

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Registration failed. Please check network connection.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanUsername = username.trim().toLowerCase();
      final res = await _api.post('/auth/login', body: {
        'username': cleanUsername,
        'password': password,
      });

      final token = res['access_token'];
      await _api.setToken(token);

      final userJson = res['user'];
      final prefsRes = await _api.get('/preferences').catchError((_) => null);
      _user = UserModel.fromJson(userJson, prefs: prefsRes);
      _status = AuthStatus.authenticated;
      _isOnboarded = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_onboarded', true);
      await prefs.setString('cached_user_name', _user!.displayName);
      await prefs.setString('cached_user_username', _user!.username);
      await prefs.setString('cached_user_id', _user!.id);

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Login failed. Please check network connection.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> updatePreferences({
    String? displayName,
    int? availableDailyMinutes,
    String? planningStyle,
    String? reminderTime,
  }) async {
    try {
      final res = await _api.patch('/preferences', body: {
        if (displayName != null) 'display_name': displayName,
        if (availableDailyMinutes != null) 'available_daily_minutes': availableDailyMinutes,
        if (planningStyle != null) 'planning_style': planningStyle,
        if (reminderTime != null) 'reminder_time': reminderTime,
      });

      if (_user != null) {
        _user = _user!.copyWith(
          displayName: res['display_name'] ?? _user!.displayName,
          availableDailyMinutes: res['available_daily_minutes'] ?? _user!.availableDailyMinutes,
          planningStyle: res['planning_style'] ?? _user!.planningStyle,
          reminderTime: res['reminder_time'] ?? _user!.reminderTime,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markOnboarded() async {
    _isOnboarded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarded', true);
    notifyListeners();
  }

  Future<void> logout() async {
    await _api.clearToken();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
