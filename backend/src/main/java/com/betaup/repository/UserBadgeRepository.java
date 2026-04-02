package com.betaup.repository;

import com.betaup.entity.UserBadge;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserBadgeRepository extends JpaRepository<UserBadge, Long> {

    List<UserBadge> findByUserId(Long userId);

    List<UserBadge> findByUserIdOrderByAwardedAtDesc(Long userId);

    long countByUserId(Long userId);

    boolean existsByUserIdAndBadgeId(Long userId, Long badgeId);

    void deleteByBadgeId(Long badgeId);
}
