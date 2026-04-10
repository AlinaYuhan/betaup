package com.betaup.repository;

import com.betaup.entity.Post;
import com.betaup.entity.PostType;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PostRepository extends JpaRepository<Post, Long> {
    @EntityGraph(attributePaths = {"user"})
    Page<Post> findAllByOrderByCreatedAtDesc(Pageable pageable);

    @EntityGraph(attributePaths = {"user"})
    Page<Post> findByTypeOrderByCreatedAtDesc(PostType type, Pageable pageable);

    @EntityGraph(attributePaths = {"user"})
    Page<Post> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);

    long countByUserId(Long userId);
}
