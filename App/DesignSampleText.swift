#if DEBUG
import Foundation
import TidemarkCore

/// What a user would type (notes, medicine names, questions) for the made-up mockup data,
/// in the phone's language, so App Store screenshots don't show English entries in other languages.
/// Debug builds only. Plain strings, so nothing here reaches the string catalog.
struct DesignSampleText {
    var note: String
    var vitaminD: String
    var daily: String
    var patch: String
    var asPrescribed: String
    var clinician: String
    var firstReason: String
    var outcome: String
    var followUpReason: String
    var questions: [String]

    static func current(region: Region) -> DesignSampleText {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = ["pt-BR", "zh-Hans"].first { preferred.hasPrefix($0) } ?? String(preferred.prefix(2))
        if code == "en" { return region == .unitedStates ? .unitedStates : .english }
        return all[code] ?? .english
    }

    static let english = DesignSampleText(
        note: "Woke at 3am twice. Slow start at work.", vitaminD: "Vitamin D", daily: "Daily",
        patch: "HRT patch", asPrescribed: "As prescribed", clinician: "Dr Patel",
        firstReason: "Sleep and hot flushes since spring", outcome: "Talked through options. Blood tests next week.",
        followUpReason: "Follow-up after six weeks",
        questions: ["Could my sleep problems be linked to perimenopause?",
                    "What are my options if the patches irritate my skin?",
                    "Should we check my iron after the heavy periods?"])

    static let unitedStates: DesignSampleText = {
        var text = english
        text.patch = "Hormone patch"
        text.clinician = "Dr. Patel"
        text.firstReason = "Sleep and hot flashes since spring"
        return text
    }()

    private static let all: [String: DesignSampleText] = [
        "de": .init(note: "Zweimal um 3 Uhr aufgewacht. Zäher Start bei der Arbeit.", vitaminD: "Vitamin D", daily: "Täglich",
                    patch: "Hormonpflaster", asPrescribed: "Wie verordnet", clinician: "Dr. Weber",
                    firstReason: "Schlaf und Hitzewallungen seit dem Frühjahr", outcome: "Möglichkeiten besprochen. Blutwerte nächste Woche.",
                    followUpReason: "Kontrolle nach sechs Wochen",
                    questions: ["Können meine Schlafprobleme mit der Perimenopause zusammenhängen?",
                                "Welche Möglichkeiten habe ich, wenn die Pflaster meine Haut reizen?",
                                "Sollten wir nach den starken Blutungen mein Eisen prüfen?"]),
        "fr": .init(note: "Réveillée deux fois à 3 h. Début de journée difficile au travail.", vitaminD: "Vitamine D", daily: "Tous les jours",
                    patch: "Patch hormonal", asPrescribed: "Selon la prescription", clinician: "Dr Martin",
                    firstReason: "Sommeil et bouffées de chaleur depuis le printemps", outcome: "Options discutées. Prise de sang la semaine prochaine.",
                    followUpReason: "Suivi après six semaines",
                    questions: ["Mes troubles du sommeil peuvent-ils être liés à la périménopause ?",
                                "Quelles sont mes options si les patchs irritent ma peau ?",
                                "Faut-il vérifier mon fer après ces règles abondantes ?"]),
        "es": .init(note: "Me desperté dos veces a las 3. Me costó arrancar en el trabajo.", vitaminD: "Vitamina D", daily: "A diario",
                    patch: "Parche hormonal", asPrescribed: "Según lo prescrito", clinician: "Dra. García",
                    firstReason: "Sueño y sofocos desde la primavera", outcome: "Hablamos de las opciones. Análisis de sangre la próxima semana.",
                    followUpReason: "Revisión a las seis semanas",
                    questions: ["¿Pueden mis problemas de sueño estar relacionados con la perimenopausia?",
                                "¿Qué opciones tengo si los parches me irritan la piel?",
                                "¿Deberíamos revisar mi hierro después de las reglas abundantes?"]),
        "it": .init(note: "Sveglia due volte alle 3. Partenza lenta al lavoro.", vitaminD: "Vitamina D", daily: "Ogni giorno",
                    patch: "Cerotto ormonale", asPrescribed: "Come prescritto", clinician: "Dott.ssa Rossi",
                    firstReason: "Sonno e vampate di calore da primavera", outcome: "Parlato delle opzioni. Esami del sangue la prossima settimana.",
                    followUpReason: "Controllo dopo sei settimane",
                    questions: ["I miei problemi di sonno possono essere legati alla perimenopausa?",
                                "Quali opzioni ho se i cerotti mi irritano la pelle?",
                                "Dovremmo controllare il ferro dopo i cicli abbondanti?"]),
        "nl": .init(note: "Twee keer om 3 uur wakker. Trage start op het werk.", vitaminD: "Vitamine D", daily: "Dagelijks",
                    patch: "Hormoonpleister", asPrescribed: "Zoals voorgeschreven", clinician: "Dr. de Vries",
                    firstReason: "Slaap en opvliegers sinds het voorjaar", outcome: "Mogelijkheden besproken. Volgende week bloedonderzoek.",
                    followUpReason: "Controle na zes weken",
                    questions: ["Kunnen mijn slaapproblemen met de perimenopauze te maken hebben?",
                                "Wat zijn mijn opties als de pleisters mijn huid irriteren?",
                                "Moeten we mijn ijzer controleren na de hevige menstruaties?"]),
        "pt-BR": .init(note: "Acordei duas vezes às 3h. Começo lento no trabalho.", vitaminD: "Vitamina D", daily: "Todo dia",
                       patch: "Adesivo hormonal", asPrescribed: "Conforme prescrito", clinician: "Dra. Souza",
                       firstReason: "Sono e ondas de calor desde a primavera", outcome: "Conversamos sobre as opções. Exames de sangue na próxima semana.",
                       followUpReason: "Retorno após seis semanas",
                       questions: ["Meus problemas de sono podem ter relação com a perimenopausa?",
                                   "Quais são minhas opções se os adesivos irritarem minha pele?",
                                   "Devemos checar meu ferro depois das menstruações intensas?"]),
        "sv": .init(note: "Vaknade två gånger kl. 3. Seg start på jobbet.", vitaminD: "D-vitamin", daily: "Dagligen",
                    patch: "Hormonplåster", asPrescribed: "Enligt ordination", clinician: "Dr Lindberg",
                    firstReason: "Sömn och värmevallningar sedan i våras", outcome: "Gick igenom alternativen. Blodprover nästa vecka.",
                    followUpReason: "Uppföljning efter sex veckor",
                    questions: ["Kan mina sömnproblem hänga ihop med perimenopausen?",
                                "Vilka alternativ har jag om plåstren irriterar huden?",
                                "Borde vi kolla mitt järn efter de kraftiga mensen?"]),
        "nb": .init(note: "Våknet to ganger kl. 3. Treg start på jobben.", vitaminD: "D-vitamin", daily: "Daglig",
                    patch: "Hormonplaster", asPrescribed: "Som foreskrevet", clinician: "Dr. Hansen",
                    firstReason: "Søvn og hetetokter siden våren", outcome: "Gikk gjennom alternativene. Blodprøver neste uke.",
                    followUpReason: "Oppfølging etter seks uker",
                    questions: ["Kan søvnproblemene mine henge sammen med perimenopausen?",
                                "Hvilke alternativer har jeg hvis plastrene irriterer huden?",
                                "Bør vi sjekke jernet mitt etter de kraftige menstruasjonene?"]),
        "da": .init(note: "Vågnede to gange kl. 3. Langsom start på arbejdet.", vitaminD: "D-vitamin", daily: "Dagligt",
                    patch: "Hormonplaster", asPrescribed: "Som ordineret", clinician: "Dr. Nielsen",
                    firstReason: "Søvn og hedeture siden foråret", outcome: "Gennemgik mulighederne. Blodprøver i næste uge.",
                    followUpReason: "Opfølgning efter seks uger",
                    questions: ["Kan mine søvnproblemer hænge sammen med perimenopausen?",
                                "Hvilke muligheder har jeg, hvis plastrene irriterer huden?",
                                "Skal vi tjekke mit jern efter de kraftige menstruationer?"]),
        "fi": .init(note: "Heräsin kahdesti kello 3. Hidas aloitus töissä.", vitaminD: "D-vitamiini", daily: "Päivittäin",
                    patch: "Hormonilaastari", asPrescribed: "Ohjeen mukaan", clinician: "Lääkäri Virtanen",
                    firstReason: "Uni ja kuumat aallot keväästä asti", outcome: "Kävimme vaihtoehdot läpi. Verikokeet ensi viikolla.",
                    followUpReason: "Seuranta kuuden viikon jälkeen",
                    questions: ["Voivatko uniongelmani liittyä perimenopaussiin?",
                                "Mitä vaihtoehtoja minulla on, jos laastarit ärsyttävät ihoa?",
                                "Pitäisikö rautani tarkistaa runsaiden kuukautisten jälkeen?"]),
        "pl": .init(note: "Obudziłam się dwa razy o 3. Ciężki początek dnia w pracy.", vitaminD: "Witamina D", daily: "Codziennie",
                    patch: "Plaster hormonalny", asPrescribed: "Zgodnie z zaleceniem", clinician: "Dr Kowalska",
                    firstReason: "Sen i uderzenia gorąca od wiosny", outcome: "Omówiłyśmy możliwości. Badania krwi w przyszłym tygodniu.",
                    followUpReason: "Kontrola po sześciu tygodniach",
                    questions: ["Czy moje problemy ze snem mogą mieć związek z perimenopauzą?",
                                "Jakie mam możliwości, jeśli plastry podrażniają skórę?",
                                "Czy warto sprawdzić żelazo po obfitych miesiączkach?"]),
        "ja": .init(note: "午前3時に2回目が覚めた。仕事の出だしがつらかった。", vitaminD: "ビタミンD", daily: "毎日",
                    patch: "ホルモンパッチ", asPrescribed: "処方どおり", clinician: "佐藤先生",
                    firstReason: "春からの睡眠とほてり", outcome: "選択肢について話した。来週血液検査。",
                    followUpReason: "6週間後の再診",
                    questions: ["睡眠の問題は更年期と関係がありますか？",
                                "パッチで肌がかぶれた場合、どんな選択肢がありますか？",
                                "経血が多かったので、鉄の値を調べたほうがいいですか？"]),
        "ko": .init(note: "새벽 3시에 두 번 깼다. 출근 후 시작이 느렸다.", vitaminD: "비타민 D", daily: "매일",
                    patch: "호르몬 패치", asPrescribed: "처방대로", clinician: "김 선생님",
                    firstReason: "봄부터 이어진 수면 문제와 안면홍조", outcome: "선택지를 함께 이야기함. 다음 주 혈액 검사.",
                    followUpReason: "6주 후 재진",
                    questions: ["수면 문제가 폐경 이행기와 관련이 있을까요?",
                                "패치 때문에 피부가 자극되면 어떤 선택지가 있나요?",
                                "생리량이 많았는데 철분 수치를 확인해 봐야 할까요?"]),
        "zh-Hans": .init(note: "凌晨3点醒了两次。上班时状态很慢。", vitaminD: "维生素 D", daily: "每天",
                         patch: "激素贴片", asPrescribed: "遵医嘱", clinician: "王医生",
                         firstReason: "从春天开始的睡眠问题和潮热", outcome: "讨论了各种选择。下周验血。",
                         followUpReason: "六周后复诊",
                         questions: ["我的睡眠问题会和围绝经期有关吗？",
                                     "如果贴片刺激皮肤，我有哪些选择？",
                                     "月经量大之后，要不要查一下铁？"]),
        "tr": .init(note: "Gece 3'te iki kez uyandım. İşte güne yavaş başladım.", vitaminD: "D vitamini", daily: "Her gün",
                    patch: "Hormon bandı", asPrescribed: "Reçeteye göre", clinician: "Dr. Yılmaz",
                    firstReason: "İlkbahardan beri uyku ve sıcak basmaları", outcome: "Seçenekleri konuştuk. Gelecek hafta kan tahlili.",
                    followUpReason: "Altı hafta sonra kontrol",
                    questions: ["Uyku sorunlarım perimenopozla ilgili olabilir mi?",
                                "Bantlar cildimi tahriş ederse seçeneklerim neler?",
                                "Yoğun adetlerden sonra demir değerime bakmalı mıyız?"]),
        "ru": .init(note: "Дважды просыпалась в 3 часа. Тяжело начался рабочий день.", vitaminD: "Витамин D", daily: "Ежедневно",
                    patch: "Гормональный пластырь", asPrescribed: "По назначению", clinician: "Доктор Иванова",
                    firstReason: "Сон и приливы с весны", outcome: "Обсудили варианты. Анализы крови на следующей неделе.",
                    followUpReason: "Контроль через шесть недель",
                    questions: ["Могут ли проблемы со сном быть связаны с перименопаузой?",
                                "Какие есть варианты, если пластыри раздражают кожу?",
                                "Стоит ли проверить железо после обильных месячных?"]),
    ]
}
#endif
