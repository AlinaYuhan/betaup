package com.betaup.controller;

import com.betaup.dto.common.ApiResponse;
import com.betaup.entity.Notification;
import com.betaup.entity.User;
import com.betaup.repository.NotificationRepository;
import com.betaup.security.service.CurrentUserService;
import java.util.List;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationRepository notificationRepository;
    private final CurrentUserService currentUserService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<Map<String, Object>>>> getNotifications() {
        User me = currentUserService.getCurrentUser();
        List<Map<String, Object>> dtos = notificationRepository
            .findByRecipientIdOrderByCreatedAtDesc(me.getId())
            .stream()
            .map(this::toMap)
            .toList();
        return ResponseEntity.ok(ApiResponse.success("Notifications loaded.", dtos));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<Long>> getUnreadCount() {
        User me = currentUserService.getCurrentUser();
        long count = notificationRepository.countByRecipientIdAndIsReadFalse(me.getId());
        return ResponseEntity.ok(ApiResponse.success("Unread count.", count));
    }

    @PostMapping("/mark-all-read")
    @Transactional
    public ResponseEntity<ApiResponse<Void>> markAllRead() {
        User me = currentUserService.getCurrentUser();
        notificationRepository.markAllReadByRecipientId(me.getId());
        return ResponseEntity.ok(ApiResponse.success("Marked as read.", null));
    }

    private Map<String, Object> toMap(Notification n) {
        return Map.of(
            "id", n.getId(),
            "type", n.getType(),
            "actorId", n.getActorId(),
            "actorName", n.getActorName(),
            "referenceId", n.getReferenceId() != null ? n.getReferenceId() : 0L,
            "content", n.getContent(),
            "isRead", n.isRead(),
            "createdAt", n.getCreatedAt() != null ? n.getCreatedAt().toString() : ""
        );
    }
}
