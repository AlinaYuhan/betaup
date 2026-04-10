package com.betaup.repository;

import com.betaup.entity.Follow;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface FollowRepository extends JpaRepository<Follow, Long> {
    boolean existsByFollowerIdAndFollowingId(Long followerId, Long followingId);
    Optional<Follow> findByFollowerIdAndFollowingId(Long followerId, Long followingId);
    long countByFollowerId(Long followerId);
    long countByFollowingId(Long followingId);

    /** 获取关注了 followingId 的所有用户（即 followingId 的粉丝列表） */
    @EntityGraph(attributePaths = {"follower"})
    List<Follow> findByFollowingId(Long followingId);

    /** 获取 followerId 所关注的所有用户（即 followerId 的关注列表） */
    @EntityGraph(attributePaths = {"following"})
    List<Follow> findByFollowerId(Long followerId);
}
