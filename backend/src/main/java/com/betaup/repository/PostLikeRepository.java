package com.betaup.repository;

import com.betaup.entity.PostLike;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PostLikeRepository extends JpaRepository<PostLike, Long> {
    Optional<PostLike> findByUserIdAndPostId(Long userId, Long postId);
    boolean existsByUserIdAndPostId(Long userId, Long postId);

    @Query("SELECT COUNT(pl) FROM PostLike pl WHERE pl.post.user.id = :userId")
    long countByPostUserId(@Param("userId") Long userId);
}
