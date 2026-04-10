package com.betaup.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

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
    @Column(nullable = false, length = 20)
    private PostType type;

    // Denormalized counters for fast reads
    @Column(nullable = false)
    private int likeCount = 0;

    @Column(nullable = false)
    private int commentCount = 0;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
