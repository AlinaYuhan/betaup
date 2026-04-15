package com.betaup.service.impl;

import com.betaup.entity.PostMediaKind;
import com.betaup.service.PostMediaStorageService;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class PostMediaStorageServiceImpl implements PostMediaStorageService {

    private static final Map<String, PostMediaKind> SUPPORTED_TYPES = Map.of(
        "image/jpeg", PostMediaKind.IMAGE,
        "image/jpg", PostMediaKind.IMAGE,
        "image/png", PostMediaKind.IMAGE,
        "image/webp", PostMediaKind.IMAGE,
        "video/mp4", PostMediaKind.VIDEO,
        "video/webm", PostMediaKind.VIDEO,
        "video/quicktime", PostMediaKind.VIDEO
    );

    private static final Map<String, PostMediaKind> SUPPORTED_EXTENSIONS = Map.of(
        ".jpg", PostMediaKind.IMAGE,
        ".jpeg", PostMediaKind.IMAGE,
        ".png", PostMediaKind.IMAGE,
        ".webp", PostMediaKind.IMAGE,
        ".mp4", PostMediaKind.VIDEO,
        ".webm", PostMediaKind.VIDEO,
        ".mov", PostMediaKind.VIDEO
    );

    @Value("${app.upload.dir}")
    private String uploadDir;

    @Override
    public StoredMedia save(MultipartFile media) {
        if (media == null || media.isEmpty()) {
            throw new IllegalArgumentException("Media file is required.");
        }

        String originalFilename = media.getOriginalFilename();
        PostMediaKind mediaKind = resolveMediaKind(media.getContentType(), originalFilename);
        if (mediaKind == null) {
            throw new IllegalArgumentException("Only JPEG, PNG, WebP images or MP4, WebM, MOV videos are accepted.");
        }

        String subDir = mediaKind == PostMediaKind.IMAGE ? "posts/images" : "posts/videos";
        String extension = getExtension(originalFilename, mediaKind);
        String filename = UUID.randomUUID() + extension;
        Path directory = Paths.get(uploadDir, subDir);
        Path target = directory.resolve(filename);

        try {
            Files.createDirectories(directory);
            Files.copy(media.getInputStream(), target, StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException exception) {
            throw new RuntimeException("Failed to save post media.", exception);
        }

        String relativePath = subDir + "/" + filename;
        return new StoredMedia(relativePath, "/uploads/" + relativePath, mediaKind);
    }

    @Override
    public List<StoredMedia> saveMultiple(List<MultipartFile> mediaFiles) {
        if (mediaFiles == null || mediaFiles.isEmpty()) {
            throw new IllegalArgumentException("At least one media file is required.");
        }

        if (mediaFiles.size() > 6) {
            throw new IllegalArgumentException("Maximum 6 images allowed per post.");
        }

        // Validate all files are images and within size limit
        for (MultipartFile file : mediaFiles) {
            if (file.isEmpty()) {
                throw new IllegalArgumentException("Empty file detected.");
            }

            // Check file size (10MB = 10 * 1024 * 1024 bytes)
            if (file.getSize() > 10 * 1024 * 1024) {
                throw new IllegalArgumentException("Each image must be less than 10MB. File: " + file.getOriginalFilename());
            }

            String originalFilename = file.getOriginalFilename();
            PostMediaKind mediaKind = resolveMediaKind(file.getContentType(), originalFilename);

            if (mediaKind != PostMediaKind.IMAGE) {
                throw new IllegalArgumentException("Multi-image posts only support images (JPEG, PNG, WebP). Videos are not allowed.");
            }
        }

        // Save all files
        List<StoredMedia> results = new ArrayList<>();
        for (MultipartFile file : mediaFiles) {
            try {
                results.add(save(file));
            } catch (RuntimeException e) {
                // Cleanup already saved files on failure
                for (StoredMedia saved : results) {
                    delete(saved.path());
                }
                throw new RuntimeException("Failed to save multiple media files: " + e.getMessage(), e);
            }
        }

        return results;
    }

    @Override
    public void delete(String mediaPath) {
        if (mediaPath == null || mediaPath.isBlank()) {
            return;
        }

        try {
            Files.deleteIfExists(Paths.get(uploadDir, mediaPath));
        } catch (IOException ignored) {
            // Media cleanup must not fail the main operation.
        }
    }

    @Override
    public void deleteMultiple(List<String> mediaPaths) {
        if (mediaPaths == null || mediaPaths.isEmpty()) {
            return;
        }

        for (String path : mediaPaths) {
            delete(path);
        }
    }

    private PostMediaKind resolveMediaKind(String contentType, String filename) {
        if (contentType != null) {
            PostMediaKind mediaKind = SUPPORTED_TYPES.get(contentType.toLowerCase());
            if (mediaKind != null) {
                return mediaKind;
            }
        }

        return SUPPORTED_EXTENSIONS.get(extractExtension(filename));
    }

    private String getExtension(String filename, PostMediaKind mediaKind) {
        String extension = extractExtension(filename);
        if (extension != null) {
            return extension;
        }

        return mediaKind == PostMediaKind.IMAGE ? ".jpg" : ".mp4";
    }

    private String extractExtension(String filename) {
        if (filename == null) {
            return null;
        }

        int dotIndex = filename.lastIndexOf('.');
        if (dotIndex >= 0 && dotIndex < filename.length() - 1) {
            return filename.substring(dotIndex).toLowerCase();
        }
        return null;
    }
}
