package com.practice.dailydiary.service;

import com.practice.dailydiary.model.User;

import java.util.Optional;

public interface UserService {

    User registerUser(User user);

    Optional<User> findByUsername(String username);

    Optional<User> findById(Long id);

    boolean isUsernameAvailable(String username);

    boolean updatePassword(Long userId, String oldPassword, String newPassword);

    Optional<User> authenticateUser(String username, String password);
}