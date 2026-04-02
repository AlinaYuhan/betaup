package com.betaup.service.impl;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.dashboard.DashboardActivityDto;
import com.betaup.dto.dashboard.DashboardBreakdownItemDto;
import com.betaup.dto.dashboard.DashboardChartDto;
import com.betaup.dto.dashboard.DashboardChartPointDto;
import com.betaup.dto.dashboard.DashboardMetricDto;
import com.betaup.dto.dashboard.DashboardRange;
import com.betaup.dto.dashboard.DashboardSummaryDto;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.Feedback;
import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.FeedbackRepository;
import com.betaup.repository.UserBadgeRepository;
import com.betaup.repository.UserRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.DashboardService;
import java.time.LocalDate;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DashboardServiceImpl implements DashboardService {

    private final CurrentUserService currentUserService;
    private final ClimbLogRepository climbLogRepository;
    private final FeedbackRepository feedbackRepository;
    private final UserRepository userRepository;
    private final UserBadgeRepository userBadgeRepository;

    @Override
    public ApiResponse<DashboardSummaryDto> getDashboardSummary(DashboardRange range) {
        User currentUser = currentUserService.getCurrentUser();
        DashboardRange resolvedRange = resolveRange(range);
        DashboardSummaryDto data = buildDashboard(currentUser, resolvedRange);

        return ApiResponse.success("Dashboard loaded.", data);
    }

    @Override
    public String exportDashboardSummary(DashboardRange range) {
        User currentUser = currentUserService.getCurrentUser();
        DashboardSummaryDto summary = buildDashboard(currentUser, resolveRange(range));
        StringBuilder csv = new StringBuilder();

        appendCsvRow(csv, "section", "group", "label", "value", "helper");
        appendCsvRow(csv, "meta", "dashboard", "audience", summary.getAudience(), "");
        appendCsvRow(csv, "meta", "dashboard", "title", summary.getTitle(), "");
        appendCsvRow(csv, "meta", "dashboard", "range", summary.getRangeLabel(), "");

        summary.getMetrics().forEach(metric ->
            appendCsvRow(csv, "metric", "metrics", metric.getLabel(), metric.getValue(), metric.getHelper())
        );
        summary.getBreakdown().forEach(item ->
            appendCsvRow(csv, "breakdown", "distribution", item.getLabel(), String.valueOf(item.getValue()), item.getHelper())
        );
        summary.getCharts().forEach(chart -> chart.getPoints().forEach(point ->
            appendCsvRow(csv, "chart", chart.getTitle(), point.getLabel(), String.valueOf(point.getValue()), point.getHelper())
        ));
        summary.getRecentActivity().forEach(activity ->
            appendCsvRow(csv, "activity", "recent", activity.getTitle(), activity.getMeta(), activity.getSubtitle())
        );
        summary.getHighlights().forEach(highlight ->
            appendCsvRow(csv, "highlight", "highlights", "note", highlight, "")
        );

        return csv.toString();
    }

    private DashboardSummaryDto buildDashboard(User currentUser, DashboardRange range) {
        return currentUser.getRole() == UserRole.COACH
            ? buildCoachDashboard(currentUser, range)
            : buildClimberDashboard(currentUser, range);
    }

    private DashboardSummaryDto buildClimberDashboard(User climber, DashboardRange range) {
        LocalDate today = LocalDate.now();
        LocalDate startDate = range.getStartDate(today);
        List<ClimbLog> climbLogs = filterClimbsByRange(
            climbLogRepository.findByUserIdOrderByDateDescCreatedAtDesc(climber.getId()),
            startDate
        );
        List<Feedback> feedbackEntries = filterFeedbackByRange(
            feedbackRepository.findByClimberIdOrderByCreatedAtDesc(climber.getId()),
            startDate
        );
        long totalLogs = climbLogs.size();
        long completed = climbLogs.stream().filter(log -> log.getStatus() == ClimbStatus.COMPLETED).count();
        long attempted = climbLogs.stream().filter(log -> log.getStatus() == ClimbStatus.ATTEMPTED).count();
        long feedbackCount = feedbackEntries.size();
        long earnedBadges = userBadgeRepository.countByUserId(climber.getId());
        List<DashboardActivityDto> recentActivity = buildClimberActivity(climbLogs, feedbackEntries);
        List<DashboardChartDto> charts = List.of(
            buildMonthlyChart(
                "Session trend",
                "Climbs logged within " + range.getLabel().toLowerCase(Locale.ENGLISH),
                climbLogs.stream().map(ClimbLog::getDate).toList(),
                "sessions",
                range,
                today
            ),
            buildCategoryChart("Difficulty mix", "Most repeated grades in the selected range", countByLabel(climbLogs, ClimbLog::getDifficulty), "logs", 5),
            buildCategoryChart("Venue spread", "Where your filtered session volume happened", countByLabel(climbLogs, ClimbLog::getVenue), "logs", 5)
        );

        return DashboardSummaryDto.builder()
            .audience("CLIMBER")
            .range(range)
            .rangeLabel(range.getLabel())
            .title("Climber dashboard")
            .summary("Climbing, badge, and coaching activity is now filtered by a selectable time range and exportable as CSV.")
            .metrics(List.of(
                DashboardMetricDto.builder().label("Sessions Logged").value(String.valueOf(totalLogs)).numericValue(totalLogs).helper(range.getLabel()).build(),
                DashboardMetricDto.builder().label("Completed").value(String.valueOf(completed)).numericValue(completed).helper("Successful sends").build(),
                DashboardMetricDto.builder().label("Attempted").value(String.valueOf(attempted)).numericValue(attempted).helper("In-progress projects").build(),
                DashboardMetricDto.builder().label("Coach Notes").value(String.valueOf(feedbackCount)).numericValue(feedbackCount).helper("Feedback in range").build()
            ))
            .breakdown(List.of(
                DashboardBreakdownItemDto.builder().label("Completed climbs").value(completed).helper("Solid send volume").build(),
                DashboardBreakdownItemDto.builder().label("Attempted climbs").value(attempted).helper("In-progress projects").build(),
                DashboardBreakdownItemDto.builder().label("Feedback received").value(feedbackCount).helper("Coach review loop").build(),
                DashboardBreakdownItemDto.builder().label("Earned badges").value(earnedBadges).helper("All-time unlocks").build()
            ))
            .charts(charts)
            .recentActivity(recentActivity)
            .highlights(List.of(
                totalLogs == 0
                    ? "No climbs match the selected range yet. Broaden the range or add newer logs."
                    : "Trend and distribution cards now refresh when you change the dashboard range.",
                feedbackCount == 0
                    ? "No coach notes fall inside this time window yet."
                    : "Feedback history is still paginated, and the dashboard now mirrors the same filtered time window.",
                "Dashboard export now produces a CSV snapshot of the currently selected range."
            ))
            .build();
    }

    private DashboardSummaryDto buildCoachDashboard(User coach, DashboardRange range) {
        LocalDate today = LocalDate.now();
        LocalDate startDate = range.getStartDate(today);
        List<User> climbers = userRepository.findByRoleOrderByCreatedAtDesc(UserRole.CLIMBER);
        List<ClimbLog> filteredClimbLogs = filterClimbsByRange(climbLogRepository.findAll(), startDate);
        List<Feedback> coachFeedback = filterFeedbackByRange(
            feedbackRepository.findByCoachIdOrderByCreatedAtDesc(coach.getId()),
            startDate
        );
        Map<Long, Long> climbsPerClimber = filteredClimbLogs.stream()
            .collect(Collectors.groupingBy(climb -> climb.getUser().getId(), Collectors.counting()));
        Map<Long, Long> completedPerClimber = filteredClimbLogs.stream()
            .filter(climb -> climb.getStatus() == ClimbStatus.COMPLETED)
            .collect(Collectors.groupingBy(climb -> climb.getUser().getId(), Collectors.counting()));
        long activeClimberCount = Stream.concat(
                filteredClimbLogs.stream().map(climb -> climb.getUser().getId()),
                coachFeedback.stream().map(feedback -> feedback.getClimber().getId())
            )
            .distinct()
            .count();
        long reviewCount = coachFeedback.size();
        long totalClimbLogs = filteredClimbLogs.size();
        List<DashboardBreakdownItemDto> breakdown = climbers.stream()
            .filter(climber -> climbsPerClimber.containsKey(climber.getId()))
            .sorted((left, right) -> Long.compare(
                climbsPerClimber.getOrDefault(right.getId(), 0L),
                climbsPerClimber.getOrDefault(left.getId(), 0L)
            ))
            .limit(5)
            .map(climber -> DashboardBreakdownItemDto.builder()
                .label(climber.getName())
                .value(climbsPerClimber.getOrDefault(climber.getId(), 0L))
                .helper(completedPerClimber.getOrDefault(climber.getId(), 0L) + " completed")
                .build())
            .toList();
        List<DashboardActivityDto> recentActivity = coachFeedback.stream()
            .limit(5)
            .map(this::toFeedbackActivity)
            .toList();
        List<DashboardChartDto> charts = List.of(
            buildMonthlyChart(
                "Review trend",
                "Feedback authored within " + range.getLabel().toLowerCase(Locale.ENGLISH),
                coachFeedback.stream().map(feedback -> feedback.getCreatedAt().toLocalDate()).toList(),
                "reviews",
                range,
                today
            ),
            buildCategoryChart("Rating mix", "How your filtered reviews are distributed", countRatingMix(coachFeedback), "reviews", 5),
            buildCategoryChart("Roster load", "Top climbers by filtered logged sessions", countRosterLoad(climbers, climbsPerClimber), "logs", 5)
        );

        return DashboardSummaryDto.builder()
            .audience("COACH")
            .range(range)
            .rangeLabel(range.getLabel())
            .title("Coach dashboard")
            .summary("Coach oversight data is now range-aware, exportable, and aligned with paginated roster and feedback views.")
            .metrics(List.of(
                DashboardMetricDto.builder().label("Active Climbers").value(String.valueOf(activeClimberCount)).numericValue(activeClimberCount).helper("Climbers active in range").build(),
                DashboardMetricDto.builder().label("Reviews Written").value(String.valueOf(reviewCount)).numericValue(reviewCount).helper("Feedback authored").build(),
                DashboardMetricDto.builder().label("Total Logged Sessions").value(String.valueOf(totalClimbLogs)).numericValue(totalClimbLogs).helper("Observed volume").build()
            ))
            .breakdown(breakdown)
            .charts(charts)
            .recentActivity(recentActivity)
            .highlights(List.of(
                activeClimberCount == 0
                    ? "No climbers are active in this time window yet."
                    : "Roster load now responds to the same range filter as your charts and metrics.",
                reviewCount == 0
                    ? "No feedback authored in this range yet."
                    : "Coach feedback history and dashboard now share the same date window and sorting language.",
                "Badge rule management is now isolated behind dedicated coach-only routes instead of the public badge catalog route."
            ))
            .build();
    }

    private List<ClimbLog> filterClimbsByRange(List<ClimbLog> climbLogs, LocalDate startDate) {
        if (startDate == null) {
            return climbLogs;
        }
        return climbLogs.stream()
            .filter(climbLog -> !climbLog.getDate().isBefore(startDate))
            .toList();
    }

    private List<Feedback> filterFeedbackByRange(List<Feedback> feedbackEntries, LocalDate startDate) {
        if (startDate == null) {
            return feedbackEntries;
        }
        return feedbackEntries.stream()
            .filter(feedback -> !feedback.getCreatedAt().toLocalDate().isBefore(startDate))
            .toList();
    }

    private List<DashboardActivityDto> buildClimberActivity(List<ClimbLog> climbLogs, List<Feedback> feedbackEntries) {
        List<DashboardActivityDto> climbActivities = climbLogs.stream()
            .limit(3)
            .map(this::toClimbActivity)
            .toList();
        List<DashboardActivityDto> feedbackActivities = feedbackEntries.stream()
            .limit(2)
            .map(this::toFeedbackActivity)
            .toList();

        return Stream.concat(climbActivities.stream(), feedbackActivities.stream()).toList();
    }

    private DashboardActivityDto toClimbActivity(ClimbLog climbLog) {
        return DashboardActivityDto.builder()
            .title(climbLog.getRouteName())
            .subtitle(climbLog.getDifficulty() + " at " + climbLog.getVenue())
            .meta(climbLog.getStatus().name())
            .build();
    }

    private DashboardActivityDto toFeedbackActivity(Feedback feedback) {
        return DashboardActivityDto.builder()
            .title(feedback.getClimbLog().getRouteName())
            .subtitle(feedback.getCoach().getName() + " -> " + feedback.getClimber().getName())
            .meta("Rating " + feedback.getRating() + "/5")
            .build();
    }

    private DashboardChartDto buildMonthlyChart(
        String title,
        String subtitle,
        List<LocalDate> dates,
        String unitLabel,
        DashboardRange range,
        LocalDate today
    ) {
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMM", Locale.ENGLISH);
        List<YearMonth> window = resolveChartWindow(range, today);
        Map<YearMonth, Long> counts = dates.stream()
            .collect(Collectors.groupingBy(YearMonth::from, Collectors.counting()));

        return DashboardChartDto.builder()
            .title(title)
            .subtitle(subtitle)
            .format("bar")
            .points(window.stream()
                .map(month -> DashboardChartPointDto.builder()
                    .label(month.format(formatter))
                    .value(counts.getOrDefault(month, 0L))
                    .helper(counts.getOrDefault(month, 0L) + " " + unitLabel)
                    .build())
                .toList())
            .build();
    }

    private List<YearMonth> resolveChartWindow(DashboardRange range, LocalDate today) {
        YearMonth endMonth = YearMonth.from(today);
        LocalDate startDate = range.getStartDate(today);
        YearMonth startMonth = startDate == null ? endMonth.minusMonths(5) : YearMonth.from(startDate);
        int monthCount = (int) ChronoUnit.MONTHS.between(startMonth, endMonth) + 1;
        int cappedWindow = Math.min(Math.max(monthCount, 1), 6);

        return java.util.stream.IntStream.rangeClosed(0, cappedWindow - 1)
            .mapToObj(offset -> endMonth.minusMonths(cappedWindow - 1L - offset))
            .toList();
    }

    private DashboardChartDto buildCategoryChart(
        String title,
        String subtitle,
        Map<String, Long> rawCounts,
        String unitLabel,
        int limit
    ) {
        return DashboardChartDto.builder()
            .title(title)
            .subtitle(subtitle)
            .format("bar")
            .points(rawCounts.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed().thenComparing(Map.Entry.comparingByKey()))
                .limit(limit)
                .map(entry -> DashboardChartPointDto.builder()
                    .label(entry.getKey())
                    .value(entry.getValue())
                    .helper(entry.getValue() + " " + unitLabel)
                    .build())
                .toList())
            .build();
    }

    private <T> Map<String, Long> countByLabel(List<T> source, Function<T, String> keyExtractor) {
        return source.stream()
            .collect(Collectors.groupingBy(keyExtractor, Collectors.counting()));
    }

    private Map<String, Long> countRatingMix(List<Feedback> feedbackEntries) {
        LinkedHashMap<String, Long> result = new LinkedHashMap<>();
        for (int rating = 5; rating >= 1; rating--) {
            int targetRating = rating;
            result.put(
                rating + " stars",
                feedbackEntries.stream().filter(feedback -> feedback.getRating() == targetRating).count()
            );
        }
        return result;
    }

    private Map<String, Long> countRosterLoad(List<User> climbers, Map<Long, Long> climbsPerClimber) {
        return climbers.stream()
            .filter(user -> climbsPerClimber.containsKey(user.getId()))
            .sorted(Comparator.comparingLong((User user) -> climbsPerClimber.getOrDefault(user.getId(), 0L)).reversed())
            .limit(5)
            .collect(Collectors.toMap(
                User::getName,
                user -> climbsPerClimber.getOrDefault(user.getId(), 0L),
                (left, right) -> left,
                LinkedHashMap::new
            ));
    }

    private DashboardRange resolveRange(DashboardRange range) {
        return range == null ? DashboardRange.LAST_180_DAYS : range;
    }

    private void appendCsvRow(StringBuilder csv, String section, String group, String label, String value, String helper) {
        csv.append(escapeCsv(section)).append(',')
            .append(escapeCsv(group)).append(',')
            .append(escapeCsv(label)).append(',')
            .append(escapeCsv(value)).append(',')
            .append(escapeCsv(helper)).append('\n');
    }

    private String escapeCsv(String value) {
        String safe = value == null ? "" : value;
        String escaped = safe.replace("\"", "\"\"");
        return "\"" + escaped + "\"";
    }
}
