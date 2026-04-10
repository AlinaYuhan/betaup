package com.betaup.repository;

import com.betaup.entity.Comment;
import java.util.List;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CommentRepository extends JpaRepository<Comment, Long> {
    @EntityGraph(attributePaths = {"user"})
    List<Comment> findByPostIdOrderByCreatedAtAsc(Long postId);
    long countByPostId(Long postId);
    long countByUserId(Long userId);
}
