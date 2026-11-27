# Tidemark: medical device pre-assessment (US and UK)

Prepared 26 November 2026 for the founder to take to counsel.

> **This is a pre-assessment, not legal advice and not a regulatory sign-off.** It was written by reading the app's code and texts and the public regulator documents listed under Sources. Counsel or a regulatory consultant must confirm every conclusion before launch. Where I could not open or confirm the current version of a source, the memo says so.

## Conclusion

On the code and texts as they stand, Tidemark most likely is **not a regulated medical device in the US**. The closest FDA match is "simple tools to organize and record their health information" and tools that help patients "document, show, or communicate" with their health care professional. FDA lists both as **not devices** (Policy for Device Software Functions and MMA, Appendix A items 12 and 13). Two features may count as device functions: the trend line and the red-flag prompt. Even then they fall under categories where FDA says it **will not enforce** device requirements (Appendix B items 7, 8, 12 and 13). Tidemark cannot rely on the clinical decision support exclusion in section 520(o)(1)(E), because that exclusion covers only software for health care professionals. It also should not rely mainly on the General Wellness guidance (revised 6 January 2026), because it names a condition (perimenopause or menopause) and the 2026 text now excludes products with prompts that "recommend or require specific clinical action".

In the **UK**, Tidemark most likely is **not a medical device** under the UK MDR 2002, as long as its intended purpose stays "a personal record of self-reported symptoms to share with your GP". The UK risk is higher than the US risk, for three reasons:

- The MHRA's apps guidance (v1.10g) says decision support that applies "automated reasoning such as a simple calculation", naming "symptom tracking" as an example, is "likely" to be in scope.
- The MHRA's list of medical purposes includes "to monitor therapeutic measures", which the before/after medicine comparison comes close to.
- The MHRA's symptom-checker appendix treats "an indication of seriousness, e.g. 'Red flag'" as a device-type output. Pure signposting ("see your GP, go to A&E") is unlikely to be a device.

**Overall risk is low to medium.** Every feature can stay. The red-flag prompts should be **kept, but reworded**: they should describe what the user logged and point her to her own doctor or GP, without saying how serious it is. The wording must use the region's term (doctor or GP), which the code does not do today. Remove two texts: the NICE NG23 footer and "Doctors know this scale". Also reword a few treatment and "clear pattern" phrases and drop the App Store "Medical" category.

## Summary table

| # | Feature | US likely status | UK likely status | Risk | Key change to stay outside device territory |
|---|---|---|---|---|---|
| 1 | Daily symptom logging | Not a device (MMA App. A #12) | Not a device (records data, no medical purpose by itself) | Low | None. Keep "records what you report". |
| 2 | "Higher / lower than usual" vs own baseline | Not a device, or enforcement discretion (MMA App. A #12; App. B #12–13) | Borderline: "symptom tracking" with "simple calculation" (MHRA p.12); a simple, verifiable calculation (App. 2) | Low (US) / Medium (UK) | Show the numbers behind the label (today vs the 14-day average). Never use "worse", "abnormal" or colours that mean danger. |
| 3 | Factor counts ("counts, not causes") | Not a device (App. A #12; like App. A #14, trigger logging) | Probably not a device; descriptive counts that can be checked | Low–Medium | Keep "counts, not causes". Never use "trigger", "causes" or "avoid". Always show both counts. |
| 4 | Before/after averages around a medicine start | Not a device as long as there is no advice to change treatment (App. A #12 wording) | Closest to "monitor therapeutic measures" (MHRA p.10) | Medium (UK) / Low–Medium (US) | Frame it as "your ratings before and after a date you choose". Never use "is it working", "effective" or "response". Keep "does not say whether a treatment works". |
| 5 | Menopause Rating Scale score on the report | Not a device (simple scoring; App. A #12) | Unlikely to be a device: "simple scores … easily verified" (MHRA App. 2) | Low–Medium | No severity bands or cut-offs. Show the item answers so the total can be checked. Drop "Doctors know this scale". Licence issue (Q5) is separate. |
| 6 | Red-flag prompts (heavy bleeding; bleeding after 12 months) | Possibly a device function under enforcement discretion (App. B #7–8). Outside the General Wellness safe harbour if the wording "recommends specific clinical action" | Unlikely to be a device if it only signposts (MHRA App. 1). Risk rises with "seriousness" wording | Medium | Keep, reworded: describe what she logged and signpost. No "shouldn't wait", no causes, no thresholds beyond her own log. Region term. |
| 7 | PDF report for the doctor | Not a device (App. A #12–13). Not CDS: it makes no recommendation. 520(o)(1)(C) not available (not ONC-certified) | Not a device if it shows the user's data; risk if the doctor relies on derived figures without seeing the raw data (MHRA p.12) | Low–Medium | Keep "Self-reported symptom record…". State how each figure is calculated. Remove the NICE NG23 line. |
| 8 | App Store listing claims | Fine for "record" and "for your doctor" | Promotional material sets the intended purpose (UK MDR reg. 2(1)) | Low–Medium | Health & Fitness category only. No "clinical", "validated" or "track your HRT". Keep the disclaimer paragraph. |

Related, outside the device question: the weekly summary (`WeeklySummary.swift`) is a plain count and average comparison, so it is low risk in both markets. The FTC Health Breach Notification Rule probably applies in the US (see the end of section A).

---

## A. United States

### A1. Legal framework (checked versions)

- **FD&C Act § 201(h) (21 U.S.C. § 321(h))**: a device is an article "intended for use in the diagnosis of disease or other conditions, or in the cure, mitigation, treatment, or prevention of disease … or intended to affect the structure or any function of the body", and the term "does not include software functions excluded pursuant to section 520(o)". (Wording as quoted in FDA General Wellness guidance, Jan 2026, footnote 3.)
- **§ 520(o)(1) (21 U.S.C. § 360j(o)(1))**, added by the 21st Century Cures Act § 3060:
  - **(B)** software "for maintaining or encouraging a healthy lifestyle and is unrelated to the diagnosis, cure, mitigation, prevention, or treatment of a disease or condition".
  - **(C)** electronic patient records, including "patient-provided information", but only if (i) the records were "created, stored, transferred, or reviewed by health care professionals", (ii) they are part of health IT "certified under section 300jj–11(c)(5)", and (iii) the function does not "interpret or analyze patient records … for the purpose of the diagnosis … of a disease or condition".
  - **(E)** clinical decision support for "displaying, analyzing, or printing medical information", "supporting or providing recommendations **to a health care professional**", and "enabling such health care professional to independently review the basis" (plus the image/signal exclusion).
- **FDA, General Wellness: Policy for Low Risk Devices**, issued **6 January 2026**, superseding the 27 September 2019 version (docket FDA-2014-N-1039). Verified from the FDA PDF (fda.gov/media/90652).
- **FDA, Clinical Decision Support Software**, issued **29 January 2026**, superseding the 6 January 2026 version, which superseded the 2022 version. Verified from the FDA PDF (fda.gov/media/109618).
- **FDA, Policy for Device Software Functions and Mobile Medical Applications**, issued **28 September 2022** (the PDF now carries an added cover note on the QMSR, effective 2 February 2026). Verified from the FDA PDF (fda.gov/media/80958). I found no newer revision.
- **FDA Digital Health Policy Navigator**: the step pages I could open show "Content current as of 09/27/2022". That is earlier than the January 2026 wellness and CDS revisions, so the Navigator may not reflect them. The main Navigator page returned HTTP 401 to automated access, so I could not check whether it has been updated.

### A2. How Tidemark runs through the FDA Navigator steps

1. **Medical purpose?** Arguably yes. It records perimenopause symptoms, bleeding and medicines, and it shows bleeding prompts.
2. **Administrative support (520(o)(1)(A))?** No.
3. **Healthy lifestyle (520(o)(1)(B)) or General Wellness?** Not cleanly. The 2026 guidance says products are not general wellness if their labelling or UI includes "references to specific diseases, clinical conditions, or diagnostic thresholds" or "alerts, alarms, or prompts that recommend or require specific clinical action or medical management" (GW 2026, p.6). Menopause is a life stage, not a disease, but the app names it, records bleeding, and the current red flags tell the user to "Contact your doctor now". The guidance does allow a "notification informing a user that evaluation by a healthcare professional may be helpful", provided it does "not identify or name a specific disease", does "not characterize the output as abnormal", has no "clinical thresholds, diagnoses, or treatment recommendations", and gives no "ongoing alerts or monitoring intended to manage a disease or condition" (GW 2026, p.6). Treat General Wellness as a back-up argument, not the main one.
4. **Electronic patient record (520(o)(1)(C))?** No. The records are not HCP-created or reviewed, and the app is not ONC-certified.
5. **Device data or lab data (520(o)(1)(D))?** No. Apple Health sleep and menstrual flow reads (`NSHealthShareUsageDescription`, en.json:4) are displayed next to check-ins and are not analysed for a diagnosis. Keep it that way.
6. **CDS (520(o)(1)(E))?** Not applicable. The CDS guidance says: "Software functions that support or provide recommendations to patients or caregivers – not HCPs – meet the definition of a device" (CDS 2026, p.13). Tidemark makes no recommendations to the doctor. The PDF only shows the patient's own data, so it needs no CDS exclusion.
7. **MMA guidance applies.** It lists as **not devices**:
   - "Software functions that provide patients with simple tools to organize and record their health information … without providing recommendations to alter or change a previously prescribed treatment or therapy", including tools for people "with specific conditions … to record their events or measurements … and share this information with their health care professional" (MMA 2022, App. A #12, pp.21–22).
   - "Software functions that are specifically marketed to help patients document, show, or communicate to health care professionals regarding potential medical conditions" (App. A #13, p.22).
   - Analogy for factors: apps that help asthmatics record "environmental triggers" (App. A #14, p.22).

   It lists as **possible devices under enforcement discretion**:
   - checklists of symptoms that give "advice on when to consult a health care professional" (App. B #7, p.24);
   - questionnaires that recommend "the type of health care facility most appropriate" (App. B #8, p.25);
   - "historical trending and comparison of vital signs" (App. B #12, p.25);
   - functions that "aggregate and display trends in personal health incidents" (App. B #13, p.25).

**US result:** a non-device patient record and communication tool, with at most low-risk functions under enforcement discretion. FDA's footnote 44 qualifies enforcement discretion: use must not be "intended to replace or discourage seeking treatment from a health care professional" (MMA p.14). That supports keeping a bleeding prompt that points to the doctor.

### A3. FTC Health Breach Notification Rule (16 CFR Part 318)

The amended rule (published 30 May 2024, effective 29 July 2024) expressly covers health apps that HIPAA does not cover. A "personal health record" is now one that "has the technical capacity to draw information from multiple sources". Tidemark takes user input and can read Apple Health, so it likely qualifies, which makes the developer a "vendor of personal health records". A "breach of security" now includes **unauthorized disclosure**, not only hacking; FTC enforcement against the period-tracker maker Easy Healthcare (Premom) was about sharing data with analytics/ad SDKs. Because Tidemark has no server and no analytics on health data, the main exposure is (a) adding a third-party SDK later and (b) whether data in the user's own iCloud is "held" by the vendor. Violations carry civil penalties. Notice is due to individuals within 60 days, and to the FTC at the same time if 500 or more people are affected. Ask counsel to confirm applicability and to put an incident-response note in the release checklist. (FTC blog post of 26 April 2024 read directly; Federal Register text found by search, not read in full.)

---

## B. United Kingdom

### B1. Legal framework (checked versions)

- **UK MDR 2002 (SI 2002/618), reg. 2(1)**: "medical device" means any "instrument, apparatus, appliance, **software**, material or other article … intended by the manufacturer to be used for human beings for the purpose of (i) diagnosis, prevention, **monitoring**, treatment or alleviation of disease, … (iii) investigation, replacement or modification of the anatomy or of a physiological process, or (iv) control of conception". **"Intended purpose"** is "the use to which the device is intended according to the data supplied by the manufacturer on the labelling, the instructions for use and/or the promotional materials". legislation.gov.uk shows this as up to date to 26 November 2026, with the latest amendment to reg. 2 dated 17 June 2025.
- **MHRA, "Medical devices: software applications (apps)"** (GOV.UK collection page, last updated **1 July 2023**). The main document is **"Medical device stand-alone software including apps (including IVDMDs)" v1.10g**, with Appendices 1–4 (v1.10f). I found no 2024–2026 revision. The decision flowchart (p.6) runs: computer program → "Does it have a medical purpose?" (p.10) → not a device (p.35), or IVD/accessory/device branches.
- **MHRA, "Crafting an intended purpose in the context of Software as a Medical Device (SaMD)"**, published 22 March 2023 (no later update shown). It says intended purpose "must be construed objectively from the standpoint of an objective observer", looking at labelling, IFU, promotional material and technical documentation.
- **MHRA, "Software and AI as a medical device"** hub page, last updated 3 February 2025.
- **2025–2026 changes:**
  - The **Medical Devices (Post-market Surveillance Requirements) (Amendment) (Great Britain) Regulations 2024** came into force on **16 June 2025**. They apply only if a product is a device.
  - The MHRA's implementation page (updated **12 March 2026**) says a further statutory instrument on **pre-market requirements, including an international reliance scheme** (faster routes for devices approved by trusted regulators such as the FDA), "will follow in 2026". I could not confirm that it has been laid or is in force as of November 2026.
  - A consultation on **indefinite recognition of CE-marked devices** ran from 16 February to 10 April 2026. I found no published outcome.
  - New MHRA software guidance in 2025–2026 (digital mental health v1.3; ambient voice technology, 29 July 2026) is not about symptom trackers.
  - None of these changes alters the qualification test above. They matter only if Tidemark is ever found to be a device (it would then be class I as a self-declared UKCA device, with PMS duties under the 2025 rules).

### B2. The MHRA passages that matter for Tidemark

- **Medical purpose list (p.10)** includes "Monitoring of disease…", "**To monitor therapeutic measures**", and, on the no-medical-purpose side, "Monitors fitness/health/wellbeing".
- **Decision support (p.12):** "Decision support software is usually considered a medical device when it applies automated reasoning such as a simple calculation, an algorithm or a more complex series of calculations. For example, dose calculations, **symptom tracking**, clinicians guides…". Also: "if the software/app performs a calculation or interprets or interpolates data and the healthcare professional does not review the raw data, then this software may be considered a medical device."
- **Indicative words (pp.19–25, 39–40)** that point to a device: "Detects", "Screening", "Triage", "Risk of…", "Predicts", "Alarms", "Check", "Helps" (with a disease link), "Risk score", "Algorithm", and, under control of conception, "Menstruation". The MHRA notes "There needs to be a link to a specific disease/s to qualify as a device."
- **Appendix 1, symptom checkers:**
  - Outputs can include "An indication of seriousness – e.g. 'Red flag'" and "Triage 'signposting'".
  - "May be devices": filtering "by red flag/severity/probability".
  - "Unlikely to be devices": "Software that only signposts the user to suitable care e.g. see your GP, go to A&E".
- **Appendix 2, clinical calculators:** "Simple scores. Points given for listed symptoms … simple addition of the integer scores, usually, these can be easily verified" are "unlikely to be devices". "If the calculation cannot be easily verified by the intended user then it is likely to be a device."

**UK result:** the app has a medical context but no stated medical purpose of diagnosis, monitoring of disease or treatment. If its intended purpose is written as a personal record that she shares with her GP, it most likely falls outside reg. 2(1). The weak points are symptom tracking with calculations (trend, patterns), before/after medicine comparisons, and red-flag wording. Each can be managed by keeping outputs **descriptive and verifiable** and the wording **signposting only**. Disclaimers help, but the MHRA looks at the whole presentation objectively, so a disclaimer cannot rescue a medical claim made elsewhere.

### B3. EU later (MDR 2017/745, MDCG 2019-11 rev.1)

The EU definition (MDR Art. 2(1)) is wider than the UK one. It adds "prediction, prognosis" and "monitoring". Under **Rule 11 (Annex VIII)**, software "intended to provide information which is used to take decisions with diagnosis or therapeutic purposes" is class IIa or higher, and other device software is class I. That leaves almost no low-risk class I route for decision-type outputs. **MDCG 2019-11 rev.1** (European Commission, June 2025) is the current qualification guidance, and **MDCG 2025-4** covers apps on online platforms. I read only the Commission's update notice and secondary summaries, not the rev.1 text, so counsel should check it. Practical point: the trend, pattern and before/after features and the red flags would get a closer look under the EU regime than in the UK. Do not open EU storefronts until counsel has reviewed them (question 17 in `legal-questions.md`).

---

## C. Feature-by-feature assessment

### C1. Daily symptom logging
- **What the code does:** stores ratings 0–3, impact, bleeding (`Bleeding` none/spotting/light/medium/heavy, `Models.swift:25-26`), factors and episodes. No analysis at entry. "Fill in" is limited to 3 days back (`Questionnaire.swift:64-73`).
- **US:** not a device (MMA App. A #12). **UK:** no medical purpose by itself. **Risk:** low.
- **Keep:** "This app records what you report. It does not diagnose or give medical advice." (en.json:406; `Theme.swift:273`).

### C2. "Higher / lower than usual" vs her own baseline
- **What the code does:** `Comparison.trend` (`Comparison.swift:15-33`) compares today's rating with the mean of the previous 14 days. It needs at least 5 earlier ratings and labels a difference of ±0.75 or more as "higher than usual" or "lower than usual". On the report, `ReportSummary.build` (`ReportSummary.swift:41-47`) compares the last 4 weeks with the 4 before, needs 7 or more ratings on each side, and uses ±0.3. Labels are neutral (`Comparison.swift:3-7`; en.json:492, 495, 500). After a check-in the app shows "Compared with your last 2 weeks" plus "A pattern, not a verdict. Your doctor will see the same numbers." (`CheckInView.swift:188-192`; en.json:72, 128).
- **US:** a patient-facing trend of self-reported data is App. A #12 (record and organise) or at most App. B #12–13 (trending). It is not CDS. The 2026 GW guidance also confirms that "values, ranges, trends, baselines, or longitudinal summaries" can be shown in a wellness context (p.6). **UK:** this is "symptom tracking" with a "simple calculation" (MHRA p.12). It is defensible as easily verified (App. 2), but the user cannot verify it today because the mean is hidden.
- **Risk:** low (US), medium (UK).
- **Design:** show the number next to the word, for example "Hot flushes: higher than usual (today 3, your 14-day average 1.6)". Avoid red or green colour coding, "worse", "worsening" or "flare". Never link a trend to a condition or a treatment. Keep the 5-day and 7-day minimums.

### C3. Factor counts ("counts only, not a cause")
- **What the code does:** `PatternFinder` (`Patterns.swift:22-64`) counts days with the symptom moderate or worse, with and without a factor, on the same day or the next day. It shows a pair only if both sides have 5 or more days and the rates differ by at least 0.25 (`Patterns.swift:23-26, 53-55`). It sorts by difference. The UI says "What happened together in your N check-ins. Counts, not causes, and not advice." (`HistoryView.swift:248`; en.json:446) and "A pattern, not a verdict." (`HistoryView.swift:504`).
- **US:** record and organise (App. A #12), similar to asthma trigger logs (App. A #14). **UK:** descriptive co-occurrence of lifestyle tags, with no disease link and no recommendation. The selection threshold is a calculation, but the counts shown ("6 of 8 days") can be checked by hand.
- **Risk:** low–medium.
- **Design:** always show both fractions. Never use "trigger", "causes", "linked to", "avoid" or "cut down". Never produce advice from patterns (for example "try less alcohol"). "Tags help you spot what happens together." (en.json:393) is fine.

### C4. Before/after averages around a medicine start date
- **What the code does:** `TreatmentCheck.compare` (`TreatmentCheck.swift:22-59`) computes the mean rating per symptom 28 days before and after `medication.started`, plus the nearest MRS totals. It shows nothing until there are 10 or more check-ins on each side (`TreatmentCheck.swift:24, 53`). UI texts:
  - "Started %@. Average of your daily ratings, %lld weeks before and after. 0 is none, 3 is severe." (en.json:380)
  - "Your doctor will weigh these numbers. The app does not say whether a treatment works." (`HistoryView.swift:419`; en.json:476)
  - "Shown on your report so your doctor sees everything you take. We never suggest medicines or doses." (en.json:368)
- **US:** App. A #12 expressly covers tools that record "drug intake times" and share them, provided there are no "recommendations to alter or change a previously prescribed treatment". Tidemark makes none. **UK:** this is the feature closest to "to monitor therapeutic measures" (MHRA p.10). Calling it "Treatment check" (type name) or "Started treatment" (en.json:381) moves it towards that purpose.
- **Risk:** medium (UK), low–medium (US).
- **Design:** frame it as a date comparison she chooses ("before and after a date"), not as a treatment evaluation. Never say "working", "effective", "response", "improved by" or "side effects", and never comment on dose. Keep the 476 disclaimer on the same screen. Do not market it as "see if your HRT works".

### C5. Menopause Rating Scale score on the report
- **What the code does:** 11 items scored 0–4 with domain subscores (`Questionnaire.swift:28-51`). The report shows "N of 44 on date", the subscores and earlier totals (`ReportPage.swift` questionnaire block). No severity bands are shown. On screen: "Menopause Rating Scale, 0 to 44. Higher means more symptoms." (`HistoryView.swift:46`; en.json:251) and "The score is for your doctor to interpret. It is not a diagnosis." (`QuestionnaireView.swift:92`; en.json:404).
- **US:** a simple sum of the patient's answers that she records and shares; App. A #12. The "simple calculations routinely used in clinical practice" category (MMA V.B #3) is for clinicians, and this is even lower risk. **UK:** a "simple score … easily verified" (App. 2), so unlikely to be a device.
- **Risk:** low–medium. The bigger risks are implying clinical validation (Q4) and the licence (Q5).
- **Design:** never add MRS severity categories ("mild/moderate/severe menopause") or cut-offs. Show item answers on screen so the sum can be checked. Do not claim "validated" or "clinical". Change "Doctors know this scale, so it goes at the top of your report." (`TodayView.swift:53`; en.json:66). It suggests clinical standing, and in some languages it reads as an endorsement.

### C6. Red-flag prompts
- **What the code does:** `RedFlags.check` (`RedFlags.swift:21-30`) fires `.heavyBleeding` when today's bleeding is `.heavy`. It fires `.bleedingAfterTwelveMonths` when today has any bleeding (including spotting) and the previous logged period (light or heavier flow, `CycleStats.swift:30-49`) ended 365 or more days earlier. The message is shown once on the post-save screen in a `WarningCard` (`CheckInView.swift:170, 197-198`). There is no call button and nothing on the report except "Heavy bleeding days: N" (en.json:375).
- **US:** advice on when to consult an HCP is App. B #7 (enforcement discretion). As noted in A2, the current imperative "Contact your doctor now" also takes the app outside the 2026 General Wellness safe harbour, while "evaluation … may be helpful" stays inside it. **UK:** pure signposting ("see your GP") is "unlikely" to be a device (App. 1). The current sentence "shouldn't wait for your appointment" grades the seriousness of the symptom, which is the "indication of seriousness – Red flag" output.
- **Risk:** medium.
- **Decision: keep, change the wording** (see section D). Removing the prompts lowers regulatory risk only slightly, because the app records bleeding either way. It raises the safety risk, because bleeding after 12 months without a period is a symptom clinicians want to see promptly, and MMA footnote 44 counts against software that would "discourage seeking treatment".

### C7. PDF report for the doctor
- **What the code does:** one page with:
  - a header: "Symptom summary for my %@" (doctor or GP) and "Recorded by me in the Tidemark app." (`ReportPage.swift:64, 71`);
  - a table of days present, average 0–3 and the "Last 4 weeks vs 4 before" trend;
  - the MRS, daily impact, cycle and bleeding, and medicines;
  - a footer: "Self-reported symptom record. It is not a diagnosis and does not suggest any treatment.", the UK-only line "UK guidance on menopause: NICE guideline NG23." and "Made with Tidemark on …" (`ReportPage.swift:153-157`).

  It unlocks after 7 check-ins (`ReportReadiness.swift:8-14`).
- **US:** a patient document for an HCP: App. A #12–13. It makes no recommendation, so it is not CDS. **UK:** the record is fine. The MHRA's raw-data concern (p.12) applies to the derived figures (average, trend).
- **Risk:** low–medium.
- **Design:** keep the self-reported framing and the footer. Add one line on method, for example "Average of daily self-ratings on days rated, 0–3. Trend compares the last 4 weeks with the 4 before." Keep CSV export available so a clinician can see the raw data. **Remove the NICE NG23 line.** Linking a guideline to the patient's figures suggests the report is aligned with, or should be read against, clinical guidance. It adds nothing for a GP and raises an endorsement question (Q6).

### C8. App Store listing (`docs/app-store.md`)
- **Fine and supportive:** subtitle "Symptom report for your doctor" (l.11), "Log perimenopause symptoms … take a clear one-page summary to your next appointment" (l.15), and "Tidemark records what you report. It does not diagnose, suggest treatment or give medical advice. If you are worried about a symptom, contact your doctor." (l.55). FDA App. A #13 expressly covers apps "marketed to help patients document, show, or communicate to health care professionals".
- **Watch:**
  - "Your numbers before and after starting a medicine or supplement" (l.37): reword (below).
  - "your Menopause Rating Scale score" (l.41): acceptable only once the licence is settled; never add "validated" or "clinically proven".
  - Keyword "HRT" (l.19): low risk, but with l.37 it reads like treatment monitoring. Consider dropping it.
  - Category "Medical (secondary)" (l.66): choose **Health & Fitness only**. The category is part of the promotional material that shows intended purpose under the UK definition.
  - Screenshot captions (l.74–79): fine.

---

## D. Red-flag wording review

**Current:**
- `heavyBleeding`: "Very heavy bleeding shouldn't wait for your appointment. Contact your doctor now." (`RedFlags.swift:13`; en.json:429)
- `bleedingAfterTwelveMonths`: "Bleeding after 12 months without a period shouldn't wait for your appointment. Contact your doctor now." (`RedFlags.swift:15`; en.json:110)

**Findings:**

1. **Regulatory.** "Shouldn't wait" grades how serious the symptom is (MHRA App. 1 "indication of seriousness"). "Contact your doctor now" is an imperative "prompt that recommend[s] … specific clinical action" (FDA GW 2026 p.6). Neither names a cause, which is good and should stay.
2. **Wrong term for the UK.** `RedFlag.message` has no `Region` parameter and always says "doctor". UK users should see "GP" (`ReportReadiness.swift:26` `doctorTerm`; CLAUDE.md rule). This is a bug.
3. **Label mismatch.** The prompt says "Very heavy", but the option the user taps is "Heavy" (`CheckInView.swift:155`; en.json:189), the top of a 5-step scale. So every heavy day produces a message about "very heavy" bleeding. That overstates what she logged, and repeated "now" alarms on ordinary heavy periods may teach her to ignore them.
4. **The 12-month check uses only the log.** It compares against the last *logged* period. A user who stopped logging for a year, or started using the app after her periods stopped, gets a false prompt, or none. The wording should say it is based on her log.
5. **No urgent-help route.** Acute heavy bleeding with feeling faint needs urgent care, not a GP appointment. MHRA App. 1 treats "go to A&E" signposting as unlikely to be a device, and FDA App. B #8–10 covers facility and emergency signposting under enforcement discretion. A short urgent-help line without clinical thresholds (no pad counts) is a reasonable safety addition. **Counsel should confirm it (Q-C3).**
6. **Backfilled days.** The prompt also appears after filling in an earlier day. Naming the logged day avoids an alarm about bleeding from three days ago.

**Recommendation: keep both prompts and change them** as below. Keep the triangle icon but use a neutral (non-red) tint, which is a design choice that reduces the "seriousness" signal. Add no "Call" button. Do not show the prompt on the PDF.

**Proposed wording** (doctor term from `Region.doctorTerm`, UK = "GP"):

| Key (new) | US English | UK English |
|---|---|---|
| Heavy bleeding | "You logged heavy bleeding. Please don't wait for your next appointment to mention it: talk to your doctor soon. If you feel faint or very unwell, get urgent help." | "You logged heavy bleeding. Please don't wait for your next appointment to mention it: talk to your GP soon. If you feel faint or very unwell, get urgent help." |
| Bleeding after 12 months | "You logged bleeding, and your log shows no period in the 12 months before. Please don't wait for your next appointment to mention it: talk to your doctor soon. If you had periods that aren't in your log, you can ignore this." | "You logged bleeding, and your log shows no period in the 12 months before. Please don't wait for your next appointment to mention it: talk to your GP soon. If you had periods that aren't in your log, you can ignore this." |

Why this works:
- It describes her own entries ("you logged", "your log shows").
- It signposts care and does not judge seriousness ("talk to … soon").
- It names no condition or cause, gives no likelihood or treatment, and uses no threshold beyond her own data.
- It still tells her not to wait, which protects her.

"12 months" is her own data interval, not a diagnosis. It is, however, also the clinical definition point, so it goes to counsel (Q-C2).

**More cautious fallback** (closest to the FDA GW 2026 carve-out, weaker on safety): "You logged heavy bleeding. It may help to talk to your doctor about this before your next appointment." I recommend the main version. The safety value of "don't wait" outweighs the small regulatory difference, because Tidemark does not depend on the General Wellness route.

**Implementation note** (for a later code change; not made here, since this memo is the only file in scope): give `RedFlag.message` a `Region` (or `doctorTerm`) parameter and use `L10n.format` with `%@`, as the suggested questions already do (`ExportFile.swift:146`). Pass `model.profile?.region` from `CheckInSavedView`. Change the key names in all 17 catalogs. Translators may write the word straight into the sentence where grammar needs it (as `Region.doctorTerm` comment says). Update the tests in `StatsTests.swift:71-74` only if the API changes.

---

## E. Intended-purpose statements: keep / change

Proposed intended-purpose statement (put it in the listing, support page and an About screen):
> "Tidemark is a personal diary for recording perimenopause and menopause symptoms, bleeding and medicines, and for sharing a summary of your own entries with your doctor. It does not diagnose, assess or monitor any condition, and it does not suggest or evaluate treatment."

**Keep (supports a non-device intended purpose):**

| Where | Text |
|---|---|
| en.json:406, `Theme.swift:273` | "This app records what you report. It does not diagnose or give medical advice." |
| en.json:405, `OnboardingView.swift:109` | "This app keeps a record. It does not diagnose or give medical advice." |
| en.json:358, `ReportPage.swift:153` | "Self-reported symptom record. It is not a diagnosis and does not suggest any treatment." |
| en.json:330, `ReportPage.swift:71` | "Recorded by me in the Tidemark app." |
| en.json:404 | "The score is for your doctor to interpret. It is not a diagnosis." |
| en.json:476 | "Your doctor will weigh these numbers. The app does not say whether a treatment works." |
| en.json:446 | "What happened together in your %lld check-ins. Counts, not causes, and not advice." |
| en.json:368 | "Shown on your report so your doctor sees everything you take. We never suggest medicines or doses." |
| en.json:72 / 71 | "A pattern, not a verdict. …" |
| en.json:251 | "Menopause Rating Scale, 0 to 44. Higher means more symptoms." |
| en.json:240, `OnboardingView.swift:67` | "Log how you feel in 30 seconds a day. Before your visit, get a one-page summary your doctor can read in a minute." |
| app-store.md:11, 15, 55 | Subtitle, promo text, disclaimer paragraph |

**Change:**

| en.json key (line) | Issue | New text |
|---|---|---|
| "Very heavy bleeding shouldn't wait for your appointment. Contact your doctor now." (429) | See D | Replace with a region-aware key: "You logged heavy bleeding. Please don't wait for your next appointment to mention it: talk to your %@ soon. If you feel faint or very unwell, get urgent help." |
| "Bleeding after 12 months without a period shouldn't wait for your appointment. Contact your doctor now." (110) | See D | Replace with: "You logged bleeding, and your log shows no period in the 12 months before. Please don't wait for your next appointment to mention it: talk to your %@ soon. If you had periods that aren't in your log, you can ignore this." |
| "11 questions, about 2 minutes. Doctors know this scale, so it goes at the top of your report." (66) | Suggests clinical validation or standing | "11 questions, about 2 minutes. Your total goes on your report." |
| "UK guidance on menopause: NICE guideline NG23." (419) | Links the report to a clinical guideline; endorsement issue | Remove (drop the line in `ReportPage.swift:154-156`) |
| "%lld of %lld check-ins. You can make a report after %lld, but 14 shows your doctor a clear pattern." (41) | Says the data is clinically sufficient | "%lld of %lld check-ins. You can make a report after %lld, but 14 gives a fuller picture." |
| "Started treatment" (381) | Frames it as treatment monitoring | "Started a medicine" |
| "Started %@. Average of your daily ratings, %lld weeks before and after. 0 is none, 3 is severe." (380) | Fine, but name the comparison as a date comparison | "Started %@. Your average daily ratings in the %lld weeks before and after this date. 0 is none, 3 is severe." |
| "A few taps. Your next report will show what changed after it." (68) | "What changed after" a treatment or visit implies an effect | "A few taps. Your next report will show your ratings before and after this date." |
| "All of these can come with hormonal change, even with regular periods. Many women never have hot flushes." (86) | Links her symptoms to a cause | "Pick any you've noticed, whatever the cause. You can change them anytime." |
| "Is there anything else we should rule out, such as thyroid or iron levels?" (218; `ExportFile.swift:147`) | Names possible causes (it is a question for the doctor, so low risk) | "Is there anything else we should check?" |

**Listing (`docs/app-store.md`):**
- l.37 "Your numbers before and after starting a medicine or supplement" → "Your own ratings before and after a date you choose, such as starting a medicine".
- l.66: choose Health & Fitness only (no Medical category).
- l.19: consider removing the keyword "HRT".
- l.41: keep "Menopause Rating Scale score" only once the licence is cleared. Otherwise use "your fortnightly questionnaire score".

Copy these changes into the other 16 languages (`docs/app-store/*.md`, `Localization/*.json`).

---

## Open questions for counsel

**US**
- **Q-US1.** Do you agree that Tidemark falls under MMA Appendix A #12–13 (not a device) and is not a CDS function? Is an FDA 513(g) request or a Digital Health Center of Excellence enquiry worthwhile, or unnecessary?
- **Q-US2.** Given the January 2026 General Wellness revision, should Tidemark avoid relying on General Wellness at all? Is "talk to your doctor soon" acceptable under the MMA enforcement-discretion route even though it is stronger than GW's "evaluation … may be helpful"?
- **Q-US3.** Is the developer a "vendor of personal health records" under the FTC HBNR, given data sits only on the device, in the user's private iCloud and in Apple Health? What incident-response steps should be written down now?

**UK**
- **Q-UK1.** Given MHRA v1.10g p.12 ("symptom tracking" applying "a simple calculation"), is the trend line or the pattern finder enough to bring Tidemark into scope? Does showing the underlying numbers resolve this?
- **Q-UK2.** Does the before/after medicine comparison amount to "monitor therapeutic measures"? Should it be presented only as a user-chosen date comparison, or removed for the UK?
- **Q-UK3.** If Tidemark were found to be a device, would it be class I (self-declared UKCA, UK Responsible Person if the publisher is outside the UK, PMS under the June 2025 rules)? Would the 2026 international reliance route matter?

**Red flags and wording**
- **Q-C1.** Should the red-flag prompts stay, as recommended here, given the safety duty and MMA footnote 44? Is there any liability difference between keeping and removing them (cf. question 14 on liability limitation)?
- **Q-C2.** Is "your log shows no period in the 12 months before" a "diagnostic threshold" in FDA's sense, or an acceptable description of the user's own data?
- **Q-C3.** Is the urgent-help line ("If you feel faint or very unwell, get urgent help") acceptable? Should it name a service (911; 999 or NHS 111), which would need a region field per market?
- **Q-C4.** Can the listing say "for your doctor", "report your doctor can read in a minute" and name the Menopause Rating Scale without implying clinical validation (legal-questions Q4)? Can the report mention NICE NG23 (Q6)? This memo recommends removing it.
- **Q-C5.** Apple Guideline 1.4.1 (Q11): does the Medical category or the red-flag text draw extra review? Is Health & Fitness only advisable?

**EU (later)**
- **Q-EU1.** Under MDR Rule 11 and MDCG 2019-11 rev.1, would the trend, pattern, before/after or red-flag functions make Tidemark class IIa software? Which features should be switched off for EU storefronts?

---

## Sources

All accessed 26 November 2026. "Verified" means I read the primary text. "Search only" means I relied on search results or secondary summaries and did not read the primary text.

**US**
1. FD&C Act § 201(h), 21 U.S.C. § 321(h): https://www.law.cornell.edu/uscode/text/21/321. Device definition as quoted in source 3, footnote 3 (verified via FDA quote; Cornell page not opened).
2. FD&C Act § 520(o), 21 U.S.C. § 360j(o): https://www.law.cornell.edu/uscode/text/21/360j. Verified (text of (o)(1)(A)–(E)).
3. FDA, *General Wellness: Policy for Low Risk Devices*, issued 6 January 2026, supersedes 27 September 2019; docket FDA-2014-N-1039. PDF https://www.fda.gov/media/90652/download; page https://www.fda.gov/regulatory-information/search-fda-guidance-documents/general-wellness-policy-low-risk-devices. Verified from the PDF (the HTML page returned HTTP 401 to automated access).
4. FDA, *Clinical Decision Support Software*, issued 29 January 2026, supersedes 6 January 2026 (which superseded September 2022). PDF https://www.fda.gov/media/109618/download; page https://www.fda.gov/regulatory-information/search-fda-guidance-documents/clinical-decision-support-software. Verified from the PDF.
5. FDA, *Policy for Device Software Functions and Mobile Medical Applications*, issued 28 September 2022 (QMSR cover note added; PDF modified 3 February 2026). PDF https://www.fda.gov/media/80958/download. Verified. Page numbers cited are the document's own page numbers.
6. FDA, Digital Health Policy Navigator: https://www.fda.gov/medical-devices/digital-health-center-excellence/digital-health-policy-navigator (HTTP 401 to automated access; not verified). Step 3 page https://www.fda.gov/medical-devices/digital-health-center-excellence/step-3-software-function-intended-maintaining-or-encouraging-healthy-lifestyle shows "Content current as of 09/27/2022" (verified).
7. Law-firm summaries of the January 2026 revisions, used only to confirm dates: Covington, "FDA Issues Revised Guidance on General Wellness Products" (Jan 2026) https://cov.com/en/news-and-insights/insights/2026/01/fda-issues-revised-guidance-on-general-wellness-products; Covington, "5 Key Takeaways from FDA's Revised CDS Software Guidance" (Jan 2026) https://www.cov.com/en/news-and-insights/insights/2026/01/5-key-takeaways-from-fdas-revised-clinical-decision-support-cds-software-guidance. Search only.
8. FTC, "Updated FTC Health Breach Notification Rule puts new provisions in place to protect users of health apps and devices", 26 April 2024: https://www.ftc.gov/business-guidance/blog/2024/04/updated-ftc-health-breach-notification-rule-puts-new-provisions-place-protect-users-health-apps. Verified. Final rule, 89 FR 47028 (30 May 2024), effective 29 July 2024: https://www.federalregister.gov/documents/2024/05/30/2024-10855/health-breach-notification-rule. Search only.

**UK**
9. The Medical Devices Regulations 2002 (SI 2002/618), reg. 2: https://www.legislation.gov.uk/uksi/2002/618/regulation/2. Verified ("up to date with changes known to be in force on or before 26 November 2026"; latest reg. 2 amendment 17 June 2025).
10. MHRA, *Medical devices: software applications (apps)*, collection page last updated 1 July 2023: https://www.gov.uk/government/publications/medical-devices-software-applications-apps. Verified.
11. MHRA, *Medical device stand-alone software including apps (including IVDMDs)* v1.10g, including the device decision flowchart (p.6) and medical-purpose page (p.10): https://assets.publishing.service.gov.uk/media/6abf6c8c943e890cb55e5e52/Medical_device_stand-alone_software_including_apps__including_IVDMDs.pdf. Verified. Page numbers are the PDF's own.
12. MHRA, Appendix 1, Symptom checkers (v1.10f): https://assets.publishing.service.gov.uk/media/64a7d235c531eb000c650051/Appendix_1_-_symptom_checkers.pdf. Verified.
13. MHRA, Appendix 2, Clinical calculators (v1.10f): https://assets.publishing.service.gov.uk/media/64a7d23c7a4c230013bba33e/Appendix_2_-_clinical_calculators.pdf. Verified.
14. MHRA, *Crafting an intended purpose in the context of Software as a Medical Device (SaMD)*, published 22 March 2023: https://www.gov.uk/government/publications/crafting-an-intended-purpose-in-the-context-of-software-as-a-medical-device-samd/crafting-an-intended-purpose-in-the-context-of-software-as-a-medical-device-samd. Verified.
15. MHRA, *Software and AI as a medical device*, last updated 3 February 2025: https://www.gov.uk/government/publications/software-and-artificial-intelligence-ai-as-a-medical-device/software-and-artificial-intelligence-ai-as-a-medical-device. Verified.
16. MHRA, *Implementation of the future regulation of medical devices*, updated 12 March 2026 (PMS regulations in force 16 June 2025; pre-market and international reliance SI "will follow in 2026"; CE-recognition consultation 16 February–10 April 2026): https://www.gov.uk/government/publications/implementation-of-the-future-regulation-of-medical-devices/implementation-of-the-future-regulations. Verified. **Not verified:** whether the 2026 pre-market SI has been laid or commenced by November 2026.
17. MHRA, press release on PMS guidance: https://www.gov.uk/government/news/mhra-guidance-on-new-medical-devices-post-market-surveillance-requirements. Search only.
18. NICE NG12 (suspected cancer: recognition and referral), postmenopausal bleeding recommendations, with section 1.5 under update in 2026. Used only as safety background for keeping the prompt, not quoted in the app: https://www.nice.org.uk/guidance/ng12. Search only; current wording not verified.

**EU**
19. European Commission, "Update – MDCG 2019-11 rev.1 – Qualification and classification of software" (June 2025): https://health.ec.europa.eu/latest-updates/update-mdcg-2019-11-rev1-qualification-and-classification-software-regulation-eu-2017745-and-2025-06-17_en. Search only; rev.1 text not read.
20. Regulation (EU) 2017/745, Art. 2(1) and Annex VIII Rule 11: https://eur-lex.europa.eu/eli/reg/2017/745/oj. Not opened for this memo; described from the regulation's known text, so check it.

**Tidemark files reviewed:** `README.md`, `CLAUDE.md`, `docs/legal-questions.md`, `docs/app-store.md`, `Localization/en.json`, `Packages/TidemarkCore/Sources/TidemarkCore/{RedFlags,Comparison,Patterns,TreatmentCheck,WeeklySummary,ReportSummary,Questionnaire,ReportReadiness,CycleStats,ExportFile,Models}.swift`, `App/Features/{CheckInView,ReportPage,OnboardingView,HistoryView,QuestionnaireView,TodayView}.swift`, `App/Theme.swift`. There was no `graphify-out/` directory, so no graph queries were run.
