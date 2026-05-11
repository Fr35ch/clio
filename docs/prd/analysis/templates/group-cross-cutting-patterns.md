# Template — Gruppeintervju: felles mønstre på tvers

**id:** `group-cross-cutting-patterns-v1`
**kind:** `group`
**version:** `0` (draft — pending validation against ≥3 real NAV study sets)
**language:** Norwegian Bokmål
**enables:** B7 group analysis (multiple transcripts → one analysis)

## Purpose

When a researcher has finished interviewing several participants in a study and wants a synthesis across all of them — *not* a per-interview summary, but the cross-cutting patterns and the divergences worth flagging. This is the natural follow-up to running [single-interview-themes](single-interview-themes.md) on each one.

The key thing this template does *differently*: it requires explicit attribution. Every theme says which interviews it came from. Every quote names its source. The researcher should be able to look at any claim and trace it back to source material in seconds.

## Input shape (group concatenation, B7a)

The composer concatenates the selected transcripts with explicit headers:

```
### Intervju 1 — <displayName 1>

<transcript text 1>

### Intervju 2 — <displayName 2>

<transcript text 2>

... etc
```

The headers are how the LLM cites — it refers back to "Intervju 2" in its output, and ARM displays the matching `displayName` in the result view. This is robust against transcripts being deleted later: the cited displayName lives in the analysis manifest's `AnalysisSource.displayName`.

## Prompt body

```
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
```

## Output schema

Re-uses `AnalysisResult` but with overloaded semantics for `opportunities`. This avoids a schema fork for the MVP; if researchers ask for a proper `divergences` field we add it in v2.

| Section in prompt | `AnalysisResult` field |
|-------------------|------------------------|
| Felles mønstre | `keyThemes` |
| Nøkkelsitater | `keyQuotes` |
| Felles behov | `identifiedNeeds` |
| Avvik og divergenser | `opportunities` |
| (full markdown) | `rawMarkdown` |

The result view (Phase B5) renders group results the same way as single results — but the header in the result view will show `kind = .group`, the source count, and clickable badges per source.

## Expected output sketch

```markdown
## Felles mønstre (key_themes)
- *Usikkerhet om saksgang*: Alle informantene beskriver at de ikke vet hvor
  i prosessen saken er. Sett i: Intervju 1, Intervju 2, Intervju 4,
  Intervju 5. (tolkning) En følelse av å miste kontroll over egen sak.
- ...

## Nøkkelsitater (key_quotes)
- *Usikkerhet om saksgang*: «Jeg vet ikke om jeg får svar i morgen eller
  om to måneder.» (Intervju 1, avsnitt 14)
- ...

## Felles behov (identified_needs)
- Som bruker trenger jeg å vite hvor i saksbehandlingen jeg er. (Intervju 1, 2, 4)
- ...

## Avvik og divergenser (opportunities)
- *Synet på chat-funksjonen*: Motstridende. Intervju 2 og 4 omtaler den som
  «livreddende»; Intervju 3 sier at den er «umulig å forstå». Belegg i tre
  intervjuer, men entydig motsetning.
- ...
```

## Failure modes specific to group analysis

- **Per-interview summary smell.** Watch for output that lists "Intervju 1 sa X, Intervju 2 sa Y" without crossing material — that's a synthesis failure, not a synthesis. If validation shows this, the fix is to strengthen "Målet er IKKE en oppsummering av hvert intervju" and add an example.
- **Lost attribution.** The LLM sometimes drops the `(Intervju N, avsnitt M)` cite under length pressure. The post-processor in ARM will flag any quote that doesn't have a parseable cite.
- **Theme inflation.** With multiple inputs, the LLM is tempted to produce more themes than the data supports. Hence the explicit 5–8 cap and the "minst to belegg" rule.

## Revision log

- **v0 (2026-05-11):** draft. New template — no upstream equivalent. Output schema overloads `opportunities` to carry divergences; revisit in v2 if researchers want a dedicated field.
