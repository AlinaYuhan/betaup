package com.betaup.repository;

import com.betaup.entity.ClimbLog;
import com.betaup.entity.ClimbStatus;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ClimbLogRepository extends JpaRepository<ClimbLog, Long> {

    List<ClimbLog> findByUserId(Long userId);

    Page<ClimbLog> findByUserId(Long userId, Pageable pageable);

    List<ClimbLog> findByUserIdOrderByDateDescCreatedAtDesc(Long userId);

    List<ClimbLog> findTop5ByUserIdOrderByDateDescCreatedAtDesc(Long userId);

    List<ClimbLog> findTop5ByOrderByCreatedAtDesc();

    long countByUserId(Long userId);

    long countByUserIdAndStatus(Long userId, ClimbStatus status);
}
