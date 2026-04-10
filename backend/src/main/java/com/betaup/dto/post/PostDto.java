package com.betaup.dto.post;

import com.betaup.entity.PostType;
import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class PostDto {
    private Long id;
    private Long authorId;
    private String authorName;
    private String content;
    private PostType type;
    private int likeCount;
    private int commentCount;
    private boolean likedByMe;
    private LocalDateTime createdAt;
}
