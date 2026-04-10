package com.betaup.dto.post;

import com.betaup.entity.PostType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreatePostRequest {
    @NotBlank
    @Size(max = 500)
    private String content;
    private PostType type = PostType.GENERAL;
}
