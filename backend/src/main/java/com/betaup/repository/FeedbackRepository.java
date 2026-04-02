package com.betaup.repository;

import com.betaup.entity.Feedback;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FeedbackRepository extends JpaRepository<Feedback, Long> {

    List<Feedback> findByClimberId(Long climberId);

    List<Feedback> findByCoachId(Long coachId);

    List<Feedback> findByClimberIdOrderByCreatedAtDesc(Long climberId);

    List<Feedback> findByCoachIdOrderByCreatedAtDesc(Long coachId);

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

    List<Feedback> findTop5ByClimberIdOrderByCreatedAtDesc(Long climberId);

    List<Feedback> findTop5ByCoachIdOrderByCreatedAtDesc(Long coachId);

    long countByClimberId(Long climberId);

    long countByCoachId(Long coachId);

    long countByClimbLogId(Long climbLogId);
}
