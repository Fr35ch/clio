// PromptTemplateLibrary.swift
// AudioRecordingManager
//
// Bundled and user-defined prompt templates. The four bundled templates
// are defined as Swift statics below; their human-readable specs live
// alongside under docs/prd/analysis/templates/ and are the source of
// truth for content review.
//
// User-defined templates live as JSON files under
// `<dataRoot>/analyses/_templates/<id>.json` and are loaded on demand.
// `isBundled = false` distinguishes them in the composer dropdown.

import Foundation

/// Singleton facade for reading bundled + user templates. The composer
/// calls `templates(for:)` to get the subset relevant to the current
/// analysis kind.
final class PromptTemplateLibrary {

    static let shared = PromptTemplateLibrary()

    private init() {}

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    // MARK: - Public API

    /// All templates the composer should consider for the given kind,
    /// bundled first, then user-defined (most-recently-edited first if
    /// we ever track that). For MVP user templates are in arbitrary
    /// filesystem order.
    func templates(for kind: AnalysisKind) -> [PromptTemplate] {
        let bundled = Self.bundled.filter { $0.appliesTo.includes(kind) }
        let user = userDefined().filter { $0.appliesTo.includes(kind) }
        return bundled + user
    }

    /// Look up a template by id. Used by the result view to display the
    /// template name and version that produced a given analysis. Returns
    /// nil if the template has been deleted since the analysis was run
    /// (in which case the result view falls back to the id string).
    func template(id: String) -> PromptTemplate? {
        if let bundled = Self.bundled.first(where: { $0.id == id }) {
            return bundled
        }
        return userDefined().first(where: { $0.id == id })
    }

    /// The four ARM-bundled templates. Read-only from the composer's
    /// perspective; the researcher can fork one (via "Save as ...") into
    /// a user template, but cannot edit the bundled definition in place.
    var bundledTemplates: [PromptTemplate] { Self.bundled }

    // MARK: - User templates on disk

    /// `<dataRoot>/analyses/_templates/` — created lazily by the saver.
    /// The leading underscore keeps it sorted away from per-analysis
    /// folders in the analyses root.
    private var userTemplatesDir: URL {
        StorageLayout.analysesRoot.appendingPathComponent("_templates", isDirectory: true)
    }

    /// Reads every `.json` file in the user-templates dir and decodes
    /// each as a `PromptTemplate`. Files that fail to decode are logged
    /// and skipped so one corrupt file doesn't break the dropdown.
    private func userDefined() -> [PromptTemplate] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: userTemplatesDir.path) else { return [] }
        guard let urls = try? fm.contentsOfDirectory(at: userTemplatesDir, includingPropertiesForKeys: nil) else {
            return []
        }
        var out: [PromptTemplate] = []
        for url in urls where url.pathExtension.lowercased() == "json" {
            do {
                let data = try Data(contentsOf: url)
                let template = try decoder.decode(PromptTemplate.self, from: data)
                out.append(template)
            } catch {
                print("⚠️ PromptTemplateLibrary: skipping unreadable user template \(url.lastPathComponent): \(error)")
            }
        }
        return out
    }

    // MARK: - Bundled template definitions

    /// The four ARM-shipped templates. Source-of-truth markdown lives in
    /// `docs/prd/analysis/templates/` — keep this list in sync with those
    /// docs when iterating. Each body is a complete prompt (sections 1–6
    /// of the skeleton from PROMPT_RESEARCH.md §4); the composer does not
    /// wrap them.
    private static let bundled: [PromptTemplate] = [
        singleInterviewThemes,
        groupCrossCuttingPatterns,
        painPointsAndFrustrations,
        opportunityMap,
    ]

    // MARK: Single — themes (default)

    private static let singleInterviewThemes = PromptTemplate(
        id: "single-interview-themes-v1",
        displayName: "Enkeltintervju — temaer og sitater",
        summary: "Standardanalysen for ett intervju: temaer, sitater, behov, muligheter.",
        appliesTo: .single,
        language: "no",
        body: """
        Du er en erfaren NAV-brukerforsker som gjennomfører refleksiv tematisk
        analyse i tråd med Braun & Clarke. Svar på norsk bokmål.

        Forskningskontekst:
        {{researchContext}}

        Kildemateriale:
        {{transcript}}

        Analyseinstrukser:

        Gjennomfør analysen mentalt i seks faser (Braun & Clarke) før du svarer.
        Ikke skriv ut fase 1–3; bare resultatet av fase 4–5.

          Fase 1. Bli kjent med materialet. Les hele transkripsjonen.
          Fase 2. Identifiser nøkkelord og uttrykk som bærer betydning for
                  forskningskonteksten over.
          Fase 3. Generer åpne koder. Vær abduktiv — la teksten styre, men hold
                  forskningsspørsmålet i bakhodet.
          Fase 4. Grupper koder til 3–6 hovedtemaer. Hvert tema må være distinkt;
                  slå sammen overlappende temaer.
          Fase 5. For hvert tema, identifiser både semantisk innhold (det som blir
                  sagt) og latent innhold (det som blir antydet eller tatt for gitt).
                  Latente tolkninger må markeres «(tolkning)».

        Når du svarer, lever resultatet med eksakt disse seksjonene og overskriftene:

          ## Hovedtemaer (key_themes)
          Maks 6. Hvert tema som et kulepunkt. Tittel på temaet i kursiv, fulgt
          av én setning som beskriver tema'et. Hvis det fins en latent dimensjon,
          legg den til som en setning prefikset «(tolkning)».

          ## Nøkkelsitater (key_quotes)
          Maks 8 sitater. Hvert sitat eksakt slik det står i transkripsjonen
          (ikke parafraser, ikke korriger grammatikk, behold pauser). Etter
          sitatet, oppgi avsnittsindeks i parentes: «(avsnitt N)». Hvis sitatet
          illustrerer et bestemt tema, oppgi tema-tittelen først.

          ## Identifiserte behov (identified_needs)
          Maks 6. Hvert behov fra brukerens perspektiv, formulert som «Som
          bruker trenger jeg ...». Behov må være forankret i materialet — ikke
          speculer.

          ## Muligheter (opportunities)
          Maks 4. Konkrete muligheter for NAV å handle på. Hver mulighet som et
          kulepunkt med én setning. Hvis muligheten er spekulativ, marker med
          «(tolkning)».

        Krav til output:
        - Bokmål.
        - Eksakte sitater. Du må ikke parafrasere eller komprimere.
        - Maks 6 temaer, 8 sitater, 6 behov, 4 muligheter. Slå sammen
          overlappende funn fremfor å øke antallet.
        - Format: ren markdown med eksakt seksjonsoverskriftene ovenfor.

        Selvkontroll før du svarer:
        - Står alle sitater nøyaktig slik de finnes i kildematerialet? Hvis ikke,
          fjern dem.
        - Er hvert tema forankret i minst ett sitat? Hvis ikke, fjern det.
        - Har du blandet semantiske observasjoner og latente tolkninger?
          Marker latente med «(tolkning)».
        - Er output på bokmål gjennomgående? Engelske ord i analysen er ikke
          akseptable, med unntak av seksjonsoverskriftene.
        """,
        version: 0,
        isBundled: true
    )

    // MARK: Group — cross-cutting patterns

    private static let groupCrossCuttingPatterns = PromptTemplate(
        id: "group-cross-cutting-patterns-v1",
        displayName: "Gruppeanalyse — felles mønstre på tvers",
        summary: "Syntese på tvers av flere intervjuer med eksplisitt attribusjon.",
        appliesTo: .group,
        language: "no",
        body: """
        Du er en erfaren NAV-brukerforsker som gjennomfører refleksiv tematisk
        analyse på tvers av flere intervjuer, i tråd med Braun & Clarke. Svar
        på norsk bokmål.

        Forskningskontekst:
        {{researchContext}}

        Antall intervjuer: {{interviewCount}}

        Kildemateriale:
        {{transcripts}}

        Analyseinstrukser:

        Du analyserer {{interviewCount}} intervjuer som hører til samme studie.
        Målet er IKKE en oppsummering av hvert intervju. Målet er å identifisere
        mønstre som går igjen, og divergenser som er verdt å løfte fram.

        Gjennomfør analysen mentalt i seks faser (Braun & Clarke) før du svarer.
        Skriv kun ut resultatet av fase 4–6.

          Fase 1. Les alle intervjuene.
          Fase 2. Identifiser nøkkelord og uttrykk per intervju.
          Fase 3. Kode på tvers. Når samme begrep dukker opp i flere intervjuer,
                  noter at det er felles.
          Fase 4. Grupper kodene til 5–8 mønstre på tvers. Et mønster skal være
                  dekket av minst to intervjuer. Funn fra bare ett intervju
                  rapporteres separat under «Avvik».
          Fase 5. For hvert mønster, identifiser både semantisk og latent
                  innhold. Latente tolkninger må markeres «(tolkning)».
          Fase 6. Identifiser divergenser — der intervjuene tydelig sier noe
                  ulikt om samme tema.

        Når du svarer, lever resultatet med eksakt disse seksjonene og overskriftene:

          ## Felles mønstre (key_themes)
          5–8 mønstre. For hvert mønster:
            - Tittel i kursiv.
            - Én setning som beskriver mønsteret.
            - «Sett i: Intervju 1, Intervju 3, Intervju 5» — eksplisitt
              attribuering med intervjuheaderne fra kildematerialet.
            - Hvis det finnes en latent dimensjon, én setning prefikset
              «(tolkning)».

          ## Nøkkelsitater (key_quotes)
          Maks 12 sitater. Velg sitater som best illustrerer mønstrene. For hvert
          sitat:
            - Eksakt slik det står i kildematerialet (ikke parafraser).
            - «(Intervju N, avsnitt M)» etter sitatet.
            - Hvis sitatet illustrerer et bestemt mønster, oppgi mønstrets
              tittel først.

          ## Felles behov (identified_needs)
          Maks 6. Behov som går igjen i flere intervjuer. Hvert behov formulert
          som «Som bruker trenger jeg ...». Oppgi etter behovet i parentes hvilke
          intervjuer det er belagt i: «(Intervju 1, 4, 5)».

          ## Avvik og divergenser (opportunities)
          Maks 4. Bruk denne seksjonen for funn som er VIKTIGE men som bare ett
          eller to intervjuer dekker, eller for tema der intervjuene sier
          motstridende ting. Marker hvert avvik med kilde og om det er entydig
          eller motstridende:
            - Tittel.
            - Sak: én setning.
            - Status: «Belagt i Intervju N» eller «Motstridende: Intervju N sier
              X, Intervju M sier Y».

        Krav til output:
        - Bokmål.
        - Eksakte sitater. Du må ikke parafrasere eller blande sitater fra ulike
          intervjuer.
        - Mønstre med færre enn to belegg flyttes til «Avvik og divergenser».
        - Format: ren markdown med eksakt seksjonsoverskriftene ovenfor.

        Selvkontroll før du svarer:
        - Har hvert mønster minst to intervjuer som belegg? Hvis ikke, flytt
          det til «Avvik og divergenser».
        - Er hvert sitat eksakt slik det står i kildematerialet, og er
          intervju-attribusjonen riktig? Hvis ikke, fjern.
        - Har du blandet semantiske observasjoner og latente tolkninger?
          Marker latente med «(tolkning)».
        - Har du faktisk identifisert minst noen divergenser, eller har du
          bare hovedmønstre? Forskere trenger å vite hvor materialet er
          uenig med seg selv.
        """,
        version: 0,
        isBundled: true
    )

    // MARK: Pain points & frustrations

    private static let painPointsAndFrustrations = PromptTemplate(
        id: "pain-points-and-frustrations-v1",
        displayName: "Smertepunkter og frustrasjoner",
        summary: "Fokus på det som ikke fungerer: friksjoner, workarounds, emosjonelt register.",
        appliesTo: .both,
        language: "no",
        body: """
        Du er en erfaren NAV-tjenestedesigner og brukerforsker. Målet ditt er å
        identifisere smertepunkter, frustrasjoner og friksjoner som brukerne
        opplever med tjenesten. Svar på norsk bokmål.

        Forskningskontekst:
        {{researchContext}}

        {{#group}}
        Antall intervjuer: {{interviewCount}}
        {{/group}}

        Kildemateriale:
        {{#single}}{{transcript}}{{/single}}{{#group}}{{transcripts}}{{/group}}

        Analyseinstrukser:

        Du analyserer materialet med ett fokus: hvor svikter tjenesten brukerne?
        Hva sliter de med? Hva er frustrerende eller forvirrende?

        Gjennomfør analysen i tre lag:

          Lag 1 — Eksplisitte frustrasjoner. Det brukeren faktisk sier er
                  problematisk.
          Lag 2 — Workarounds. Beskrivelser av hvordan brukeren omgår et
                  problem som ikke er nevnt eksplisitt. Workarounds er ofte
                  sterke signaler om friksjon brukeren har lært seg å leve med.
          Lag 3 — Emosjonell register. Tone, ordvalg, kroppsspråk-merker i
                  transkripsjonen (sukk, pause, sarkasme) som indikerer
                  frustrasjon selv når innholdet ikke er negativt.

        For hvert smertepunkt, sett en uformell alvorlighetsgrad basert på det
        emosjonelle registeret og hvor mye plass brukeren bruker på det:
          - alvorlig: brukeren beskriver konsekvenser for økonomi, helse,
            livskvalitet, eller bruker sterke ord.
          - betydelig: brukeren returnerer flere ganger til temaet eller
            beskriver det som «vanskelig», «slitsomt», «forvirrende».
          - irritasjon: brukeren nevner i forbifarten eller bagatelliserer.

        Når du svarer, lever resultatet med eksakt disse seksjonene:

          ## Smertepunkter (key_themes)
          Maks 8 smertepunkter, sortert med alvorligste først. For hvert:
            - Tittel i kursiv.
            - Alvorlighetsgrad: alvorlig / betydelig / irritasjon.
            - Lag-kilde: «Eksplisitt» / «Workaround» / «Emosjonell register».
            - Én setning som beskriver problemet i brukerens perspektiv.
            {{#group}}
            - «Sett i: Intervju 1, Intervju 3» — eksplisitt attribuering.
            {{/group}}

          ## Nøkkelsitater (key_quotes)
          Maks 10 sitater som best illustrerer smertepunktene. Velg sitater som
          bærer det emosjonelle registeret. Eksakte sitater, ikke parafraser.
          Etter sitatet:
            {{#single}}- «(avsnitt N)»{{/single}}{{#group}}- «(Intervju N, avsnitt M)»{{/group}}
          Hvis sitatet illustrerer et spesifikt smertepunkt, oppgi
          smertepunktets tittel først.

          ## Bakenforliggende behov (identified_needs)
          Maks 6. Til hvert smertepunkt over, formulér det bakenforliggende
          behovet brukeren prøver å få dekket. «Som bruker trenger jeg ...».
          Et behov kan dekke flere smertepunkter.

          ## Mønstre i workarounds (opportunities)
          Maks 4. Når brukerne har lært seg å gjøre noe utenfor den tiltenkte
          flyten, beskriv mønsteret og hva det forteller om tjenesten. Ikke
          foreslå løsninger — det hører til opportunity-map-malen.

        Krav til output:
        - Bokmål.
        - Eksakte sitater. Du må ikke parafrasere, særlig ikke der det
          emosjonelle registeret bærer meningen.
        - Smertepunkter sorteres alvorligste først.
        - Format: ren markdown med eksakt seksjonsoverskriftene ovenfor.

        Selvkontroll før du svarer:
        - Har hvert smertepunkt minst ett sitat som belegg? Hvis ikke, fjern.
        - Er alvorlighetsgrader forankret i materialet, eller har du gjettet?
          Hvis gjettet, marker med «(tolkning)» og senk én grad.
        - Er output på bokmål gjennomgående?
        """,
        version: 0,
        isBundled: true
    )

    // MARK: Opportunity map

    private static let opportunityMap = PromptTemplate(
        id: "opportunity-map-v1",
        displayName: "Mulighetskart",
        summary: "Strukturert ekstraksjon av handlingsrom: målgruppe, forutsetning, eksperiment.",
        appliesTo: .both,
        language: "no",
        body: """
        Du er en erfaren NAV-tjenestedesigner. Målet ditt er å trekke ut konkrete
        muligheter for forbedring av tjenesten, basert på det informantene
        beskriver. Svar på norsk bokmål.

        Forskningskontekst:
        {{researchContext}}

        {{#group}}
        Antall intervjuer: {{interviewCount}}
        {{/group}}

        Kildemateriale:
        {{#single}}{{transcript}}{{/single}}{{#group}}{{transcripts}}{{/group}}

        Analyseinstrukser:

        Du leter etter handlingsrom. For hver mulighet du foreslår, må følgende
        gjelde:

          1. Den er forankret i konkrete observasjoner i kildematerialet —
             ikke generelle prinsipper.
          2. Den har en målgruppe — hvilken brukersegment er dette nyttig for?
             Eksempel: «brukere på AAP som er i sin første saksbehandlingsrunde»,
             «brukere som primært kontakter NAV via telefon», ikke «brukere
             flest».
          3. Den har en forutsetning — hva må være på plass internt i NAV for
             at muligheten skal kunne realiseres? Tekniske, organisatoriske,
             juridiske.
          4. Den er konkret nok til at et team kan diskutere om de skal jobbe
             med den eller ikke.

        Skill mellom to typer muligheter:

          Datadrevne muligheter — muligheter der materialet eksplisitt peker
                                  på dem.
          Spekulative muligheter — plausible inferanser fra materialet, men
                                   ikke eksplisitt belagt. Disse må markeres
                                   «(spekulativ)».

        Når du svarer, lever resultatet med eksakt disse seksjonene:

          ## Datadrevne muligheter (key_themes)
          Maks 5 muligheter, sortert med høyest mulig effekt først. For hver:
            - Tittel: én konkret formulering, kursiv.
            - Beskrivelse: én setning som forklarer hva som skal skje.
            - Målgruppe: konkret brukersegment.
            - Forutsetning: hva må være på plass i NAV.
            {{#group}}
            - Belegg i: «Intervju 1, Intervju 3».
            {{/group}}

          ## Sitater som forankrer mulighetene (key_quotes)
          Maks 8 sitater fra kildematerialet som best forankrer mulighetene over.
          Eksakte sitater. Etter sitatet:
            {{#single}}- «(avsnitt N)»{{/single}}{{#group}}- «(Intervju N, avsnitt M)»{{/group}}
          Hvis sitatet forankrer en spesifikk mulighet, oppgi mulighetens tittel
          først.

          ## Brukerbehov som muligheter dekker (identified_needs)
          Maks 5. For hver, formulér behovet og pek på hvilke muligheter over som
          adresserer det. «Som bruker trenger jeg ... — dekkes av mulighet X
          og Y».

          ## Spekulative muligheter (opportunities)
          Maks 4. Muligheter som er plausible inferanser, men ikke eksplisitt
          belagt i materialet. For hver:
            - Tittel, kursiv.
            - Beskrivelse, én setning.
            - Hvilken observasjon i materialet inspirerte denne muligheten.
            - Hvilket eksperiment kunne bekrefte eller avkrefte at muligheten
              er reell.

        Krav til output:
        - Bokmål.
        - Eksakte sitater. Du må ikke parafrasere.
        - Hver datadreven mulighet må ha alle fire elementer (tittel,
          beskrivelse, målgruppe, forutsetning). Mangler du ett av dem, flytt
          muligheten til spekulative.
        - Format: ren markdown med eksakt seksjonsoverskriftene ovenfor.

        Selvkontroll før du svarer:
        - Er hver datadreven mulighet forankret i minst ett sitat? Hvis ikke,
          flytt til spekulative.
        - Har du målgrupper som faktisk er segmenter, ikke «brukere flest»?
        - Er forutsetningene konkrete nok til at noen i NAV kan teste om de
          er oppfylt?
        - Har du markert spekulative muligheter eksplisitt med
          «(spekulativ)»?
        """,
        version: 0,
        isBundled: true
    )
}
