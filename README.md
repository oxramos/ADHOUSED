# ADHOUSED

**ADHD-Tailored Household Management & Executive-Functioning App for iOS**

ADHOUSED is a native iOS (`Swift 6` / `SwiftUI` / `SwiftData` / `WidgetKit` / `ActivityKit` / `AlarmKit`) household chore tracker designed specifically around ADHD executive functioning, visual salience, zero-guilt recovery, and relentless-until-resolved reminders.

---

## Core Features

### 1. Relentless-Until-Resolved Escalating Reminders
- **Persistent Nagging Cadences**: Single dismissals never silently bury a due task. Choose per-task reminder cadences (**Gentle** `4h`, **Standard** `90m`, **Relentless** `30m`, or **Custom** `15m–240m`) strictly within your configured **Awake Window** (e.g., `09:00–22:00`).
- **4-Stage Escalation Ladder**: Progresses automatically from passive awareness → standard chimes → **Time Sensitive** breakthrough notifications → optional **System Alarm (`AlarmKit`)** for hard real-world cutoffs (like trash night or pet medication).
- **56-Slot Rolling Notification Planner**: Deterministically packs iOS's 64-notification ceiling with an 8-slot reserve for Live Activities and Undo timers, replenishing automatically on every app open or widget tap.
- **Vacation & Break Mode (`From Date & Time → Until Date & Time`)**: Designate any start and end Date & Time (or 1-tap presets like **🏡 Countryside Weekend**, **⛺ 3-Day Trip**, **🌴 7-Day Vacation**, **🌙 Rest of Today**, or **☕ 3 Hours**) to pause chores and silence all persistent notifications, Lock Screen Live Activities, and Cutoff Alarms while away—with automatic chore freshness decay freeze so you never return from a trip to a wall of overdue chores.

### 2. 1-Tap Home Screen, Lock Screen & StandBy Widgets (`AppIntents`)
- **Zero-App-Open Completion**: Interactive `Button(intent: CompleteChoreTaskIntent(...))` widgets across `systemSmall`, `systemMedium`, `accessoryRectangular`, and `accessoryCircular` families.
- **8-Second Undo Grace Window**: Completing any task from the app or widget flips the card into an 8-second `Undo` state before committing—eliminating accidental-tap anxiety on the Lock Screen.

### 3. Anti-Shame Rolling Recurrence & Shared Household Turns
- **Rolling Intervals (`X days after last done`)**: Completing a task resets its freshness battery to `100%` from *right now*—never punishing you with a stacked backlog of missed calendar occurrences.
- **Fixed Calendar Schedules (`Specific weekdays`)**: Supports hard municipal or weekly cutoffs (`Mon`–`Sun`).
- **Fair-Play Alternating Turns**: Supports Solo or Shared Household mode (`My Turn` / `Partner's Turn` / `Anyone`) with automatic turn rotation on completion and clean rollback on Undo.
- **Anti-Avalanche Starter Catalog**: Room-by-room onboarding automatically staggers Day-1 due dates so you never start with more than 2 tasks due today.

### 4. 9-Preset Multi-Family Visual Theme Engine & Five Cognitive Scaffolds
Includes **9 complete visual presets** across **3 aesthetic families** (`Signature | Auto | Light | Dark`), synchronized across both the main app and WidgetKit extensions:
- **ADHOUSED Originals**:
  - *Warm Tactile Bento* (Cozy Oat & Terracotta / Warm Espresso OLED)
  - *Chunky Neo-Brutalist Pop* (High-Salience Cream & Ink / Neon Arcade OLED)
- **Omarchy Quattro OS 4.x (`SF Mono` HUD + `45°` Dual-Gradient Focus Rings)**:
  - *Omarchy Quattro* (Tokyo-Night Obsidian `#1A1B26` & Daylight Paper `#F4F4F6`)
  - *Omarchy Cyberpunk* (Deep Void `#0D0221`, Neon Magenta `#FF0055` & Cyber Cyan `#00F0FF`)
  - *Omarchy Amber Wave & Sunflower* (Warm Charcoal `#1C1917` & Cream `#FFFBEB`)
  - *Omarchy Solar Flare* (Obsidian `#090D16`, Tangerine `#FF6B00` & Crimson `#EF4444`)
- **Quattro Minimal & Botanical**:
  - *Omarchy Everforest* (Woodland Bark `#232A2E` & Botanical Sage Mist `#EAEFE6`)
  - *Quattro Minimal & Mist* (Zero-Saturation Monochrome Slate `#1E1E24` & Cool Alabaster `#F0F4F8`)
  - *Quattro Ash & Desert Sun* (Warm Stone `#262626` & Sand Parchment `#FDF6E3`)

**Built-in ADHD Cognitive Scaffolds**:
1. **Freshness Battery Depletion Bars** (`100% → 0%`) replacing abstract date math
2. **Bionic / Salient Word-Stem Highlighting** (`SalientText`)
3. **Energy & Activation Cost Badges** (`⚡ 2m · Low Energy`, `🔋 10m · Medium`, `🔥 20m+ · Deep Focus`) + *"Low Energy Mode"* 1-tap filter
4. **Beat-the-Clock Micro-Sprint Timer** (`2m` / `5m` / `10m` / `15m`) with Live Activity & Dynamic Island ring
5. **Dual Layout Modes**: *Today Spotlight + Room Cards* (capped at Max 3 Focus items) or *Visual Battery Stream*

---

## Project Architecture

```text
ADHOUSED/
├── ADHOUSED.xcodeproj/          # Native Xcode 26+ project (App + Widget Extension targets)
├── Config/
│   ├── Signing.xcconfig         # Centralized Bundle ID, App Group & Team ID configuration
│   └── ExportOptions-AppStore.plist
├── App/                         # Main iOS application target (SwiftUI)
│   ├── ADHOUSEDApp.swift
│   ├── State/AppSessionViewModel.swift
│   └── Views/                   # Dashboard, Spotlight, Battery Stream, Sprint Timer, Settings
├── Widgets/                     # WidgetKit + ActivityKit Live Activities extension
│   ├── ADHOUSEDFocusWidget.swift
│   └── ChoreLiveActivities.swift
├── Packages/
│   └── ADHOUSEDCore/            # Shared Swift 6 domain package (Models, Engines, Intents, Theme, Tests)
└── scripts/
    └── deploy.sh                # 1-command physical iPhone install & TestFlight upload script
```

## Building & Running

### Run Unit Tests
```bash
swift test --package-path Packages/ADHOUSEDCore
```

### Deploy to Physical iPhone or TestFlight
```bash
./scripts/deploy.sh device       # Build, sign & install to connected iPhone
./scripts/deploy.sh testflight   # Archive & upload Release build to App Store Connect
```
