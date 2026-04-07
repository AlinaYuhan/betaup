package com.betaup.dto.checkin;

import java.time.LocalDateTime;
import java.util.List;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CheckInResult {
    private Long checkInId;
    private Long gymId;
    private String gymName;
    private boolean gpsVerified;
    private LocalDateTime checkedAt;
    private List<String> newBadgeKeys;  // badges unlocked by this check-in
}
