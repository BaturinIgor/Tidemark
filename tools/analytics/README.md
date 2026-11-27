# Статистика Tidemark (Google Analytics for Firebase)

Схема как в ZenHab и Hearthmend, с двумя отличиями:

1. **Только по согласию (opt-in).** Tidemark — приложение про менопаузу, и даже то, какие экраны открывает человек, говорит о его здоровье (UK/EU GDPR). Пока пользователь не включил «Help improve Tidemark» при настройке или «Share anonymous usage» в Settings › Privacy, не уходит ничего.
2. **Никаких медицинских данных.** Отправить можно только события из `Packages/TidemarkCore/Sources/TidemarkCore/AnalyticsEvent.swift`: экраны, нажатия, покупки. Значения параметров берутся только из закрытых enum и корзин счётчиков, свободного текста нет. Тесты `AnalyticsEventTests` перебирают все возможные события и проверяют, что в них нет id и названий симптомов, оценок, кровотечения, факторов, заметок, лекарств, вопросов, визитов, своих симптомов, ответов и баллов опросника, и что нет события о предупреждении про кровотечение.

Обёртка: `App/Services/UsageAnalytics.swift`. Продукт `FirebaseAnalyticsCore` (без IDFA/AdSupport), IDFV, рекламные сигналы и подмена делегата выключены в `project.yml`, consent mode: `analytics_storage` по выбору пользователя, `ad_storage`, `ad_user_data`, `ad_personalization` всегда denied. При выключении вызывается `resetAnalyticsData()`.

В Debug, на симуляторе и в дизайн-каталоге (`-design`) ничего не уходит. Локально включить: аргументы `-AnalyticsDebug -FIRDebugEnabled`, события видны в Firebase › DebugView (и согласие в приложении должно быть включено).

## Что уходит

У всех событий, кроме `screen_view`, есть параметр `screen` — экран, на котором это случилось.

| Событие | Параметры | Когда |
|---|---|---|
| `screen_view` | `screen_name`, `screen_class` | показ экрана (список ниже) |
| `tab_selected` | `tab`: today / history / report / settings | переключение вкладки |
| `onboarding_step` | `step` 1–3 | шаг настройки |
| `onboarding_completed` | `count_bucket` (число выбранных симптомов), `enabled` (напоминание) | настройка завершена |
| `restore_chosen` / `start_fresh_chosen` | — | выбор при найденной копии в iCloud |
| `check_in_opened`, `missed_day_opened` | — | открыта отметка дня / пропущенного дня |
| `rating_changed` | — | изменена оценка (без симптома и значения) |
| `check_in_saved` | `count_bucket` (сколько всего отметок) | отметка сохранена |
| `quick_log_saved` | — | быстрая запись (без типа и силы) |
| `questionnaire_completed` | — | опросник заполнен (без баллов) |
| `medicine_saved`, `question_saved`, `visit_saved`, `appointment_saved` | — | сохранено (без текста) |
| `range_selected` | `range_weeks`: 4 / 8 / 12 / 26 / 52 | период в истории или отчёте |
| `report_previewed` | — | отчёт открыт на экране |
| `pdf_saved` | `range_weeks` | сохранён PDF |
| `comparison_toggled` | `enabled` | страница «Since your last visit» |
| `export_json`, `export_csv` | — | экспорт |
| `import_completed` | `count_bucket` (новых дней) | импорт файла |
| `delete_all_confirmed`, `restore_deleted` | — | удаление / восстановление |
| `symptoms_changed` | `count_bucket` | изменён список симптомов (без самих симптомов) |
| `own_symptom_added` | — | добавлен свой симптом (без названия) |
| `theme_changed` | `theme`: teal / plum / ocean / forest | тема |
| `icon_changed` | `icon`: standard / plum / ocean / forest / night | иконка |
| `reminder_toggled`, `face_id_toggled`, `apple_health_toggled`, `analytics_toggled` | `enabled` | переключатели в настройках |
| `contact_tapped` | — | «Contact us» |
| `pro_feature_tapped` | `feature` | нажата закрытая Pro-функция |
| `paywall_shown` | `feature` (откуда открыли, если из функции) | показан paywall |
| `plan_selected` | `plan`: yearly / monthly | выбран план |
| `purchase_started` / `purchase_cancelled` / `purchase_failed` / `purchase_completed` | `plan` | покупка |
| `trial_started` | `plan` | покупка началась с бесплатного периода |
| `purchase` | `value`, `currency`, `item_id`, `plan` | стандартное событие GA4, доход в отчётах (у пробного периода `value = 0`) |
| `restore_tapped`, `manage_subscription_tapped` | — | восстановление / управление подпиской |

`feature`: `pdf_report`, `since_last_visit`, `long_history`, `csv_export`, `more_symptoms`, `appearance`.

`count_bucket`: 0, 1, 2-6, 7-13, 14-29, 30-89, 90+.

Экраны (`screen_name`): onboarding_welcome, onboarding_symptoms, onboarding_visit, restore, today, check_in, check_in_saved, quick_log, history, cycle, patterns, medicines, medicine_detail, add_medicine, visit_history, after_visit, weekly_summary, questionnaire, report, report_preview, questions, paywall, settings, symptoms_editor, appointment, apple_health, import_preview, recently_deleted, appearance, lock, store_error.

User properties: `build_type` (debug / testflight / appstore), `first_seen_week` (вида 2026-W48), `is_pro` (0/1).

## Включение (владелец)

1. Firebase console › общий проект с ZenHab › приложение iOS `app.tidemark.ios` уже заведено. Его `GoogleService-Info.plist` лежит в `tools/analytics/` (файл в `.gitignore`).
2. Для CI: `gh secret set GOOGLE_SERVICE_INFO_PLIST < tools/analytics/GoogleService-Info.plist`.
3. Перед сборкой для App Store: `tools/analytics/add_firebase_config.sh` (по умолчанию ждёт bundle ID `app.tidemark.ios`), затем `xcodegen generate`. Без файла или с plist на другой bundle ID сборка не падает: warning в логе, статистика выключена.
4. Firebase / GA4 › Администратор:
   - Data retention: **2 месяца** (так написано в политике конфиденциальности);
   - Google Signals: **выключить**;
   - «Специальные определения»: user properties `build_type`, `is_pro`, `first_seen_week`; параметры событий `screen`, `tab`, `feature`, `plan`, `range_weeks`, `count_bucket`, `enabled`, `theme`, `icon`. Без этого их не видно в отчётах. Смотреть с фильтром `build_type = appstore`.
5. App Store Connect › App Privacy: см. `docs/apple-setup.md`, §4. Политика: `docs/privacy-policy.md`, раздел «Usage analytics».

## Воронки

- Первая сессия: `first_open` › `onboarding_step` 2 › 3 › `onboarding_completed` › `check_in_saved`.
- Подписка: `pro_feature_tapped` (по `feature`) › `paywall_shown` › `plan_selected` › `purchase_started` › `trial_started` / `purchase_completed`. Какая функция чаще приводит к покупке: разбивка `paywall_shown` и `purchase` по `feature` из `paywall_shown`.
- Удержание: «Когорты» по `first_seen_week`; доля дошедших до 7 и 14 отметок — `check_in_saved` с `count_bucket` 7-13 и 14-29.

Помните, что видна только часть пользователей: те, кто дал согласие.
