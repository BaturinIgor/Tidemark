# Working on Tidemark

Read README.md first. Hard rules:

- Never write code that can lose or silently drop user data. Do not delete the store on a load error, do not hard-delete rows (soft delete with `deletedAt`), and only add optional attributes to the Core Data model.
- No medical advice in any user-facing text: no diagnosis, no likelihoods, no treatment or dose suggestions. Describe the user's own numbers only. Keep the "does not diagnose" line on screens that show results.
- Health data must not go to analytics, logs (use `privacy: .private` or don't log it) or any server.
- Put logic that can be tested without UIKit or Core Data in `Packages/TidemarkCore` and cover it with Swift Testing.
- UI text is in English (US and UK markets). Use region terms from `Region` (GP vs doctor, HRT vs hormone therapy).
