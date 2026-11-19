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

