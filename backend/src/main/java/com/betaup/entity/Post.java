package com.betaup.entity;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "posts", indexes = {
    @Index(name = "idx_posts_user_created", columnList = "user_id, created_at"),
    @Index(name = "idx_posts_type_created", columnList = "type, created_at")
})
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Post {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(nullable = false, length = 500)
    private String content;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(nullable = false, length = 20)
    private PostType type;

    @Column(columnDefinition = "TEXT")
    private String mediaPath;

    @Enumerated(EnumType.STRING)
    @JdbcTypeCode(SqlTypes.VARCHAR)
    @Column(length = 20)
    private PostMediaKind mediaKind;

    @Column(name = "media_count", nullable = false)
    private int mediaCount = 0;

    // Denormalized counters for fast reads
    @Column(nullable = false)
    private int likeCount = 0;

    @Column(nullable = false)
    private int commentCount = 0;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    // Helper methods for multi-image support
    private static final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Get media paths as a list. Handles both single-path (string) and multi-path (JSON array) formats.
     */
    public List<String> getMediaPaths() {
        if (mediaPath == null || mediaPath.isBlank()) {
            return Collections.emptyList();
        }

        // Check if it's a JSON array
        if (mediaPath.trim().startsWith("[")) {
            try {
                return objectMapper.readValue(mediaPath, new TypeReference<List<String>>() {});
            } catch (JsonProcessingException e) {
                // Fallback to single path if JSON parsing fails
                return List.of(mediaPath);
            }
        }

        // Single path (backward compatibility)
        return List.of(mediaPath);
    }

    /**
     * Set media paths from a list. Stores as JSON array if multiple, single string if one.
     */
    public void setMediaPaths(List<String> paths) {
        if (paths == null || paths.isEmpty()) {
            this.mediaPath = null;
            this.mediaCount = 0;
            return;
        }

        this.mediaCount = paths.size();

        if (paths.size() == 1) {
            // Store as single string for backward compatibility
            this.mediaPath = paths.get(0);
        } else {
            // Store as JSON array
            try {
                this.mediaPath = objectMapper.writeValueAsString(paths);
            } catch (JsonProcessingException e) {
                throw new RuntimeException("Failed to serialize media paths", e);
            }
        }
    }
}
