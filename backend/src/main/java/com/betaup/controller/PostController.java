package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.dto.post.CreatePostRequest;
import com.betaup.dto.post.PostDto;
import com.betaup.entity.Notification;
import com.betaup.entity.Post;
import com.betaup.entity.PostType;
import com.betaup.entity.User;
import com.betaup.entity.PostLike;
import com.betaup.repository.NotificationRepository;
import com.betaup.repository.PostLikeRepository;
import com.betaup.repository.PostRepository;
import com.betaup.security.service.CurrentUserService;
import com.betaup.service.BadgeAutomationService;
import com.betaup.service.PostMediaStorageService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/posts")
@RequiredArgsConstructor
public class PostController {

    private final PostRepository postRepository;
    private final PostLikeRepository postLikeRepository;
    private final NotificationRepository notificationRepository;
    private final CurrentUserService currentUserService;
    private final BadgeAutomationService badgeAutomationService;
    private final PostMediaStorageService postMediaStorageService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<PostDto>>> getPosts(
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "20") int size,
        @RequestParam(required = false) String type
    ) {
        var pageable = PageRequest.of(page, size, Sort.by("createdAt").descending());
        var posts = (type != null && type.equalsIgnoreCase("BETA"))
            ? postRepository.findByIsBetaTrueOrderByCreatedAtDesc(pageable)
            : (type != null && !type.isBlank())
                ? postRepository.findByTypeOrderByCreatedAtDesc(PostType.valueOf(type.toUpperCase()), pageable)
                : postRepository.findAllByOrderByCreatedAtDesc(pageable);

        Long currentUserId = tryGetCurrentUserId();
        List<PostDto> dtos = posts.getContent().stream()
            .map(p -> toDto(p, currentUserId))
            .toList();
        return ResponseEntity.ok(ApiResponse.success("Posts loaded.", dtos));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<PostDto>> getPost(@PathVariable Long id) {
        Long currentUserId = tryGetCurrentUserId();
        Post post = postRepository.findWithUserById(id)
            .orElseThrow(() -> new IllegalArgumentException("Post not found."));
        return ResponseEntity.ok(ApiResponse.success("Post loaded.", toDto(post, currentUserId)));
    }

    @PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
    public ResponseEntity<ApiResponse<PostDto>> createPost(@Valid @RequestBody CreatePostRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Post created.", createPostInternal(request, null)));
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<PostDto>> createPostWithMedia(
        @Valid @ModelAttribute CreatePostRequest request,
        @RequestParam(value = "media", required = false) List<MultipartFile> media
    ) {
        return ResponseEntity.ok(ApiResponse.success("Post created.", createPostInternal(request, media)));
    }

    private PostDto createPostInternal(CreatePostRequest request, List<MultipartFile> media) {
        User user = currentUserService.getCurrentUser();
        String content = request.getContent() == null ? "" : request.getContent().trim();
        List<MultipartFile> normalizedMedia = (media != null && !media.isEmpty()) ? media : null;
        if (content.isBlank() && normalizedMedia == null) {
            throw new IllegalArgumentException("Post content or media is required.");
        }

        List<PostMediaStorageService.StoredMedia> storedMediaList = null;
        Post saved;
        try {
            if (normalizedMedia != null) {
                if (normalizedMedia.size() == 1) {
                    // Single media (image or video)
                    storedMediaList = List.of(postMediaStorageService.save(normalizedMedia.get(0)));
                } else {
                    // Multiple images (2-6)
                    storedMediaList = postMediaStorageService.saveMultiple(normalizedMedia);
                }
            }

            Post post = Post.builder()
                .user(user)
                .content(content)
                .type(request.getType() != null ? request.getType() : PostType.GENERAL)
                .isBeta(request.isBeta())
                .routeName(request.getRouteName())
                .build();

            if (storedMediaList != null && !storedMediaList.isEmpty()) {
                List<String> paths = storedMediaList.stream()
                    .map(PostMediaStorageService.StoredMedia::path)
                    .toList();
                post.setMediaPaths(paths);
                post.setMediaKind(storedMediaList.get(0).kind());
            }

            saved = postRepository.save(post);
        } catch (RuntimeException exception) {
            if (storedMediaList != null) {
                for (PostMediaStorageService.StoredMedia stored : storedMediaList) {
                    postMediaStorageService.delete(stored.path());
                }
            }
            throw exception;
        }

        PostDto dto = toDto(saved, user.getId());
        try {
            var newBadges = badgeAutomationService.evaluateUserBadges(user);
            dto.setNewlyUnlockedBadges(newBadges.isEmpty() ? null : newBadges);
        } catch (Exception ignored) { /* badge eval must not fail the main operation */ }
        return dto;
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deletePost(@PathVariable Long id) {
        User user = currentUserService.getCurrentUser();
        Post post = postRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Post not found."));
        if (!post.getUser().getId().equals(user.getId())) {
            throw new org.springframework.security.access.AccessDeniedException("Not your post.");
        }
        postMediaStorageService.deleteMultiple(post.getMediaPaths());
        postRepository.delete(post);
        return ResponseEntity.ok(ApiResponse.success("Post deleted.", null));
    }

    PostDto toDto(Post post, Long currentUserId) {
        List<String> mediaPaths = post.getMediaPaths();
        return PostDto.builder()
            .id(post.getId())
            .authorId(post.getUser().getId())
            .authorName(post.getUser().getName())
            .authorIsCoach(post.getUser().isCoachCertified())
            .content(post.getContent())
            .type(post.getType())
            .mediaUrl(mediaPaths.isEmpty() ? null : "/uploads/" + mediaPaths.get(0))
            .mediaUrls(mediaPaths.isEmpty() ? null : mediaPaths.stream()
                .map(path -> "/uploads/" + path)
                .toList())
            .mediaKind(post.getMediaKind())
            .likeCount(post.getLikeCount())
            .commentCount(post.getCommentCount())
            .likedByMe(currentUserId != null && postLikeRepository.existsByUserIdAndPostId(currentUserId, post.getId()))
            .createdAt(post.getCreatedAt())
            .isBeta(post.isBeta())
            .routeName(post.getRouteName())
            .build();
    }

    @PostMapping("/{id}/like")
    public ResponseEntity<ApiResponse<Void>> likePost(@PathVariable Long id) {
        User user = currentUserService.getCurrentUser();
        Post post = postRepository.findWithUserById(id)
            .orElseThrow(() -> new IllegalArgumentException("Post not found."));
        if (!postLikeRepository.existsByUserIdAndPostId(user.getId(), id)) {
            postLikeRepository.save(PostLike.builder().user(user).post(post).build());
            post.setLikeCount(post.getLikeCount() + 1);
            postRepository.save(post);
            // Notify post author (skip if liking own post)
            if (!post.getUser().getId().equals(user.getId())) {
                notificationRepository.save(Notification.builder()
                    .recipient(post.getUser())
                    .type("LIKE")
                    .actorId(user.getId())
                    .actorName(user.getName())
                    .referenceId(post.getId())
                    .content(user.getName() + " 赞了你的动态")
                    .build());
            }
            // Evaluate badges for post author (LIKES_RECEIVED)
            try { badgeAutomationService.evaluateUserBadges(post.getUser()); }
            catch (Exception ignored) { /* badge eval must not fail the main operation */ }
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
