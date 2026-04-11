import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({
    required this.readToken,
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl();

  final String? Function() readToken;
  final http.Client _httpClient;
  final String baseUrl;

  static String _defaultBaseUrl() {
    const override = String.fromEnvironment("BETAUP_API_BASE_URL");
    if (override.isNotEmpty) {
      return override;
    }

    if (!kIsWeb && Platform.isAndroid) {
      return "http://10.0.2.2:8080/api";
    }
    return "http://127.0.0.1:8080/api";
  }

  Future<UserProfile> fetchCurrentUser() async {
    final data = await _send("GET", "/auth/me");
    return UserProfile.fromJson(JsonMap.from(data as Map));
  }

  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final data = await _send(
      "POST",
      "/auth/login",
      body: {
        "email": email.trim(),
        "password": password,
      },
    );
    return AuthPayload.fromJson(JsonMap.from(data as Map));
  }

  Future<AuthPayload> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final data = await _send(
      "POST",
      "/auth/register",
      body: {
        "name": name.trim(),
        "email": email.trim(),
        "password": password,
        "role": role.rawValue,
      },
    );
    return AuthPayload.fromJson(JsonMap.from(data as Map));
  }

  Future<DashboardSummary> fetchDashboard(String range) async {
    final data = await _send(
      "GET",
      "/dashboard",
      queryParameters: {"range": range},
    );
    return DashboardSummary.fromJson(JsonMap.from(data as Map));
  }

  Future<PageResult<ClimbLog>> fetchClimbs({
    int page = 0,
    int size = 6,
    String? sortBy,
    String? sortDir,
  }) async {
    final data = await _send(
      "GET",
      "/climbs",
      queryParameters: {
        "page": page,
        "size": size,
        "sortBy": sortBy,
        "sortDir": sortDir,
      },
    );

    return PageResult<ClimbLog>.fromJson(
      JsonMap.from(data as Map),
      ClimbLog.fromJson,
    );
  }

  Future<ClimbLog> fetchClimb(int id) async {
    final data = await _send("GET", "/climbs/$id");
    return ClimbLog.fromJson(JsonMap.from(data as Map));
  }

  Future<ClimbLog> createClimb(JsonMap payload) async {
    final data = await _send("POST", "/climbs", body: payload);
    return ClimbLog.fromJson(JsonMap.from(data as Map));
  }

  Future<ClimbLog> updateClimb(int id, JsonMap payload) async {
    final data = await _send("PUT", "/climbs/$id", body: payload);
    return ClimbLog.fromJson(JsonMap.from(data as Map));
  }

  Future<void> deleteClimb(int id) async {
    await _send("DELETE", "/climbs/$id");
  }

  Future<List<GradeStat>> fetchGradeStats() async {
    final data = await _send("GET", "/climbs/grade-stats");
    return (data as List<dynamic>)
        .map((item) => GradeStat.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  // ── Session API ────────────────────────────────────────────────────────

  Future<ClimbSession> startSession(String venue) async {
    final data = await _send("POST", "/sessions", body: {"venue": venue});
    return ClimbSession.fromJson(JsonMap.from(data as Map));
  }

  /// Returns null when no active session exists.
  Future<ClimbSession?> fetchActiveSession() async {
    final data = await _send("GET", "/sessions/active");
    if (data == null) return null;
    return ClimbSession.fromJson(JsonMap.from(data as Map));
  }

  Future<SessionSummary> endSession(int sessionId) async {
    final data = await _send("POST", "/sessions/$sessionId/end");
    return SessionSummary.fromJson(JsonMap.from(data as Map));
  }

  Future<List<SessionSummary>> fetchSessions({int page = 0, int size = 10}) async {
    final data = await _send(
      "GET",
      "/sessions",
      queryParameters: {"page": page, "size": size},
    );
    if (data == null) return [];
    final result = PageResult<SessionSummary>.fromJson(
      JsonMap.from(data as Map),
      SessionSummary.fromJson,
    );
    return result.items;
  }

  // ── Badge / Feedback ───────────────────────────────────────────────────

  Future<List<BadgeProgress>> fetchBadgeProgress() async {
    final data = await _send("GET", "/badges/progress");
    return (data as List<dynamic>)
        .map((item) => BadgeProgress.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<PageResult<FeedbackEntry>> fetchFeedback({
    int page = 0,
    int size = 6,
    int? climberId,
    int? rating,
    String? sortBy,
    String? sortDir,
  }) async {
    final data = await _send(
      "GET",
      "/feedback",
      queryParameters: {
        "page": page,
        "size": size,
        "climberId": climberId,
        "rating": rating,
        "sortBy": sortBy,
        "sortDir": sortDir,
      },
    );

    return PageResult<FeedbackEntry>.fromJson(
      JsonMap.from(data as Map),
      FeedbackEntry.fromJson,
    );
  }

  Future<FeedbackEntry> fetchFeedbackEntry(int id) async {
    final data = await _send("GET", "/feedback/$id");
    return FeedbackEntry.fromJson(JsonMap.from(data as Map));
  }

  Future<FeedbackEntry> createFeedback(JsonMap payload) async {
    final data = await _send("POST", "/feedback", body: payload);
    return FeedbackEntry.fromJson(JsonMap.from(data as Map));
  }

  Future<FeedbackEntry> updateFeedback(int id, JsonMap payload) async {
    final data = await _send("PUT", "/feedback/$id", body: payload);
    return FeedbackEntry.fromJson(JsonMap.from(data as Map));
  }

  Future<void> deleteFeedback(int id) async {
    await _send("DELETE", "/feedback/$id");
  }

  Future<PageResult<ClimberOverview>> fetchClimbers({
    String? query,
    int page = 0,
    int size = 8,
    String? sortBy,
    String? sortDir,
  }) async {
    final data = await _send(
      "GET",
      "/coach/climbers",
      queryParameters: {
        "q": query,
        "page": page,
        "size": size,
        "sortBy": sortBy,
        "sortDir": sortDir,
      },
    );

    return PageResult<ClimberOverview>.fromJson(
      JsonMap.from(data as Map),
      ClimberOverview.fromJson,
    );
  }

  Future<List<ClimberOverview>> fetchClimberOptions() async {
    final data = await _send("GET", "/coach/climbers/options");
    return (data as List<dynamic>)
        .map((item) => ClimberOverview.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<ClimberDetail> fetchClimberDetail(int id) async {
    final data = await _send("GET", "/coach/climbers/$id");
    return ClimberDetail.fromJson(JsonMap.from(data as Map));
  }

  Future<List<BadgeRule>> fetchBadgeRules() async {
    final data = await _send("GET", "/badges/rules");
    return (data as List<dynamic>)
        .map((item) => BadgeRule.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<BadgeRule> createBadgeRule(JsonMap payload) async {
    final data = await _send("POST", "/badges/rules", body: payload);
    return BadgeRule.fromJson(JsonMap.from(data as Map));
  }

  Future<BadgeRule> updateBadgeRule(int id, JsonMap payload) async {
    final data = await _send("PUT", "/badges/rules/$id", body: payload);
    return BadgeRule.fromJson(JsonMap.from(data as Map));
  }

  Future<void> deleteBadgeRule(int id) async {
    await _send("DELETE", "/badges/rules/$id");
  }

  Future<List<Gym>> fetchGyms({String? city}) async {
    final data = await _send(
      "GET",
      "/gyms",
      queryParameters: {"city": city},
    );
    return (data as List<dynamic>)
        .map((item) => Gym.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<CheckInResult> checkIn({
    required int gymId,
    double? userLat,
    double? userLng,
  }) async {
    final data = await _send(
      "POST",
      "/checkins",
      body: {
        "gymId": gymId,
        if (userLat != null) "userLat": userLat,
        if (userLng != null) "userLng": userLng,
      },
    );
    return CheckInResult.fromJson(JsonMap.from(data as Map));
  }

  Future<List<Post>> fetchPosts({String? type, int page = 0, int size = 20}) async {
    final data = await _send("GET", "/posts",
        queryParameters: {"type": type, "page": page, "size": size});
    return (data as List<dynamic>)
        .map((item) => Post.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<Post> createPost({required String content, required PostType type}) async {
    final data = await _send("POST", "/posts",
        body: {"content": content, "type": type.rawValue});
    return Post.fromJson(JsonMap.from(data as Map));
  }

  Future<void> deletePost(int postId) async {
    await _send("DELETE", "/posts/$postId");
  }

  Future<void> likePost(int postId) async {
    await _send("POST", "/posts/$postId/like");
  }

  Future<void> unlikePost(int postId) async {
    await _send("DELETE", "/posts/$postId/like");
  }

  Future<List<Comment>> fetchComments(int postId) async {
    final data = await _send("GET", "/posts/$postId/comments");
    return (data as List<dynamic>)
        .map((item) => Comment.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<Comment> addComment(int postId, String content, {int? parentId}) async {
    final data = await _send("POST", "/posts/$postId/comments",
        body: {"content": content, if (parentId != null) "parentId": parentId});
    return Comment.fromJson(JsonMap.from(data as Map));
  }

  Future<void> deleteComment(int postId, int commentId) async {
    await _send("DELETE", "/posts/$postId/comments/$commentId");
  }

  Future<UserProfile> updateProfile({String? name, String? city, String? bio}) async {
    final data = await _send("PUT", "/auth/profile", body: {
      if (name != null) "name": name,
      if (city != null) "city": city,
      if (bio != null) "bio": bio,
    });
    return UserProfile.fromJson(JsonMap.from(data as Map));
  }

  Future<PublicUserProfile> fetchUser(int userId) async {
    final data = await _send("GET", "/users/$userId");
    return PublicUserProfile.fromJson(JsonMap.from(data as Map));
  }

  Future<void> followUser(int userId) async {
    await _send("POST", "/users/$userId/follow");
  }

  Future<void> unfollowUser(int userId) async {
    await _send("DELETE", "/users/$userId/follow");
  }

  Future<List<AppNotification>> fetchNotifications() async {
    final data = await _send("GET", "/notifications");
    return (data as List<dynamic>)
        .map((item) => AppNotification.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    final data = await _send("GET", "/notifications/unread-count");
    return (data as num).toInt();
  }

  Future<void> markAllNotificationsRead() async {
    await _send("POST", "/notifications/mark-all-read");
  }

  Future<Post> fetchPost(int postId) async {
    final data = await _send("GET", "/posts/$postId");
    return Post.fromJson(JsonMap.from(data as Map));
  }

  Future<List<FollowUser>> fetchFollowers(int userId) async {
    final data = await _send("GET", "/users/$userId/followers");
    return (data as List<dynamic>)
        .map((item) => FollowUser.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<List<FollowUser>> fetchFollowing(int userId) async {
    final data = await _send("GET", "/users/$userId/following");
    return (data as List<dynamic>)
        .map((item) => FollowUser.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard({String type = "badges"}) async {
    final data = await _send(
      "GET",
      "/leaderboard",
      queryParameters: {"type": type},
    );
    return (data as List<dynamic>)
        .map((item) => LeaderboardEntry.fromJson(JsonMap.from(item as Map)))
        .toList();
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, Object?> queryParameters = const {},
    JsonMap? body,
  }) async {
    final requestUri = _buildUri(path, queryParameters);
    final headers = <String, String>{
      "Accept": "application/json",
      if (body != null) "Content-Type": "application/json",
    };

    final token = readToken();
    if (token != null && token.isNotEmpty) {
      headers["Authorization"] = "Bearer $token";
    }

    http.Response response;
    try {
      switch (method) {
        case "GET":
          response = await _httpClient
              .get(requestUri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        case "POST":
          response = await _httpClient
              .post(requestUri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case "PUT":
          response = await _httpClient
              .put(requestUri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 15));
          break;
        case "DELETE":
          response = await _httpClient
              .delete(requestUri, headers: headers)
              .timeout(const Duration(seconds: 15));
          break;
        default:
          throw const ApiException("Unsupported HTTP method.");
      }
    } on TimeoutException {
      throw const ApiException("Request timed out. Check the backend connection.");
    } on SocketException {
      throw const ApiException("Cannot reach the BetaUp backend.");
    } on http.ClientException catch (error) {
      throw ApiException(error.message);
    }

    final responseJson = _parseJsonBody(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _messageFromResponse(responseJson) ??
          response.reasonPhrase ??
          "Request failed.";
      throw ApiException(message, statusCode: response.statusCode);
    }

    if (responseJson is Map<String, dynamic>) {
      if (responseJson["success"] == false) {
        throw ApiException(
          _asResponseMessage(responseJson) ?? "Request failed.",
          statusCode: response.statusCode,
        );
      }
      return responseJson["data"];
    }

    return responseJson;
  }

  Uri _buildUri(String path, Map<String, Object?> queryParameters) {
    final cleaned = <String, String>{};
    for (final entry in queryParameters.entries) {
      final value = entry.value;
      if (value == null) {
        continue;
      }
      final stringValue = value.toString().trim();
      if (stringValue.isEmpty) {
        continue;
      }
      cleaned[entry.key] = stringValue;
    }

    final base = Uri.parse("$baseUrl$path");
    return base.replace(queryParameters: cleaned.isEmpty ? null : cleaned);
  }

  dynamic _parseJsonBody(String body) {
    if (body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String? _messageFromResponse(dynamic json) {
    if (json is Map<String, dynamic>) {
      return _asResponseMessage(json);
    }
    return null;
  }

  String? _asResponseMessage(Map<String, dynamic> json) {
    final message = json["message"];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    return null;
  }
}
