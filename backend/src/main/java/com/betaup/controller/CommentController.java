package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.post.CommentDto;
import com.betaup.dto.post.CreateCommentRequest;
import com.betaup.entity.Comment;
import com.betaup.entity.Post;
import com.betaup.entity.User;
import com.betaup.repository.CommentRepository;
import com.betaup.repository.PostRepository;
import com.betaup.security.service.CurrentUserService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/posts/{postId}/comments")
@RequiredArgsConstructor
public class CommentController {

    private final CommentRepository commentRepository;
    private final PostRepository postRepository;
    private final CurrentUserService currentUserService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<CommentDto>>> getComments(@PathVariable Long postId) {
        List<CommentDto> dtos = commentRepository.findByPostIdOrderByCreatedAtAsc(postId)
            .stream().map(this::toDto).toList();
        return ResponseEntity.ok(ApiResponse.success("Comments loaded.", dtos));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CommentDto>> addComment(
        @PathVariable Long postId,
        @Valid @RequestBody CreateCommentRequest request
    ) {
        User user = currentUserService.getCurrentUser();
        Post post = postRepository.findById(postId)
            .orElseThrow(() -> new IllegalArgumentException("Post not found."));
        Comment comment = Comment.builder()
            .post(post)
            .user(user)
            .content(request.getContent().trim())
            .build();
        commentRepository.save(comment);
        post.setCommentCount(post.getCommentCount() + 1);
        postRepository.save(post);
        return ResponseEntity.ok(ApiResponse.success("Comment added.", toDto(comment)));
    }

    @DeleteMapping("/{commentId}")
    public ResponseEntity<ApiResponse<Void>> deleteComment(
        @PathVariable Long postId,
        @PathVariable Long commentId
    ) {
        User user = currentUserService.getCurrentUser();
        Comment comment = commentRepository.findById(commentId)
            .orElseThrow(() -> new IllegalArgumentException("Comment not found."));
        if (!comment.getUser().getId().equals(user.getId())) {
            throw new org.springframework.security.access.AccessDeniedException("Not your comment.");
        }
        commentRepository.delete(comment);
        postRepository.findById(postId).ifPresent(post -> {
            post.setCommentCount(Math.max(0, post.getCommentCount() - 1));
            postRepository.save(post);
        });
        return ResponseEntity.ok(ApiResponse.success("Comment deleted.", null));
    }

    private CommentDto toDto(Comment comment) {
        return CommentDto.builder()
            .id(comment.getId())
            .authorId(comment.getUser().getId())
            .authorName(comment.getUser().getName())
            .content(comment.getContent())
            .createdAt(comment.getCreatedAt())
            .build();
    }
}
