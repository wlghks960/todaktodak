package com.project.model.repository;

import com.project.model.entity.User;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {
    
    Optional<User> findUserByUserNickname(String userNickname);
    
    boolean existsUserByUserNickname(String userNickname);
}
