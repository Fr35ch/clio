# Template — Smertepunkter og frustrasjoner

**id:** `pain-points-and-frustrations-v1`
**kind:** `single` or `group`
**version:** `1` (revised — supersedes v0 draft from 2026-05-11)
**language:** Norwegian Bokmål

## Purpose

For studies focused on service quality — where the goal is to surface what's *wrong* with a service from the user's perspective. The general-purpose [single-interview-themes](single-interview-themes.md) template tends to over-balance the output (themes + needs + opportunities), which dilutes pain-point analysis. This template explicitly weights toward negative experiences and emotional register.

Common NAV use cases: post-launch service evaluation, complaint clustering, retrospective on a process change.

## What changed from v0

- **Timestamp anchoring** replaces `(avsnitt N)` — same rationale as the other templates.
- **SPEAKER_XX handling added.** Especially important here: whether a frustration came from the informant or interviewer materially affects how it should be read.
- **Severity tagging now has anchor word lists.** The three levels (`alvorlig` / `betydelig` / `irritasjon`) are now anchored to concrete linguistic cues, not vibes-based judgement. Reduces run-to-run drift.
- **One-shot example added for the three-layer model.** Eksplisitt / Workaround / Emosjonell register is hard for a 7–8B model without a worked example.
- **Self-check folded into thinking-phase.**

## What this template does differently from the default

- **Higher latent-meaning weight.** Pain points are often unsaid — the user describes a behavior or workaround rather than naming the frustration. The prompt instructs the model to surface these inferences explicitly.
- **Severity hints.** Each pain point carries a soft severity tag based on emotional register and linguistic cues. This is a tolerance hint for the researcher; the researcher remains the final judge.
- **No opportunities section.** Opportunities are a separate template ([opportunity-map](opportunity-map.md)). Running both gives the researcher a "problems" view and a "solutions" view as parallel artifacts, not a forced single-pass mix.

## Prompt body

```
Du er en erfaren NAV-tjenestedesigner og brukerforsker. Målet ditt er
å identifisere smertepunkter, frustrasjoner og friksjoner som brukerne
opplever med tjenesten. Svar på norsk bokmål.

Forskningskontekst:
{{researchContext}}

{{#group}}
Antall intervjuer: {{interviewCount}}
{{/group}}

Kildemateriale:
{{transcripts}}

Notat om format på kildematerialet:
- Hver replikk har et tidsstempel [tt:mm:ss] eller [mm:ss] som første
  element.
- Hvis transkripsjonen inneholder SPEAKER_XX-labels, kommer disse fra
  automatisk talerseparering. Det er viktig å skille hvem som sier hva
  — en frustrasjon fra informanten leses annerledes enn en hypotese
  fra intervjueren. Hvis SPEAKER_XX-labels mangler, omtal utsagn
  nøytralt uten å gjette rolle.

Analyseinstrukser:

Du analyserer materialet med ett fokus: hvor svikter tjenesten brukerne?
Hva sliter de med? Hva er frustrerende eller forvirrende?

Du har thinking-modus aktivert. Bruk thinking-fasen til å gjennomføre
analysen i tre lag, og selvkontrollen, før du formaterer svaret.

Tre lag:
  Lag 1 — Eksplisitte frustrasjoner. Det brukeren faktisk sier er
          problematisk.
  Lag 2 — Workarounds. Beskrivelser av hvordan brukeren omgår et
          problem som ikke er nevnt eksplisitt. Workarounds er ofte
          sterke signaler om friksjon brukeren har lært seg å leve med.
  Lag 3 — Emosjonell register. Tone, ordvalg, transkripsjonsmerker
          (sukk, pause, sarkasme) som indikerer frustrasjon selv når
          innholdet ikke er negativt.

Eksempel på de tre lagene:

  Transkripsjon-utdrag:
    [00:12:04] SPEAKER_00: Aktivitetsplanen er helt umulig å forstå.
    [00:14:31] SPEAKER_00: Jeg ringer alltid moren min før jeg sender,
                            hun har jobbet i kommunen, hun vet hva
                            de vil ha.
    [00:18:09] SPEAKER_00: (sukker) Joda, jeg fikk jo svar til slutt.

  Lag-tilskrivning:
    [00:12:04] er Lag 1 (Eksplisitt) — informanten sier rett ut at
               aktivitetsplanen er umulig å forstå.
    [00:14:31] er Lag 2 (Workaround) — informanten beskriver ikke et
               problem direkte, men har lært seg å ringe en bekjent for
               å unngå feil. Det er en sterk indikasjon på at
               veiledningen i tjenesten ikke fungerer.
    [00:18:09] er Lag 3 (Emosjonell register) — innholdet er nøytralt
               («fikk svar til slutt»), men sukket og «til slutt»
               bærer en frustrasjon over ventetiden.

For hvert smertepunkt, sett en uformell alvorlighetsgrad basert på det
emosjonelle registeret, ordvalg, og hvor mye plass brukeren bruker på
det:

  - alvorlig: brukeren beskriver konsekvenser for økonomi, helse,
    livskvalitet, familie, eller bruker sterke ord («katastrofalt»,
    «forferdelig», «helt umulig», «brøt sammen», «mistet jobben»).
  - betydelig: brukeren returnerer flere ganger til temaet eller
    beskriver det som «vanskelig», «slitsomt», «forvirrende», «tungt»,
    «irriterende», eller bruker generelle uttrykk for frustrasjon.
  - irritasjon: brukeren nevner i forbifarten eller bagatelliserer
    («det er litt rart», «bare litt irriterende», «kunne vært bedre»).

Hvis du må gjette alvorlighetsgrad fordi materialet er tvetydig, marker
med «(tolkning)» og senk én grad.

Produser deretter resultatet med eksakt disse seksjonene og overskriftene:

  ## Smertepunkter
  Inntil 8 smertepunkter, sortert med alvorligste først. For hvert:
    - Tittel i kursiv (3–6 ord).
    - Alvorlighetsgrad: alvorlig / betydelig / irritasjon.
    - Lag-kilde: Eksplisitt / Workaround / Emosjonell register.
    - Én setning som beskriver problemet i brukerens perspektiv.
    {{#group}}
    - «Sett i: Intervju 1, Intervju 3» — eksplisitt attribuering.
    {{/group}}

  ## Nøkkelsitater
  Inntil 10 sitater som best illustrerer smertepunktene. Velg sitater
  som bærer det emosjonelle registeret. Eksakte sitater, ikke
  parafraser. Behold pauser og repetisjoner. Format per sitat:
    {{#single}}
    - Uten taleridentifikasjon:
      [tidsstempel] «sitat»
    - Med taleridentifikasjon:
      [tidsstempel] SPEAKER_XX: «sitat»
    {{/single}}
    {{#group}}
    - Uten taleridentifikasjon:
      (Intervju N) [tidsstempel] «sitat»
    - Med taleridentifikasjon:
      (Intervju N) [tidsstempel] SPEAKER_XX: «sitat»
    {{/group}}
  Hvis sitatet illustrerer et bestemt smertepunkt, oppgi
  smertepunktets tittel først.

  ## Bakenforliggende behov
  3–6 behov. Til hvert smertepunkt over, formulér det bakenforliggende
  behovet brukeren prøver å få dekket: «Som bruker trenger jeg ...».
  Et behov kan dekke flere smertepunkter.

  ## Mønstre i workarounds
  Inntil 4 punkter. Når brukerne har lært seg å gjøre noe utenfor den
  tiltenkte flyten, beskriv mønsteret og hva det forteller om
  tjenesten. Ikke foreslå løsninger — det hører til opportunity-map-
  malen.

Krav til output:
- Bokmål gjennomgående.
- Eksakte sitater med tidsstempel. Du må ikke parafrasere, særlig ikke
  der det emosjonelle registeret bærer meningen.
- Smertepunkter sorteres alvorligste først.
- Format: ren markdown med eksakt seksjonsoverskriftene ovenfor.

Selvkontroll — gjennomfør i thinking-fasen før du formaterer svaret:
1. Har hvert smertepunkt minst ett sitat som belegg? Hvis ikke, fjern.
2. Er hvert sitat eksakt slik det står i kildematerialet, inkludert
   transkripsjonsmerker som (sukker), (pause)? Hvis du er usikker, fjern.
3. Er alvorlighetsgrader forankret i konkrete ord eller signaler i
   materialet? Hvis du har gjettet, marker med «(tolkning)» og senk
   én grad.
4. Stemmer Lag-kilde-tagen med sitatet du har valgt? Et eksplisitt
   sitat skal være ordrett negativt; en workaround beskriver en
   handling, ikke et problem; en emosjonell-register-tag krever et
   linguistisk signal (sukk, pause, sarkasme, sterk understreking).
5. Hvis SPEAKER_XX-labels er til stede, har du brukt dem riktig?
   Klager fra intervjueren er ikke informantens smertepunkter.
6. Er all output på bokmål?
```

## Output schema

Re-uses `AnalysisResult`. Severity tags and Lag-kilde tags are embedded in the theme strings — the parser doesn't need to know about them; they render naturally in markdown.

| Section in prompt | `AnalysisResult` field |
|-------------------|------------------------|
| Smertepunkter | `keyThemes` |
| Nøkkelsitater | `keyQuotes` |
| Bakenforliggende behov | `identifiedNeeds` |
| Mønstre i workarounds | `opportunities` |

## Expected output sketch

```markdown
## Smertepunkter
- *Aktivitetsplan-utfylling*: alvorlig. Eksplisitt. Brukerne klarer
  ikke å fylle ut aktivitetsplanen på egen hånd og frykter
  konsekvensene.
- *Telefonkø*: betydelig. Workaround. Brukerne har lært seg å ringe
  rett etter åpningstid, ellers bommer de.
- ...

## Nøkkelsitater
- *Aktivitetsplan-utfylling*: [00:22:18] SPEAKER_00: «Jeg satt i fem
  timer og ble bare mer redd for å trykke send.»
- ...

## Bakenforliggende behov
- Som bruker trenger jeg å forstå konsekvensene av å gjøre feil i
  aktivitetsplanen, før jeg sender den inn.
- ...

## Mønstre i workarounds
- Mange brukere ringer en bekjent som har vært gjennom prosessen før,
  framfor å bruke veiledningen. Tjenesten antar at veiledningen er
  tilstrekkelig, men praksis viser at uformell mentoring fyller et
  hull.
- ...
```

## Failure modes specific to pain-point analysis

- **Over-dramatization.** A small model with emotional-register cues may inflate severity. The anchor word lists are the primary defense; the "marker (tolkning) og senk én grad" rule is the secondary.
- **Confusing workarounds with explicit complaints.** The one-shot example is the primary defense. The cross-template quote-verification pass also substring-checks each cited quote; if the Lag-kilde tag says "Eksplisitt" but the quote is a behavioural description, the post-processor can flag the inconsistency.
- **Stripping context from quotes.** A frustrated quote out of context can be misleading. The prompt requires verbatim quotes including transcription markers; the B5 "verify this quote" affordance lets researchers cross-check at the audio level via timestamp.

## Revision log

- **v1 (2026-05-13):** revised. Timestamp anchoring replaces paragraph indices. SPEAKER_XX handling added (especially relevant for distinguishing informant from interviewer). Severity tags now have anchor word lists. One-shot example added for the three-layer model. Self-check folded into thinking-phase.
- **v0 (2026-05-11):** draft. New template — no upstream equivalent. Three-layer model (eksplisitt / workaround / emosjonell register) is the novel structural element vs. the default themes template.
