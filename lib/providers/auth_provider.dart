import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../core/api_client.dart';
import '../core/socket_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiClient apiClient;
  Map<String, dynamic>? _user;
  String _language = 'EN';
  ThemeMode _themeMode = ThemeMode.dark;
  List<dynamic> _continueWatching = [];
  List<dynamic> _watchlist = [];
  List<dynamic> _notifications = [];
  Map<String, dynamic> _preferences = {'audio': 'sub', 'server': 'hd-1'};

  Map<String, dynamic> _ignoredFolders = {
    'watching': false,
    'onHold': false,
    'planToWatch': false,
    'dropped': false,
    'completed': false,
  };

  Map<String, dynamic>? get user => _user;
  String get language => _language;
  ThemeMode get themeMode => _themeMode;
  List<dynamic> get continueWatching => _continueWatching;
  List<dynamic> get watchlist => _watchlist;
  List<dynamic> get notifications => _notifications;
  Map<String, dynamic> get preferences => _preferences;
  Map<String, dynamic> get ignoredFolders => _ignoredFolders;
  bool get isLoggedIn => _user != null;

  AuthProvider(this.apiClient) {
    // Listen to unauthorized event from ApiClient
    apiClient.onUnauthorized.listen((_) {
      logout();
    });
    restoreSession();
  }

  void _updateIgnoredFolders() {
    if (_user != null && _user!['notificationIgnore'] != null) {
      final ignore = _user!['notificationIgnore'];
      _ignoredFolders = {
        'watching': ignore['watching'] ?? false,
        'onHold': ignore['on_hold'] ?? false,
        'planToWatch': ignore['plan_to_watch'] ?? false,
        'dropped': ignore['dropped'] ?? false,
        'completed': ignore['completed'] ?? false,
      };
    } else {
      _ignoredFolders = {
        'watching': false,
        'onHold': false,
        'planToWatch': false,
        'dropped': false,
        'completed': false,
      };
    }
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedTheme = prefs.getString('themeMode');
      if (storedTheme != null) {
        _themeMode = storedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      }
      final storedLang = prefs.getString('language');
      if (storedLang != null) {
        _language = storedLang;
      }
      final storedUser = prefs.getString('user');
      final storedToken = prefs.getString('token');

      if (storedUser != null && storedToken != null) {
        _user = json.decode(storedUser);
        _updateIgnoredFolders();
        notifyListeners();
        
        _initSocket(storedToken);
        
        await fetchContinueWatching();
        await fetchWatchlist();
        await fetchNotifications();
        await fetchPreferences();
        return;
      }

      if (storedToken != null) {
        // Fetch profile
        final res = await apiClient.dio.get('/auth/me');
        if (res.statusCode == 200 && res.data != null && res.data['data'] != null) {
          _user = res.data['data'];
          _updateIgnoredFolders();
          await prefs.setString('user', json.encode(_user));
          notifyListeners();
          
          _initSocket(storedToken);
          
          await fetchContinueWatching();
          await fetchWatchlist();
          await fetchNotifications();
          await fetchPreferences();
        }
      }
    } catch (e) {
      debugPrint('Restore session failed: $e');
      logout();
    }
  }

  Future<void> login(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', userData['token']);
      await prefs.setString('user', json.encode(userData));
      _user = userData;
      _updateIgnoredFolders();
      notifyListeners();

      _initSocket(userData['token']);

      await fetchContinueWatching();
      await fetchWatchlist();
      await fetchNotifications();
      await fetchPreferences();
    } catch (e) {
      debugPrint('Login state update failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      _socketSubscription?.cancel();
      _socketSubscription = null;
      SocketService().disconnect();

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      _user = null;
      _continueWatching = [];
      _watchlist = [];
      _notifications = [];
      _ignoredFolders = {
        'watching': false,
        'onHold': false,
        'planToWatch': false,
        'dropped': false,
        'completed': false,
      };
      notifyListeners();
    } catch (e) {
      debugPrint('Logout state update failed: $e');
    }
  }

  Future<void> fetchContinueWatching() async {
    if (!isLoggedIn) return;
    try {
      final res = await apiClient.dio.get('/continue-watching');
      if (res.data != null && res.data['data'] != null) {
        _continueWatching = res.data['data'] as List<dynamic>;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch continue watching: $e');
    }
  }

  Future<void> clearContinueWatching() async {
    if (!isLoggedIn) return;
    try {
      await apiClient.dio.delete('/continue-watching');
      _continueWatching = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear continue watching: $e');
    }
  }

  Future<void> removeContinueWatching(String animeId) async {
    if (!isLoggedIn) return;
    try {
      await apiClient.dio.delete('/continue-watching/$animeId');
      _continueWatching.removeWhere((item) => item['animeId'] == animeId);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove continue watching: $e');
      rethrow;
    }
  }


  Future<List<dynamic>> fetchWatchlist([Map<String, dynamic>? status]) async {
    if (!isLoggedIn) return [];
    try {
      final res = await apiClient.dio.get(
        '/watchlist',
        queryParameters: status,
      );
      if (res.data != null && res.data['data'] != null) {
        final list = res.data['data'] as List<dynamic>;
        if (status == null) {
          _watchlist = list;
          notifyListeners();
        }
        return list;
      }
    } catch (e) {
      debugPrint('Failed to fetch watchlist: $e');
    }
    return [];
  }

  Future<void> fetchPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!isLoggedIn) {
      final stored = prefs.getString('preferences');
      if (stored != null) {
        _preferences = json.decode(stored) as Map<String, dynamic>;
        notifyListeners();
      }
      return;
    }

    try {
      final res = await apiClient.dio.get('/users/preferences');
      if (res.data != null && res.data['success'] == true && res.data['data'] != null) {
        _preferences = res.data['data'] as Map<String, dynamic>;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch preferences: $e');
    }
  }

  Future<void> updatePreferences(Map<String, dynamic> newPrefs) async {
    _preferences = {..._preferences, ...newPrefs};
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (!isLoggedIn) {
      await prefs.setString('preferences', json.encode(_preferences));
      return;
    }

    try {
      await apiClient.dio.put('/users/preferences', data: newPrefs);
    } catch (e) {
      debugPrint('Failed to update preferences: $e');
    }
  }

  Future<void> fetchNotifications() async {
    if (!isLoggedIn) return;
    try {
      final res = await apiClient.dio.get('/notification');
      if (res.data != null && res.data['data'] != null) {
        _notifications = res.data['data'] as List<dynamic>;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch notifications: $e');
    }
  }

  Future<void> updateWatchlist(String id, String status) async {
    if (!isLoggedIn) return;
    try {
      final res = await apiClient.dio.put('/watchlist/$id', data: {'status': status});
      if (res.data != null && res.data['data'] != null) {
        final updatedItem = res.data['data'];
        final index = _watchlist.indexWhere((item) => item['_id'] == updatedItem['_id']);
        if (index != -1) {
          _watchlist[index] = updatedItem;
        } else {
          _watchlist.insert(0, updatedItem);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update watchlist: $e');
      rethrow;
    }
  }

  Future<void> addWatchlist(String animeId, String animeTitle, String animeImage, String status) async {
    if (!isLoggedIn) return;
    try {
      final res = await apiClient.dio.post('/watchlist', data: {
        'animeId': animeId,
        'animeTitle': animeTitle,
        'animeImage': animeImage,
        'status': status,
      });
      if (res.data != null && res.data['data'] != null) {
        final updatedItem = res.data['data'];
        _watchlist.insert(0, updatedItem);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to add watchlist: $e');
    }
  }

  Future<void> removeWatchlist(String id) async {
    if (!isLoggedIn) return;
    try {
      await apiClient.dio.delete('/watchlist/$id');
      _watchlist.removeWhere((item) => item['_id'] == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to remove watchlist: $e');
    }
  }

  Future<void> markRead(String notificationId) async {
    if (!isLoggedIn) return;
    try {
      await apiClient.dio.put('/notification/$notificationId/read');
      _notifications = _notifications.map((item) {
        if (item['_id'] == notificationId) {
          final copy = Map<String, dynamic>.from(item);
          copy['read'] = true;
          return copy;
        }
        return item;
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to mark notification read: $e');
    }
  }

  Future<void> clearNotifications() async {
    if (!isLoggedIn) return;
    try {
      await apiClient.dio.delete('/notification/clear');
      _notifications = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to clear notifications: $e');
    }
  }

  Future<void> updateProgress(Map<String, dynamic> progressData) async {
    if (!isLoggedIn) return;
    try {
      final res = await apiClient.dio.post('/continue-watching', data: progressData);
      if (res.data != null && res.data['data'] != null) {
        final updated = res.data['data'];
        final index = _continueWatching.indexWhere((i) => i['animeId'] == updated['animeId']);
        if (index != -1) {
          _continueWatching.removeAt(index);
        }
        _continueWatching.insert(0, updated);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update progress: $e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    if (!isLoggedIn) return;
    try {
      final res = await apiClient.dio.put('/users/profile', data: profileData);
      if (res.data != null && res.data['data'] != null) {
        _user = res.data['data'];
        _updateIgnoredFolders();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update profile: $e');
    }
  }

  Future<void> updateSettings(Map<String, dynamic> settings) async {
    if (!isLoggedIn) return;
    try {
      final res = await apiClient.dio.put('/users/settings', data: settings);
      if (res.data != null && res.data['data'] != null) {
        _user = res.data['data'];
        _updateIgnoredFolders();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update settings: $e');
    }
  }

  Future<void> setLanguage(String lang) async {
    _language = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', lang);
    } catch (e) {
      debugPrint('Failed to save language: $e');
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeMode == ThemeMode.light ? 'light' : 'dark');
  }

  // Real-time socket methods
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;

  void _initSocket(String token) {
    _socketSubscription?.cancel();
    
    final socketService = SocketService();
    socketService.connect(ApiClient.baseUrl, token);
    
    _socketSubscription = socketService.notifications.listen((notif) {
      final exists = _notifications.any((n) => n['_id'] == notif['_id']);
      if (!exists) {
        _notifications.insert(0, notif);
        notifyListeners();
        _playNotificationSound();
      }
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      await _audioPlayer.play(AssetSource('notification.mp3'));
    } catch (e) {
      debugPrint('Failed to play notification sound: $e');
    }
  }

  @override
  void dispose() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _audioPlayer.dispose();
    super.dispose();
  }
}
