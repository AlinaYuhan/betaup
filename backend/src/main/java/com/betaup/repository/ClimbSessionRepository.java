package com.betaup.repository;

import com.betaup.entity.ClimbSession;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClimbSessionRepository extends JpaRepository<ClimbSession, Long> {

    @EntityGraph(attributePaths = "user")
    Optional<ClimbSession> findByUserIdAndEndTimeIsNull(Long userId);

    @EntityGraph(attributePaths = "user")
    Optional<ClimbSession> findByIdAndUserId(Long id, Long userId);

    Page<ClimbSession> findByUserIdAndEndTimeIsNotNullOrderByStartTimeDesc(Long userId, Pageable pageable);
}
