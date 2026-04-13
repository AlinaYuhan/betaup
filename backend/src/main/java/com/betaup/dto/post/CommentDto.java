package com.betaup.dto.post;

import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CommentDto {
    private Long id;
    private Long parentId;
    private Long authorId;
    private String authorName;
    private boolean authorIsCoach;
    private String content;
    private LocalDateTime createdAt;
}
