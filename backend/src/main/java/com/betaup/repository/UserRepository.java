package com.betaup.repository;

import com.betaup.entity.User;
import com.betaup.entity.UserRole;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);

    boolean existsByNameIgnoreCase(String name);

    boolean existsByNameIgnoreCaseAndIdNot(String name, Long id);

    List<User> findByRoleOrderByCreatedAtDesc(UserRole role);

    List<User> findByRoleOrderByNameAsc(UserRole role);

    @Query("""
        select user
        from User user
        where user.role = :role
          and (
              :query is null
              or lower(user.name) like lower(concat('%', :query, '%'))
              or lower(user.email) like lower(concat('%', :query, '%'))
          )
        """)
    Page<User> searchByRole(
        @Param("role") UserRole role,
        @Param("query") String query,
        Pageable pageable
    );
}
