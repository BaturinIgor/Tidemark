# Translation review, 19 Nov 2026

An independent AI review (four reviewers, four languages each) checked every app string, the permission prompts and the App Store listing against the English source and the project rules. All fixes below are already applied. This is not a native-speaker review: the notes per language list what a human reviewer should still look at.

| Language | Fixes (critical / major / minor) | Verdict |
|---|---|---|
| de | 0 / 5 / 26 | ready after these fixes |
| fr | 0 / 5 / 38 | ready after these fixes |
| es | 0 / 5 / 30 | ready after these fixes |
| it | 0 / 4 / 24 | ready after these fixes |
| nl | 0 / 4 / 18 | ready after these fixes |
| pt-BR | 0 / 3 / 12 | ready after these fixes |
| sv | 0 / 9 / 21 | ready after these fixes |
| nb | 0 / 3 / 17 | ready after these fixes |
| da | 0 / 6 / 17 | ready after these fixes |
| fi | 0 / 8 / 21 | ready after these fixes |
| pl | 0 / 5 / 23 | ready after these fixes |
| ja | 0 / 1 / 18 | ready after these fixes |
| ko | 0 / 5 / 16 | ready after these fixes |
| zh-Hans | 0 / 5 / 18 | ready after these fixes |
| tr | 0 / 3 / 19 | ready after these fixes |
| ru | 0 / 2 / 26 | ready after these fixes |

Open decisions for Igor:

- Spanish: one `es` file follows Spain's Apple terms (Ajustes, Añadir). Mexico's iOS says Configuración and Agregar. A separate `es-MX` localization is a small addition if Mexico is opened.
- Apple renamed Apple ID to Apple Account in several languages; texts still say Apple ID. Check against the current iOS before release.
- The 11 MRS items stay as our own wording until the official translations arrive.

## de

The German draft is good overall: natural du-register, correct Apple terms (Einstellungen, Mitteilungen, Sperrbildschirm, Zuletzt gelöscht, Health), consistent Hitzewallung/Nachtschweiß and keine/leicht/mittel/stark, and gender-fair "Ärztin oder Arzt". The main real errors are "Tipp" used for a tap (it means a tip/advice) in two strings and the listing, one count string that is not a plural object, and a dropped %@ in the treatment-options question. The rest are small fixes: missing "am" before dates, a few anglicisms, and mixing "Symptome" and "Beschwerden". The MRS items match the meaning of the established German MRS wording. A native reviewer may want to decide between "Symptome" and "Beschwerden" globally (the draft mostly uses Beschwerden; Settings › My symptoms and the onboarding list should match), and whether "Apple-ID" should become "Apple Account" for iOS 18+.

Major fixes:
- `A few taps. Your next report will show what changed after it.`: "Ein paar Tipps" reads as "a few tips/pieces of advice", not taps.
- `One tap saves a hot flush with the time.`: "Ein Tipp" means "a tip (advice)"; the gesture is "tippen".
- `Bleeding on %lld days`: Count with a noun needs a plural object; "an 1 Tagen" is wrong.
- `What are my treatment options, including %@, and what are the risks fo`: %@ was dropped, but this string is not one of the five where dropping is allowed.
- Store listing, Description: "mit einem Tipp" means "with a tip (advice)", which is wrong in a health listing.

## fr

The French draft is solid: consistent vous register, feminine agreement where the user is addressed (gênée, prise au sérieux, débitée), correct Apple terms (Réglages, Santé, Supprimés récemment, écran verrouillé, OK for Done) and consistent bouffée de chaleur / aucun-léger-modéré-sévère. Real errors are one count string without plural forms, a dropped %@, "urgences" (emergencies) in an MRS item, and the "Jours présents" report header. The listing keywords waste space by repeating "ménopause" and "suivi" from the Name. A native reviewer should decide on the word for check-in: the draft uses "suivi" for check-in, tracking and follow-up, and "relevé" in a prompt; "suivi" works but a global choice is worth confirming. "Sévère" for severe is common in French medical usage; confirm it against the validated French MRS when it arrives.

Major fixes:
- `Bleeding on %lld days`: Needs a plural object and a preposition; "Saignements 1 jours" is ungrammatical.
- `What are my treatment options, including %@, and what are the risks fo`: %@ was dropped, but this string is not one of the five where dropping is allowed; both region terms are "traitement hormonal", so "le %@" works.
- `Needing to pee often, urgency, leaking`: "urgences" means emergencies in French; the symptom is an urgent need to urinate.
- `Days present`: Report column header; "Jours présents" means "days that are present", not days the symptom was present.
- Store listing, Keywords: "ménopause" and "suivi" repeat words from the Name (wasted characters); French women commonly search "préménopause", "THS" and "gynéco". 100 characters.

## es

The Spanish draft reads naturally, keeps tú consistently, uses feminine forms where needed (Bienvenida) and keeps sofoco and nada/leve/moderado/fuerte consistent. Real errors are one count string without plural forms, a dropped %@, a headline that starts with "Toca" (the app's word for Tap), and the "Días presente" report header. The biggest open issue is that one file serves Spain and Mexico but follows Spain's Apple terms: iOS in Mexican Spanish says "Configuración" (not "Ajustes") and "Agregar" (not "Añadir"), and Mexican users say "bochornos" more than "sofocos". A native reviewer should decide whether to ship a separate es-MX localization; until then the Settings path in the subscription and Health strings will not match what Mexican users see. Smaller items fixed here are Spain-only phrasing (contacta con, picor) and first-person symptom names.

Major fixes:
- `Bleeding on %lld days`: Needs a plural object and a preposition; "Sangrado 1 días" is ungrammatical.
- `What are my treatment options, including %@, and what are the risks fo`: %@ was dropped, but this string is not one of the five where dropping is allowed; both region terms are "terapia hormonal".
- `Fortnightly questionnaire is due`: "Toca" is also the app's word for "Tap", so the headline reads "Tap the fortnightly questionnaire".
- `Days present`: Report column header; "Días presente" is ungrammatical and unclear.
- Store listing, Keywords: "menopausia" and "diario" repeat words from the Name; Mexican users search "bochornos", and "premenopausia" is the common everyday word in both markets. 95 characters.

## it

The Italian draft is natural and warm, keeps tu consistently, uses feminine forms correctly (presa sul serio, condizionata, ostacolata, Bentornata) and keeps vampata and nessuno/lieve/moderato/forte consistent. Apple terms are right (Impostazioni, Salute, Eliminati di recente, schermata di blocco, Fine for Done). Real errors are one count string without plural forms, a dropped %@, and the "Giorni presenti" report header; the rest are small fixes (missing articles before dates, a few calques, "flusso" versus "sanguinamento" and "appuntamento" versus "visita"). The listing keywords repeat two words from the Name and miss the everyday word "caldane". A native reviewer may want to check that "resoconto" for report reads naturally to users; "report" is also common in Italian health apps.

Major fixes:
- `Bleeding on %lld days`: Count with a noun needs a plural object; "in 1 giorni" is wrong.
- `What are my treatment options, including %@, and what are the risks fo`: %@ was dropped, but this string is not one of the five where dropping is allowed; both region terms are "terapia ormonale".
- `Days present`: Report column header; "Giorni presenti" means "days that are present", not days the symptom was present.
- Store listing, Keywords: "menopausa" and "diario" repeat words from the Name; Italian women commonly say "caldane" for hot flushes and search "premenopausa" and "climaterio". 99 characters.

## nl

The Dutch draft is good overall: natural, warm je-register, correct Apple terms (Gezondheid, Instellingen, toegangsscherm, Recent verwijderd) and the disclaimers keep their exact meaning; no medical-advice drift found. Main issues are one lost plural, one dropped %@ placeholder, and a few literal calques (onboarding headline, field labels). Bleeding terminology was mixed (bloeding vs bloedverlies) and is unified to bloedverlies. A native reviewer may still want to confirm the symptom term "Wazig hoofd" for brain fog (hersenmist / brainfog are also common) and the Belgian market wording (e.g. huisarts vs dokter), and whether "Apple Gezondheid" matches Apple's current NL copy. The je convention is right for this app.

Major fixes:
- `Bleeding on %lld days`: Count with a noun needs a plural object (one/other); also uses the consistent term bloedverlies.
- `What are my treatment options, including %@, and what are the risks fo`: The %@ (region term HRT / hormone therapy) was dropped; this string is not one of the five allowed exceptions.
- `Walk into your appointment with the full picture`: "Ga je afspraak in met het hele plaatje" is a literal calque and sounds unnatural in an onboarding headline.
- Store listing, Keywords: "overgang" repeats a word from the Name (wasted keyword); overgangsklachten is the common Dutch search term. 100 characters.

## pt-BR

The Brazilian Portuguese draft is fluent and warm, uses você consistently, correct Apple terms (Ajustes, Saúde, ID Apple, Tela Bloqueada, OK for Done) and feminine forms for the user (levada, cobrada, pronta). Disclaimers are exact and nothing drifts into advice. Main issues are one lost plural, one dropped %@ placeholder, and a few calques. A native reviewer should decide between "fogacho" (medical/lay mix, used throughout) and the more everyday "calorão"/"ondas de calor" for the in-app term, and confirm "Apagados recentemente" against the current iOS album name (Photos shows "Apagados").

Major fixes:
- `Bleeding on %lld days`: Count with a noun needs a plural object (one/other); the plain string gives "1 dias".
- `What are my treatment options, including %@, and what are the risks fo`: The %@ (region term) was dropped; this string is not one of the five allowed exceptions.
- Store listing, Keywords: "menopausa" and "diário" repeat words from the Name; "ondas de calor" and "suor noturno" are common searches. 98 characters.

## sv

The Swedish draft is natural and friendly in the du-form, with correct Apple terms (Inställningar, Hälsa, Apple-ID, låsskärmen, lösenkod, Klar) and exact disclaimers; nothing reads as medical advice, and "Kontakta vården" is a good local choice. Main issues: one lost plural, one dropped %@, inconsistent night-sweat terms (nattsvett / nattliga svettningar / nattsvettningar), the ambiguous "Utskrivet" for prescribed, and a few calques. A native reviewer should check that "besvär" for "symptom" reads right in every short label (it is used everywhere instead of "symtom"), and the mixed use of "Din data" (common gender) vs "all data", which is accepted but debated.

Major fixes:
- `Bleeding on %lld days`: Count with a noun needs a plural object (one/other); the plain string gives "1 dagar".
- `What are my treatment options, including %@, and what are the risks fo`: The %@ (region term) was dropped; this string is not one of the five allowed exceptions.
- `Night sweats`: The symptom was "Nattliga svettningar" here but "nattsvettningar"/"Nattsvett" elsewhere; use one standard term everywhere.
- `Night sweat`: Consistent with Nattsvettningar; "nattsvett" is colloquial and differs from the rest of the app.
- `+ Night sweat`: Consistent night-sweat term.
- `Log a night sweat`: Consistent night-sweat term.
- `Prescribed`: "Utskrivet" also means "printed" or "discharged"; "På recept" is unambiguous for a medicine type.
- `Walk into your appointment with the full picture`: "Gå till besöket med hela bilden" is a literal calque and sounds unnatural as an onboarding headline.
- Store listing, Keywords: Adds the very common lay searches "övergångsåldern" and "vallningar", uses the standard "nattsvettningar", drops "dagbok" which echoes the Name. 98 characters.

## nb

The Norwegian Bokmål draft is good: natural du-form, correct Apple terms (Innstillinger, Helse, Apple-ID, Nylig slettet, låseskjermen, Bruk kode, Ferdig), consistent hetetokt/nattesvette and exact disclaimers; no medical-advice drift. Main issues are one lost plural, one dropped %@, a few calques and small grammar slips (mer/flere plager, missing "den" before a date). "fastlege" for the GP term is a good local choice. A native reviewer may want to confirm that "plage/plager" (used everywhere for "symptom") reads right in short labels, and that the keywords cover "overgangsalderen" (definite form, common in searches).

Major fixes:
- `Bleeding on %lld days`: Count with a noun needs a plural object (one/other); the plain string gives "1 dager".
- `What are my treatment options, including %@, and what are the risks fo`: The %@ (region term) was dropped; this string is not one of the five allowed exceptions.
- `Walk into your appointment with the full picture`: "Gå til timen med hele bildet" is a literal calque and sounds unnatural as an onboarding headline.

## da

The Danish drafts are fluent, warm and mostly idiomatic, with consistent use of 'gener', 'hedeture' and 'registrering' and correct du-form. The main defects are one missing plural object, a dropped %@ in the HRT question (not an allowed exception), and the wrong Apple name for Recently Deleted ('Senest slettet'). 'Natlig sved' was replaced by the standard 'nattesved' everywhere, and the listing keywords repeated a word from the name. A native reviewer should confirm Apple's current Danish naming for the Health app ('Sundhed' vs 'Apple Sundhed') and whether 'Færdig' or 'OK' matches iOS Danish for Done. Several count strings that are not plural in English (e.g. '%lld days ago · %lld days long') can show 1 and still read '1 dage'; the worst ones are fixed, the two-count one needs a source-side fix. In 'With %@' (Patterns) the factor label keeps its capital letter in non-English locales ('Med Alkohol'), a code issue. No medical-advice drift found; disclaimers are exact.

Major fixes:
- `Bleeding on %lld days`: English has plural forms; the singular needs 'dag', so this must be a plural object.
- `What are my treatment options, including %@, and what are the risks fo`: The %@ region term (HRT/hormone therapy) was dropped; this string is not one of the doctor-term exceptions.
- `Everything moves to Recently deleted for %lld days, on this iPhone and`: Apple's Danish name for Recently Deleted is 'Senest slettet'.
- `Recently deleted`: Apple's Danish name for Recently Deleted is 'Senest slettet'.
- Store listing, Keywords: 'overgangsalder' repeats a word from the name (wasted, Apple indexes the name already); adds 'klimakteriet', 'nattesved' (the word people search) and 'symptomer'.
- Store listing, Description: Apple's Danish name for Recently Deleted is 'Senest slettet'; must match the app.

## fi

The Finnish drafts are good overall: natural terminology (kuumat aallot, yöhikoilu, kirjaus, vastaanotto), correct case after numbers in most strings (genitive/inessive singular after %lld), and exact disclaimers. The main errors are number-agreement slips (plural verb after a number + partitive), the ungrammatical 'kahden kuukautisten', an ambiguous 'vuoto' in the urinary symptom, and strings with %@ dates where word order broke ('Palauta kaikki %@ poistettu'). Several count strings that are not plural in English can show 1; fixed with plural objects or 'pv'. A native reviewer should check 'With %@' in Patterns ('Alkoholi mukana', nominative label, no case possible) and whether Apple now uses 'Apple-tili' instead of 'Apple ID' in iOS 18 Finnish. Tone (sinä, plain and warm) is right.

Major fixes:
- `Rate how today felt for your %lld symptoms. It takes about 30 seconds.`: After a number + partitive the verb is singular ('tuntui', not 'tuntuivat'); '1 oireesi' is unnatural and Finnish 'one' is exactly 1.
- `Your %lld check-ins are safe on this iPhone, but they are not backed u`: Number + partitive takes a singular verb: '%lld kirjaustasi on', not 'ovat'.
- `Log bleeding in your daily check-in. Cycle lengths appear after two pe`: 'kahden kuukautisten' is ungrammatical; 'kuukautiset' is plural-only and needs 'kahdet'.
- `Needing to pee often, urgency, leaking`: Bare 'pakko' and 'vuoto' are unclear, and 'vuoto' is the app's word for bleeding.
- `Restore everything deleted on %@`: 'Palauta kaikki %@ poistettu' is ungrammatical and reads as 'everything is deleted'.
- `What are my treatment options, including %@, and what are the risks fo`: The %@ region term was dropped; this string is not one of the doctor-term exceptions, and the nominative apposition 'myös %@' works with 'hormonihoito'.
- Store listing, Description: Apple's Finnish term for Lock Screen is 'lukitusnäyttö'.
- Store listing, Screenshot captions: Apple's Finnish term for Lock Screen is 'lukitusnäyttö'.

## pl

The Polish drafts are good: correct Ty-form with capitalised pronouns, consistent feminine past forms (pominęłaś, zauważyłaś, przestałam), consistent terms (uderzenia gorąca, nocne poty, plamienie, łagodne/umiarkowane/silne) and all four CLDR categories in the plural objects. Main issues: a verb-agreement error in a 'few' form, a dropped %@ in the treatment question, a plural key flattened to a plain string ('Your top %lld questions'), and several counts pushed into brackets or label form, which reads machine-made in a few prominent places. To restore %@ in the HRT question without case problems I set both region terms to 'HTZ'; a native reviewer should confirm HTZ vs the newer MHT. Also check 'Z: %@' in Patterns, a workaround because the factor label cannot be put into the instrumental.

Major fixes:
- `%lld days are already on this iPhone and stay as they are.`: With 2–4 (few) the verb is plural: '3 dni są … pozostają', not 'jest … pozostaje'.
- `What are my treatment options, including %@, and what are the risks fo`: The %@ region term was dropped (not an allowed exception). Works with an indeclinable term; see the 'hormone therapy' fix.
- `hormone therapy`: Needed so %@ can be restored in the treatment-options question: 'terapia hormonalna' would need the accusative after 'w tym'. Polish uses HTZ for both regions anyway.
- `Your top %lld questions`: English is plural; with 1 the plain string reads 'najważniejsze pytania (1)'. Needs one/few/many/other.
- Store listing, Keywords: 'dziennik' repeats the name; adds 'przekwitanie' and 'uderzenia ciepła' (very common everyday search terms) and 'nocne poty' instead of bare 'poty'. 'objawy' dropped to fit 100 (the subtitle already has 'objawów').

## ja

The Japanese draft is good: natural polite です/ます register, consistent severity labels (なし・軽い・中くらい・強い), disclaimers kept exact, and Apple terms such as 最近削除した項目 and 設定 are right. The one real defect is a dropped %@ in the treatment-options question, which is not one of the allowed exceptions. The other fixes are word choice: 不正出血 (a clinical 'abnormal bleeding' label) for spotting, 睡眠不足 for poor sleep, and Appleヘルスケア where Apple says ヘルスケア. A native reviewer should decide whether to keep 'Menopause Rating Scale' in English; Japanese clinicians know it less than the Kupperman index or the SMI, so the line 'Doctors know this scale' is a slight overstatement in Japan. The polite tone convention fits a Japanese health app.

Major fixes:
- `What are my treatment options, including %@, and what are the risks fo`: The %@ placeholder was dropped and the term hard-coded; this string is not one of the five allowed exceptions, so the region term (HRT / hormone therapy) must stay a placeholder.

## ko

The Korean draft is fluent overall, keeps the 해요체 register consistently, and has correct Apple terms such as 최근 삭제된 항목, 설정, 구독 and 암호. The real errors: the treatment-options question drops %@; 'Who you're seeing' is rendered as 'the person receiving care' (the patient); and spotting appears as 점상 출혈 (petechiae) in two places while the main label says 소량 출혈. Several smaller issues are calques ('full picture', 'useful picture') and plan labels (매월/매년 instead of 월간/연간). A native reviewer should decide whether 식은땀 (literally 'cold sweat') is the best label for night sweats: Korean menopause content uses it widely, but 야간 발한 is the precise term, and the change would have to be made everywhere at once. 해요체 is a good fit for this app.

Major fixes:
- `What are my treatment options, including %@, and what are the risks fo`: The %@ placeholder was dropped and the term hard-coded; this string is not one of the five allowed exceptions.
- `Who you're seeing (optional)`: 진료받는 분 means 'the person receiving care' (the patient), the opposite of the clinician the field asks for.
- `%lld spotting days`: 점상 출혈 is the medical term for petechiae (pinpoint skin bleeding), not spotting; the app's own Spotting label is 소량 출혈.
- `Spotting days: %lld · Heavy bleeding days: %lld`: Same wrong term (점상 출혈 = petechiae); keeps it consistent with Spotting = 소량 출혈.
- Store listing, Description: 점상 출혈 means petechiae, not spotting.

## zh-Hans

The Simplified Chinese draft is clean and natural, uses the right Apple terms (面容 ID, 最近删除, 锁定屏幕, 设置, App) and correct symptom vocabulary (潮热, 盗汗, 围绝经期, 点滴出血), and keeps 你 consistently. The main pattern to fix is the verb 建议: 'does not suggest treatment' became 不建议治疗, which Chinese readers also take as 'advises against treatment'. That happens in the PDF disclaimer, the medicines hint and the store description, and it turns a disclaimer into something that sounds like advice. Also: the treatment-options question drops %@; HRT and 'hormone therapy' were translated the same way, so the region switch did nothing; and 就诊对象 for 'who you're seeing' suggests the patient. The rest are small wording and consistency fixes. 你 is fine for a consumer health app in mainland China.

Major fixes:
- `What are my treatment options, including %@, and what are the risks fo`: The %@ placeholder was dropped and the term hard-coded; this string is not one of the five allowed exceptions.
- `Self-reported symptom record. It is not a diagnosis and does not sugge`: 不建议任何治疗 also reads as 'advises against any treatment'; the disclaimer must say the app makes no treatment suggestion.
- `Shown on your report so your doctor sees everything you take. We never`: 从不建议药物 can read as 'we never advise taking medicines'; 推荐 keeps the neutral meaning 'we never suggest'.
- `Who you're seeing (optional)`: 就诊对象 usually means the patient, not the clinician the field asks for.
- Store listing, Description: 不建议治疗 reads as 'advises against treatment', which is advice.

## tr

The Turkish drafts are of high quality: natural sen-form, correct Apple terms (Vazgeç, Bitti, Son Silinenler, Ayarlar, Parola), and suffixes after placeholders are avoided by using label forms or 'tarihinde/tarihli', while apostrophe suffixes on fixed names (Ayarlar'dan, Sağlık'a, PDF'yi, 3'te) follow vowel harmony correctly. The two real defects are the dropped %@ in the treatment question and 'En önemli %lld sorun', which reads as 'problems' on the PDF. Others are calques and small ambiguities ('Neden gidiyorsun?' = 'why are you leaving?', 'bir tarihim var'). A native reviewer should decide whether GP should be 'aile hekimi' for Turkish users and whether Apple's newer 'Apple Hesabı' should replace 'Apple Kimliği'. No medical-advice drift; disclaimers are exact.

Major fixes:
- `What are my treatment options, including %@, and what are the risks fo`: The %@ region term was dropped (not an allowed exception); a nominative term before 'dahil' needs no suffix.
- `Your top %lld questions`: 'sorun' (soru + your) is read first as 'problem', so a report heading 'En önemli 3 sorun' says 'your 3 biggest problems'.
- Store listing, Keywords: 'menopoz' repeats the name; 'klimakteri' is not the usual Turkish spelling ('klimakteryum'); adds 'gece terlemesi'.

## ru

The Russian draft is competent: the вы register is consistent, feminine past tense is right where it appears (проснулась, перестала), the plural objects use correct one/few/many/other forms, and the Apple terms are right (Недавно удаленные, Настройки, код-пароль, экран блокировки). The most visible bug is the narrow button 'Умер.', which reads as 'died'. The treatment-options question also drops %@; that is fixable by using 'например', which keeps the inserted term in the nominative. Elsewhere the drafter often avoided plurals with 'Label: %lld' constructions. That is acceptable Russian UI style, and I converted only the two places where a following pronoun broke agreement. The rest are calques ('не должно ждать приема', 'полная картина') and 'Apple Здоровье' where Apple says «Здоровье». A native reviewer should check that the symptom labels sound natural, since they mix first-person phrases ('Забываю слова', 'Просыпаюсь ночью') with noun phrases ('Туман в голове').

Major fixes:
- `Mod.`: 'Умер.' reads as 'died' (the past tense of умереть) on a severity button in a health app; 'Умерн.' is still short and cannot be misread.
- `What are my treatment options, including %@, and what are the risks fo`: The %@ placeholder was dropped and ЗГТ hard-coded; with 'например' the inserted term stays in the nominative, so both ЗГТ and 'гормональная терапия' fit grammatically.


# Second independent review, 26 Nov 2026

Four new AI reviewers (four languages each) checked every string and listing again without reading the first review. Fixes are applied, except two pt-BR plural fixes that dropped the number from the "one" form (in Portuguese "one" also covers 0), which `l10n.py lint` rejected. Still not a native-speaker review.

Code fixes found on the way: "How did it go?" showed in English in every language (ScreenHeader picked the verbatim overload), and the Patterns card header "THE DAY BEFORE / THE SAME DAY" was hard-coded English. "Apple ID" in the English source is now "Apple Account", as the translations already said.

| Language | Fixes (critical / major / minor) | Verdict |
|---|---|---|
| de | 0 / 0 / 5 | ready after fixes |
| fr | 0 / 0 / 6 | ready after fixes |
| es | 0 / 0 / 7 | ready after fixes |
| it | 0 / 0 / 8 | ready after fixes |
| nl | 0 / 0 / 10 | ready after fixes |
| pt-BR | 0 / 0 / 5 | ready after fixes |
| sv | 0 / 0 / 2 | ready after fixes |
| nb | 0 / 0 / 9 | ready after fixes |
| da | 0 / 0 / 6 | ready after fixes |
| fi | 0 / 0 / 7 | ready after fixes |
| pl | 0 / 1 / 5 | ready after fixes |
| ja | 0 / 1 / 7 | ready after fixes |
| ko | 0 / 5 / 7 | ready after fixes |
| zh-Hans | 0 / 0 / 3 | ready after fixes |
| tr | 0 / 1 / 5 | ready after fixes |
| ru | 0 / 0 / 8 | ready after fixes |

## de (second review)

The German strings are accurate, complete and consistently informal (du) with gender-fair 'Ärztin oder Arzt'. Placeholders and plurals are correct, the 'stellt keine Diagnosen' line and the red-flag texts are faithful and no stronger than English. Apple terms (Einstellungen, Mitteilungen, Zuletzt gelöscht, Sperrbildschirm, Health) are right except the outdated 'Apple-ID'. Remaining issues are small: one clinical-sounding word, an odd abbreviation, a widget text that is too long, and listing wording.

For the native reviewer:
- MRS vs established German MRS wording (from memory, not certain): item 1 title is 'Wallungen, Schwitzen' (ours 'Hitzewallungen, Schwitzen'), item 4 'Depressive Verstimmung' (ours 'Gedrückte Stimmung'), item 10 'Trockenheit der Scheide' (ours 'Scheidentrockenheit'), item 9 hint 'Beschwerden beim Wasserlassen, häufiger Harndrang, unwillkürlicher Harnabgang', item 7 hint includes 'Vergesslichkeit'. Scale labels keine/leicht/mittel/stark/sehr stark match. Replace with the licence holder's text when supplied.
- 'Brain fog' is translated 'Konzentrationsprobleme', which overlaps with the MRS item 7 hint; decide whether 'Brain Fog' / 'Gedankennebel' is more recognisable to German users.
- Report PDF title 'Übersicht meiner Beschwerden für meine Ärztin oder meinen Arzt' (62 chars, 18 pt bold) will likely wrap to two lines; consider a shorter title such as 'Meine Beschwerden – Übersicht für den Arzttermin'.
- App name 'Tidemark: Wechseljahre-Tracker': the grammatical compound is 'Wechseljahres-…' but that is 31 chars; confirm the chosen form reads naturally.
- Listing uses 'Symptome' in three places while the app consistently says 'Beschwerden'; fine for search, but confirm it is intended.
- Listing omits the USD prices (says monthly or yearly, prices vary by country); confirm that is acceptable for the German storefront.
- MRS item titles 'Irritability', 'Anxiety', 'Low mood' and 'Vaginal dryness' are the same catalog keys as daily symptom names, and the MRS answer labels None/Mild/Moderate/Severe are the same keys as the daily severity scale. When the licence holder's official MRS wording arrives, pasting it into these keys will also rename the daily symptoms and scale. Developers should split the MRS keys (e.g. with a context comment/separate keys) before applying the official translation.
- Scale name 'Menopause Rating Scale (MRS)' is kept in English in the app and the listing; check what name the official translation uses.

## fr (second review)

The French strings are accurate and complete, consistently use vous, and use feminine agreement where the user is addressed (gênée, prise au sérieux, débitée). Placeholders and plurals are valid; the 'ne pose pas de diagnostic' line and the red-flag texts are faithful. Apple terms (Réglages, Supprimés récemment, écran verrouillé, Santé) are right, except 'identifiant Apple' (now compte Apple) and the non-Apple name 'Apple Santé'. Typography uses normal spaces before ? : ; » and the check-in term 'suivi' is overloaded; both are left for a native decision.

For the native reviewer:
- 'Check-in' is translated 'suivi' everywhere, but 'suivi' also means tracking ('Tracking' → 'Suivi') and follow-up ('Rendez-vous de suivi'). Strings like 'Pas de suivi', 'Commencer le suivi' may read as 'no follow-up'. Consider 'bilan du jour' or 'saisie' for the daily check-in.
- All French strings use a normal space before ? : ; ! and inside « ». Apple French UI uses a narrow no-break space (U+202F) or no-break space (U+00A0), so lines never break before the punctuation. Decide whether to replace mechanically.
- Severity scale uses 'sévère' / 'très sévère'; check against the validated French MRS answer labels when supplied (I do not know them with certainty).
- MRS item titles ('Troubles urinaires', 'Troubles sexuels', 'Gêne cardiaque', 'Épuisement physique et mental') are plausible, but I can't confirm the validated French MRS wording; replace with the licence holder's text.
- Small widget caption 'Bouffées de chaleur aujourd’hui' (31 chars, caption font) may wrap; check on a device.
- Promotional text says 'sur votre iPhone et iCloud' and drops 'your own'; 'et dans votre iCloud' would exceed 170 characters, so confirm the shortened wording is acceptable.
- MRS item titles 'Irritability', 'Anxiety', 'Low mood' and 'Vaginal dryness' are the same catalog keys as daily symptom names, and the MRS answer labels None/Mild/Moderate/Severe are the same keys as the daily severity scale. When the licence holder's official MRS wording arrives, pasting it into these keys will also rename the daily symptoms and scale. Developers should split the MRS keys (e.g. with a context comment/separate keys) before applying the official translation.
- Scale name 'Menopause Rating Scale (MRS)' is kept in English in the app and the listing; check what name the official translation uses.

## es (second review)

The Spanish strings are accurate, complete and consistently informal (tú), with feminine forms where the user is addressed (Bienvenida). Placeholders and plurals are valid. The 'No diagnostica' line and red-flag texts are faithful, and Apple terms (Ajustes, Eliminado recientemente, pantalla de bloqueo, Copia en iCloud, Salud) are correct apart from 'ID de Apple' and 'Apple Salud'. The listing wastes one keyword on a word already in the subtitle. Regional vocabulary (Spain vs Mexico) is for a native reviewer.

For the native reviewer:
- The listing targets Spain and Mexico, but the app only says 'sofoco' and 'regla'. Mexican users often say 'bochorno' and 'periodo/menstruación'. Decide whether one neutral Spanish works or an es-MX variant is needed.
- Severity scale uses 'fuerte' / 'muy fuerte'. The validated Spanish MRS probably uses 'severo' or 'intenso' (not certain); align the daily scale and MRS answers once the official text arrives.
- 'Registro' is used for check-in, tracking, log and 'registro de síntomas'; check that screens like 'Sin registro' and 'Registro' (Tracking settings section) stay clear.
- 'Good evening' → 'Buenas tardes' is shown as the Today title at any time of day before the first check-in; confirm this reads right.
- MRS item titles (e.g. 'Problemas de vejiga', 'Molestias en el corazón', 'Ánimo bajo') may differ from the validated Spanish MRS; replace with the licence holder's text.
- MRS item titles 'Irritability', 'Anxiety', 'Low mood' and 'Vaginal dryness' are the same catalog keys as daily symptom names, and the MRS answer labels None/Mild/Moderate/Severe are the same keys as the daily severity scale. When the licence holder's official MRS wording arrives, pasting it into these keys will also rename the daily symptoms and scale. Developers should split the MRS keys (e.g. with a context comment/separate keys) before applying the official translation.
- Scale name 'Menopause Rating Scale (MRS)' is kept in English in the app and the listing; check what name the official translation uses.

## it (second review)

The Italian strings are accurate, complete and consistently informal (tu), with feminine forms where the user is addressed (ostacolata, presa sul serio, Bentornata). Placeholders and plurals are valid. The 'Non fa diagnosi' line and red-flag texts are faithful ('subito' matches 'now'). Apple terms (Impostazioni, Eliminati di recente, schermata di blocco, Backup iCloud, Salute) are correct apart from 'ID Apple' and 'Apple Salute'. There are a few small wording slips.

For the native reviewer:
- 'Report' is translated 'resoconto' throughout; check that it sounds natural for a document you bring to the doctor ('riepilogo' is also used in places, e.g. the onboarding and listing).
- Severity scale uses 'forte' / 'molto forte'. The validated Italian MRS probably uses 'grave' / 'molto grave' or 'severo' (not certain); align once the official text arrives.
- MRS domain header 'Physical' → 'Fisici' (plural, implies 'sintomi'), while the other headers are 'Umore e mente' and 'Intimo e urinario'; check the three read as a set.
- 'Period' (menstruation) is mostly 'ciclo', so 'Ultimo ciclo iniziato il %@' and 'Nessun ciclo registrato' can be read as 'cycle'; decide whether 'mestruazioni' is clearer in these spots.
- MRS item titles (e.g. 'Disturbi cardiaci', 'Disturbi urinari', 'Umore basso') may differ from the validated Italian MRS; replace with the licence holder's text.
- MRS item titles 'Irritability', 'Anxiety', 'Low mood' and 'Vaginal dryness' are the same catalog keys as daily symptom names, and the MRS answer labels None/Mild/Moderate/Severe are the same keys as the daily severity scale. When the licence holder's official MRS wording arrives, pasting it into these keys will also rename the daily symptoms and scale. Developers should split the MRS keys (e.g. with a context comment/separate keys) before applying the official translation.
- Scale name 'Menopause Rating Scale (MRS)' is kept in English in the app and the listing; check what name the official translation uses.

## nl (second review)

Dutch is accurate, natural and consistently informal (je/jij), with Apple's Dutch UI conventions (Annuleer, Gereed, Bewaar, Instellingen, Gezondheid, toegangsscherm, Recent verwijderd, meldingen). Placeholders and one/other plurals are correct, and the 'geen diagnose' lines are intact. No medical-advice problems; the two red-flag lines say 'kan niet wachten' (cannot wait), a touch stronger than 'shouldn't wait'. Remaining issues are small: the outdated 'Apple ID' in the subscription path, a stiff report column header, and doctor-term strings that ignore the region setting. Store listing fits all limits (subtitle exactly 30, keywords exactly 100) with no repeated words.

For the native reviewer:
- Keep the English 'check-in' / 'inchecken' as the term for the daily entry, or use a Dutch word such as 'dagelijkse invoer'? It is used consistently, so this is a style call.
- The app uses 'de overgang' for perimenopause in a doctor question ('Kunnen deze klachten de overgang zijn…') and 'perimenopauze' elsewhere; confirm that mix reads naturally to Dutch women.
- MRS: the item hints follow our English wording, not the validated Dutch MRS (for example item 1 is usually 'Opvliegers, zweten (periodes van zweten)' and item 11 'Gewrichts- en spierklachten (gewrichtspijn, reumatische klachten)'). Swap in the licence holder's official Dutch text when it arrives; I could not verify the exact validated wording.
- 'Apple Gezondheid' as the name of Apple Health: Apple's Dutch material mostly says 'de Gezondheid-app'. Decide whether to keep 'Apple Gezondheid' in Settings and the listing.
- The listing drops the English prices ($6.99/$39.99) and says only 'maand- of jaarabonnement'. That is acceptable because storefront prices differ, but confirm it's intended (the same is true in all four languages).

## pt-BR (second review)

Brazilian Portuguese is accurate and natural, consistently uses 'você', and addresses the user in the feminine where it matters (levada, cobrada, Bem-vinda, PRONTA PARA A CONSULTA). Apple's pt-BR terms are right (Ajustes, Saúde, Tela Bloqueada, Apagados recentemente, Face ID, Usar código, OK for Done). Placeholders and one/other plurals are valid, and the 'não é um diagnóstico' lines are intact with no added medical claims. Fixes are minor: the outdated 'ID Apple', an ambiguous MRS hint ('relações'), and two awkward singular plural forms. The store listing is within all limits with no keyword repeats.

For the native reviewer:
- 'Fogacho' is used for hot flush throughout the app. It is the clinical term; many Brazilian women say 'calorão' or 'onda de calor'. The keywords already cover both. Decide which word the app UI should use.
- 'Low mood' is 'Desânimo', which is milder than the MRS item 'humor depressivo' in the Portuguese MRS. The same string is also a daily symptom name, so the MRS title may need its own key if the official translation differs.
- MRS answer labels use 'nenhum, leve, moderado, forte, muito forte'; the Portuguese MRS versions I know use 'severo / muito severo' for the top two. Confirm against the licence holder's official text.
- Generic masculine 'seu médico' is used everywhere. That's standard pt-BR, but confirm it's acceptable for this audience; 'seu médico ou sua médica' would be too long for small screens.
- 'neste aparelho' (Apple Health unavailable): Apple pt-BR usually says 'dispositivo'. Optional change.
- The listing drops the English prices and says only 'Uma assinatura mensal ou anual'. Acceptable because prices vary by storefront; confirm it's intended.

## sv (second review)

Swedish is accurate and idiomatic, consistently uses 'du', and follows Apple's Swedish UI terms (Inställningar, Hälsa, låsskärm, Nyligen raderade, notiser, lösenkod, Klar). The severity scale (inga, lätt, måttlig, svår, mycket svår) and symptom terms ('besvär') are consistent, placeholders and plurals are valid, and the 'ingen diagnos' lines are intact. The red flags say 'Kontakta vården nu' (contact healthcare), which is natural in Sweden and no stronger than the English. The only fixes are the outdated 'Apple-ID' in the app and the listing. The store listing is within all limits with no repeated words.

For the native reviewer:
- 'Incheckning' / 'checka in' for the daily entry sounds like an airport or hotel to some readers. Is 'dagsregistrering' or 'registrering' better? It's used consistently, so change all occurrences or none.
- The red flags use 'Kontakta vården nu' instead of 'your doctor'. Confirm this is preferred over 'Kontakta din läkare nu'; it is not a stronger claim.
- MRS: the hints follow our English wording. The Swedish MRS uses its own validated phrasing, for example for item 6 'Fysisk och psykisk utmattning' (our hint 'Sämre ork' is close). Replace with the licence holder's official Swedish text; I could not verify the exact wording.
- Bleeding amount 'Heavy' is 'Riklig' but the symptom 'Heavy bleeding' is 'Kraftig blödning'. Both are idiomatic; align them if you want one term.
- The listing drops the English prices; acceptable because prices vary by storefront, but confirm it's intended.

## nb (second review)

Norwegian Bokmål is accurate and natural, consistently uses 'du', and follows Apple's Norwegian UI terms (Innstillinger, Helse, låseskjerm, Nylig slettet, varsler, Bruk kode, Ferdig). 'Plage(r)', 'registrering' and 'time' are used consistently, the red flags keep 'bør ikke vente' with no stronger claim, and the 'ikke en diagnose' lines are intact. Placeholders and plurals are valid. Fixes are minor: the outdated 'Apple-ID', one MRS hint word ('gråtkvalt'), a progress line that drops 'igjen', and doctor-term strings that ignore the region setting (UK region gives 'fastlege' only in onboarding). The store listing is within limits.

For the native reviewer:
- The severity scale uses 'ingen, lett, middels, kraftig, svært kraftig'. 'Kraftig' also means Heavy bleeding on the same check-in screen. Would 'alvorlig' / 'sterk' read better for symptom severity, and what does the Norwegian MRS use?
- MRS: the hints follow our English wording. Replace with the licence holder's official Norwegian text; I could not verify the validated wording.
- The UK region maps 'GP' to 'fastlege'. That's fine, but confirm it, since a UK GP and a Norwegian fastlege are close but not identical.
- The listing drops the English prices; acceptable because prices vary by storefront, but confirm it's intended.

## da (second review)

The Danish strings are accurate, natural and consistently informal (du). Placeholders and plural forms are correct, and the red-flag and 'does not diagnose' lines keep the same strength as the English. The fixes are small: an outdated Apple ID term, two wording slips in MRS item 1 and a visit outcome, and mixed 'symptomdagbog'/'symptomlog'. The store listing is within every limit and makes no medical claims.

For the native reviewer:
- Apple Health naming: the app uses 'Apple Sundhed' (strings 'Apple Health', 'Apple Health isn't available on this device.' and the listing). Apple's Danish materials say 'Sundhed' / 'Sundhed-appen'. Decide which one to use, then use it everywhere.
- Symptoms are 'gener' throughout, while the keywords and the Face ID text use 'symptom'. Check that 'gener' is the register you want, compared with 'symptomer'.
- MRS: the answer labels are ingen/let/moderat/svær/meget svær. Compare them and the 11 item titles and hints with the official Danish MRS once the licence holder sends it. In particular check item 4's 'mangler energi' (the original means lack of drive) and item 7's 'nedsat overskud' (the original means lower performance).
- "With %@" (Patterns, paired with "Other days") receives the capitalised factor label in non-English languages. Danish shows 'Med Alkohol' with a capital letter in mid-phrase. Consider 'Med: %@' or another wording.
- The name 'Tidemark: overgangsalder-log' uses a hyphenated half-English compound. A native copywriter may prefer 'overgangsalderdagbog' or similar (30 characters max).
- The listing drops the English prices but keeps '(priserne varierer fra land til land)', which reads oddly with no price before it. Either add local prices or drop the parenthesis.
- Code issue, not a translation: HistoryView.swift:259 builds the Patterns card header from untranslated Swift literals "THE DAY BEFORE" / "THE SAME DAY" (the key "%@ · %@" has no letters, so l10n.py check skips it). Every non-English user sees English here.

## fi (second review)

The Finnish strings are good quality, informal (sinä) and consistent: kirjaus, oire, lievä/kohtalainen/vaikea. Placeholders and plural forms are correct. Both red-flag messages say 'ei voi odottaa' ('cannot wait'), which is a little stronger than the English 'shouldn't wait'. Smaller issues: an outdated Apple ID term, plan names written as adverbs, and MRS item 11 turning 'rheumatic-like' into 'rheumatic'. The store listing is within every limit and has no medical claims.

For the native reviewer:
- Apple Health naming: the app uses 'Apple Terveys' ('Apple Health', 'Apple Health isn't available on this device.' and the listing's 'Apple Terveyteen'). Elsewhere it uses 'Terveys-appi', which is what Apple's Finnish materials use. Decide whether 'Apple Terveys' is acceptable or should become 'Terveys-appi'.
- MRS item 2 'Heart discomfort' is 'Sydänoireet' ('heart symptoms'), which is broader. 'Sydänvaivat' may be closer. Check against the official Finnish MRS once it arrives, along with the answer labels (ei lainkaan/lievä/kohtalainen/vaikea/erittäin vaikea). The same key 'None' is used for MRS answers, bleeding amount and the daily scale.
- The daily scale says '0 ei oireita' but the 'None' button says 'Ei lainkaan'. Both are fine, but check that this mismatch is intended.
- "With %@" (Patterns, paired with "Other days") receives the capitalised factor label in non-English languages. Finnish shows '%@ mukana' (for example 'Alkoholi mukana'), which is understandable but unusual. Consider 'Merkitty: %@' or another wording.
- The listing drops the English prices but keeps '(hinnat vaihtelevat maittain)'. Either add local prices or drop the parenthesis.
- Code issue, not a translation: HistoryView.swift:259 builds the Patterns card header from untranslated Swift literals "THE DAY BEFORE" / "THE SAME DAY" (the key "%@ · %@" has no letters, so l10n.py check skips it). Every non-English user sees English here.

## pl (second review)

The Polish strings are good. They consistently use feminine forms for the user (pominęłaś, zapisałaś, przestałam) and the plural one/few/many/other forms are correct in every plural key. The red-flag and 'does not diagnose' lines are faithful. One technical risk: the key 'Started %@ … %lld weeks …' is a plural dict even though it has two arguments, while English and every other language use a plain string. Other fixes are small: an outdated Apple ID term, 'Okres' as the report-range header (it also means menstruation), MRS item 11, and a wasted duplicate in the keywords.

Major fixes:
- `Started %@. Average of your daily ratings, %lld weeks before and after`: This is a top-level plural variation on a key with two arguments (%@ and %lld). No other language does this, and it may pick the wrong argument or fail to build. 'tyg.' avoids needing plural forms.

For the native reviewer:
- Apple Health naming: 'Apple Zdrowie' ('Apple Health', 'Apple Health isn't available on this device.' and the listing) is not a form Apple uses. Apple's Polish materials say 'aplikacja Zdrowie'. Decide on, for example, 'Aplikacja Zdrowie' and use it everywhere.
- MRS answer labels are brak/łagodne/umiarkowane/silne/bardzo silne. The validated Polish MRS may use 'ciężkie / bardzo ciężkie' for severe/very severe; I am not certain. Compare these and the 11 items with the official Polish version once it arrives. The daily 0–3 scale shares the same labels.
- Subscription status values don't agree in gender: 'Active' is 'Aktywna' (feminine) and 'Free' is 'Bezpłatny' (masculine). Both show after 'Status'. Choose one form.
- "With %@" (Patterns, paired with "Other days") receives the capitalised factor label in non-English languages. Polish shows 'Z: %@', which is terse. Consider 'Dni z oznaczeniem: %@' to pair with 'Inne dni'.
- Capitalised Twój/Twoje/Ci are used throughout. This is acceptable in Polish UI but should be applied consistently (some strings use lowercase 'swój').
- Code issue, not a translation: HistoryView.swift:259 builds the Patterns card header from untranslated Swift literals "THE DAY BEFORE" / "THE SAME DAY" (the key "%@ · %@" has no letters, so l10n.py check skips it). Every non-English user sees English here.

## ja (second review)

The Japanese strings are natural and politely consistent (です/ます), and they use Apple's terms correctly (ヘルスケア, 最近削除した項目, 設定, ロック画面, ウィジェット). One real bug: '%@: moderate or severe on %lld of %lld days' puts the two numbers in Japanese order without positional specifiers, so it says '8 days out of 6' instead of '6 out of 8'. The red-flag and 'does not diagnose' lines are faithful. Smaller issues: Apple ID becoming Apple アカウント, plan titles that repeat their detail line, the promo text adding 'only', and a keyword repeated from the subtitle. The listing is within every limit.

Major fixes:
- `%@: moderate or severe on %lld of %lld days`: In Japanese the total comes first, but the arguments arrive as (hits, total). Without positional specifiers 6 of 8 days renders as '6日中8日' (8 out of 6 days); it should be '8日中6日'.

For the native reviewer:
- In the bleeding picker, 'Spotting' (少量の出血) and 'Light' (少ない) are near-synonyms in Japanese. Users may not see the difference. Consider a distinct term for spotting (for example 点状出血 or おりものに血が混じる程度) and apply it to 'Spotting', '%lld spotting days' and 'Spotting days: …'.
- MRS answer labels are なし/軽い/中くらい/強い/非常に強い, and the daily scale shares them. The validated Japanese MRS likely uses clinical terms (for example 軽度/中等度/重度). I am not certain. Compare these and the 11 item texts with the official Japanese version once the licence holder supplies it.
- Perimenopause is rendered as 更年期の始まり in strings and as プレ更年期 in the listing. Both are understandable, but decide on one term.
- The listing drops the English prices but keeps '（価格は国によって異なります）'. Either add local prices or drop the parenthesis.
- Code issue, not a translation: HistoryView.swift:259 builds the Patterns card header from untranslated Swift literals "THE DAY BEFORE" / "THE SAME DAY" (the key "%@ · %@" has no letters, so l10n.py check skips it). Every non-English user sees English here.

## ko (second review)

Korean is accurate and consistent overall, in a friendly 해요체 register, with Apple terms (건강 앱, 최근 삭제된 항목, 잠금 화면, Face ID, 암호) used correctly. The one real terminology problem is night sweats rendered as 식은땀 (cold sweat) across five strings that end up on the doctor-facing report. A few sentences are awkward or ambiguous (worst-day instruction, 약 %lld개, perimenopause term). Safety lines (does not diagnose, contact your doctor now) are intact and not strengthened; placeholders and listing limits are fine.

Major fixes:
- `Night sweat`: 식은땀 means cold sweat (a different sign), not night sweats; the report is read by doctors.
- `Night sweats`: Same term fix as "Night sweat"; symptom name on the report.
- `+ Night sweat`: Same term fix; quick-log button.
- `Log a night sweat`: Same term fix; App Intent / widget action.
- `Hot flushes and night sweats logged: %lld`: Same term fix; report line.

For the native reviewer:
- 식은땀 is common colloquially for menopausal sweating in Korean health media; confirm 야간 발한 (clinical) vs a plain form like 밤에 나는 땀 for the symptom label.
- Good evening is 좋은 저녁이에요, a calque; decide whether a more natural evening greeting fits the Today header.
- Keywords use 56 of 100 characters; consider adding symptom terms such as 야간발한, 생리불순, 질건조, 두근거림.
- Hot flush is 안면홍조 throughout; confirm vs 열감/홍조 for the target audience.
- MRS item wording should be replaced by the licensed Korean MRS when supplied; the scale name is left in English.

## zh-Hans (second review)

Simplified Chinese is accurate, natural and consistent: 围绝经期/更年期, 潮热, 盗汗, 点滴出血 and the 无/轻度/中度/重度 scale are used throughout, and Apple terms (“健康”App, 面容 ID, 最近删除, 锁定屏幕, 小组件) match iOS. Safety and does-not-diagnose lines are intact and not strengthened. Only small fixes: a relative-date word order and the renamed Apple Account. Store listing is within limits and keywords do not repeat the name or subtitle.

For the native reviewer:
- MRS item 'Feeling nervous, tense, aggressive' is 紧张、焦躁、易怒; check against the licensed Chinese MRS (aggressive vs irritable).
- Keywords use 50 of 100 characters; consider adding e.g. 月经紊乱, 阴道干涩, 心悸.
- Promo text says data is 只 (only) on iPhone and iCloud; the English has no 'only'. Fine unless Apple Health sync makes legal want it softened.

## tr (second review)

Turkish is accurate and natural, with correct Apple terms (Ayarlar, Son Silinenler, Parola, Vazgeç, Bitti, Kilitli Ekran) and careful suffix handling around placeholders (tarihinden beri, %%%lld). One MRS item, 'Heart discomfort', is rendered as 'Kalp rahatsızlığı', which in Turkish reads as heart disease and should be softened. Safety lines are intact; 'Hemen doktoruna başvur' matches 'contact your doctor now'. The listing is within limits, but one keyword repeats the subtitle.

Major fixes:
- `Heart discomfort`: "Kalp rahatsızlığı" means heart disease/condition, a diagnostic-sounding claim; MRS item means discomfort.

For the native reviewer:
- The whole app uses informal 'sen'. iOS itself uses 'siz', and users are women around 45-55 in a health context; decide whether to switch to 'siz' throughout (large change, do it in one pass).
- HRT and hormone therapy both map to 'hormon tedavisi'; confirm vs 'hormon replasman tedavisi (HRT)' for the UK region.
- Screenshot captions 1, 5 and 6 are 44-53 characters; check they fit the caption layout.
- MRS items should be replaced by the licensed Turkish MRS when supplied; the scale name is left in English.

## ru (second review)

Russian is accurate and natural, addressing the user formally with 'Вы' and using feminine forms in first-person strings (перестала, проснулась). Plural dicts have one/few/many/other, and the other strings sidestep plurals with 'дн.' or a 'label: N' pattern. Apple terms (Настройки, «Здоровье», Недавно удаленные, код-пароль, экран блокировки) are correct. Safety and does-not-diagnose lines are intact and not strengthened. Only minor fixes: one agreement error, one MRS nuance, the Cyrillic ОК, the Apple Account rename, and a keyword that repeats the subtitle.

For the native reviewer:
- Severity scale is adverbial (нет/слабо/умеренно/сильно/очень сильно); validated Russian MRS answers may use adjectives (e.g. слабые/умеренные/выраженные); align when the licensed version arrives.
- 'Check-in' is 'отметка' throughout; confirm it reads naturally vs 'запись' to a native speaker.
- Spelling uses е instead of ё (отчет); fine and consistent, confirm house style.
- App Store purchases on the Russian storefront may be unavailable to many users; confirm the subscription copy is wanted there.
