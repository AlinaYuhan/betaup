package com.betaup.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(
    name = "follows",
    uniqueConstraints = @UniqueConstraint(columnNames = {"follower_id", "following_id"})
)
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Follow {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "follower_id", nullable = false)
    private User follower;   // 关注者

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "following_id", nullable = false)
    private User following;  // 被关注者

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
