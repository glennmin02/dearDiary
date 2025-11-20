package com.practice.dailydiary.controller;

import com.practice.dailydiary.model.User;
import com.practice.dailydiary.service.UserService;
import jakarta.servlet.http.HttpSession;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
public class AuthController {

    private final UserService userService;

    public AuthController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/")
    public String landingPage(HttpSession session) {
        return session.getAttribute("userId") != null
                ? "redirect:/diary/dashboard"
                : "redirect:/login";
    }

    @GetMapping("/login")
    public String showLoginPage(HttpSession session) {
        if (session.getAttribute("userId") != null) {
            return "redirect:/diary/dashboard";
        }
        return "auth/login";
    }

    @PostMapping("/login")
    public String login(@RequestParam String username,
                        @RequestParam String password,
                        HttpSession session,
                        RedirectAttributes redirectAttributes) {
        return userService.authenticateUser(username, password)
                .map(user -> {
                    session.setAttribute("userId", user.getId());
                    session.setAttribute("username", user.getUsername());
                    return "redirect:/diary/dashboard";
                })
                .orElseGet(() -> {
                    redirectAttributes.addFlashAttribute("errorMessage", "Invalid username or password.");
                    return "redirect:/login";
                });
    }

    @PostMapping("/logout")
    public String logout(HttpSession session, RedirectAttributes redirectAttributes) {
        session.invalidate();
        redirectAttributes.addFlashAttribute("successMessage", "Signed out successfully.");
        return "redirect:/login";
    }

    @GetMapping("/register")
    public String showRegistrationPage(HttpSession session, Model model) {
        if (session.getAttribute("userId") != null) {
            return "redirect:/diary/dashboard";
        }
        if (!model.containsAttribute("user")) {
            model.addAttribute("user", new User());
        }
        return "auth/register";
    }

    @PostMapping("/register")
    public String registerUser(
            @Valid @ModelAttribute("user") User user,
            BindingResult result,
            @RequestParam("confirmPassword") String confirmPassword,
            RedirectAttributes redirectAttributes,
            Model model
    ) {
        if (result.hasErrors()) {
            return "auth/register";
        }

        if (!user.getPassword().equals(confirmPassword)) {
            model.addAttribute("errorMessage", "Passwords do not match");
            return "auth/register";
        }

        if (!userService.isUsernameAvailable(user.getUsername())) {
            model.addAttribute("errorMessage", "Username is already taken");
            return "auth/register";
        }

        try {
            userService.registerUser(user);
            redirectAttributes.addFlashAttribute("successMessage",
                    "Registration successful! Please log in.");
            return "redirect:/login";
        } catch (IllegalArgumentException e) {
            model.addAttribute("errorMessage", e.getMessage());
            return "auth/register";
        }
    }

    @GetMapping("/reset-password")
    public String showResetPassword(Model model) {
        if (!model.containsAttribute("resetForm")) {
            model.addAttribute("resetForm", new PasswordResetForm());
        }
        return "auth/reset-password";
    }

    @PostMapping("/reset-password")
    public String resetPassword(
            @Valid @ModelAttribute("resetForm") PasswordResetForm form,
            BindingResult result,
            RedirectAttributes redirectAttributes,
            Model model
    ) {
        if (result.hasErrors()) {
            return "auth/reset-password";
        }

        if (!form.passwordsMatch()) {
            model.addAttribute("errorMessage", "New passwords do not match");
            return "auth/reset-password";
        }

        return userService.findByUsername(form.getUsername())
                .map(user -> {
                    boolean updated = userService.updatePassword(
                            user.getId(),
                            form.getCurrentPassword(),
                            form.getNewPassword()
                    );

                    if (!updated) {
                        model.addAttribute("errorMessage", "Current password is incorrect");
                        return "auth/reset-password";
                    }

                    redirectAttributes.addFlashAttribute("successMessage",
                            "Password updated. Please log in.");
                    return "redirect:/login";
                })
                .orElseGet(() -> {
                    model.addAttribute("errorMessage", "User not found");
                    return "auth/reset-password";
                });
    }

    public static class PasswordResetForm {
        @NotBlank(message = "Username is required")
        private String username;

        @NotBlank(message = "Current password is required")
        private String currentPassword;

        @NotBlank(message = "New password is required")
        @Size(min = 6, max = 100, message = "Password must be between 6 and 100 characters")
        private String newPassword;

        @NotBlank(message = "Confirm password is required")
        private String confirmPassword;

        public String getUsername() {
            return username;
        }

        public void setUsername(String username) {
            this.username = username;
        }

        public String getCurrentPassword() {
            return currentPassword;
        }

        public void setCurrentPassword(String currentPassword) {
            this.currentPassword = currentPassword;
        }

        public String getNewPassword() {
            return newPassword;
        }

        public void setNewPassword(String newPassword) {
            this.newPassword = newPassword;
        }

        public String getConfirmPassword() {
            return confirmPassword;
        }

        public void setConfirmPassword(String confirmPassword) {
            this.confirmPassword = confirmPassword;
        }

        public boolean passwordsMatch() {
            return newPassword != null && newPassword.equals(confirmPassword);
        }
    }
}