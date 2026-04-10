package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.post.CreatePostRequest;
import com.betaup.dto.post.PostDto;
import com.betaup.entity.Post;
import com.betaup.entity.PostType;
import com.betaup.entity.User;
import com.betaup.entity.PostLike;
import com.betaup.repository.PostLikeRepository;
import com.betaup.repository.PostRepository;
import com.betaup.security.service.CurrentUserService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostRepository postRepository;
    private final PostLikeRepository postLikeRepository;
    private final CurrentUserService currentUserService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<PostDto>>> getPosts(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String type
    ) {
        var pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        var posts = (type != null && !type.isBlank())
            ? postRepository.findByTypeOrderByCreatedAtDesc(PostType.valueOf(type.toUpperCase()), pageable)
            : postRepository.findAllByOrderByCreatedAtDesc(pageable);

        Long currentUserId = tryGetCurrentUserId();
        List<PostDto> dtos = posts.getContent().stream()
            .map(p -> toDto(p, currentUserId))
            .toList();
        return ResponseEntity.ok(ApiResponse.success("Posts loaded.", dtos));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<PostDto>> createPost(@Valid @RequestBody CreatePostRequest request) {
        User user = currentUserService.getCurrentUser();
        Post post = Post.builder()
            .user(user)
            .content(request.getContent().trim())
            .type(request.getType() != null ? request.getType() : PostType.GENERAL)
            .build();
        Post saved = postRepository.save(post);
        return ResponseEntity.ok(ApiResponse.success("Post created.", toDto(saved, user.getId())));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deletePost(@PathVariable Long id) {
        User user = currentUserService.getCurrentUser();
        Post post = postRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Post not found."));
        if (!post.getUser().getId().equals(user.getId())) {
            throw new org.springframework.security.access.AccessDeniedException("Not your post.");
        }
        postRepository.delete(post);
        return ResponseEntity.ok(ApiResponse.success("Post deleted.", null));
    }

    PostDto toDto(Post post, Long currentUserId) {
        return PostDto.builder()
            .id(post.getId())
            .authorId(post.getUser().getId())
            .authorName(post.getUser().getName())
            .content(post.getContent())
            .type(post.getType())
            .likeCount(post.getLikeCount())
            .commentCount(post.getCommentCount())
            .likedByMe(currentUserId != null && postLikeRepository.existsByUserIdAndPostId(currentUserId, post.getId()))
            .createdAt(post.getCreatedAt())
            .build();
    }

    @PostMapping("/{id}/like")
    public ResponseEntity<ApiResponse<Void>> likePost(@PathVariable Long id) {
        User user = currentUserService.getCurrentUser();
        Post post = postRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Post not found."));
        if (!postLikeRepository.existsByUserIdAndPostId(user.getId(), id)) {
            postLikeRepository.save(PostLike.builder().user(user).post(post).build());
            post.setLikeCount(post.getLikeCount() + 1);
            postRepository.save(post);
        }
        return ResponseEntity.ok(ApiResponse.success("Liked.", null));
    }

    @DeleteMapping("/{id}/like")
    public ResponseEntity<ApiResponse<Void>> unlikePost(@PathVariable Long id) {
        User user = currentUserService.getCurrentUser();
        postLikeRepository.findByUserIdAndPostId(user.getId(), id).ifPresent(like -> {
            postLikeRepository.delete(like);
            postRepository.findById(id).ifPresent(post -> {
                post.setLikeCount(Math.max(0, post.getLikeCount() - 1));
                postRepository.save(post);
            });
        });
        return ResponseEntity.ok(ApiResponse.success("Unliked.", null));
    }

    private Long tryGetCurrentUserId() {
        try {
            return currentUserService.getCurrentUser().getId();
        } catch (Exception e) {
            return null;
        }
    }
}
