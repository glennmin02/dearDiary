package com.practice.dailydiary.repository;

import com.practice.dailydiary.model.Diary;
import com.practice.dailydiary.model.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface DiaryRepository extends JpaRepository<Diary, Long> {


    Page<Diary> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    Optional<Diary> findByIdAndUser(Long id, User user);

    @Query("SELECT d FROM Diary d WHERE d.user = :user AND " +
            "(LOWER(d.title) LIKE LOWER(CONCAT('%', :keyword, '%')) OR " +
            "LOWER(d.content) LIKE LOWER(CONCAT('%', :keyword, '%'))) " +
            "ORDER BY d.createdAt DESC")
    Page<Diary> searchByUserAndKeyword(@Param("user") User user,
                                       @Param("keyword") String keyword,
                                       Pageable pageable);

    long countByUser(User user);
}