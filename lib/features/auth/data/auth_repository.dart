import 'dart:async';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/session_storage.dart';

class SessionUser {
  const SessionUser({required this.uid, required this.email});

  final String uid;
  final String email;
}

class AuthRepository {
  AuthRepository(this._apiClient);

  final ApiClient _apiClient;
  final _controller = StreamController<SessionUser?>.broadcast();

  SessionUser? _currentUser;
  AppUser? _currentProfile;

  SessionUser? get currentUser => _currentUser;

  Stream<SessionUser?> authChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  Future<void> restoreSession() async {
    final userJson = await SessionStorage.readUser();
    if (userJson == null) {
      _currentUser = null;
      _currentProfile = null;
      _controller.add(null);
      return;
    }
    _applyUser(userJson);
    _controller.add(_currentUser);
  }

  Future<void> signIn(String email, String password) async {
    final payload = await _apiClient.postJson(
      '/api/auth/login',
      authenticated: false,
      body: {'email': email, 'password': password},
    );
    final token = payload['token']?.toString();
    final user = payload['user'];
    if (token == null || user is! Map<String, dynamic>) {
      throw StateError('Invalid login response from server');
    }

    await SessionStorage.writeSession(token: token, user: user);
    _applyUser(user);
    _controller.add(_currentUser);
  }

  Future<void> register(String email, String password) async {
    final payload = await _apiClient.postJson(
      '/api/auth/register',
      authenticated: false,
      body: {'email': email, 'password': password},
    );
    final token = payload['token']?.toString();
    final user = payload['user'];
    if (token == null || user is! Map<String, dynamic>) {
      throw StateError('Invalid register response from server');
    }

    await SessionStorage.writeSession(token: token, user: user);
    _applyUser(user);
    _controller.add(_currentUser);
  }

  Future<void> signOut() async {
    try {
      await _apiClient.post('/api/auth/logout');
    } catch (_) {
      // Ignore network errors and clear local session regardless.
    }
    await SessionStorage.clear();
    _currentUser = null;
    _currentProfile = null;
    _controller.add(null);
  }

  Future<AppUser?> fetchProfile(String uid) async {
    if (_currentProfile != null && _currentProfile!.uid == uid) {
      return _currentProfile;
    }

    final payload = await _apiClient.getJson('/api/auth/me');
    final user = payload['user'];
    if (user is! Map<String, dynamic>) return null;

    final profile = _profileFromApi(user);
    _currentProfile = profile;
    _currentUser = SessionUser(uid: profile.uid, email: profile.email);
    return profile;
  }

  Future<void> upsertUser(AppUser user) async {
    await _apiClient.post('/api/auth/sync-profile', body: {
      'displayName': user.displayName,
      'phone': user.phone,
      'role': user.role.name,
      'email': user.email,
    });
  }

  Future<void> completeOnboarding({
    required String uid,
    required String email,
    required UserRole role,
    required String displayName,
    String? phone,
    String? bio,
    List<String> niches = const [],
    String? companyName,
  }) async {
    await _apiClient.post('/api/auth/sync-profile', body: {
      'displayName': displayName,
      'phone': phone,
      'role': role.name,
      'email': email,
      'bio': bio,
      'niches': niches,
      'companyName': companyName,
    });

    final payload = await _apiClient.getJson('/api/auth/me');
    final user = payload['user'];
    if (user is Map<String, dynamic>) {
      final existingToken = await SessionStorage.readToken();
      if (existingToken != null) {
        await SessionStorage.writeSession(token: existingToken, user: user);
      }
      _applyUser(user);
      _controller.add(_currentUser);
    }
  }

  Future<void> chooseRole(UserRole role) async {
    final payload = await _apiClient.getJson('/api/auth/me');
    final user = payload['user'];
    if (user is! Map<String, dynamic>) {
      throw StateError('Unable to load current user profile');
    }

    final email = user['email']?.toString() ?? _currentUser?.email ?? '';
    final currentName = user['display_name']?.toString().trim() ?? '';
    final displayName = _normalizeDisplayName(
      currentName: currentName,
      email: email,
    );

    await _apiClient.post('/api/auth/sync-profile', body: {
      'displayName': displayName,
      'phone': user['phone']?.toString(),
      'role': role.name,
      'email': email,
      'bio': role == UserRole.creator ? '' : null,
      'niches': const <String>[],
      'companyName': role == UserRole.business ? displayName : null,
    });

    final refreshed = await _apiClient.getJson('/api/auth/me');
    final updatedUser = refreshed['user'];
    if (updatedUser is Map<String, dynamic>) {
      final existingToken = await SessionStorage.readToken();
      if (existingToken != null) {
        await SessionStorage.writeSession(
            token: existingToken, user: updatedUser);
      }
      _applyUser(updatedUser);
      _controller.add(_currentUser);
    }
  }

  String _normalizeDisplayName({
    required String currentName,
    required String email,
  }) {
    if (currentName.isNotEmpty &&
        currentName.toLowerCase() != 'promo zone user') {
      return currentName;
    }

    final localPart = email.split('@').first.trim();
    if (localPart.isEmpty) return 'New User';
    return localPart;
  }

  void _applyUser(Map<String, dynamic> user) {
    final profile = _profileFromApi(user);
    _currentProfile = profile;
    _currentUser = SessionUser(uid: profile.uid, email: profile.email);
  }

  AppUser _profileFromApi(Map<String, dynamic> user) {
    return AppUser(
      uid: user['id']?.toString() ?? '',
      role: parseRole(user['role']?.toString() ?? 'creator'),
      displayName: user['display_name']?.toString() ?? 'Promo Zone User',
      email: user['email']?.toString() ?? '',
      phone: user['phone']?.toString(),
      createdAt: parseDate(user['created_at']),
      updatedAt: parseDate(user['updated_at']),
    );
  }
}
