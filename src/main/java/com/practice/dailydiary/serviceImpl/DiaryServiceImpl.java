package com.practice.dailydiary.serviceImpl;

import com.practice.dailydiary.model.Diary;
import com.practice.dailydiary.model.User;
import com.practice.dailydiary.repository.DiaryRepository;
import com.practice.dailydiary.service.DiaryService;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

@Service
@Transactional
public class DiaryServiceImpl implements DiaryService {

    private final DiaryRepository diaryRepository;

    public DiaryServiceImpl(DiaryRepository diaryRepository) {
        this.diaryRepository = diaryRepository;
    }

    @Override
    public Diary createDiary(Diary diary, User user) {
        diary.setUser(user);

        if (diary.getEntryDate() == null) {
            diary.setEntryDate(LocalDate.now());
        }

        LocalDateTime now = LocalDateTime.now();
        diary.setCreatedAt(now);
        diary.setUpdatedAt(now);

        return diaryRepository.save(diary);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<Diary> getDiariesByUser(User user, int page, int size) {
        return diaryRepository.findByUserOrderByCreatedAtDesc(
                user,
                PageRequest.of(page, size)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<Diary> getDiaryByIdAndUser(Long diaryId, User user) {
        return diaryRepository.findByIdAndUser(diaryId, user);
    }

    @Override
    public Diary updateDiary(Long diaryId, Diary updatedDiary, User user) {
        Diary existingDiary = diaryRepository.findByIdAndUser(diaryId, user)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Diary not found or you don't have permission to edit it"));

        existingDiary.setTitle(updatedDiary.getTitle());
        existingDiary.setContent(updatedDiary.getContent());
        existingDiary.setUpdatedAt(LocalDateTime.now());

        if (updatedDiary.getEntryDate() != null) {
            existingDiary.setEntryDate(updatedDiary.getEntryDate());
        }

        return diaryRepository.save(existingDiary);
    }

    @Override
    public void deleteDiary(Long diaryId, User user) {
        Diary diary = diaryRepository.findByIdAndUser(diaryId, user)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Diary not found or you don't have permission to delete it"));

        diaryRepository.delete(diary);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<Diary> searchDiaries(User user, String keyword, int page, int size) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return getDiariesByUser(user, page, size);
        }
        return diaryRepository.searchByUserAndKeyword(
                user,
                keyword.trim(),
                PageRequest.of(page, size)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public long countDiariesByUser(User user) {
        return diaryRepository.countByUser(user);
    }
}