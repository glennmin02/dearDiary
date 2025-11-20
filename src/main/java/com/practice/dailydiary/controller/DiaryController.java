package com.practice.dailydiary.controller;

import com.practice.dailydiary.model.Diary;
import com.practice.dailydiary.model.User;
import com.practice.dailydiary.service.DiaryService;
import com.practice.dailydiary.service.UserService;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import org.springframework.data.domain.Page;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.time.LocalDate;
import java.util.List;

@Controller
@RequestMapping("/diary")
public class DiaryController {

    private static final int PAGE_SIZE = 50;

    private final DiaryService diaryService;
    private final UserService userService;

    public DiaryController(DiaryService diaryService,
                           UserService userService) {
        this.diaryService = diaryService;
        this.userService = userService;
    }

    @GetMapping("/dashboard")
    public String dashboard(
            @RequestParam(required = false) String search,
            @RequestParam(value = "page", defaultValue = "1") int page,
            HttpSession session,
            Model model
    ) {
        User currentUser = getCurrentUser(session);
        int pageIndex = Math.max(page, 1) - 1;

        String normalizedSearch = (search != null && !search.trim().isEmpty())
                ? search.trim()
                : null;

        Page<Diary> diaryPage = diaryService.searchDiaries(
                currentUser,
                normalizedSearch,
                pageIndex,
                PAGE_SIZE
        );

        List<Diary> diaries = diaryPage.getContent();
        model.addAttribute("searchKeyword", normalizedSearch);

        long totalDiaries = diaryService.countDiariesByUser(currentUser);

        model.addAttribute("diaries", diaries);
        model.addAttribute("diaryPage", diaryPage);
        model.addAttribute("currentPage", diaryPage.getTotalPages() == 0 ? 0 : diaryPage.getNumber() + 1);
        model.addAttribute("totalPages", diaryPage.getTotalPages());
        model.addAttribute("hasPrevious", diaryPage.hasPrevious());
        model.addAttribute("hasNext", diaryPage.hasNext());
        model.addAttribute("pageSize", PAGE_SIZE);
        model.addAttribute("totalElements", diaryPage.getTotalElements());
        model.addAttribute("totalDiaries", totalDiaries);
        model.addAttribute("username", currentUser.getUsername());

        return "diary/dashboard";
    }

    @GetMapping("/create")
    public String showCreateForm(Model model, HttpSession session) {
        User currentUser = getCurrentUser(session);

        Diary diary = new Diary();
        diary.setEntryDate(LocalDate.now());

        model.addAttribute("diary", diary);
        model.addAttribute("isEdit", false);
        model.addAttribute("username", currentUser.getUsername());

        return "diary/form";
    }

    @PostMapping("/create")
    public String createDiary(
            @Valid @ModelAttribute("diary") Diary diary,
            BindingResult result,
            HttpSession session,
            RedirectAttributes redirectAttributes,
            Model model
    ) {
        User currentUser = getCurrentUser(session);

        if (result.hasErrors()) {
            model.addAttribute("diary", diary);
            model.addAttribute("isEdit", false);
            model.addAttribute("username", currentUser.getUsername());
            return "diary/form";
        }

        try {
            if (diary.getEntryDate() == null) {
                diary.setEntryDate(LocalDate.now());
            }

            diaryService.createDiary(diary, currentUser);

            redirectAttributes.addFlashAttribute("successMessage",
                    "Diary entry created successfully!");
            return "redirect:/diary/dashboard";

        } catch (Exception e) {
            model.addAttribute("errorMessage", "Error creating diary: " + e.getMessage());
            model.addAttribute("isEdit", false);
            model.addAttribute("username", currentUser.getUsername());
            return "diary/form";
        }
    }

    @GetMapping("/edit/{id}")
    public String showEditForm(
            @PathVariable Long id,
            HttpSession session,
            Model model,
            RedirectAttributes redirectAttributes
    ) {
        User currentUser = getCurrentUser(session);

        return diaryService.getDiaryByIdAndUser(id, currentUser)
                .map(diary -> {
                    model.addAttribute("diary", diary);
                    model.addAttribute("diaryId", id);
                    model.addAttribute("isEdit", true);
                    model.addAttribute("username", currentUser.getUsername());

                    return "diary/form";
                })
                .orElseGet(() -> {
                    redirectAttributes.addFlashAttribute("errorMessage",
                            "Diary not found or you don't have permission to edit it");
                    return "redirect:/diary/dashboard";
                });
    }

    @PostMapping("/edit/{id}")
    public String updateDiary(
            @PathVariable Long id,
            @Valid @ModelAttribute("diary") Diary diary,
            BindingResult result,
            HttpSession session,
            RedirectAttributes redirectAttributes,
            Model model
    ) {
        User currentUser = getCurrentUser(session);

        if (result.hasErrors()) {
            model.addAttribute("diary", diary);
            model.addAttribute("diaryId", id);
            model.addAttribute("isEdit", true);
            model.addAttribute("username", currentUser.getUsername());
            return "diary/form";
        }

        try {

            Diary updatedDiary = new Diary();
            updatedDiary.setTitle(diary.getTitle());
            updatedDiary.setContent(diary.getContent());
            updatedDiary.setEntryDate(diary.getEntryDate());

            diaryService.updateDiary(id, updatedDiary, currentUser);

            redirectAttributes.addFlashAttribute("successMessage",
                    "Diary entry updated successfully!");
            return "redirect:/diary/dashboard";

        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
            return "redirect:/diary/dashboard";
        } catch (Exception e) {
            model.addAttribute("errorMessage", "Error updating diary: " + e.getMessage());
            model.addAttribute("diary", diary);
            model.addAttribute("diaryId", id);
            model.addAttribute("isEdit", true);
            model.addAttribute("username", currentUser.getUsername());
            return "diary/form";
        }
    }

    @GetMapping("/view/{id}")
    public String viewDiary(
            @PathVariable Long id,
            HttpSession session,
            Model model,
            RedirectAttributes redirectAttributes
    ) {
        User currentUser = getCurrentUser(session);

        return diaryService.getDiaryByIdAndUser(id, currentUser)
                .map(diary -> {
                    model.addAttribute("diary", diary);
                    model.addAttribute("username", currentUser.getUsername());
                    return "diary/view";
                })
                .orElseGet(() -> {
                    redirectAttributes.addFlashAttribute("errorMessage",
                            "Diary not found or you don't have permission to view it");
                    return "redirect:/diary/dashboard";
                });
    }

    @PostMapping("/delete/{id}")
    public String deleteDiary(
            @PathVariable Long id,
            HttpSession session,
            RedirectAttributes redirectAttributes
    ) {
        try {
            User currentUser = getCurrentUser(session);
            diaryService.deleteDiary(id, currentUser);

            redirectAttributes.addFlashAttribute("successMessage",
                    "Diary entry deleted successfully!");

        } catch (IllegalArgumentException e) {
            redirectAttributes.addFlashAttribute("errorMessage", e.getMessage());
        } catch (Exception e) {
            redirectAttributes.addFlashAttribute("errorMessage",
                    "Error deleting diary: " + e.getMessage());
        }

        return "redirect:/diary/dashboard";
    }

    private User getCurrentUser(HttpSession session) {
        Long userId = (Long) session.getAttribute("userId");
        if (userId == null) {
            throw new IllegalStateException("Session expired. Please sign in again.");
        }

        return userService.findById(userId)
                .orElseThrow(() -> new IllegalStateException("User not found"));
    }
}