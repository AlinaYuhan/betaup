package com.betaup.dto.dashboard;

import java.time.LocalDate;

public enum DashboardRange {
    LAST_30_DAYS(30, "Last 30 days"),
    LAST_90_DAYS(90, "Last 90 days"),
    LAST_180_DAYS(180, "Last 180 days"),
    ALL_TIME(null, "All time");

    private final Integer days;
    private final String label;

    DashboardRange(Integer days, String label) {
        this.days = days;
        this.label = label;
    }

    public String getLabel() {
        return label;
    }

    public LocalDate getStartDate(LocalDate today) {
        if (days == null) {
            return null;
        }
        return today.minusDays(days - 1L);
    }
}
