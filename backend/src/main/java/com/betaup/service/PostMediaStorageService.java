package com.betaup.service;

import java.util.List;
import org.springframework.web.multipart.MultipartFile;

public interface PostMediaStorageService {

    StoredMedia save(MultipartFile media);

    List<StoredMedia> saveMultiple(List<MultipartFile> mediaFiles);

    void delete(String mediaPath);

    void deleteMultiple(List<String> mediaPaths);

    record StoredMedia(String path, String url, com.betaup.entity.PostMediaKind kind) {}
}
