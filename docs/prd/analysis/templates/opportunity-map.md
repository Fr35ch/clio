# Template — Mulighetskart

**id:** `opportunity-map-v1`
**kind:** `single` or `group`
**version:** `1` (revised — supersedes v0 draft from 2026-05-11)
**language:** Norwegian Bokmål

## Purpose

For studies that feed into product or service design decisions. Where [pain-points-and-frustrations](pain-points-and-frustrations.md) catalogues what's wrong, this template extracts *what could be done about it* — with the discipline that an opportunity is only useful if it has a preconditions list and a target user segment.

This is the most prescriptive of the four templates because product/service-design output benefits from forcing the model to be specific. Vague opportunities ("forbedre brukerreisen") are noise; concrete opportunities ("la brukeren se estimert ventetid på aktiv sak") are signal.

## What changed from v0

- **Timestamp anchoring** replaces `(avsnitt N)` — same rationale as the other templates.
- **SPEAKER_XX handling added.**
- **Forutsetninger now require a category tag** (`teknisk` / `organisatorisk` / `juridisk`). Pushes the model away from vague "trenger arbeid på Min Side" toward concrete claims about what type of work.
- **Soft expectation that 1–3 muligheter are speculative.** The data-driven vs speculative split has no incentive structure in v0; the model tends to claim everything as data-driven to look rigorous. The new wording makes "all data-driven" a smell the model should notice.
- **Self-check folded into thinking-phase.**

## What this template does differently

- **Each opportunity must have a precondition list.** What has to be true for this to be valuable to act on? This forces the model to think about feasibility, not just desirability.
- **Each opportunity must name a target user segment.** "Brukere flest" is rejected; the prompt asks for segment characteristics that map to NAV's actual user typology (livssituasjon, kanalpreferanse, tidligere erfaring med tjenesten).
- **No theme section.** Themes belong to [single-interview-themes](single-interview-themes.md). This template skips straight to actionable output.
- **Speculative vs. data-driven split.** The sections separate opportunities the data clearly supports from opportunities that are plausible inferences. Researchers downstream can choose which set to push forward.

## Prompt body

```
Du er en erfaren NAV-tjenestedesigner. Målet ditt er å trekke ut
konkrete muligheter for forbedring av tjenesten, basert på det
informantene beskriver. Svar på norsk bokmål.

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
  automatisk talerseparering. En mulighet skal forankres i utsagn fra
  informanten, ikke fra intervjueren.

Analyseinstrukser:

Du leter etter handlingsrom. Du har thinking-modus aktivert. Bruk
thinking-fasen til analyse og selvkontroll før du formaterer svaret.

For hver mulighet du foreslår, må følgende gjelde:

  1. Den er forankret i konkrete observasjoner i kildematerialet —
     ikke generelle prinsipper.
  2. Den har en målgruppe — hvilket brukersegment er dette nyttig for?
     Eksempel: «brukere på AAP som er i sin første saksbehandlings-
     runde», «brukere som primært kontakter NAV via telefon», ikke
     «brukere flest».
  3. Den har en forutsetning med kategori-tag: (teknisk),
     (organisatorisk) eller (juridisk). Hva må være på plass i NAV
     for at muligheten skal kunne realiseres?
  4. Den er konkret nok til at et team kan diskutere om de skal jobbe
     med den eller ikke.

Skill mellom to typer muligheter:

  Datadrevne muligheter — muligheter der materialet eksplisitt peker
                          på dem.
  Spekulative muligheter — plausible inferanser fra materialet, men
                           ikke eksplisitt belagt. Disse markeres
                           «(spekulativ)».

Det er normalt at 1–3 av mulighetene er spekulative. Hvis du har null
spekulative, sjekk om noen av de «datadrevne» faktisk mangler direkte
belegg og bør flyttes. Spekulative muligheter er verdifulle så lenge
de er markert.

Produser deretter resultatet med eksakt disse seksjonene og overskriftene:

  ## Datadrevne muligheter
  Inntil 5 muligheter, sortert med høyest mulig effekt først. For hver:
    - Tittel i kursiv (3–6 ord), én konkret formulering.
    - Beskrivelse: én setning som forklarer hva som skal skje.
    - Målgruppe: konkret brukersegment.
    - Forutsetning (kategori): hva må være på plass i NAV. Tag med
      (teknisk), (organisatorisk) eller (juridisk).
    {{#group}}
    - Belegg i: «Intervju 1, Intervju 3».
    {{/group}}

  ## Sitater som forankrer mulighetene
  Inntil 8 sitater fra kildematerialet som best forankrer mulighetene
  over. Eksakte sitater. Format per sitat:
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
  Hvis sitatet forankrer en spesifikk mulighet, oppgi mulighetens
  tittel først.

  ## Brukerbehov som muligheter dekker
  3–5 behov. For hver, formulér behovet og pek på hvilke muligheter
  over som adresserer det: «Som bruker trenger jeg ... — dekkes av
  mulighet X og Y».

  ## Spekulative muligheter
  Inntil 4 muligheter som er plausible inferanser, men ikke eksplisitt
  belagt i materialet. For hver:
    - Tittel i kursiv, prefikset «(spekulativ)».
    - Beskrivelse: én setning.
    - Hvilken observasjon i materialet inspirerte denne muligheten.
    - Hvilket eksperiment kunne bekrefte eller avkrefte at muligheten
      er reell.

Krav til output:
- Bokmål gjennomgående.
- Eksakte sitater med tidsstempel. Du må ikke parafrasere.
- Hver datadreven mulighet må ha alle fire elementer (tittel,
  beskrivelse, målgruppe, forutsetning med kategori-tag). Mangler du
  ett av dem, flytt muligheten til spekulative.
- Format: ren markdown med eksakt seksjonsoverskriftene ovenfor.

Selvkontroll — gjennomfør i thinking-fasen før du formaterer svaret:
1. Er hver datadreven mulighet forankret i minst ett sitat fra
   materialet? Hvis ikke, flytt til spekulative.
2. Har du målgrupper som faktisk er segmenter, ikke «brukere flest»?
3. Har hver datadrevne mulighet en kategori-tag på forutsetningen?
   Hvis (teknisk), er det noe et utviklingsteam kan teste?
   Hvis (organisatorisk), er det noe en avdelingsleder kan beslutte?
   Hvis (juridisk), kreves det jurist-konsultasjon?
4. Har du markert spekulative muligheter eksplisitt med
   «(spekulativ)»?
5. Hvis du har null spekulative muligheter, har du virkelig kun
   datadrevne, eller har du oppgradert spekulative til datadrevne
   for å virke streng?
6. Er hvert sitat eksakt slik det står i materialet, med tidsstempel
   som finnes der? Hvis du er usikker, fjern.
7. Er all output på bokmål?
```

## Output schema

Re-uses `AnalysisResult`. The "datadrevne muligheter" land in `keyThemes` (despite the section name) because that's the *primary* output of this template — the existing parser treats `keyThemes` as the headline section. The "spekulative muligheter" land in `opportunities`, matching how the field is named.

| Section in prompt | `AnalysisResult` field |
|-------------------|------------------------|
| Datadrevne muligheter | `keyThemes` |
| Sitater som forankrer mulighetene | `keyQuotes` |
| Brukerbehov som muligheter dekker | `identifiedNeeds` |
| Spekulative muligheter | `opportunities` |

This is a deliberately overloaded use of the field names. The result view (Phase B5) renders section headings based on the `promptTemplateId` so researchers see "Datadrevne muligheter" rather than "Hovedtemaer" when this template is active.

## Expected output sketch

```markdown
## Datadrevne muligheter
- *Estimert ventetid synlig på aktiv sak*: Vise brukerne en oppdatert
  estimert ventetid for deres pågående sak direkte i Min Side.
  Målgruppe: brukere på AAP i første saksbehandlingsrunde.
  Forutsetning (teknisk): saksbehandlingstid kan estimeres datadrevet
  per saksstype. Belegg i: Intervju 1, Intervju 4.
- ...

## Sitater som forankrer mulighetene
- *Estimert ventetid synlig på aktiv sak*: (Intervju 1) [00:14:22]
  SPEAKER_00: «Jeg vet ikke om jeg får svar i morgen eller om to
  måneder.»
- ...

## Brukerbehov som muligheter dekker
- Som bruker trenger jeg å vite hvor i saksbehandlingen jeg er —
  dekkes av mulighet «Estimert ventetid synlig på aktiv sak».
- ...

## Spekulative muligheter
- *(spekulativ) Push-varsling ved statusendring*. Sende push-varsel
  når saksstatus endres. Inspirert av at flere informanter beskriver
  at de sjekker Min Side flere ganger daglig. Eksperiment: kjør A/B
  på push-varslinger og mål endring i Min Side-trafikk.
- ...
```

## Failure modes specific to opportunity mapping

- **Vague opportunities.** The four-element rule (title, description, segment, precondition-with-category) is the primary defense; the self-check is a second pass.
- **Solutionism creep.** The model sometimes proposes opportunities the data doesn't support. The data-driven vs. speculative split keeps these out of the wrong column; the explicit "1–3 spekulative is normal" expectation keeps the model from sweeping them into the data-driven column to look rigorous.
- **Borrowed-from-training-data opportunities.** Watch for opportunities that sound suspiciously generic ("AI-chatbot for veiledning") and aren't actually supported by the interview material. Validation should reject these. The quote-verification pass catches the surface case; reviewer judgment is required for the deeper case.

## Revision log

- **v1 (2026-05-13):** revised. Timestamp anchoring replaces paragraph indices. SPEAKER_XX handling added. Forutsetninger require category tag (teknisk/organisatorisk/juridisk). "1–3 spekulative is normal" expectation added to counter all-data-driven inflation. Self-check folded into thinking-phase.
- **v0 (2026-05-11):** draft. New template — no upstream equivalent. Most prescriptive output schema of the four (four-element rule on each opportunity).
