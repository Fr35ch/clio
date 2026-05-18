# Template — Enkeltintervju: temaer, sitater, behov, muligheter

**id:** `single-interview-themes-v1`
**kind:** `single`
**version:** `1` (revised — supersedes v0 draft from 2026-05-11)
**language:** Norwegian Bokmål
**replaces:** the hardcoded prompt in `navt.py` (the current default)

## Purpose

The everyday default. Run this when a researcher has one corrected, optionally anonymized interview transcript and wants the structured synthesis NAV researchers already expect: a short orienting summary followed by themes, quotes, identified needs, and opportunities. Output maps cleanly onto the existing `AnalysisResult` fields plus a free-text prelude for `summary`.

## What changed from v0

- **Timestamps replace paragraph indices.** Quotes are anchored with `[mm:ss]` or `[tt:mm:ss]` from the NB-Whisper transcript, not `(avsnitt N)`. This restores the citation anchor the functional spec v1.0 used and makes the B5 "verify this quote" affordance audio-scrubbable, not just text-scrubbable.
- **SPEAKER_XX handling restored.** The prompt now branches on whether diarization labels are present in the transcript and instructs the model accordingly.
- **Sammendrag re-introduced as a prelude.** A 3–5 sentence orienting summary at the top of the output, matching the functional spec v1.0 §4.1. Free-text — does not map to a structured field.
- **Self-check moved into the thinking phase.** The verification rubric is read by the model before output, not after. With Qwen3 in thinking mode this aligns the instruction with where the model actually verifies.
- **Range caps instead of `Maks N`.** Each section has a minimum and maximum (e.g. 3–6 themes) with explicit guidance that under-production is a synthesis failure to fix, not a feature.
- **Variable name standardized** to `{{transcripts}}` to match the other three templates. The composer wraps even a single transcript with `### Intervju 1 — <displayName>` for header-based citation consistency.

## Prompt body

The composer wraps the body below with sections 1, 5, and 6 of the shared skeleton (see [PROMPT_RESEARCH.md §4](../PROMPT_RESEARCH.md#4-prompt-structure-used-by-all-arm-templates)).

```
Du er en erfaren NAV-brukerforsker som gjennomfører refleksiv tematisk
analyse i tråd med Braun & Clarke. Svar på norsk bokmål.

Forskningskontekst:
{{researchContext}}

Kildemateriale:
{{transcripts}}

Notat om format på kildematerialet:
- Hver replikk har et tidsstempel [tt:mm:ss] eller [mm:ss] som første
  element.
- Hvis transkripsjonen inneholder SPEAKER_XX-labels (f.eks. SPEAKER_00,
  SPEAKER_01), kommer disse av automatisk talerseparering. Bruk dem til
  å skille intervjuer fra informant i sitatseksjonen. Hvis SPEAKER_XX-
  labels mangler, omtal alle utsagn nøytralt uten å gjette rolle.

Analyseinstrukser:

Du har thinking-modus aktivert. Bruk thinking-fasen til å gjennomføre
analysen og selvkontrollen før du formaterer det endelige svaret.

I thinking-fasen:
  1. Les hele transkripsjonen.
  2. Identifiser nøkkelord og uttrykk som bærer betydning for
     forskningskonteksten over.
  3. Generér åpne koder abduktivt — la teksten styre, men hold
     forskningsspørsmålet i bakhodet.
  4. Grupper koder til distinkte hovedtemaer. Slå sammen overlappende
     temaer.
  5. For hvert tema, skill mellom semantisk innhold (det som blir sagt)
     og latent innhold (det som blir antydet eller tatt for gitt).
     Latente tolkninger må markeres «(tolkning)» i output.
  6. Gjennomfør selvkontrollen nedenfor før du formaterer svaret.

Produser deretter resultatet med eksakt disse seksjonene og overskriftene:

  ## Sammendrag
  3–5 setninger. Beskriver intervjuets overordnede tema og kontekst.
  Nevner informantens situasjon eller rolle hvis det fremgår av
  transkripsjonen. Ingen tolkning her — kun oppsummering. Skal være
  orienterende for en leser som ikke har lest transkripsjonen.

  ## Hovedtemaer
  3–6 temaer. Hvis du finner under 3, er det fordi materialet er kort
  eller du har slått sammen for hardt — vurder å splitte. Hvert tema
  som ett kulepunkt:
    - Tittel i kursiv (3–6 ord).
    - Én setning som beskriver temaet.
    - Hvis det finnes en latent dimensjon, én setning prefikset
      «(tolkning)».

  ## Nøkkelsitater
  5–8 sitater. Eksakt slik de står i transkripsjonen — ikke parafraser,
  ikke korriger grammatikk, behold pauser og repetisjoner. Format per
  sitat:
    - Uten taleridentifikasjon:
      [tidsstempel] «sitat» — kort kontekst i én setning.
    - Med taleridentifikasjon:
      [tidsstempel] SPEAKER_XX: «sitat» — kort kontekst i én setning.
  Hvis sitatet illustrerer et bestemt tema, oppgi tema-tittelen først.

  ## Identifiserte behov
  3–6 behov. Hvert behov fra brukerens perspektiv, formulert som «Som
  bruker trenger jeg ...». Hvert behov må være forankret i et konkret
  utsagn eller en hendelse i transkripsjonen — ikke spekulér.

  ## Muligheter
  2–4 muligheter. Konkrete handlingsrom for NAV. Hver mulighet som ett
  kulepunkt med én setning. Hvis muligheten er en plausibel inferanse
  uten direkte belegg, marker med «(tolkning)».

Krav til output:
- Bokmål gjennomgående. Engelske ord i analysen er ikke akseptable,
  med unntak av navn og egennavn som forekommer i materialet.
- Eksakte sitater med tidsstempel. Tidsstempelet må finnes i
  transkripsjonen.
- Format: ren markdown med eksakt seksjonsoverskriftene ovenfor.
- Ingen forklarende tekst utenfor strukturen.

Selvkontroll — gjennomfør i thinking-fasen før du formaterer svaret:
1. Står hvert sitat eksakt slik det finnes i kildematerialet? Hvis du
   er usikker på ett tegn, fjern sitatet.
2. Har hvert tidsstempel et reelt forankringspunkt i transkripsjonen?
3. Er hvert tema forankret i minst ett konkret sitat? Hvis ikke, fjern
   eller flytt til muligheter med «(tolkning)»-markering.
4. Har du blandet semantiske observasjoner med latente tolkninger?
   Marker latente med «(tolkning)».
5. Hvis transkripsjonen har SPEAKER_XX-labels, har du brukt dem riktig
   i sitatseksjonen? Hvis ikke til stede, har du unngått å gjette
   rolle?
6. Er all output på bokmål?
```

## Output schema

The prompt produces a `## Sammendrag` prelude plus the four structured sections that map to `AnalysisResult`. The parser treats anything before the first `## Hovedtemaer` heading as `summary` (a new optional field; see B5 schema note in `PROMPT_RESEARCH.md` §5).

| Section in prompt | `AnalysisResult` field | Cardinality |
|-------------------|------------------------|-------------|
| Sammendrag | `summary: String?` | 1 (optional) |
| Hovedtemaer | `keyThemes: [String]` | 3–6 |
| Nøkkelsitater | `keyQuotes: [String]` | 5–8 |
| Identifiserte behov | `identifiedNeeds: [String]` | 3–6 |
| Muligheter | `opportunities: [String]` | 2–4 |
| (whole markdown response) | `rawMarkdown: String` | 1 |
| `qwen3:8b` (or whatever) | `llmModel: String` | 1 |
| Unix epoch | `generatedAt: Date` | 1 |

`AnalysisResult` parsing is the responsibility of `TranscriptionService.analyze(...)`. Section headings must match exactly.

## Expected output sketch

For a NAV interview about a service-recipient's first months on AAP:

```markdown
## Sammendrag

Intervjuet handler om en informants første tre måneder som AAP-mottaker.
Informanten beskriver møtet med saksbehandlingen, selvbetjeningsløsningen
og veiledningsmaterialet. Hovedanliggendet er manglende oversikt over
egen sak og usikkerhet om hva som forventes av informanten selv.

## Hovedtemaer
- *Usikkerhet om saksgang*: Informanten vet ikke hvordan saken
  behandles eller hvor lenge det vil ta. (tolkning) En følelse av å
  miste kontroll over egen økonomi.
- *Digital terskel*: Selvbetjeningsløsningen oppleves som vanskelig å
  forstå, særlig ved utfylling av aktivitetsplaner.
- ... (3–6 totalt)

## Nøkkelsitater
- *Usikkerhet om saksgang*: [00:14:22] SPEAKER_00: «Jeg vet ikke om
  jeg får svar i morgen eller om to måneder, og jeg tør liksom ikke
  å spørre.» — Informanten beskriver passiv venting.
- ... (5–8 totalt)

## Identifiserte behov
- Som bruker trenger jeg å vite hvor i saksbehandlingen jeg er, til
  enhver tid.
- ... (3–6 totalt)

## Muligheter
- Statusvisning av aktiv sak med estimert ventetid.
- ... (2–4 totalt)
```

The product owner is the final judge of whether output of this quality is acceptable per the validation plan in `PROMPT_RESEARCH.md` §7.

## Verification

Two cross-template mechanisms back the verbatim-quote requirement (see `PROMPT_RESEARCH.md` §6):

1. **Quote-verification pass.** Every `"`-quoted string ≥ 8 words is substring-checked against the transcript at the timestamp it cites. Failures are flagged in the B5 result view as "ikke verifisert" — they are not silently dropped.
2. **Transcript hashing.** Each `AnalysisSource` carries the SHA-256 of the transcript at run time; the result view shows a stale banner if the underlying text has been edited since.

## Revision log

- **v1 (2026-05-13):** revised. Timestamps replace paragraph indices for quote anchoring. SPEAKER_XX handling added (Variant A/B per spec v1.0 §3). Sammendrag prelude reintroduced. Self-check folded into thinking-phase guidance. `Maks N` caps replaced with ranges. Variable standardized to `{{transcripts}}`.
- **v0 (2026-05-11):** draft. Built on Braun & Clarke six-phase framework with explicit semantic/latent split and quote verbatim requirement. Used `(avsnitt N)` for citation; no SPEAKER_XX handling; no Sammendrag section.
