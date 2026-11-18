# Questions for a lawyer before launch

Tidemark: iOS app, US and UK first. Users log perimenopause symptoms; the app makes a one-page PDF summary for their doctor. No diagnosis, no treatment suggestions. Data stays on the device and in the user's private iCloud database; the developer runs no server for health data. Paid feature: PDF report via App Store subscription.

## 1. Medical device status

1. US (FDA): is the app a "general wellness" product or non-device software under the 21st Century Cures Act / FDA guidance on Clinical Decision Support and General Wellness, given that it only records and summarises self-reported symptoms?
2. UK (MHRA): does it fall outside the definition of a medical device (UK MDR 2002 and the MHRA guidance on software and AI as a medical device)? Does the answer change once we sell in the EU (MDR 2017/745, MDCG 2019-11)?
3. Which features could move it into device territory? Specifically:
   - "Red flag" prompts: when a user logs very heavy bleeding, or bleeding after 12 months without a period, the app says "... shouldn't wait for your appointment. Contact your doctor now." (see `RedFlags.swift`). Is this acceptable, is it safer to keep or to remove, and does it make the app a device?
   - The trend line "higher than usual / lower than usual" for the user's own ratings.
   - Counts of how often a symptom followed a factor (alcohol, poor sleep). Copy says "counts only, not a cause".
   - "Before and after" averages around a medicine start date.
4. Can the App Store listing and screenshots say "for your doctor" and name the Menopause Rating Scale without implying clinical validation?

## 2. Questionnaire licence

5. The Menopause Rating Scale (MRS) is used with an 11-item, 0–4 scoring. What licence or permission do we need to show the items in a paid app, and what attribution? (Fallback: our own non-scored checklist.)
5a. The app ships in 17 languages. Does the licence cover showing the MRS in all of them, and can we get the validated official translations? Until then the items are our own translations.
6. Can we mention NICE guideline NG23 on the UK report footer ("UK guidance on menopause: NICE guideline NG23")?

## 3. Data protection

7. The developer never receives health data. Is the developer still a controller under UK GDPR / EU GDPR for data stored in the user's iCloud? Do we need a DPIA, an Article 27 representative or a DPO?
8. Is the privacy policy draft (docs/privacy-policy.md) sufficient? What must change for UK, EU and US (Washington My Health My Data Act, Connecticut, Nevada, California CCPA/CPRA, FTC Health Breach Notification Rule)?
9. Apple's App Privacy label: is "Data Not Collected" correct given data sits only in the user's private CloudKit database and Apple Health?
10. Crash reports from Apple (opt-in): any obligations if they could ever contain health data?

## 4. Apple rules

11. App Store Review Guidelines 5.1.1, 5.1.3 (health data) and 1.4.1 (medical apps): anything in the flows or texts likely to be rejected?
12. HealthKit: we write symptom samples and may read sleep and menstrual flow. Any extra disclosures needed in the app or policy?

## 5. Consumer and subscription law

13. Subscription terms ($6.99/month, $39.99/year, auto-renew): is the paywall wording enough for UK Consumer Rights / DMCC Act 2024 subscription rules and US state auto-renewal laws (e.g. California)?
14. Do we need our own Terms of Use, or is Apple's standard EULA enough? Liability limitation for a health-adjacent app?

## 6. Name and brand

15. "Tidemark" trademark clearance in classes 9 and 44 (US USPTO, UK UKIPO, EUIPO). Known users: insightsoftware (B2B planning software) and two small US therapy practices. Risk of conflict? Should we file?

## 7. Company

16. Which entity publishes the app (individual or company), and in which country? This affects the App Store seller name, the privacy policy and tax.

## 8. Countries beyond the US and UK

17. The app is translated into 17 languages, but we only have to open the storefronts we choose. Which countries can we open in 1.0 without extra work? Notes: EU countries bring MDR and GDPR (questions 2 and 7); mainland China requires an ICP filing number for new apps and has its own rules for health apps; South Korea and Japan have their own medical device and privacy laws. Should the privacy policy and terms be translated where we open?
