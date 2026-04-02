package com.betaup.security.service;

import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import com.betaup.exception.ResourceNotFoundException;
import com.betaup.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CurrentUserService {

    private final UserRepository userRepository;

    public User getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null
            || !authentication.isAuthenticated()
            || authentication instanceof AnonymousAuthenticationToken) {
            throw new AccessDeniedException("Authentication is required for this operation.");
        }

        return userRepository.findByEmailIgnoreCase(authentication.getName())
            .orElseThrow(() -> new ResourceNotFoundException("Authenticated user could not be found."));
    }

    public User requireRole(UserRole role) {
        User user = getCurrentUser();
        if (user.getRole() != role) {
            throw new AccessDeniedException("This operation requires role: " + role.name());
        }
        return user;
    }
}
