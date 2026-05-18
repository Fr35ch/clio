# Template — Mulighetskart

**id:** `opportunity-map-v1`
**kind:** `single` or `group`
**version:** `0` (draft — pending validation against ≥3 product-discovery studies)
**language:** Norwegian Bokmål

## Purpose

For studies that feed into product or service design decisions. Where [pain-points-and-frustrations](pain-points-and-frustrations.md) catalogues what's wrong, this template extracts *what could be done about it* — with the discipline that an opportunity is only useful if it has a preconditions list and a target user segment.

This is the most prescriptive of the four templates because product/service-design output benefits from forcing the model to be specific. Vague opportunities ("forbedre brukerreisen") are noise; concrete opportunities ("la brukeren se estimert ventetid på aktiv sak") are signal.

## What this template does differently

- **Each opportunity must have a precondition list.** What has to be true for this to be valuable to act on? This forces the model to think about feasibility, not just desirability.
- **Each opportunity must name a target user segment.** "Brukere flest" is rejected; the prompt asks for segment characteristics that map to NAV's actual user typology (livssituasjon, kanalpreferanse, tidligere erfaring med tjenesten).
- **No theme section.** Themes belong to [single-interview-themes](single-interview-themes.md). This template skips straight to actionable output.
- **Speculative vs. data-driven split.** The four sections separate opportunities the data clearly supports from opportunities that are plausible inferences. Researchers downstream can choose which set to push forward.

## Prompt body

```
Du er en erfaren NAV-tjenestedesigner. Målet ditt er å trekke ut konkrete
muligheter for forbedring av tjenesten, basert på det informantene
beskriver. Svar på norsk bokmål.

Forskningskontekst:
{{researchContext}}

{{#group}}
Antall intervjuer: {{interviewCount}}
{{/group}}

Kildemateriale:
{{transcripts}}

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
    {{#single}}
    - «(avsnitt N)»
    {{/single}}
    {{#group}}
    - «(Intervju N, avsnitt M)»
    {{/group}}
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
```

## Output schema

Re-uses `AnalysisResult`. The "datadrevne muligheter" land in `keyThemes` (despite the section name) because that's the *primary* output of this template — the existing parser treats `keyThemes` as the headline section. The "spekulative muligheter" land in `opportunities`, matching how the field is named.

| Section in prompt | `AnalysisResult` field |
|-------------------|------------------------|
| Datadrevne muligheter | `keyThemes` |
| Sitater som forankrer mulighetene | `keyQuotes` |
| Brukerbehov som muligheter dekker | `identifiedNeeds` |
| Spekulative muligheter | `opportunities` |

This is a deliberately overloaded use of the field names. The result view (Phase B5) will render section headings based on the `promptTemplateId` so researchers see "Datadrevne muligheter" rather than "Hovedtemaer" when this template is active.

## Expected output sketch

```markdown
## Datadrevne muligheter (key_themes)
- *Estimert ventetid synlig på aktiv sak*: Vise brukerne en oppdatert
  estimert ventetid for deres pågående sak direkte i Min Side.
  Målgruppe: brukere på AAP i første saksbehandlingsrunde.
  Forutsetning: at saksbehandlingstid kan estimeres datadrevet per
  saksstype. Belegg i: Intervju 1, Intervju 4.
- ...

## Sitater som forankrer mulighetene (key_quotes)
- *Estimert ventetid synlig på aktiv sak*: «Jeg vet ikke om jeg får svar
  i morgen eller om to måneder.» (Intervju 1, avsnitt 14)
- ...

## Brukerbehov som muligheter dekker (identified_needs)
- Som bruker trenger jeg å vite hvor i saksbehandlingen jeg er — dekkes
  av mulighet «Estimert ventetid synlig på aktiv sak».
- ...

## Spekulative muligheter (opportunities)
- *(spekulativ) Push-varsling ved statusendring*. Sende push-varsel når
  saksstatus endres. Inspirert av at flere informanter beskriver at de
  sjekker Min Side flere ganger daglig. Eksperiment: kjør A/B på
  push-varslinger og mål endring i Min Side-trafikk.
- ...
```

## Failure modes specific to opportunity mapping

- **Vague opportunities.** The model is tempted to produce "forbedre brukerflyten" or "gjøre tjenesten mer brukervennlig". The four-element rule (title, description, segment, precondition) is the primary defense; the self-check at the end is a second pass.
- **Solutionism creep.** The model sometimes proposes opportunities the data doesn't support. The data-driven vs. speculative split is meant to keep these out of the wrong column rather than suppress them entirely — speculative opportunities are valuable as long as they're labelled.
- **Borrowed-from-training-data opportunities.** Watch for opportunities that sound suspiciously generic ("AI-chatbot for veiledning") and aren't actually supported by the interview material. Validation should reject these.

## Revision log

- **v0 (2026-05-11):** draft. New template — no upstream equivalent. Most prescriptive output schema of the four (four-element rule on each opportunity). Validation against real product-discovery studies pending.
