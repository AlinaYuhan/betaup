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
  coach("COACH", "Coach");

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

enum BadgeCriteriaType {
  totalLogs("TOTAL_LOGS", "Total logs"),
  completedClimbs("COMPLETED_CLIMBS", "Completed climbs"),
  feedbackReceived("FEEDBACK_RECEIVED", "Feedback received"),
  gymCheckins("GYM_CHECKINS", "Gym check-ins"),
  uniqueGyms("UNIQUE_GYMS", "Unique gyms");

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
      isCoachCertified: json["isCoachCertified"] == true,
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
      "isCoachCertified": isCoachCertified,
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
          .map((item) => DashboardBreakdownItem.fromJson(JsonMap.from(item as Map)))
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
          .map((item) => DashboardChartPoint.fromJson(JsonMap.from(item as Map)))
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
    required this.notes,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String routeName;
  final String difficulty;
  final DateTime? date;
  final String venue;
  final ClimbStatus status;
  final String notes;
  final DateTime? createdAt;

  factory ClimbLog.fromJson(JsonMap json) {
    return ClimbLog(
      id: _asInt(json["id"]),
      userId: _asInt(json["userId"]),
      routeName: _asString(json["routeName"]),
      difficulty: _asString(json["difficulty"]),
      date: _asDateTime(json["date"]),
      venue: _asString(json["venue"]),
      status: ClimbStatus.fromRaw(_asString(json["status"], "ATTEMPTED")),
      notes: _asString(json["notes"]),
      createdAt: _asDateTime(json["createdAt"]),
    );
  }
}

class BadgeProgress {
  const BadgeProgress({
    required this.badgeId,
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.criteriaType,
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
    required this.newBadgeKeys,
  });

  final int? checkInId;
  final int gymId;
  final String gymName;
  final bool gpsVerified;
  final DateTime? checkedAt;
  final List<String> newBadgeKeys;

  factory CheckInResult.fromJson(JsonMap json) {
    return CheckInResult(
      checkInId: json["checkInId"] == null ? null : _asInt(json["checkInId"]),
      gymId: _asInt(json["gymId"]),
      gymName: _asString(json["gymName"]),
      gpsVerified: json["gpsVerified"] == true,
      checkedAt: _asDateTime(json["checkedAt"]),
      newBadgeKeys: (json["newBadgeKeys"] as List<dynamic>? ?? const [])
          .map((k) => _asString(k))
          .toList(),
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.score,
  });

  final int rank;
  final int userId;
  final String name;
  final int score;

  factory LeaderboardEntry.fromJson(JsonMap json) {
    return LeaderboardEntry(
      rank: _asInt(json["rank"]),
      userId: _asInt(json["userId"]),
      name: _asString(json["name"]),
      score: _asInt(json["score"]),
    );
  }
}
