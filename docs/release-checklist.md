# Release 1.0 checklist

Status as of 18 Nov 2026. [x] done in the repo, [ ] still to do (owner in brackets).

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
- [x] Team ID 46V47ZSX5V in `project.yml`. IDs to register in the Apple Developer portal: app `app.tidemark.Tidemark`, widget `app.tidemark.Tidemark.Widgets`, iCloud container `iCloud.app.tidemark`, app group `group.app.tidemark`, subscriptions `app.tidemark.report.monthly` and `app.tidemark.report.yearly`
- [ ] Point `Links.privacy` at the published policy page (Claude)
- [ ] Screenshots 6.9" (1320 × 2868) with sample data (Claude can produce them from the simulator in CI)

## Apple Developer and App Store Connect (Igor)

- [ ] Paid Apps agreement, tax and bank details (subscriptions can't go live without them)
- [ ] App ID with iCloud (CloudKit), HealthKit, App Groups, Push Notifications; iCloud container and app group created
- [ ] App record: name, subtitle, description, keywords from `docs/app-store.md` (English) and `docs/app-store/<language>.md` (16 more languages)
- [ ] Subscription group "Tidemark report" with `…report.yearly` ($39.99) and `…report.monthly` ($6.99), review screenshot of the paywall
- [ ] CloudKit Console: deploy the schema from Development to Production (otherwise backup does not work in the App Store build)
- [ ] App Privacy: "Data Not Collected"; age rating questionnaire; export compliance (no non-exempt encryption)
- [ ] Privacy Policy URL (fill in the brackets in `docs/privacy-policy.md` and publish) and Support URL
- [ ] Review notes: no login; explain the report unlocks after 7 check-ins and how to see it (sample data or a demo tip)

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

- [ ] Native-speaker review of the app texts (`Localization/<language>.json`) and store listings (`docs/app-store/`), at least for the languages of the storefronts opened first
- [ ] Official Menopause Rating Scale translations from the licence holder replace our own wording of the 11 items in every language

## Legal (Igor with a lawyer, see `docs/legal-questions.md`)

- [ ] Menopause Rating Scale licence for a paid app, including the official translations (fallback: own checklist without a score)
- [ ] Not a medical device in the US and UK; red-flag wording approved
- [ ] Privacy policy reviewed; seller entity decided
- [ ] "Tidemark" trademark check, classes 9 and 44
