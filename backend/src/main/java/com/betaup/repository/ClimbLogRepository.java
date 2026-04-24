package com.betaup.repository;

import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbResult;
import com.betaup.entity.ClimbStatus;
import com.betaup.repository.projection.UserCountProjection;
import java.time.LocalDate;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ClimbLogRepository extends JpaRepository<ClimbLog, Long> {

    List<ClimbLog> findByUserId(Long userId);

    @EntityGraph(attributePaths = "user")
    Page<ClimbLog> findByUserId(Long userId, Pageable pageable);

    @EntityGraph(attributePaths = "user")
    List<ClimbLog> findByUserIdAndSessionIdOrderByCreatedAtAsc(Long userId, Long sessionId);

    @EntityGraph(attributePaths = "user")
    List<ClimbLog> findByUserIdOrderByDateDescCreatedAtDesc(Long userId);

    @EntityGraph(attributePaths = "user")
    List<ClimbLog> findByUserIdAndDateGreaterThanEqualOrderByDateDescCreatedAtDesc(Long userId, LocalDate startDate);

    @EntityGraph(attributePaths = "user")
    List<ClimbLog> findTop5ByUserIdOrderByDateDescCreatedAtDesc(Long userId);

    @EntityGraph(attributePaths = "user")
    List<ClimbLog> findTop5ByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = "user")
    List<ClimbLog> findAllByOrderByDateDescCreatedAtDesc();

    @EntityGraph(attributePaths = "user")
    List<ClimbLog> findByDateGreaterThanEqualOrderByDateDescCreatedAtDesc(LocalDate startDate);

    long countByUserId(Long userId);

    long countByUserIdAndStatus(Long userId, ClimbStatus status);

    long countByUserIdAndResult(Long userId, ClimbResult result);

    @EntityGraph(attributePaths = "user")
    @Query("""
        select climb
        from ClimbLog climb
        where climb.id = :climbLogId
        """)
    Optional<ClimbLog> findDetailedById(@Param("climbLogId") Long climbLogId);

    @Query("""
        select climb.user.id as userId, count(climb) as total
        from ClimbLog climb
        where climb.user.id in :userIds
        group by climb.user.id
        """)
    List<UserCountProjection> countByUserIds(@Param("userIds") Collection<Long> userIds);

    List<ClimbLog> findBySessionIdIn(Collection<Long> sessionIds);

    void deleteBySessionId(Long sessionId);
}
