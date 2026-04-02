package com.betaup.repository;

import com.betaup.entity.Badge;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface BadgeRepository extends JpaRepository<Badge, Long> {

    Optional<Badge> findByBadgeKey(String badgeKey);

    boolean existsByBadgeKeyIgnoreCase(String badgeKey);

    List<Badge> findAllByOrderByThresholdAsc();
}
