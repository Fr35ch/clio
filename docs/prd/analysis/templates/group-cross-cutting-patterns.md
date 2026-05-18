# Template — Gruppeintervju: felles mønstre på tvers

**id:** `group-cross-cutting-patterns-v1`
**kind:** `group`
**version:** `1` (revised — supersedes v0 draft from 2026-05-11)
**language:** Norwegian Bokmål
**enables:** B7 group analysis (multiple transcripts → one analysis)

## Purpose

When a researcher has finished interviewing several participants in a study and wants a synthesis across all of them — *not* a per-interview summary, but the cross-cutting patterns and the divergences worth flagging. The natural follow-up to running [single-interview-themes](single-interview-themes.md) on each one.

The key thing this template does *differently*: it requires explicit attribution. Every theme says which interviews it came from. Every quote names its source. The researcher should be able to look at any claim and trace it back to source material in seconds — both to the interview (via header) and to the moment (via timestamp).

## What changed from v0

- **Timestamps replace paragraph indices.** Citation format is now `(Intervju N) [mm:ss]` rather than `(Intervju N, avsnitt M)`. Aligns with single-interview-themes-v1 and lets the B5 audio-verify affordance work for group results too.
- **SPEAKER_XX handling added.** Group analyses often mix diarized and undiarized transcripts; the prompt now branches per-interview.
- **Divergence cap raised from 4 to 6.** In studies with deliberately diverse participants, the divergence section is often where the most interesting findings live.
- **Self-check folded into thinking-phase.** Same rationale as single-interview-themes-v1.
- **Explicit token-budget caveat documented.** Group analyses can blow past `num_ctx: 16384` for 4+ medium-length interviews. See "Context window" below.

## Input shape (group concatenation, B7a)

The composer concatenates the selected transcripts with explicit headers:

```
### Intervju 1 — <displayName 1>

<transcript text 1>

### Intervju 2 — <displayName 2>

<transcript text 2>

... etc
```

The headers are how the LLM cites — it refers back to "Intervju 2" in its output, and ARM displays the matching `displayName` in the result view. Robust against transcripts being deleted later: the cited `displayName` lives in the analysis manifest's `AnalysisSource.displayName`.

## Context window

Group analyses risk exceeding `num_ctx: 16384` because the cost is multiplicative. Rough budget:

- Skeleton + analyseinstrukser: ~1,500 tokens
- Research context: 100–500 tokens
- Output: ~2,000 tokens reserved
- Available for transcripts: ~12,000 tokens

That covers roughly 3–4 medium-length transcripts (10-minute interviews at ~3,000 tokens each) or 1–2 long ones. The composer in B4 should:

1. Show an estimated token total before running, with a warning band at >85% of `num_ctx`.
2. Offer to either bump `num_ctx` for this run (paid in VRAM and latency) or drop to a chunking strategy.
3. Refuse to run silently truncated input.

This is implementation guidance, not prompt content — flagged here so the composer team has it documented.

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

Notat om format på kildematerialet:
- Hvert intervju starter med en overskrift «### Intervju N — <navn>».
- Hver replikk har et tidsstempel [tt:mm:ss] eller [mm:ss] som første
  element. Tidsstempler er lokale for hvert intervju.
- Enkelte intervjuer kan inneholde SPEAKER_XX-labels fra automatisk
  talerseparering. Bruk dem hvis de er der; ikke gjett rolle for
  intervjuer som mangler dem.

Analyseinstrukser:

Du analyserer {{interviewCount}} intervjuer som hører til samme studie.
Målet er IKKE en oppsummering av hvert intervju. Målet er å identifisere
mønstre som går igjen på tvers, og divergenser som er verdt å løfte fram.

Du har thinking-modus aktivert. Bruk thinking-fasen til å gjennomføre
analysen og selvkontrollen før du formaterer det endelige svaret.

I thinking-fasen:
  1. Les alle intervjuene.
  2. Identifiser nøkkelord og uttrykk per intervju.
  3. Kode på tvers. Når samme begrep dukker opp i flere intervjuer,
     noter at det er felles.
  4. Grupper kodene til 5–8 mønstre på tvers. Et mønster skal være
     dekket av minst to intervjuer. Funn fra bare ett intervju
     rapporteres separat under «Avvik og divergenser».
  5. For hvert mønster, identifiser både semantisk og latent innhold.
     Latente tolkninger må markeres «(tolkning)».
  6. Identifiser divergenser — der intervjuene tydelig sier noe ulikt
     om samme tema.
  7. Gjennomfør selvkontrollen nedenfor før du formaterer svaret.

Produser deretter resultatet med eksakt disse seksjonene og overskriftene:

  ## Felles mønstre
  5–8 mønstre. For hvert mønster:
    - Tittel i kursiv (3–6 ord).
    - Én setning som beskriver mønsteret.
    - «Sett i: Intervju 1, Intervju 3, Intervju 5» — eksplisitt
      attribuering med intervjuheaderne fra kildematerialet.
    - Hvis det finnes en latent dimensjon, én setning prefikset
      «(tolkning)».

  ## Nøkkelsitater
  Inntil 12 sitater. Velg sitater som best illustrerer mønstrene.
  Format per sitat:
    - Uten taleridentifikasjon:
      (Intervju N) [tidsstempel] «sitat»
    - Med taleridentifikasjon:
      (Intervju N) [tidsstempel] SPEAKER_XX: «sitat»
  Eksakt sitat slik det står i kildematerialet — ikke parafraser, ikke
  bland sitater fra ulike intervjuer. Hvis sitatet illustrerer et
  bestemt mønster, oppgi mønstrets tittel først.

  ## Felles behov
  3–6 behov. Behov som går igjen i flere intervjuer. Hvert behov
  formulert som «Som bruker trenger jeg ...». Oppgi etter behovet i
  parentes hvilke intervjuer det er belagt i: «(Intervju 1, 4, 5)».

  ## Avvik og divergenser
  Inntil 6 punkter. Bruk denne seksjonen for funn som er VIKTIGE men
  som bare ett eller to intervjuer dekker, eller for tema der
  intervjuene sier motstridende ting. For hvert avvik:
    - Tittel i kursiv.
    - Sak: én setning.
    - Status: «Belagt i Intervju N» eller «Motstridende: Intervju N
      sier X, Intervju M sier Y».

Krav til output:
- Bokmål gjennomgående.
- Eksakte sitater. Du må ikke parafrasere eller blande sitater fra
  ulike intervjuer.
- Mønstre med færre enn to belegg flyttes til «Avvik og divergenser».
- Format: ren markdown med eksakt seksjonsoverskriftene ovenfor.

Selvkontroll — gjennomfør i thinking-fasen før du formaterer svaret:
1. Har hvert mønster minst to intervjuer som belegg? Hvis ikke, flytt
   til «Avvik og divergenser».
2. Er hvert sitat eksakt slik det står i kildematerialet, og er
   intervju-attribusjon og tidsstempel riktig? Hvis du er usikker på
   ett tegn, fjern sitatet.
3. Har du blandet semantiske observasjoner og latente tolkninger?
   Marker latente med «(tolkning)».
4. Har du faktisk identifisert noen divergenser, eller har du bare
   hovedmønstre? Forskere trenger å vite hvor materialet er uenig
   med seg selv. Hvis du ikke ser noen, skriv «Ingen tydelige
   divergenser observert» i seksjonen heller enn å hoppe over den.
5. Er all output på bokmål?
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

The result view (Phase B5) renders group results the same way as single results — but the header in the result view will show `kind = .group`, the source count, and clickable badges per source. Section labels are rendered from the `promptTemplateId` so researchers see "Felles mønstre" not "Hovedtemaer" and "Avvik og divergenser" not "Muligheter".

## Expected output sketch

```markdown
## Felles mønstre
- *Usikkerhet om saksgang*: Alle informantene beskriver at de ikke vet
  hvor i prosessen saken er. Sett i: Intervju 1, Intervju 2, Intervju 4,
  Intervju 5. (tolkning) En følelse av å miste kontroll over egen sak.
- ...

## Nøkkelsitater
- *Usikkerhet om saksgang*: (Intervju 1) [00:14:22] SPEAKER_00: «Jeg
  vet ikke om jeg får svar i morgen eller om to måneder.»
- ...

## Felles behov
- Som bruker trenger jeg å vite hvor i saksbehandlingen jeg er.
  (Intervju 1, 2, 4)
- ...

## Avvik og divergenser
- *Synet på chat-funksjonen*: Motstridende. Intervju 2 og 4 omtaler den
  som «livreddende»; Intervju 3 sier at den er «umulig å forstå».
  Belagt i tre intervjuer, men entydig motsetning.
- ...
```

## Failure modes specific to group analysis

- **Per-interview summary smell.** Watch for output that lists "Intervju 1 sa X, Intervju 2 sa Y" without crossing material — that's a synthesis failure. The "Målet er IKKE en oppsummering av hvert intervju" phrasing is the primary defense; if validation shows this happening, add a counter-example to the prompt.
- **Lost attribution.** The LLM sometimes drops the `(Intervju N) [mm:ss]` cite under length pressure. The cross-template quote-verification pass flags quotes that don't substring-match against the cited interview's transcript.
- **Theme inflation.** With multiple inputs, the LLM is tempted to produce more themes than the data supports. The 5–8 cap and the "minst to belegg" rule push back; the divergence section is the escape valve for "interesting but only-one-interview" findings.
- **Truncation from context overflow.** See "Context window" above — composer-side guardrails are required.

## Revision log

- **v1 (2026-05-13):** revised. Timestamp anchoring replaces paragraph indices. SPEAKER_XX handling added per-interview. Divergence cap raised 4 → 6. Self-check folded into thinking-phase. Context-window budget documented for the composer team.
- **v0 (2026-05-11):** draft. New template — no upstream equivalent. Output schema overloads `opportunities` to carry divergences; revisit in v2 if researchers want a dedicated field.
