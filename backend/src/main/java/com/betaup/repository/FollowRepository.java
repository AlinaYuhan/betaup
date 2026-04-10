package com.betaup.repository;

import com.betaup.entity.Follow;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FollowRepository extends JpaRepository<Follow, Long> {
    boolean existsByFollowerIdAndFollowingId(Long followerId, Long followingId);
    Optional<Follow> findByFollowerIdAndFollowingId(Long followerId, Long followingId);
    long countByFollowerId(Long followerId);
    long countByFollowingId(Long followingId);
}
