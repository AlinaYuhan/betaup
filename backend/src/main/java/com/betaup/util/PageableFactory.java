package com.betaup.util;

import com.betaup.dto.common.PageQuery;
import java.util.Map;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

public final class PageableFactory {

    private PageableFactory() {
    }

    public static Pageable create(
        PageQuery pageQuery,
        int defaultSize,
        String defaultSortBy,
        Sort.Direction defaultDirection,
        Map<String, String> sortableFields
    ) {
        int page = pageQuery == null || pageQuery.getPage() == null ? 0 : Math.max(pageQuery.getPage(), 0);
        int size = pageQuery == null || pageQuery.getSize() == null ? defaultSize : Math.min(Math.max(pageQuery.getSize(), 1), 50);

        String requestedSortBy = pageQuery == null ? null : pageQuery.getSortBy();
        String resolvedSortBy = sortableFields.getOrDefault(requestedSortBy, sortableFields.get(defaultSortBy));
        Sort.Direction direction = resolveDirection(pageQuery == null ? null : pageQuery.getSortDir(), defaultDirection);

        return PageRequest.of(page, size, Sort.by(direction, resolvedSortBy));
    }

    private static Sort.Direction resolveDirection(String rawDirection, Sort.Direction fallback) {
        if (rawDirection == null || rawDirection.isBlank()) {
            return fallback;
        }

        try {
            return Sort.Direction.fromString(rawDirection);
        } catch (IllegalArgumentException exception) {
            return fallback;
        }
    }
}
