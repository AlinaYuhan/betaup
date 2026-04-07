package com.betaup.repository;

import com.betaup.entity.CheckIn;
import java.time.LocalDate;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CheckInRepository extends JpaRepository<CheckIn, Long> {

    boolean existsByUserIdAndGymIdAndCheckDate(Long userId, Long gymId, LocalDate checkDate);

    long countByUserId(Long userId);

    @Query("SELECT COUNT(DISTINCT c.gym.id) FROM CheckIn c WHERE c.user.id = :userId")
    long countDistinctGymsByUserId(@Param("userId") Long userId);

    List<CheckIn> findByUserIdOrderByCreatedAtDesc(Long userId);
}
