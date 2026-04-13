package com.betaup.dto.post;

import com.betaup.dto.badge.BadgeProgressDto;
import com.betaup.entity.PostType;
import java.time.LocalDateTime;
import java.util.List;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PostDto {
    private Long id;
    private Long authorId;
    private String authorName;
    private boolean authorIsCoach;
    private String content;
    private PostType type;
    private int likeCount;
    private int commentCount;
    private boolean likedByMe;
    private LocalDateTime createdAt;
    /** Non-null only on the createPost response; null/absent otherwise. */
    private List<BadgeProgressDto> newlyUnlockedBadges;
}
