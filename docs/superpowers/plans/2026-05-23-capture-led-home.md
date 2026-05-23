# Capture-Led Home Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make photo capture the primary SnagSnap journey so a user can start taking property photos first and let the report structure form around that evidence.

**Architecture:** Keep routing centralized in `AppRouter`, add a capture-specific workspace launch action, and keep draft report creation in a small domain helper instead of burying persistence logic inside view layout code. The home screen becomes capture-led while preserving report-detail creation for users who want to fill out metadata first.

**Tech Stack:** SwiftUI, SwiftData, existing `AppRouter`, `ReportWorkspaceView`, `CreateEditIssueView`, and Xcode simulator tests.

---

### Task 1: Add Capture Draft Helper

**Files:**
- Create: `SnagSnap/Features/Home/CaptureDraftFactory.swift`
- Test: `SnagSnap/Tests/SnagSnapTests/JourneyCompletionTests.swift`

- [ ] Add `CaptureDraftFactory` with `makeCaptureDraft(context:) -> (report: InspectionReport, area: InspectionArea)` that inserts a draft report and a `General` area.
- [ ] Add a unit test that verifies the draft title, placeholder property values, general notes, report-area relationship, and context persistence.
- [ ] Run `xcodebuild test -project SnagSnap.xcodeproj -scheme SnagSnapTests -destination 'platform=iOS Simulator,name=iPhone 17'`.

### Task 2: Add Start-Capture Routing

**Files:**
- Modify: `SnagSnap/App/AppRouter.swift`
- Modify: `SnagSnap/Features/Home/MainTabView.swift`
- Modify: `SnagSnap/Features/Reports/Workspace/ReportWorkspaceViewModel.swift`
- Modify: `SnagSnap/Features/Reports/Workspace/ReportWorkspaceView.swift`
- Modify: `SnagSnap/Features/Issues/CreateEditIssueView.swift`
- Test: `SnagSnap/Tests/SnagSnapTests/NavigationRouteTests.swift`

- [ ] Extend `WorkspaceLaunchAction` with `startCapture`.
- [ ] Extend `Route.issueEditor` and `AppRouter.navigateToIssueEditor` with a defaulted `startWithCamera: Bool = false`.
- [ ] Pass `startWithCamera` through `MainTabView` into `CreateEditIssueView`.
- [ ] Add `startWithCamera` to `CreateEditIssueView`, opening the camera sheet once after the view model is ready.
- [ ] In `ReportWorkspaceView`, handle `.startCapture` by creating or reusing the first area and navigating to the issue editor with `startWithCamera: true`.
- [ ] Add route tests for the new capture launch action and issue editor camera flag.

### Task 3: Redesign Home Around Capture

**Files:**
- Modify: `SnagSnap/Features/Home/HomeDashboardView.swift`

- [ ] Change the top-right icon button from plus/create to camera/start capture.
- [ ] Change the hero copy to prioritize capture.
- [ ] Replace the primary CTA copy with `Start Capture`.
- [ ] Add a secondary `Report Details` action for form-first users.
- [ ] Make the empty-state quick-start grid place `Capture` first and route it to the capture flow.
- [ ] Use `CaptureDraftFactory` when no report exists; if a report exists, route into the latest report with `.startCapture`.

### Task 4: Verify UX and Release State

**Files:**
- No planned source changes unless verification reveals a defect.

- [ ] Build and run on the iPhone 17 simulator.
- [ ] Verify tapping `Start Capture` opens the issue editor and camera permission/camera flow.
- [ ] Verify `Report Details` still opens the metadata-first form.
- [ ] Run the full test suite.
- [ ] Run a Release build for generic iOS.
- [ ] Commit and push.

### Self-Review

- Spec coverage: The plan covers capture-first home, automatic draft creation, camera-first issue creation, report-details fallback, tests, simulator verification, and release build.
- Placeholder scan: No TBD/TODO placeholders remain.
- Type consistency: `WorkspaceLaunchAction.startCapture`, `startWithCamera`, and `CaptureDraftFactory.makeCaptureDraft(context:)` are named consistently across tasks.
