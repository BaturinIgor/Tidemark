# Tidemark

A perimenopause symptom tracker for iPhone. You log how you feel in 30 seconds a day, and before an appointment Tidemark makes a one-page report your doctor can read in a minute.

- **Platform:** iOS 17+, Swift, SwiftUI. There is no Android version.
- **Markets for 1.0:** United States and United Kingdom, English UI.
- **Business model:** daily logging is free; the PDF report needs a subscription ($6.99/month or $39.99/year).

## Product rules

1. **Never lose user data.** Every tap is saved immediately. Data is backed up, encrypted, to the user's own iCloud by default. The app also supports export and import, 30-day Recently deleted, and safe migrations. See requirements D1–D9 in the version plan.
2. **No medical advice.** No diagnosis, no "chance of perimenopause", no treatment or dose suggestions. Screens describe the user's own numbers ("higher than usual", "6 of 8 days") and leave conclusions to the doctor.
3. **No backend with health data.** Storage is local Core Data plus the user's private CloudKit database. Analytics and crash reports never contain health data.

## Docs

- Version plan (v1.0 must-haves, data safety, next versions): https://claude.ai/artifact/TdMF9xQ6c2fWmt9DMRafiU
- Research and requirements (pains, JTBD, user stories): https://claude.ai/artifact/W4aKPoNsHpfWVXWuGxNVb9
- Mockups (all MVP screens and states): https://claude.ai/artifact/E1q22tCFWZE4pX4qgrgAt4

## Project layout

| Path | What lives there |
|---|---|
| `Packages/TidemarkCore` | Pure Swift logic with no UI or storage: models, day keys, comparisons, patterns, cycle stats, treatment check, weekly summary, red flags, export format, merge rules. Fully unit tested. |
| `Shared/` | Code that is compiled into both the app and the widget: Core Data model, persistence stack, and the "log a hot flush" App Intent. |
| `App/` | The iOS app: SwiftUI screens (`Features/`), the repository that maps Core Data to core models (`Data/`), and services for iCloud backup status, Face ID lock, StoreKit, HealthKit and reminders (`Services/`). |
| `Widgets/` | Home Screen and Lock Screen widget for one-tap logging. |
| `AppTests/` | Tests that need the real Core Data model (save, edit, delete and restore, export and import). |

## Getting started

```sh
brew install xcodegen
xcodegen generate
open Tidemark.xcodeproj
```

Before you run the app on a device:

1. Set `DEVELOPMENT_TEAM` in `project.yml`, or in Xcode under Signing.
2. Replace the placeholder identifiers if you need to: bundle id `app.tidemark.Tidemark`, iCloud container `iCloud.app.tidemark`, app group `group.app.tidemark`, StoreKit products `app.tidemark.report.yearly` and `app.tidemark.report.monthly`.
3. In the CloudKit console, deploy the schema to production before release. Core Data creates the development schema on first run.

Tests:

```sh
cd Packages/TidemarkCore && swift test     # core logic, runs anywhere with Swift 6
xcodebuild test -scheme Tidemark -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

CI runs both on every pull request (`.github/workflows/ci.yml`).

## Data safety in code

| Requirement | Where |
|---|---|
| D1 autosave on every tap | `CheckInView` calls `Repository.save(checkIn:)` on every change |
| D2 encrypted iCloud backup on by default | `PersistenceController` (`NSPersistentCloudKitContainer`, `allowsCloudEncryption` on health fields in the model) |
| D3 restore on a new iPhone | `BackupMonitor.hasExistingBackup()` runs before onboarding |
| D4 warning when backup fails | `BackupHealth` in core, `BackupMonitor`, and `BackupBanner` on Today |
| D5 export and import | `ExportFile` / `ExportCodec` (versioned JSON and CSV), `Repository.importFile` |
| D6 safe migrations | `MigrationSnapshot` copies the store before any schema change; the store is never deleted on a load error |
| D7 Recently deleted for 30 days | soft delete with `deletedAt`, `RecentlyDeleted`, `RecentlyDeletedView` |
| D8 per-field merge | one row per symptom rating, `NSMergeByPropertyObjectTrumpMergePolicy`, `FieldMerge` for duplicates |
| D9 monitoring without health data | to do: MetricKit and sync error counters |

### Schema change rules

- Only add entities and optional attributes. Never rename or remove anything that has shipped, because CloudKit keeps the old fields forever.
- Each new model version gets a fixture database from the previous version in `AppTests/Fixtures/`, plus a test that migrates it.
- Bump `ExportFile.currentFormatVersion` only when you add fields, and keep the importer reading every older version.
