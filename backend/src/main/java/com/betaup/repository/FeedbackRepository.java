package com.betaup.repository;

import com.betaup.entity.Feedback;
import com.betaup.repository.projection.UserCountProjection;
import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FeedbackRepository extends JpaRepository<Feedback, Long> {

    List<Feedback> findByClimberId(Long climberId);

    List<Feedback> findByCoachId(Long coachId);

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    List<Feedback> findByClimberIdOrderByCreatedAtDesc(Long climberId);

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    List<Feedback> findByCoachIdOrderByCreatedAtDesc(Long coachId);

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    List<Feedback> findByClimberIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(Long climberId, LocalDateTime startDate);

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    List<Feedback> findByCoachIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(Long coachId, LocalDateTime startDate);

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    @Query("""
        select feedback
        from Feedback feedback
        where feedback.climber.id = :climberId
          and (:rating is null or feedback.rating = :rating)
        """)
    Page<Feedback> findClimberHistory(
        @Param("climberId") Long climberId,
        @Param("rating") Integer rating,
        Pageable pageable
    );

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    @Query("""
        select feedback
        from Feedback feedback
        where feedback.coach.id = :coachId
          and (:climberId is null or feedback.climber.id = :climberId)
          and (:rating is null or feedback.rating = :rating)
        """)
    Page<Feedback> findCoachHistory(
        @Param("coachId") Long coachId,
        @Param("climberId") Long climberId,
        @Param("rating") Integer rating,
        Pageable pageable
    );

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    List<Feedback> findTop5ByClimberIdOrderByCreatedAtDesc(Long climberId);

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    List<Feedback> findTop5ByCoachIdOrderByCreatedAtDesc(Long coachId);

    long countByClimberId(Long climberId);

    long countByCoachId(Long coachId);

    long countByClimbLogId(Long climbLogId);

    @EntityGraph(attributePaths = {"climbLog", "climbLog.user", "coach", "climber"})
    @Query("""
        select feedback
        from Feedback feedback
        where feedback.id = :feedbackId
        """)
    Optional<Feedback> findDetailedById(@Param("feedbackId") Long feedbackId);

    @Query("""
        select feedback.climber.id as userId, count(feedback) as total
        from Feedback feedback
        where feedback.climber.id in :climberIds
        group by feedback.climber.id
        """)
    List<UserCountProjection> countByClimberIds(@Param("climberIds") Collection<Long> climberIds);
}
