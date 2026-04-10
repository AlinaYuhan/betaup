package com.betaup.dto.post;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateCommentRequest {
    @NotBlank
    @Size(max = 300)
    private String content;
}
