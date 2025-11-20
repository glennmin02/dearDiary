package com.practice.dailydiary.service;

import com.practice.dailydiary.model.Diary;
import com.practice.dailydiary.model.User;
import org.springframework.data.domain.Page;

import java.util.Optional;

public interface DiaryService {

    Diary createDiary(Diary diary, User user);

    Page<Diary> getDiariesByUser(User user, int page, int size);

    Optional<Diary> getDiaryByIdAndUser(Long diaryId, User user);

    Diary updateDiary(Long diaryId, Diary updatedDiary, User user);

    void deleteDiary(Long diaryId, User user);

    Page<Diary> searchDiaries(User user, String keyword, int page, int size);

    long countDiariesByUser(User user);
}