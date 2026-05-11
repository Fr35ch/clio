# Template — Enkeltintervju: temaer, sitater, behov, muligheter

**id:** `single-interview-themes-v1`
**kind:** `single`
**version:** `0` (draft — pending validation against ≥3 real NAV interviews)
**language:** Norwegian Bokmål
**replaces:** the hardcoded prompt in `navt.py` (the current default)

## Purpose

The everyday default. Run this when a researcher has one corrected, optionally anonymized interview transcript and wants the four-section synthesis NAV researchers already expect (themes, quotes, identified needs, opportunities). Output maps cleanly onto the existing `AnalysisResult` fields so the result view doesn't need a schema change.

## Prompt body

The composer wraps the body below with sections 1, 5, and 6 of the shared skeleton (see [PROMPT_RESEARCH.md §4](../PROMPT_RESEARCH.md#4-prompt-structure-used-by-all-arm-templates)).

```
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
```

## Output schema

Maps to `AnalysisResult` (`Sources/AudioRecordingManager/AnalysisResult.swift`):

| Section in prompt | `AnalysisResult` field | Cardinality |
|-------------------|------------------------|-------------|
| Hovedtemaer | `keyThemes: [String]` | ≤ 6 |
| Nøkkelsitater | `keyQuotes: [String]` | ≤ 8 |
| Identifiserte behov | `identifiedNeeds: [String]` | ≤ 6 |
| Muligheter | `opportunities: [String]` | ≤ 4 |
| (whole markdown response) | `rawMarkdown: String` | 1 |
| `qwen3:8b` (or whatever) | `llmModel: String` | 1 |
| Unix epoch | `generatedAt: Date` | 1 |

`AnalysisResult` parsing is the responsibility of `TranscriptionService.analyze(...)`. As long as the section headings match exactly the four `## …` lines above, the existing parser splits them correctly.

## Expected output sketch

For a NAV interview about a service-recipient's first months on AAP, the LLM should produce something like:

```markdown
## Hovedtemaer (key_themes)
- *Usikkerhet om saksgang*: Brukeren vet ikke hvordan saken behandles eller hvor lenge det vil ta. (tolkning) En følelse av ikke å ha kontroll over egen økonomi.
- *Digital terskel*: Selvbetjeningsløsningen oppleves som vanskelig å forstå, særlig for utfylling av aktivitetsplaner.
- ... (≤ 6 totalt)

## Nøkkelsitater (key_quotes)
- *Usikkerhet om saksgang*: «Jeg vet ikke om jeg får svar i morgen eller om to måneder, og jeg tør liksom ikke å spørre.» (avsnitt 14)
- ... (≤ 8 totalt)

## Identifiserte behov (identified_needs)
- Som bruker trenger jeg å vite hvor i saksbehandlingen jeg er, til enhver tid.
- ... (≤ 6 totalt)

## Muligheter (opportunities)
- Statusvisning av aktiv sak med estimert ventetid.
- ... (≤ 4 totalt)
```

The product owner is the judge of whether output of this quality is acceptable.

## Revision log

- **v0 (2026-05-11):** draft. Built on Braun & Clarke six-phase framework with explicit semantic/latent split and quote verbatim requirement. Output schema preserves the existing four-section format for backwards compatibility with `AnalysisResult`. Pending validation against ≥3 real NAV interviews.
