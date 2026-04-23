typedef JsonMap = Map<String, dynamic>;

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? fallback;
  }
  return fallback;
}

String _asString(dynamic value, [String fallback = ""]) {
  if (value is String) {
    return value;
  }
  return fallback;
}

DateTime? _asDateTime(dynamic value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

enum UserRole {
  climber("CLIMBER", "Climber"),
  coach("COACH", "Coach"),
  admin("ADMIN", "Admin");

  const UserRole(this.rawValue, this.label);

  final String rawValue;
  final String label;

  static UserRole fromRaw(String raw) {
    return values.firstWhere(
      (role) => role.rawValue == raw,
      orElse: () => UserRole.climber,
    );
  }
}

enum ClimbStatus {
  completed("COMPLETED", "Completed"),
  attempted("ATTEMPTED", "Attempted");

  const ClimbStatus(this.rawValue, this.label);

  final String rawValue;
  final String label;

  static ClimbStatus fromRaw(String raw) {
    return values.firstWhere(
      (status) => status.rawValue == raw,
      orElse: () => ClimbStatus.attempted,
    );
  }
}

enum ClimbResult {
  flash("FLASH", "Flash", "Flash"),
  send("SEND", "完成", "Send"),
  attempt("ATTEMPT", "尝试", "Attempt");

  const ClimbResult(this.rawValue, this.label, this.shortLabel);

  final String rawValue;
  final String label;
  final String shortLabel;

  static ClimbResult fromRaw(String raw) {
    return values.firstWhere(
      (r) => r.rawValue == raw,
      orElse: () => ClimbResult.send,
    );
  }
}

enum BadgeCriteriaType {
  totalLogs("TOTAL_LOGS", "Total logs"),
  completedClimbs("COMPLETED_CLIMBS", "Completed climbs"),
  flashClimbs("FLASH_CLIMBS", "Flash climbs"),
  feedbackReceived("FEEDBACK_RECEIVED", "Feedback received"),
  gymCheckins("GYM_CHECKINS", "Gym check-ins"),
  uniqueGyms("UNIQUE_GYMS", "Unique gyms"),
  postsCreated("POSTS_CREATED", "Posts created"),
  likesReceived("LIKES_RECEIVED", "Likes received"),
  commentsMade("COMMENTS_MADE", "Comments made");

  const BadgeCriteriaType(this.rawValue, this.label);

  final String rawValue;
  final String label;

  static BadgeCriteriaType fromRaw(String raw) {
    return values.firstWhere(
      (type) => type.rawValue == raw,
      orElse: () => BadgeCriteriaType.totalLogs,
    );
  }
}

class AuthPayload {
  const AuthPayload({
    required this.user,
    required this.token,
  });

  final UserProfile user;
  final String token;

  factory AuthPayload.fromJson(JsonMap json) {
    return AuthPayload(
      user: UserProfile.fromJson(JsonMap.from(json["user"] as Map)),
      token: _asString(json["token"]),
    );
  }

  JsonMap toJson() {
    return {
      "user": user.toJson(),
      "token": token,
    };
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.city = "",
    this.bio = "",
    this.followerCount = 0,
    this.followingCount = 0,
    this.totalClimbLogs = 0,
    this.isCoachCertified = false,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String city;
  final String bio;
  final int followerCount;
  final int followingCount;
  final int totalClimbLogs;
  final bool isCoachCertified;

  factory UserProfile.fromJson(JsonMap json) {
    return UserProfile(
      id: _asInt(json["id"]),
      name: _asString(json["name"]),
      email: _asString(json["email"]),
      role: UserRole.fromRaw(_asString(json["role"], "CLIMBER")),
      city: _asString(json["city"]),
      bio: _asString(json["bio"]),
      followerCount: _asInt(json["followerCount"]),
      followingCount: _asInt(json["followingCount"]),
      totalClimbLogs: _asInt(json["totalClimbLogs"]),
      // Backend serialises boolean isXxx fields without the "is" prefix.
      // Accept both keys so cached SharedPrefs data also works.
      isCoachCertified:
          json["coachCertified"] == true || json["isCoachCertified"] == true,
    );
  }

  JsonMap toJson() {
    return {
      "id": id,
      "name": name,
      "email": email,
      "role": role.rawValue,
      "city": city,
      "bio": bio,
      "followerCount": followerCount,
      "followingCount": followingCount,
      "totalClimbLogs": totalClimbLogs,
      "coachCertified": isCoachCertified,
    };
  }
}

class PageResult<T> {
  const PageResult({
    required this.items,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
    required this.hasNext,
    required this.hasPrevious,
  });

  final List<T> items;
  final int totalElements;
  final int totalPages;
  final int page;
  final int size;
  final bool hasNext;
  final bool hasPrevious;

  factory PageResult.fromJson(
    JsonMap json,
    T Function(JsonMap item) itemBuilder,
  ) {
    return PageResult<T>(
      items: (json["items"] as List<dynamic>? ?? const [])
          .map((item) => itemBuilder(JsonMap.from(item as Map)))
          .toList(),
      totalElements: _asInt(json["totalElements"]),
      totalPages: _asInt(json["totalPages"]),
      page: _asInt(json["page"]),
      size: _asInt(json["size"]),
      hasNext: json["hasNext"] == true,
      hasPrevious: json["hasPrevious"] == true,
    );
  }
}

class DashboardSummary {
  const DashboardSummary({
    required this.audience,
    required this.range,
    required this.rangeLabel,
    required this.title,
    required this.summary,
    required this.metrics,
    required this.breakdown,
    required this.charts,
    required this.recentActivity,
    required this.highlights,
  });

  final String audience;
  final String range;
  final String rangeLabel;
  final String title;
  final String summary;
  final List<DashboardMetric> metrics;
  final List<DashboardBreakdownItem> breakdown;
  final List<DashboardChart> charts;
  final List<DashboardActivity> recentActivity;
  final List<String> highlights;

  factory DashboardSummary.fromJson(JsonMap json) {
    return DashboardSummary(
      audience: _asString(json["audience"]),
      range: _asString(json["range"]),
      rangeLabel: _asString(json["rangeLabel"]),
      title: _asString(json["title"]),
      summary: _asString(json["summary"]),
      metrics: (json["metrics"] as List<dynamic>? ?? const [])
          .map((item) => DashboardMetric.fromJson(JsonMap.from(item as Map)))
          .toList(),
      breakdown: (json["breakdown"] as List<dynamic>? ?? const [])
          .map((item) =>
              DashboardBreakdownItem.fromJson(JsonMap.from(item as Map)))
          .toList(),
      charts: (json["charts"] as List<dynamic>? ?? const [])
          .map((item) => DashboardChart.fromJson(JsonMap.from(item as Map)))
          .toList(),
      recentActivity: (json["recentActivity"] as List<dynamic>? ?? const [])
          .map((item) => DashboardActivity.fromJson(JsonMap.from(item as Map)))
          .toList(),
      highlights: (json["highlights"] as List<dynamic>? ?? const [])
          .map((item) => _asString(item))
          .where((item) => item.isNotEmpty)
          .toList(),
    );
  }
}

class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.numericValue,
    required this.helper,
  });

  final String label;
  final String value;
  final int numericValue;
  final String helper;

  factory DashboardMetric.fromJson(JsonMap json) {
    return DashboardMetric(
      label: _asString(json["label"]),
      value: _asString(json["value"]),
      numericValue: _asInt(json["numericValue"]),
      helper: _asString(json["helper"]),
    );
  }
}

class DashboardBreakdownItem {
  const DashboardBreakdownItem({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final int value;
  final String helper;

  factory DashboardBreakdownItem.fromJson(JsonMap json) {
    return DashboardBreakdownItem(
      label: _asString(json["label"]),
      value: _asInt(json["value"]),
      helper: _asString(json["helper"]),
    );
  }
}

class DashboardChart {
  const DashboardChart({
    required this.title,
    required this.subtitle,
    required this.format,
    required this.points,
  });

  final String title;
  final String subtitle;
  final String format;
  final List<DashboardChartPoint> points;

  factory DashboardChart.fromJson(JsonMap json) {
    return DashboardChart(
      title: _asString(json["title"]),
      subtitle: _asString(json["subtitle"]),
      format: _asString(json["format"]),
      points: (json["points"] as List<dynamic>? ?? const [])
          .map(
              (item) => DashboardChartPoint.fromJson(JsonMap.from(item as Map)))
          .toList(),
    );
  }
}

class DashboardChartPoint {
  const DashboardChartPoint({
    required this.label,
    required this.value,
    required this.helper,
  });

  final String label;
  final int value;
  final String helper;

  factory DashboardChartPoint.fromJson(JsonMap json) {
    return DashboardChartPoint(
      label: _asString(json["label"]),
      value: _asInt(json["value"]),
      helper: _asString(json["helper"]),
    );
  }
}

class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.meta,
  });

  final String title;
  final String subtitle;
  final String meta;

  factory DashboardActivity.fromJson(JsonMap json) {
    return DashboardActivity(
      title: _asString(json["title"]),
      subtitle: _asString(json["subtitle"]),
      meta: _asString(json["meta"]),
    );
  }
}

class ClimbLog {
  const ClimbLog({
    required this.id,
    required this.userId,
    required this.routeName,
    required this.difficulty,
    required this.date,
    required this.venue,
    required this.status,
    required this.result,
    required this.attempts,
    required this.notes,
    required this.createdAt,
    this.newlyUnlockedBadges = const [],
  });

  final int id;
  final int userId;
  final String routeName; // may be empty string for unnamed routes
  final String difficulty;
  final DateTime? date;
  final String venue;
  final ClimbStatus status;
  final ClimbResult result;
  final int attempts;
  final String notes;
  final DateTime? createdAt;
  final List<BadgeProgress> newlyUnlockedBadges;

  factory ClimbLog.fromJson(JsonMap json) {
    final status = ClimbStatus.fromRaw(_asString(json["status"], "ATTEMPTED"));
    return ClimbLog(
      id: _asInt(json["id"]),
      userId: _asInt(json["userId"]),
      routeName: _asString(json["routeName"]),
      difficulty: _asString(json["difficulty"]),
      date: _asDateTime(json["date"]),
      venue: _asString(json["venue"]),
      status: status,
      result: json["result"] != null
          ? ClimbResult.fromRaw(_asString(json["result"]))
          : (status == ClimbStatus.completed
              ? ClimbResult.send
              : ClimbResult.attempt),
      attempts: _asInt(json["attempts"], 1),
      notes: _asString(json["notes"]),
      createdAt: _asDateTime(json["createdAt"]),
      newlyUnlockedBadges: (json["newlyUnlockedBadges"] as List<dynamic>? ?? [])
          .map((e) => BadgeProgress.fromJson(JsonMap.from(e as Map)))
          .toList(),
    );
  }
}

class GradeStat {
  const GradeStat({
    required this.difficulty,
    required this.total,
    required this.sends,
    required this.flashes,
  });

  final String difficulty;
  final int total;
  final int sends;
  final int flashes;

  factory GradeStat.fromJson(JsonMap json) => GradeStat(
        difficulty: _asString(json["difficulty"]),
        total: _asInt(json["total"]),
        sends: _asInt(json["sends"]),
        flashes: _asInt(json["flashes"]),
      );
}

class ClimbSession {
  const ClimbSession({
    required this.id,
    required this.userId,
    required this.venue,
    required this.startTime,
    this.endTime,
    required this.active,
  });

  final int id;
  final int userId;
  final String venue;
  final DateTime startTime;
  final DateTime? endTime;
  final bool active;

  factory ClimbSession.fromJson(JsonMap json) => ClimbSession(
        id: _asInt(json["id"]),
        userId: _asInt(json["userId"]),
        venue: _asString(json["venue"]),
        startTime: _asDateTime(json["startTime"]) ?? DateTime.now(),
        endTime: _asDateTime(json["endTime"]),
        active: json["active"] == true,
      );
}

class SessionSummary {
  const SessionSummary({
    required this.sessionId,
    required this.venue,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.totalLogs,
    required this.flashes,
    required this.sends,
    required this.attempts,
    this.hardestSend,
    required this.gradeSummary,
    this.newlyUnlockedBadges = const [],
  });

  final int sessionId;
  final String venue;
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final int totalLogs;
  final int flashes;
  final int sends;
  final int attempts;
  final String? hardestSend;
  final List<GradeStat> gradeSummary;
  final List<BadgeProgress> newlyUnlockedBadges;

  factory SessionSummary.fromJson(JsonMap json) => SessionSummary(
        sessionId: _asInt(json["sessionId"]),
        venue: _asString(json["venue"]),
        startTime: _asDateTime(json["startTime"]) ?? DateTime.now(),
        endTime: _asDateTime(json["endTime"]),
        durationMinutes: _asInt(json["durationMinutes"]),
        totalLogs: _asInt(json["totalLogs"]),
        flashes: _asInt(json["flashes"]),
        sends: _asInt(json["sends"]),
        attempts: _asInt(json["attempts"]),
        hardestSend: json["hardestSend"] as String?,
        gradeSummary: (json["gradeSummary"] as List<dynamic>? ?? [])
            .map((e) => GradeStat.fromJson(JsonMap.from(e as Map)))
            .toList(),
        newlyUnlockedBadges:
            (json["newlyUnlockedBadges"] as List<dynamic>? ?? [])
                .map((e) => BadgeProgress.fromJson(JsonMap.from(e as Map)))
                .toList(),
      );
}

class BadgeProgress {
  const BadgeProgress({
    required this.badgeId,
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.criteriaType,
    required this.category,
    required this.threshold,
    required this.currentValue,
    required this.earned,
    required this.awardedAt,
  });

  final int badgeId;
  final String badgeKey;
  final String name;
  final String description;
  final BadgeCriteriaType criteriaType;

  /// "LEVEL" | "CHALLENGE" | "VENUE" | "SOCIAL"
  final String category;
  final int threshold;
  final int currentValue;
  final bool earned;
  final DateTime? awardedAt;

  factory BadgeProgress.fromJson(JsonMap json) {
    return BadgeProgress(
      badgeId: _asInt(json["badgeId"]),
      badgeKey: _asString(json["badgeKey"]),
      name: _asString(json["name"]),
      description: _asString(json["description"]),
      criteriaType: BadgeCriteriaType.fromRaw(
        _asString(json["criteriaType"], "TOTAL_LOGS"),
      ),
      category: _asString(json["category"], "CHALLENGE"),
      threshold: _asInt(json["threshold"]),
      currentValue: _asInt(json["currentValue"]),
      earned: json["earned"] == true,
      awardedAt: _asDateTime(json["awardedAt"]),
    );
  }
}

class BadgeRule {
  const BadgeRule({
    required this.id,
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.threshold,
    required this.criteriaType,
    required this.createdAt,
  });

  final int id;
  final String badgeKey;
  final String name;
  final String description;
  final int threshold;
  final BadgeCriteriaType criteriaType;
  final DateTime? createdAt;

  factory BadgeRule.fromJson(JsonMap json) {
    return BadgeRule(
      id: _asInt(json["id"]),
      badgeKey: _asString(json["badgeKey"]),
      name: _asString(json["name"]),
      description: _asString(json["description"]),
      threshold: _asInt(json["threshold"]),
      criteriaType: BadgeCriteriaType.fromRaw(
        _asString(json["criteriaType"], "TOTAL_LOGS"),
      ),
      createdAt: _asDateTime(json["createdAt"]),
    );
  }
}

class FeedbackEntry {
  const FeedbackEntry({
    required this.id,
    required this.climbLogId,
    required this.routeName,
    required this.difficulty,
    required this.venue,
    required this.climbDate,
    required this.climbStatus,
    required this.coachId,
    required this.coachName,
    required this.climberId,
    required this.climberName,
    required this.comment,
    required this.rating,
    required this.createdAt,
  });

  final int id;
  final int climbLogId;
  final String routeName;
  final String difficulty;
  final String venue;
  final DateTime? climbDate;
  final ClimbStatus climbStatus;
  final int coachId;
  final String coachName;
  final int climberId;
  final String climberName;
  final String comment;
  final int rating;
  final DateTime? createdAt;

  factory FeedbackEntry.fromJson(JsonMap json) {
    return FeedbackEntry(
      id: _asInt(json["id"]),
      climbLogId: _asInt(json["climbLogId"]),
      routeName: _asString(json["routeName"]),
      difficulty: _asString(json["difficulty"]),
      venue: _asString(json["venue"]),
      climbDate: _asDateTime(json["climbDate"]),
      climbStatus: ClimbStatus.fromRaw(
        _asString(json["climbStatus"], "ATTEMPTED"),
      ),
      coachId: _asInt(json["coachId"]),
      coachName: _asString(json["coachName"]),
      climberId: _asInt(json["climberId"]),
      climberName: _asString(json["climberName"]),
      comment: _asString(json["comment"]),
      rating: _asInt(json["rating"]),
      createdAt: _asDateTime(json["createdAt"]),
    );
  }
}

class ClimberOverview {
  const ClimberOverview({
    required this.id,
    required this.name,
    required this.email,
    required this.climbCount,
    required this.feedbackCount,
  });

  final int id;
  final String name;
  final String email;
  final int climbCount;
  final int feedbackCount;

  factory ClimberOverview.fromJson(JsonMap json) {
    return ClimberOverview(
      id: _asInt(json["id"]),
      name: _asString(json["name"]),
      email: _asString(json["email"]),
      climbCount: _asInt(json["climbCount"]),
      feedbackCount: _asInt(json["feedbackCount"]),
    );
  }
}

class ClimberDetail {
  const ClimberDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.climbCount,
    required this.completedCount,
    required this.attemptedCount,
    required this.feedbackCount,
    required this.recentClimbs,
    required this.recentFeedback,
  });

  final int id;
  final String name;
  final String email;
  final int climbCount;
  final int completedCount;
  final int attemptedCount;
  final int feedbackCount;
  final List<ClimbLog> recentClimbs;
  final List<FeedbackEntry> recentFeedback;

  factory ClimberDetail.fromJson(JsonMap json) {
    return ClimberDetail(
      id: _asInt(json["id"]),
      name: _asString(json["name"]),
      email: _asString(json["email"]),
      climbCount: _asInt(json["climbCount"]),
      completedCount: _asInt(json["completedCount"]),
      attemptedCount: _asInt(json["attemptedCount"]),
      feedbackCount: _asInt(json["feedbackCount"]),
      recentClimbs: (json["recentClimbs"] as List<dynamic>? ?? const [])
          .map((item) => ClimbLog.fromJson(JsonMap.from(item as Map)))
          .toList(),
      recentFeedback: (json["recentFeedback"] as List<dynamic>? ?? const [])
          .map((item) => FeedbackEntry.fromJson(JsonMap.from(item as Map)))
          .toList(),
    );
  }
}

class Gym {
  const Gym({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.lat,
    required this.lng,
    required this.phone,
    required this.openHours,
    required this.types,
    required this.bookingUrl,
    required this.coverImageUrl,
    required this.logoUrl,
  });

  final int id;
  final String name;
  final String city;
  final String address;
  final double lat;
  final double lng;
  final String phone;
  final String openHours;
  final String types;
  final String bookingUrl;
  final String coverImageUrl;
  final String logoUrl;

  factory Gym.fromJson(JsonMap json) {
    return Gym(
      id: _asInt(json["id"]),
      name: _asString(json["name"]),
      city: _asString(json["city"]),
      address: _asString(json["address"]),
      lat: (json["lat"] as num?)?.toDouble() ?? 0.0,
      lng: (json["lng"] as num?)?.toDouble() ?? 0.0,
      phone: _asString(json["phone"]),
      openHours: _asString(json["openHours"]),
      types: _asString(json["types"]),
      bookingUrl: _asString(json["bookingUrl"]),
      coverImageUrl: _asString(json["coverImageUrl"]),
      logoUrl: _asString(json["logoUrl"]),
    );
  }

  JsonMap toJson() => {
        "id": id,
        "name": name,
        "city": city,
        "address": address,
        "lat": lat,
        "lng": lng,
        "phone": phone,
        "openHours": openHours,
        "types": types,
        "bookingUrl": bookingUrl,
        "coverImageUrl": coverImageUrl,
        "logoUrl": logoUrl,
      };
}

class CheckInResult {
  const CheckInResult({
    required this.checkInId,
    required this.gymId,
    required this.gymName,
    required this.gpsVerified,
    required this.checkedAt,
    this.newlyUnlockedBadges = const [],
  });

  final int? checkInId;
  final int gymId;
  final String gymName;
  final bool gpsVerified;
  final DateTime? checkedAt;
  final List<BadgeProgress> newlyUnlockedBadges;

  factory CheckInResult.fromJson(JsonMap json) {
    return CheckInResult(
      checkInId: json["checkInId"] == null ? null : _asInt(json["checkInId"]),
      gymId: _asInt(json["gymId"]),
      gymName: _asString(json["gymName"]),
      gpsVerified: json["gpsVerified"] == true,
      checkedAt: _asDateTime(json["checkedAt"]),
      newlyUnlockedBadges: (json["newlyUnlockedBadges"] as List<dynamic>? ?? [])
          .map((e) => BadgeProgress.fromJson(JsonMap.from(e as Map)))
          .toList(),
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.isCoach,
    required this.score,
  });

  final int rank;
  final int userId;
  final String name;
  final bool isCoach;
  final int score;

  factory LeaderboardEntry.fromJson(JsonMap json) {
    return LeaderboardEntry(
      rank: _asInt(json["rank"]),
      userId: _asInt(json["userId"]),
      name: _asString(json["name"]),
      isCoach: json["isCoach"] == true,
      score: _asInt(json["score"]),
    );
  }
}

enum PostType {
  general("GENERAL", "动态"),
  findPartner("FIND_PARTNER", "找搭子");

  const PostType(this.rawValue, this.label);
  final String rawValue;
  final String label;

  static PostType fromRaw(String raw) => values.firstWhere(
        (t) => t.rawValue == raw,
        orElse: () => PostType.general,
      );
}

enum PostMediaKind {
  image("IMAGE"),
  video("VIDEO");

  const PostMediaKind(this.rawValue);
  final String rawValue;

  static PostMediaKind? fromRaw(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return values.firstWhere(
      (kind) => kind.rawValue == raw,
      orElse: () => PostMediaKind.image,
    );
  }
}

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    this.authorIsCoach = false,
    required this.content,
    required this.type,
    this.mediaUrl,
    this.mediaUrls,
    this.mediaKind,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.createdAt,
    this.newlyUnlockedBadges = const [],
  });

  final int id;
  final int authorId;
  final String authorName;
  final bool authorIsCoach;
  final String content;
  final PostType type;
  @Deprecated('Use mediaUrls instead')
  final String? mediaUrl;
  final List<String>? mediaUrls;
  final PostMediaKind? mediaKind;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final DateTime? createdAt;
  final List<BadgeProgress> newlyUnlockedBadges;

  /// Helper to get all media URLs (backward compatible)
  List<String> get allMediaUrls {
    if (mediaUrls != null && mediaUrls!.isNotEmpty) {
      return mediaUrls!;
    }
    if (mediaUrl != null) {
      return [mediaUrl!];
    }
    return [];
  }

  factory Post.fromJson(JsonMap json) => Post(
        id: _asInt(json["id"]),
        authorId: _asInt(json["authorId"]),
        authorName: _asString(json["authorName"]),
        authorIsCoach: json["authorIsCoach"] == true,
        content: _asString(json["content"]),
        type: PostType.fromRaw(_asString(json["type"], "GENERAL")),
        mediaUrl: json["mediaUrl"] as String?,
        mediaUrls: (json["mediaUrls"] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        mediaKind: PostMediaKind.fromRaw(json["mediaKind"] as String?),
        likeCount: _asInt(json["likeCount"]),
        commentCount: _asInt(json["commentCount"]),
        likedByMe: json["likedByMe"] == true,
        createdAt: _asDateTime(json["createdAt"]),
        newlyUnlockedBadges:
            (json["newlyUnlockedBadges"] as List<dynamic>? ?? [])
                .map((e) => BadgeProgress.fromJson(e as JsonMap))
                .toList(),
      );

  Post copyWith({int? likeCount, bool? likedByMe}) => Post(
        id: id,
        authorId: authorId,
        authorName: authorName,
        authorIsCoach: authorIsCoach,
        content: content,
        type: type,
        mediaUrl: mediaUrl,
        mediaUrls: mediaUrls,
        mediaKind: mediaKind,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
        createdAt: createdAt,
        newlyUnlockedBadges: newlyUnlockedBadges,
      );
}

class Comment {
  const Comment({
    required this.id,
    this.parentId,
    required this.authorId,
    required this.authorName,
    this.authorIsCoach = false,
    required this.content,
    required this.createdAt,
  });

  final int id;
  final int? parentId;
  final int authorId;
  final String authorName;
  final bool authorIsCoach;
  final String content;
  final DateTime? createdAt;

  factory Comment.fromJson(JsonMap json) => Comment(
        id: _asInt(json["id"]),
        parentId: json["parentId"] != null ? _asInt(json["parentId"]) : null,
        authorId: _asInt(json["authorId"]),
        authorName: _asString(json["authorName"]),
        authorIsCoach: json["authorIsCoach"] == true,
        content: _asString(json["content"]),
        createdAt: _asDateTime(json["createdAt"]),
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    required this.referenceId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String type; // FOLLOW | COMMENT | LIKE
  final int actorId;
  final String actorName;
  final int referenceId;
  final String content;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(JsonMap json) => AppNotification(
        id: _asInt(json["id"]),
        type: _asString(json["type"]),
        actorId: _asInt(json["actorId"]),
        actorName: _asString(json["actorName"]),
        referenceId: _asInt(json["referenceId"]),
        content: _asString(json["content"]),
        isRead: json["isRead"] == true,
        createdAt: _asDateTime(json["createdAt"]),
      );
}

/// Lightweight user item used in follower / following lists.
class FollowUser {
  const FollowUser({
    required this.id,
    required this.name,
    required this.isCoachCertified,
  });

  final int id;
  final String name;
  final bool isCoachCertified;

  factory FollowUser.fromJson(JsonMap json) => FollowUser(
        id: _asInt(json["id"]),
        name: _asString(json["name"]),
        isCoachCertified: json["coachCertified"] == true,
      );
}

class PublicUserProfile {
  const PublicUserProfile({
    required this.id,
    required this.name,
    required this.isCoachCertified,
    required this.followerCount,
    required this.followingCount,
    required this.totalClimbLogs,
    required this.followedByMe,
  });

  final int id;
  final String name;
  final bool isCoachCertified;
  final int followerCount;
  final int followingCount;
  final int totalClimbLogs;
  final bool followedByMe;

  factory PublicUserProfile.fromJson(JsonMap json) => PublicUserProfile(
        id: _asInt(json["id"]),
        name: _asString(json["name"]),
        isCoachCertified: json["coachCertified"] == true,
        followerCount: _asInt(json["followerCount"]),
        followingCount: _asInt(json["followingCount"]),
        totalClimbLogs: _asInt(json["totalClimbLogs"]),
        followedByMe: json["followedByMe"] == true,
      );

  PublicUserProfile copyWith({bool? followedByMe}) => PublicUserProfile(
        id: id,
        name: name,
        isCoachCertified: isCoachCertified,
        followerCount: followedByMe == true
            ? followerCount + 1
            : (followedByMe == false ? followerCount - 1 : followerCount),
        followingCount: followingCount,
        totalClimbLogs: totalClimbLogs,
        followedByMe: followedByMe ?? this.followedByMe,
      );
}

// ── Stats models ────────────────────────────────────────────────────────────

class StatsBucket {
  const StatsBucket({
    required this.label,
    required this.climbCount,
    required this.flashCount,
    required this.sendCount,
    required this.attemptCount,
  });

  final String label;
  final int climbCount;
  final int flashCount;
  final int sendCount;
  final int attemptCount;

  factory StatsBucket.fromJson(JsonMap json) => StatsBucket(
        label: _asString(json["label"]),
        climbCount: _asInt(json["climbCount"]),
        flashCount: _asInt(json["flashCount"]),
        sendCount: _asInt(json["sendCount"]),
        attemptCount: _asInt(json["attemptCount"]),
      );
}

class StatsSummary {
  const StatsSummary({
    required this.totalClimbs,
    required this.totalFlashes,
    required this.totalSends,
    required this.totalAttempts,
    required this.flashRatePct,
    required this.totalSessions,
    this.topGrade,
  });

  final int totalClimbs;
  final int totalFlashes;
  final int totalSends;
  final int totalAttempts;
  final int flashRatePct;
  final int totalSessions;
  final String? topGrade;

  factory StatsSummary.fromJson(JsonMap json) => StatsSummary(
        totalClimbs: _asInt(json["totalClimbs"]),
        totalFlashes: _asInt(json["totalFlashes"]),
        totalSends: _asInt(json["totalSends"]),
        totalAttempts: _asInt(json["totalAttempts"]),
        flashRatePct: _asInt(json["flashRatePct"]),
        totalSessions: _asInt(json["totalSessions"]),
        topGrade: json["topGrade"] as String?,
      );
}

class ClimbStats {
  const ClimbStats({
    required this.period,
    required this.buckets,
    required this.gradeDistribution,
    required this.summary,
  });

  final String period;
  final List<StatsBucket> buckets;
  final List<GradeStat> gradeDistribution;
  final StatsSummary summary;

  factory ClimbStats.fromJson(JsonMap json) => ClimbStats(
        period: _asString(json["period"]),
        buckets: (json["buckets"] as List<dynamic>? ?? [])
            .map((e) => StatsBucket.fromJson(JsonMap.from(e as Map)))
            .toList(),
        gradeDistribution: (json["gradeDistribution"] as List<dynamic>? ?? [])
            .map((e) => GradeStat.fromJson(JsonMap.from(e as Map)))
            .toList(),
        summary: StatsSummary.fromJson(JsonMap.from(json["summary"] as Map)),
      );
}

// ── Coach certification models ───────────────────────────────────────────────

enum CertificationStatus {
  pending("PENDING"),
  approved("APPROVED"),
  rejected("REJECTED");

  const CertificationStatus(this.rawValue);
  final String rawValue;

  static CertificationStatus? fromRaw(String? raw) {
    if (raw == null) return null;
    return values.firstWhere(
      (s) => s.rawValue == raw,
      orElse: () => CertificationStatus.pending,
    );
  }
}

class CoachStatus {
  const CoachStatus({
    required this.isCoachCertified,
    this.certificationStatus,
    this.rejectReason,
    this.appliedAt,
    this.reviewedAt,
  });

  final bool isCoachCertified;
  final CertificationStatus? certificationStatus;
  final String? rejectReason;
  final DateTime? appliedAt;
  final DateTime? reviewedAt;

  factory CoachStatus.fromJson(JsonMap json) => CoachStatus(
        isCoachCertified:
            json["coachCertified"] == true || json["isCoachCertified"] == true,
        certificationStatus:
            CertificationStatus.fromRaw(json["certificationStatus"] as String?),
        rejectReason: json["rejectReason"] as String?,
        appliedAt: _asDateTime(json["appliedAt"]),
        reviewedAt: _asDateTime(json["reviewedAt"]),
      );
}

class CertificationReview {
  const CertificationReview({
    required this.certificationId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.status,
    required this.certificateImageUrl,
    this.resumeText,
    this.rejectReason,
    required this.appliedAt,
  });

  final int certificationId;
  final int userId;
  final String userName;
  final String userEmail;
  final CertificationStatus status;
  final String certificateImageUrl;
  final String? resumeText;
  final String? rejectReason;
  final DateTime? appliedAt;

  factory CertificationReview.fromJson(JsonMap json) => CertificationReview(
        certificationId: _asInt(json["certificationId"]),
        userId: _asInt(json["userId"]),
        userName: _asString(json["userName"]),
        userEmail: _asString(json["userEmail"]),
        status: CertificationStatus.fromRaw(_asString(json["status"])) ??
            CertificationStatus.pending,
        certificateImageUrl: _asString(json["certificateImageUrl"]),
        resumeText: json["resumeText"] as String?,
        rejectReason: json["rejectReason"] as String?,
        appliedAt: _asDateTime(json["appliedAt"]),
      );
}
