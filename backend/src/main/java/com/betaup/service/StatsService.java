package com.betaup.service;

import com.betaup.dto.stats.StatsPeriodDto;
import com.betaup.entity.User;

public interface StatsService {

    StatsPeriodDto getStats(User user, String period);
}
