# Release 1.0 checklist

Status as of 27 Nov 2026. Version 1.0 (build 1) and both subscriptions submitted for review on 27 Nov 2026. [x] done in the repo, [ ] still to do (owner in brackets).

## In the code

- [x] All v1 screens, report PDF, paywall, settings (PR #2)
- [x] App icon 1024 px (PR #3)
- [x] Privacy manifests for the app and the widget
- [x] Paywall and Settings link to Terms of Use and Privacy Policy (Guideline 3.1.2)
- [x] Apple Health asks only for what the app uses (write symptoms)
- [x] iPhone only (`TARGETED_DEVICE_FAMILY = 1`)
- [x] Reminder the evening before an appointment
- [x] If the data store can't be opened, the app shows an error and writes nothing
- [x] 17 languages: en, de, fr, es, it, nl, pt-BR, sv, nb, da, fi, pl, ja, ko, zh-Hans, tr, ru (PR #5). The phone's language picks one; CI fails if any string is untranslated
- [x] Team ID 46V47ZSX5V in `project.yml`. IDs to register in the Apple Developer portal: app `app.tidemark.ios`, widget `app.tidemark.ios.widgets`, iCloud container `iCloud.app.tidemark`, app group `group.app.tidemark`, subscriptions `app.tidemark.report.monthly` and `app.tidemark.report.yearly`
- [x] Point `Links.privacy` at the published policy page (Claude)
- [x] Feedback email dawnwell.app+tidemark@gmail.com: Settings › Contact us, the data error screen, the privacy policy and `docs/support.md` (KAN-143)
- [x] Screenshots 6.9" (1320 × 2868) with captions in all 18 App Store locales: `tools/store_screenshots.sh`, then `tools/frame_screenshots.py` (output in `build/store-screenshots/final/`)
- [x] Debug flag `-initCloudKitSchema` creates the full CloudKit schema in Development (see `docs/apple-setup.md` §2)
- [x] Sample export file for App Review (8 weeks of made-up data), so the reviewer sees the report without 7 days of check-ins: `REVIEW_SAMPLE_OUT=build/Tidemark-review-sample.json swift test --filter ReviewSample` in `Packages/TidemarkCore`. Make it on submission day and attach it to the review notes

## Apple Developer and App Store Connect (Igor; step by step in `docs/apple-setup.md`)

- [x] Paid Apps agreement, tax and bank details
- [x] App ID with iCloud (CloudKit), HealthKit, App Groups, Push Notifications; iCloud container and app group created. The widget App ID needs `group.app.tidemark` ticked by hand in the portal: the API can turn App Groups on but can't pick the group, and the archive then fails with "Authentication failed"
- [x] App record: name, subtitle, description, keywords from `docs/app-store.md` (English) and `docs/app-store/<language>.md` (16 more languages)
- [x] Subscription group "Tidemark report" with `…report.yearly` ($39.99) and `…report.monthly` ($6.99), review screenshot of the paywall
- [x] CloudKit Console: deploy the schema from Development to Production (otherwise backup does not work in the App Store build)
- [x] App Privacy: 5 data types for opt-in analytics, not linked, no tracking (Igor, in the web UI; API can't set it)
- [x] Age rating questionnaire (Claude via the API, answers in `docs/apple-setup.md` §5)
- [x] Export compliance: `ITSAppUsesNonExemptEncryption = false` in Info.plist
- [x] Privacy Policy URL (fill in the brackets in `docs/privacy-policy.md` and publish) and Support URL (`docs/support.md`, published with the policy)
- [x] Review notes (`tools/asc/review-notes.txt`): no login; explain the report unlocks after 7 check-ins and how to see it (sample data or a demo tip)

- [x] App price Free and availability in all 175 territories (Claude via the API; submission is refused without them)
- [x] Per-app declarations in App Information: regulated medical device, security and AI-generated content forms (Igor, web UI only)
- [x] First subscriptions picked on the version page (Igor, web UI only: the API refuses `FIRST_SUBSCRIPTION_MUST_BE_SUBMITTED_ON_VERSION`)
- [x] Build: `ASC_KEY_ID=… ASC_ISSUER_ID=… tools/release/upload_build.sh` with an Admin API key (App Manager can't create signing profiles)

## Testing (Igor, TestFlight)

- [ ] First run, check-in, quick log from the Lock Screen widget
- [ ] Backup: log on phone A, install on phone B with the same Apple ID, data comes back (D3)
- [ ] iCloud signed out and iCloud full: warning banner shows
- [ ] Export, delete all, restore from Recently deleted, import the export
- [ ] Purchase in the sandbox, restore, cancel; PDF prints on Letter (US) and A4 (UK)
- [ ] Face ID lock, reminders, Apple Health write
- [ ] Largest text size and dark mode on every screen
- [ ] Every language: switch in Settings › Tidemark › Language, check that no text is cut off on Today, Check-in, Report and the PDF (German and Finnish are the longest)

## Translations (Igor)

- [x] Independent AI review of all 16 languages, fixes applied (`docs/translation-review.md`)
- [x] Second independent AI review of all 16 languages, 26 Nov: 108 fixes applied (2 pt-BR fixes rejected by `l10n.py lint`); untranslated "How did it go?" and the Patterns card header fixed in code
- [ ] Native-speaker review of the app texts (`Localization/<language>.json`) and store listings (`docs/app-store/`), at least for the languages of the storefronts opened first
- [ ] Official Menopause Rating Scale translations from the licence holder replace our own wording of the 11 items in every language

## Legal (Igor with a lawyer, see `docs/legal-questions.md`)

- [x] Menopause Rating Scale licence for a paid app: ZEG Berlin granted permission (Nov 2026). Keep their letter with the attribution terms
- [ ] Not a medical device in the US and UK; red-flag wording approved. Pre-assessment: `docs/regulatory-assessment.md` (likely not a device; to confirm with counsel)
- [ ] Privacy policy reviewed; seller entity decided
- [ ] "Tidemark" trademark check, classes 9 and 44. Knockout search: `docs/trademark-search.md` (US low–medium; UKIPO and EUIPO need a manual search)
