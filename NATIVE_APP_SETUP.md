# Dear Diary - Native App Setup (iOS & macOS)

## Overview

The `DearDiaryApp/` folder contains a SwiftUI app that works on both iOS and macOS, connecting to your Vercel backend.

## Setup Instructions

### Step 1: Open Xcode and Create Project

1. Open **Xcode**
2. File → New → Project
3. Select **Multiplatform** → **App**
4. Configure:
   - **Product Name:** `DearDiary`
   - **Team:** Your Apple Developer account
   - **Organization Identifier:** `com.yourname`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** None
5. **Save location:** Choose the `DearDiaryApp` folder in this project

### Step 2: Replace Generated Files

1. In Xcode, delete the auto-generated `ContentView.swift` and `DearDiaryApp.swift`
2. In Finder, open `DearDiaryApp/DearDiary/`
3. Drag all files and folders into your Xcode project:
   - `DearDiaryApp.swift`
   - `ContentView.swift`
   - `Models/` folder
   - `Views/` folder
   - `ViewModels/` folder
   - `Services/` folder

### Step 3: Update API URL

1. Open `Services/APIService.swift`
2. Find line 24 and update with your Vercel URL:

```swift
private let baseURL = "https://deardiary.vercel.app"
```

This is already configured for your deployment.

### Step 4: Build and Run

1. Select target:
   - **My Mac** for macOS app
   - **iPhone 15** (or any simulator) for iOS app
2. Press **Cmd + R** to build and run

## Features

- Login & Register (syncs with web app)
- View all diary entries
- Create new entries
- Edit existing entries
- Delete entries
- Search functionality
- Pagination

## Project Structure

```
DearDiaryApp/
└── DearDiary/
    ├── DearDiaryApp.swift      # App entry point
    ├── ContentView.swift        # Root view
    ├── Models/
    │   ├── User.swift          # User & auth models
    │   └── Diary.swift         # Diary model
    ├── Services/
    │   └── APIService.swift    # API client
    ├── ViewModels/
    │   ├── AuthViewModel.swift # Auth logic
    │   └── DiaryViewModel.swift# Diary logic
    └── Views/
        ├── AuthView.swift      # Login/Register screens
        ├── DashboardView.swift # Main diary list
        ├── DiaryFormView.swift # Create/Edit form
        └── DiaryDetailView.swift# Entry detail view
```

## Requirements

- Xcode 15 or later
- iOS 17+ / macOS 14+
- Apple Developer account (free works for simulators)

## Troubleshooting

### "Cannot connect to server"
- Check that your Vercel app is deployed and running
- Verify the `baseURL` in `APIService.swift` is correct
- Make sure you have internet connection

### Build errors about missing files
- Ensure all Swift files are added to the Xcode project target
- Check that files show a target membership checkmark in File Inspector

### Authentication not working
- The app uses session cookies - make sure your backend is properly configured
- Try logging in on the web first to verify credentials work
