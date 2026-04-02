package com.betaup.util;

import java.time.LocalDateTime;
import java.time.ZoneOffset;

public final class TimeUtil {

    private TimeUtil() {
    }

    public static LocalDateTime utcNow() {
        return LocalDateTime.now(ZoneOffset.UTC);
    }
}
