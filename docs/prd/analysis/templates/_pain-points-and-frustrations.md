# Template — Smertepunkter og frustrasjoner

**id:** `pain-points-and-frustrations-v1`
**kind:** `single` or `group`
**version:** `0` (draft — pending validation against ≥3 service-improvement studies)
**language:** Norwegian Bokmål

## Purpose

For studies focused on service quality — where the goal is to surface what's *wrong* with a service from the user's perspective. The general-purpose [single-interview-themes](single-interview-themes.md) template tends to over-balance the output (themes + needs + opportunities), which dilutes pain-point analysis. This template explicitly weights toward negative experiences and emotional register.

Common NAV use cases: post-launch service evaluation, complaint clustering, retrospective on a process change.

## What this template does differently

- **Higher latent-meaning weight.** Pain points are often unsaid — the user describes a behavior or workaround rather than naming the frustration. The prompt instructs the model to surface these inferences explicitly.
- **Severity hints.** Each pain point carries a soft severity tag (`alvorlig` / `betydelig` / `irritasjon`) based on emotional register cues in the source. This is a tolerance hint for the researcher; the researcher remains the final judge.
- **No opportunities section.** Opportunities are a separate template ([opportunity-map](opportunity-map.md)). Running both gives the researcher a "problems" view and a "solutions" view as parallel artifacts, not a forced single-pass mix.

## Prompt body

```
Du er en erfaren NAV-tjenestedesigner og brukerforsker. Målet ditt er å
identifisere smertepunkter, frustrasjoner og friksjoner som brukerne
opplever med tjenesten. Svar på norsk bokmål.

Forskningskontekst:
{{researchContext}}

{{#group}}
Antall intervjuer: {{interviewCount}}
{{/group}}

Kildemateriale:
{{transcripts}}

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
    {{#single}}
    - «(avsnitt N)»
    {{/single}}
    {{#group}}
    - «(Intervju N, avsnitt M)»
    {{/group}}
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
```

## Output schema

Re-uses `AnalysisResult`. Severity tags are embedded in the theme strings — the parser doesn't need to know about them; they render naturally in markdown.

| Section in prompt | `AnalysisResult` field |
|-------------------|------------------------|
| Smertepunkter | `keyThemes` |
| Nøkkelsitater | `keyQuotes` |
| Bakenforliggende behov | `identifiedNeeds` |
| Mønstre i workarounds | `opportunities` |

## Expected output sketch

```markdown
## Smertepunkter (key_themes)
- *Aktivitetsplan-utfylling*: alvorlig. Eksplisitt. Brukerne klarer ikke å
  fylle ut aktivitetsplanen på egen hånd og frykter konsekvensene.
- *Telefonkø*: betydelig. Workaround. Brukerne har lært seg å ringe rett
  etter åpningstid, ellers bommer de.
- ...

## Nøkkelsitater (key_quotes)
- *Aktivitetsplan-utfylling*: «Jeg satt i fem timer og ble bare mer redd
  for å trykke send.» (avsnitt 22)
- ...

## Bakenforliggende behov (identified_needs)
- Som bruker trenger jeg å forstå konsekvensene av å gjøre feil i
  aktivitetsplanen, før jeg sender den inn.
- ...

## Mønstre i workarounds (opportunities)
- Mange brukere ringer en bekjent som har vært gjennom prosessen før,
  framfor å bruke veiledningen. Tjenesten antar at veiledningen er
  tilstrekkelig, men praksis viser at uformell mentoring fyller et hull.
- ...
```

## Failure modes specific to pain-point analysis

- **Over-dramatization.** A small model with emotional-register cues may inflate severity. The "marker med (tolkning) og senk én grad" self-check guards against this.
- **Confusing workarounds with explicit complaints.** Validation should check that the `Lag-kilde` label matches the underlying interview text (the post-processor can substring-check the quote).
- **Stripping context from quotes.** A frustrated quote out of context can be misleading. The prompt requires verbatim quotes and the result view's "verify this quote" affordance (B5) will let researchers cross-check.

## Revision log

- **v0 (2026-05-11):** draft. New template — no upstream equivalent. Three-layer model (eksplisitt / workaround / emosjonell register) is the novel structural element vs. the default themes template.
