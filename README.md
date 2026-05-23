# SnagSnap -- Property Reports

A complete, production-ready native iOS app for creating professional property inspection, snagging, defect and condition reports directly from your iPhone.

## Core Promise

Create professional property inspection reports from photos in under 5 minutes.

## Target Users

- Landlords & letting agents
- Property managers
- Airbnb hosts
- Cleaners & handymen
- Small builders & facilities managers

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Swift 5.9+ | Language |
| SwiftUI | UI Framework |
| SwiftData | Persistence |
| PDFKit | PDF Report Generation |
| PencilKit | Photo Annotation |
| StoreKit 2 | Subscriptions |
| PhotosUI | Photo Library Access |
| AVFoundation | Camera Access |

**Minimum iOS**: 17.0

**No third-party dependencies.**

## Project Structure

```
SnagSnap/
|-- SnagSnap.xcodeproj/          # Xcode project
|-- SnagSnap/
|   |-- App/                     # Entry point & routing
|   |   |-- SnagSnapApp.swift
|   |   |-- AppRouter.swift
|   |-- Core/                    # Design system, extensions, utilities
|   |   |-- DesignSystem/        # Reusable UI components
|   |   |-- Extensions/          # Swift extensions
|   |   |-- Utilities/           # Helper functions & modifiers
|   |-- Models/                  # SwiftData models & enums
|   |   |-- Enums.swift          # ReportType, ReportStatus, IssueSeverity, IssueStatus
|   |   |-- UserProfile.swift
|   |   |-- InspectionReport.swift
|   |   |-- InspectionArea.swift
|   |   |-- InspectionIssue.swift
|   |   |-- IssuePhoto.swift
|   |-- Services/                # Business logic services
|   |   |-- FileStorageService.swift
|   |   |-- ThumbnailService.swift
|   |   |-- PDFReportService.swift
|   |   |-- CameraPermissionService.swift
|   |   |-- StoreKitService.swift
|   |   |-- EntitlementManager.swift
|   |   |-- ReportRepository.swift
|   |-- Features/                # Feature modules
|   |   |-- Onboarding/          # 3-screen onboarding flow
|   |   |-- Home/                # Dashboard with stats & recent reports
|   |   |-- Reports/             # Create report + workspace with 4 tabs
|   |   |-- Areas/               # Area/room management
|   |   |-- Issues/              # Issue creation, editing, detail
|   |   |-- Photos/              # Camera capture & PencilKit annotation
|   |   |-- Paywall/             # StoreKit 2 subscription UI
|   |   |-- Settings/            # Profile, subscription, defaults
|   |-- Tests/                   # XCTest unit tests
|   |   |-- SnagSnapTests/
|   |-- Info.plist               # App configuration & permissions
|   |-- Assets.xcassets/         # App icons & assets
```

## Features

### Onboarding (3 screens)
1. **Welcome** -- App introduction with hero illustration
2. **Use Case Selection** -- Select primary use cases with icon grid
3. **Branding Setup** -- Company/inspector name, phone, email

### Home Dashboard
- Summary stats (Total reports, Open issues, Completed)
- Recent reports list with search/filter
- Empty state with CTA
- Pull to refresh

### Create New Report
- Full form: title, property name, address, date, report type
- Optional: client name, inspector name, notes
- Report type picker with icons (7 types)
- Paywall gating for free tier

### Report Workspace (4 tabs)
- **Overview** -- Report details, stats grid, severity breakdown bar
- **Areas** -- Manage rooms/areas with suggested names
- **Issues** -- Filtered/sorted issue list with severity/status badges
- **Report** -- PDF export settings, generate & share

### Issue Management
- Create/edit issues with title, area, severity, status, notes
- Photo attachment (camera + library)
- PencilKit photo annotation (draw, erase, undo, save)
- Full-screen photo viewer with zoom

### PDF Report Generation
- Professional cover page with branding
- Summary page with issue counts
- Individual issue pages with photos
- Configurable export settings
- Watermark for free tier
- Native iOS share sheet

### Paywall & Subscriptions (StoreKit 2)
- Free: 1 report/month, watermarked PDF
- Pro Monthly: Unlimited, no watermark, custom branding
- Pro Annual: Same as monthly, better value
- Product cards with pricing from App Store
- Restore purchases

### Settings
- Profile/branding management
- Subscription status
- Default PDF export settings
- App version & privacy info

## Architecture

- **MVVM** with @Observable (iOS 17+)
- **Clean separation**: UI / Domain / Services / Data
- **Navigation**: NavigationStack + Route enum with UUID-based identifiers
- **Persistence**: SwiftData with cascade delete rules
- **File Storage**: FileManager (images, thumbnails, PDFs)
- **Subscriptions**: StoreKit 2 with graceful fallback

## Permissions

The following permissions are declared in Info.plist:
- **Camera** -- Capture inspection and issue photos
- **Photo Library** -- Attach photos from library to reports

## Code Statistics

| Module | Files | Lines |
|--------|------:|------:|
| App | 2 | 266 |
| Core | 17 | 3,290 |
| Models | 6 | 764 |
| Services | 7 | 3,345 |
| Features | 31 | 8,095 |
| Tests | 7 | 2,411 |
| **Total** | **70** | **18,171** |

## Getting Started

1. Open `SnagSnap.xcodeproj` in Xcode 15+
2. Select an iOS 17+ simulator or device
3. Build and run (Command+R)

No additional setup required -- the app uses only native Apple frameworks.

## Subscription Product IDs

Configure these in App Store Connect:
- `snagsnap.pro.monthly` -- Pro Monthly subscription
- `snagsnap.pro.annual` -- Pro Annual subscription

The app includes a development fallback mode that works without configured products.

## License

Proprietary -- All rights reserved.
