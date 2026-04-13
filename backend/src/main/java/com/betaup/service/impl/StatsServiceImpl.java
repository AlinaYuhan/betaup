package com.betaup.service.impl;

import com.betaup.dto.climb.GradeStatDto;
import com.betaup.dto.stats.StatsBucketDto;
import com.betaup.dto.stats.StatsPeriodDto;
import com.betaup.dto.stats.StatsSummaryDto;
import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbResult;
import com.betaup.entity.ClimbStatus;
import com.betaup.entity.User;
import com.betaup.repository.ClimbLogRepository;
import com.betaup.repository.ClimbSessionRepository;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.temporal.WeekFields;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class StatsServiceImpl implements com.betaup.service.StatsService {

    private static final List<String> GRADE_ORDER = List.of(
        "VB", "V0", "V1", "V2", "V3", "V4", "V5", "V6", "V7", "V8", "V9", "V10", "V11", "V12"
    );

    private final ClimbLogRepository climbLogRepository;
    private final ClimbSessionRepository climbSessionRepository;

    @Override
    public StatsPeriodDto getStats(User user, String period) {
        Long userId = user.getId();
        List<ClimbLog> allLogs = climbLogRepository.findByUserIdOrderByDateDescCreatedAtDesc(userId);

        List<StatsBucketDto> buckets = buildBuckets(allLogs, period);
        List<GradeStatDto> gradeDistribution = buildGradeDistribution(allLogs);
        StatsSummaryDto summary = buildSummary(user, allLogs);

        return StatsPeriodDto.builder()
            .period(period.toUpperCase())
            .buckets(buckets)
            .gradeDistribution(gradeDistribution)
            .summary(summary)
            .build();
    }

    // ── private helpers ────────────────────────────────────────────────────────

    private List<StatsBucketDto> buildBuckets(List<ClimbLog> logs, String period) {
        return switch (period.toUpperCase()) {
            case "WEEK" -> buildWeekBuckets(logs, 8);
            case "MONTH" -> buildMonthBuckets(logs, 6);
            default -> buildMonthBuckets(logs, 999); // ALL: all months
        };
    }

    private List<StatsBucketDto> buildWeekBuckets(List<ClimbLog> logs, int count) {
        LocalDate today = LocalDate.now();
        WeekFields wf = WeekFields.of(Locale.getDefault());
        // Generate last `count` week-start dates (Monday of each week)
        List<LocalDate> weekStarts = new ArrayList<>();
        LocalDate weekStart = today.with(wf.dayOfWeek(), 1);
        for (int i = 0; i < count; i++) {
            weekStarts.add(0, weekStart.minusWeeks(i));
        }

        // Group logs by week-start
        Map<LocalDate, List<ClimbLog>> byWeek = logs.stream().collect(
            Collectors.groupingBy(log -> log.getDate().with(wf.dayOfWeek(), 1))
        );

        return weekStarts.stream().map(ws -> {
            List<ClimbLog> week = byWeek.getOrDefault(ws, List.of());
            String label = ws.format(DateTimeFormatter.ofPattern("M/d"));
            return toBucket(label, week);
        }).toList();
    }

    private List<StatsBucketDto> buildMonthBuckets(List<ClimbLog> logs, int maxMonths) {
        // Collect all year-month keys that appear in logs
        Map<String, List<ClimbLog>> byMonth = new LinkedHashMap<>();
        for (ClimbLog log : logs) {
            String key = log.getDate().format(DateTimeFormatter.ofPattern("yyyy-MM"));
            byMonth.computeIfAbsent(key, k -> new ArrayList<>()).add(log);
        }

        if (byMonth.isEmpty()) return List.of();

        // Sort keys ascending, take last maxMonths
        List<String> keys = byMonth.keySet().stream().sorted().toList();
        List<String> limited = keys.size() > maxMonths
            ? keys.subList(keys.size() - maxMonths, keys.size())
            : keys;

        return limited.stream().map(key -> {
            List<ClimbLog> month = byMonth.get(key);
            // label: "4月" for 2026-04
            int monthNum = Integer.parseInt(key.substring(5));
            String label = monthNum + "月";
            return toBucket(label, month);
        }).toList();
    }

    private StatsBucketDto toBucket(String label, List<ClimbLog> logs) {
        int flashes = 0, sends = 0, attempts = 0;
        for (ClimbLog log : logs) {
            if (log.getResult() == ClimbResult.FLASH) flashes++;
            else if (log.getResult() == ClimbResult.SEND) sends++;
            else attempts++;
        }
        return StatsBucketDto.builder()
            .label(label)
            .climbCount(logs.size())
            .flashCount(flashes)
            .sendCount(sends)
            .attemptCount(attempts)
            .build();
    }

    private List<GradeStatDto> buildGradeDistribution(List<ClimbLog> logs) {
        Map<String, List<ClimbLog>> byGrade = logs.stream()
            .collect(Collectors.groupingBy(ClimbLog::getDifficulty));

        return byGrade.entrySet().stream().map(e -> {
            List<ClimbLog> g = e.getValue();
            long flashes = g.stream().filter(l -> l.getResult() == ClimbResult.FLASH).count();
            long sends = g.stream().filter(l ->
                l.getResult() == ClimbResult.SEND
                || (l.getResult() == null && l.getStatus() == ClimbStatus.COMPLETED)
            ).count();
            return GradeStatDto.builder()
                .difficulty(e.getKey())
                .total(g.size())
                .sends(sends + flashes)  // sends column = total completed (Flash+Send)
                .flashes(flashes)
                .build();
        }).sorted(Comparator.comparingInt(dto -> {
            int idx = GRADE_ORDER.indexOf(dto.getDifficulty());
            return idx < 0 ? 999 : idx;
        })).toList();
    }

    private StatsSummaryDto buildSummary(User user, List<ClimbLog> logs) {
        int flashes = 0, sends = 0, attempts = 0;
        String topGrade = null;
        int topGradeIdx = -1;

        for (ClimbLog log : logs) {
            if (log.getResult() == ClimbResult.FLASH) {
                flashes++;
                int idx = GRADE_ORDER.indexOf(log.getDifficulty());
                if (idx > topGradeIdx) { topGradeIdx = idx; topGrade = log.getDifficulty(); }
            } else if (log.getResult() == ClimbResult.SEND) {
                sends++;
                int idx = GRADE_ORDER.indexOf(log.getDifficulty());
                if (idx > topGradeIdx) { topGradeIdx = idx; topGrade = log.getDifficulty(); }
            } else {
                attempts++;
            }
        }

        int total = logs.size();
        int flashRate = total > 0 ? (int) Math.round(flashes * 100.0 / total) : 0;

        long totalSessions = climbSessionRepository
            .findByUserIdAndEndTimeIsNotNullOrderByStartTimeDesc(
                user.getId(),
                PageRequest.of(0, Integer.MAX_VALUE, Sort.unsorted())
            ).getTotalElements();

        return StatsSummaryDto.builder()
            .totalClimbs(total)
            .totalFlashes(flashes)
            .totalSends(sends)
            .totalAttempts(attempts)
            .flashRatePct(flashRate)
            .totalSessions((int) totalSessions)
            .topGrade(topGrade)
            .build();
    }
}
