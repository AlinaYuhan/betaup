package com.betaup.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

@Entity
@Table(name = "notifications", indexes = {
    @Index(name = "idx_notifications_recipient_read", columnList = "recipient_id, is_read, created_at")
})
@Getter @Setter @Builder @NoArgsConstructor @AllArgsConstructor
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    // FOLLOW | COMMENT | LIKE
    @Column(nullable = false, length = 20)
    private String type;

    @Column(nullable = false)
    private Long actorId;

    @Column(nullable = false, length = 120)
    private String actorName;

    // postId for COMMENT/LIKE, actorId for FOLLOW
    private Long referenceId;

    @Column(nullable = false, length = 200)
    private String content;

    @Column(nullable = false)
    private boolean isRead = false;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;
}
