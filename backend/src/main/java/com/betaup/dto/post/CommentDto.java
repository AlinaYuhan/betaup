package com.betaup.dto.post;

import java.time.LocalDateTime;
import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class CommentDto {
    private Long id;
    private Long authorId;
    private String authorName;
    private String content;
    private LocalDateTime createdAt;
}
