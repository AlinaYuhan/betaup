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

    /**
     * Accepts any of the given roles. Use this when multiple roles share the
     * same capability (e.g. CLIMBER and COACH can both log climbs).
     */
    public User requireAnyRole(UserRole... roles) {
        User user = getCurrentUser();
        for (UserRole role : roles) {
            if (user.getRole() == role) return user;
        }
        String allowed = java.util.Arrays.stream(roles)
            .map(UserRole::name)
            .collect(java.util.stream.Collectors.joining(", "));
        throw new AccessDeniedException("This operation requires one of: " + allowed);
    }
}
