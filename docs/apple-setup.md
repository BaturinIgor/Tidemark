# Apple Developer и App Store Connect: пошагово

Для Tidemark 1.0. Team ID `46V47ZSX5V`. Все идентификаторы ниже уже прописаны в `project.yml`. Если их поменять, проект нужно поменять тоже.

| Что | Идентификатор |
|---|---|
| Приложение | `app.tidemark.ios` |
| Виджет | `app.tidemark.ios.widgets` |
| App Group | `group.app.tidemark` |
| iCloud-контейнер | `iCloud.app.tidemark` |
| Подписки | `app.tidemark.report.monthly`, `app.tidemark.report.yearly` |

## 1. App ID, App Group и iCloud-контейнер (developer.apple.com)

Откройте developer.apple.com › Account › **Certificates, IDs & Profiles** › **Identifiers**.

### 1.1 App Group
1. Нажмите **+** › **App Groups** › Continue.
2. Description: `Tidemark`. Identifier: `group.app.tidemark`.
3. Continue › Register.

### 1.2 iCloud-контейнер
1. Нажмите **+** › **iCloud Containers** › Continue.
2. Description: `Tidemark`. Identifier: `iCloud.app.tidemark`.
3. Continue › Register.

### 1.3 App ID приложения
1. Нажмите **+** › **App IDs** › Continue › тип **App** › Continue.
2. Description: `Tidemark`. Bundle ID: **Explicit**, `app.tidemark.ios`.
3. В списке Capabilities отметьте:
   - **App Groups**;
   - **HealthKit**. Clinical Health Records и Background Delivery не нужны;
   - **iCloud**, режим «Include CloudKit support»;
   - **Push Notifications**. Через них CloudKit сообщает о новых данных с других устройств, без этого бэкап между телефонами не синхронизируется.
4. Continue › Register.
5. Откройте созданный App ID. Напротив **App Groups** нажмите **Configure**, отметьте `group.app.tidemark` › Continue › Save.
6. Напротив **iCloud** нажмите **Configure**, отметьте `iCloud.app.tidemark` › Continue › Save. Если Apple предупредит, что профили станут недействительными, это нормально, нажмите Confirm.

### 1.4 App ID виджета
1. Нажмите **+** › **App IDs** › **App**.
2. Description: `Tidemark Widgets`. Bundle ID: Explicit, `app.tidemark.ios.widgets`.
3. Capabilities: только **App Groups**, затем Register.
4. Откройте этот App ID › **App Groups** › Configure › `group.app.tidemark` › Save.

### 1.5 Подписи и профили
Проще всего так: в Xcode › target Tidemark › **Signing & Capabilities** включите **Automatically manage signing** с командой 46V47ZSX5V, то же для TidemarkWidgets. Xcode сам создаст профили. В `App/Tidemark.entitlements` стоит `aps-environment: development`: при архивации для App Store Xcode автоматически подставит `production`, руками менять не нужно.

Проверка: Product › Archive › Validate App не должен ругаться на entitlements.

## 2. Схема CloudKit в Production

Без этого шага бэкап в App Store-сборке не работает. Ошибок пользователь при этом не увидит, просто ничего не будет сохраняться в iCloud.

1. **Создайте полную схему в Development.** Запустите Debug-сборку на iPhone, где выполнен вход в iCloud: Xcode › Product › Scheme › Edit Scheme › Run › Arguments › добавьте `-initCloudKitSchema`. Достаточно одного запуска. Приложение создаст в среде Development все типы записей и поля, даже те, что вы ни разу не заполняли. Локальные данные этот шаг не трогает. Потом уберите аргумент.
2. Откройте **icloud.developer.apple.com** › CloudKit Database › контейнер `iCloud.app.tidemark` › среда **Development** › **Schema** › Record Types. Там должны быть 8 типов: `CD_CDDay`, `CD_CDRating`, `CD_CDEpisode`, `CD_CDQuestionnaire`, `CD_CDMedication`, `CD_CDQuestion`, `CD_CDVisit`, `CD_CDProfile`. У полей с медицинскими данными должна стоять пометка **Encrypted**.
3. Слева внизу нажмите **Deploy Schema Changes…**. Проверьте список и нажмите **Deploy**. Production открывается только на добавление: удалить или переименовать поле там нельзя. Поэтому в README есть правило «только добавлять».
4. Это нужно повторять при каждом релизе, в котором меняется модель Core Data.

Могу проверить схему до деплоя. Создайте management token: CloudKit Console › иконка аккаунта › **Manage Tokens** › Management Token. Затем выполните в терминале `xcrun cktool save-token --type management` и вставьте туда токен, мне его не присылайте. После этого я выгружу схему Development командой `cktool export-schema` и сверю её с моделью. Сам деплой в Production делается кнопкой в консоли.

## 3. Запись приложения в App Store Connect

Создать запись через API нельзя, это делается вручную, примерно 2 минуты.

1. appstoreconnect.apple.com › **Apps** › **+** › **New App**.
2. Platforms: iOS. Name: `Tidemark: Menopause Tracker`. Primary Language: **English (U.S.)**. Bundle ID: `app.tidemark.ios`. SKU: `tidemark-ios`. User Access: Full Access.
3. **Ключ API для меня**, чтобы я сам загрузил карточку, подписки и скриншоты:
   - Users and Access › **Integrations** › **App Store Connect API** › Team Keys › **+**;
   - Name: `Claude`, Access: **App Manager**;
   - скачайте `AuthKey_XXXXXXXXXX.p8` (скачать можно только один раз) и положите в `~/.appstoreconnect/private_keys/`;
   - пришлите мне **Key ID** и **Issuer ID**, они видны на той же странице. Содержимое ключа в чат не вставляйте.

После этого я загружаю всё остальное: тексты на 18 локалей, подписки, возрастной рейтинг, заметки для ревью и скриншоты.

## 4. То, что API не умеет: App Privacy (раздел «Конфиденциальность»)

С версии 1.0 в приложении есть статистика использования через Firebase: только по согласию, только экраны и нажатия, без медицинских данных (`tools/analytics/README.md`). Поэтому ответ «Data Not Collected» больше не подходит.

App Store Connect › приложение › **App Privacy** › Get Started › **Yes, we collect data from this app**. Отметьте пять типов (сделано 27.11.2026):

| Раздел | Тип | Linked to the user | Tracking | Purpose |
|---|---|---|---|---|
| Usage Data | **Product Interaction** | No | No | Analytics |
| Identifiers | **Device ID** (app instance ID Firebase) | No | No | Analytics |
| Purchases | **Purchase History** (событие покупки с суммой) | No | No | Analytics |
| Location | **Coarse Location** (Firebase определяет страну по IP) | No | No | Analytics |
| Diagnostics | **Other Diagnostic Data** | No | No | Analytics |

Health & Fitness, Contact Info, Precise Location и остальное **не** отмечайте: медицинские данные с устройства к нам не уходят, они лежат на iPhone и в частной базе iCloud пользователя. Отчёты о сбоях присылает Apple, это под определение «collected» не подпадает. После выбора нажмите Save › **Publish**. Те же типы объявлены в `App/PrivacyInfo.xcprivacy`.

Privacy Policy URL (App Information) и Support URL (раздел версии) нужно указать до отправки. См. `docs/privacy-policy.md` (раздел «Usage analytics») и `docs/support.md`.

## 5. Ответы, которые я внесу через API (для справки)

**Категории:** основная Health & Fitness, вторую не ставим. Категория Medical привлекает больше вопросов на ревью, и юридический разбор (`docs/regulatory-assessment.md`) советует её не брать.

**Возрастной рейтинг** (новая анкета Apple 2025 года): Medical or Treatment Information: Infrequent; Health or Wellness Topics: Yes. Остальное: None или No (насилие, азартные игры, контент от пользователей, чаты, реклама, браузер). Итоговый рейтинг посчитает Apple, ожидаемо 13+ или 16+. Для женщин 40+ это не ограничение.

**Export compliance:** в `Info.plist` уже стоит `ITSAppUsesNonExemptEncryption = false`. Приложение использует только шифрование iOS и CloudKit, поэтому вопрос при загрузке сборки не появится.

**Заметки для ревью:** текст в `tools/asc/review-notes.txt`, загружается шагом `upload.py review` вместе с `build/Tidemark-review-sample.zip`. Тот же файл данных лежит на https://baturinigor.github.io/tidemark-legal/review-sample.json, чтобы ревьюер открыл его прямо на iPhone. Файл делается в день отправки (`REVIEW_SAMPLE_OUT=… swift test --filter ReviewSample`), иначе данные «устареют».

**Подписки «Tidemark Pro»** (группа с внутренним именем «Tidemark report»), 7 дней бесплатно для новых подписчиков во всех странах:

| Product ID | Длительность | Цена (US) | Reference name |
|---|---|---|---|
| `app.tidemark.report.monthly` | 1 месяц | $6.99 | Report monthly |
| `app.tidemark.report.yearly` | 1 год | $39.99 | Report yearly |

Цены для 175 стран выровнены от США, имена и описания на 18 локалях (`tools/asc/subscriptions.json`). Скриншот paywall для ревью: `build/design-screens/22-paywall-light.png`. Первые подписки уходят на ревью вместе с версией 1.0: при отправке их нужно добавить в ту же заявку.

## 6. Firebase (статистика использования)

Приложение Tidemark заведено в общем проекте Firebase вместе с ZenHab, bundle ID `app.tidemark.ios`.

1. Файл `GoogleService-Info.plist` лежит в `tools/analytics/` (он в `.gitignore`, в репозиторий не попадает).
2. Перед сборкой для App Store выполните `tools/analytics/add_firebase_config.sh`. Скрипт проверит файл и скопирует его в `App/GoogleService-Info.plist` (тоже в `.gitignore`), затем `xcodegen generate`. Без файла сборка не падает, просто статистика выключена.
3. Что отправляется и как смотреть отчёты: `tools/analytics/README.md`.

