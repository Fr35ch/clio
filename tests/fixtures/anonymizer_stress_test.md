# Anonymizer stress-test transcript (NB)

A deliberately tricky Norwegian-language transcript for the
avidentifisering pipeline. Designed to expose the limits of the
**current** library (`no-anonymizer` v0.5.0, NbAiLab BERT NER) and to
serve as the canonical fixture for the v2 evidence-based rewrite (see
[docs/no_anonymizer_v2_implementasjon.md](../../docs/no_anonymizer_v2_implementasjon.md)).

**Goal:** every token that should be redacted, kept, or flagged is
called out in the expectation table at the bottom. The transcript reads
like a real NAV-researcher interview so the model encounters tokens in
natural context, not as a word list.

## How to test

1. Save the *Transcript* section to a plain `.txt` file
2. Run the bridge directly:
   ```
   python3 Resources/anonymize_bridge.py \
     --input /tmp/stress.txt --output /tmp/stress.json
   ```
3. Compare `/tmp/stress.json` against the *Expectations* table.

For v0.5.0 you should expect **lots** of false positives on homographs.
That's the point — v2 is supposed to fix them.

---

## Transcript

```
[00:00] R: Først litt om bakgrunnen din. Hvor jobbet du før du ble sykemeldt?

[00:08] I: Jeg jobbet hos Statens vegvesen i Bergen. Sjefen min het Anne Olsen, hun var grei nok, men ledelsen over henne var en katastrofe. Per i dag har jeg vært ute i seks måneder.

[00:25] R: Per i dag, ja. Hvordan har dialogen med NAV vært?

[00:30] I: Helt på trynet. Jeg ringte 22 02 33 00 fjorten ganger den første uka. Når jeg endelig fikk tak i saksbehandleren — han het Bjørn — sa han at saken min var sendt til feil avdeling. Igjen.

[00:55] R: Og du måtte vente?

[00:57] I: Ja, jeg måtte vente. Den nye saksbehandleren heter Sigurd Hovde, og han har faktisk vært ok. Han har ringt meg tre ganger på +47 41 23 45 67. Vi har avtalt et nytt møte i mai.

[01:20] R: Snakker du om mai måned eller var det navnet til noen?

[01:24] I: Måneden. Møtet er i mai 2026. Jeg har også fått hjelp av en kollega som heter Mai Lindberg — det er en kvinne, ikke måneden. Hun jobber i Tromsø.

[01:42] R: Skrekk og gru med navn som er måneder. Hvilke andre folk har vært involvert i saken din?

[01:50] I: La meg tenke. Det var Per Slette, han som først tok imot meldingen. Så var det Tone — etternavn glemte jeg. Tor Even Frostad ringte fra et legekontor. Og en lege på Diakonhjemmet, Magnus Knutsen.

[02:15] R: Du nevnte at du fikk en SMS med fødselsnummeret ditt — hvordan reagerte du?

[02:22] I: Jeg ble forbanna. De sendte 12108512345 på SMS i klartekst! Til en mobil — 99 88 77 66 — som hele familien ser på. Jeg sendte klage til personvernombud@nav.no, ingen svar.

[02:48] R: Det er ALVORLIG. Har du tatt det videre?

[02:51] I: Datatilsynet har fått klagen min. Saken min har D-nummer 41108512345 fordi jeg er bosatt utenlands halve året. De roter med begge typer numre.

[03:10] R: Du sa du bor utenlands halvparten av året — hvor da?

[03:14] I: Vi har et hus på Mallorca, men jeg er folkeregistrert i Storgata 5 i Oslo. Postboks 11, 0150 Oslo. Hovde er en liten plass jeg er fra, ute på Stadlandet.

[03:32] R: Tilbake til saken. Hva er det største problemet med systemet slik du ser det?

[03:38] I: Det er at ingen tar ansvar. Du blir kastet rundt mellom Bjørn, Sigurd og en tredje saksbehandler som het Vår Olsen. Vår, ja — som årstiden. Jeg trodde først det var en spøk.

[04:00] R: Sluttkommentar?

[04:02] I: NAV må skjønne at en sykemelding ikke bare er et papir. Det er livet til folk. Slette saken min er det siste jeg vil — jeg vil ha den løst.

[04:18] R: Takk for at du tok deg tid. Jeg kontakter deg på kari.hansen@gmail.com hvis vi trenger oppfølging.
```

---

## Expectations

### Direct identifiers — MUST redact (high-confidence, no homograph problem)

| Token | Category | Notes |
|---|---|---|
| `Anne Olsen` | NAVN | Full first + last |
| `Sigurd Hovde` | NAVN | Note: "Hovde" is also a place name later — disambiguation matters |
| `Mai Lindberg` | NAVN | Full first + last; "Mai" is a homograph (month) — see flag set |
| `Magnus Knutsen` | NAVN | Unambiguous first + last |
| `Tor Even Frostad` | NAVN | Triple-name; "Tor" and "Even" are both homographs in isolation |
| `Vår Olsen` | NAVN | Homograph first name "Vår" (season); test of bucket model |
| `Per Slette` | NAVN | **Both** parts homographs — "Per" (preposition) and "Slette" (verb/noun) |
| `kari.hansen@gmail.com` | EPOST | |
| `personvernombud@nav.no` | EPOST | |
| `22 02 33 00` | TELEFON | Spaced 8-digit |
| `+47 41 23 45 67` | TELEFON | International prefix + spaced |
| `99 88 77 66` | TELEFON | Mobile |
| `12108512345` | FØDSELSNUMMER | 11-digit, first digit ≤ 3 |
| `41108512345` | D-NUMMER | 11-digit, first digit ≥ 4 |

### Homograph words — MUST keep (today's v0.5.0 will likely false-positive most of these)

| Token | Context in transcript | Why keep |
|---|---|---|
| `Per i dag` (×2) | "Per i dag har jeg vært ute …" | Idiomatic preposition use |
| `i mai` (×2) | "avtalt et nytt møte i mai", "Møtet er i mai 2026" | Month |
| `mai måned` | "om mai måned eller var det navnet" | Month |
| `Vår` (standalone) | "Vår, ja — som årstiden" | Season, not a person |
| `Slette saken` | "Slette saken min er det siste jeg vil" | Verb |
| `Tone` (alone) | "Så var det Tone — etternavn glemte jeg" | Borderline — here it IS a name. See flagged set. |
| `Bjørn` (saksbehandler) | "han het Bjørn" | Borderline — here it IS a name. See flagged set. |
| `Hovde` (as place) | "Hovde er en liten plass" | Geographic, not the surname |

### Tokens v2 should `flag` for review (model uncertain, context ambiguous)

These are the cases where the lexicon would put the token in the
`ambiguous` bucket and contextual evidence would land the final score
between 0.0 and 0.5:

| Token | Reasoning |
|---|---|
| `Bjørn` (saksbehandler) | Identity-verb context ("het Bjørn") points to PER (+0.4) but lexicon start is ambiguous (0.0). With pos_propn (+0.2), final ~0.6 → `redact`. **Boundary case** — verify v2 doesn't drift below threshold. |
| `Tone` (no last name) | "Det var Tone — etternavn glemte jeg" — narrative naming pattern; mention_intro signal applies. Score should put it in `flag` or `redact` depending on v2 tuning. |
| `Vår Olsen` ↔ `Vår` | The full bigram with `Olsen` after should trigger `last_name_after` (+0.3). Standalone `Vår — som årstiden` should `keep` via `temporal_context`. |
| `Mai` (Lindberg) | last_name_after (+0.3) + pos_propn (+0.2) → `redact`. But "i mai" preceding the name twice in nearby context will be a signal-collector stress test. |
| `Hovde` (place vs name) | Cross-token resonnering not in v2 scope, so the surname mention vs place mention may both render the same decision. Worth verifying. |

### Places (STED) — MUST redact for v0.5.0 / Kartverket

| Token | Notes |
|---|---|
| `Bergen` | Major city |
| `Tromsø` | Major city |
| `Oslo` (×2) | Major city |
| `Mallorca` | Foreign — may not be in Kartverket; verify |
| `Storgata 5` | Street + number |
| `Postboks 11, 0150 Oslo` | Postal box + postcode |
| `Stadlandet` | Small place — Kartverket-lookup stress |

### Organisations — current v0.5.0 logs but doesn't redact (per spec)

| Token | Notes |
|---|---|
| `Statens vegvesen` | Norwegian state agency |
| `NAV` (×3+) | Subject org — kept by design |
| `Datatilsynet` | State agency |
| `Diakonhjemmet` | Private hospital — could leak via cross-reference |

### CAPS edge case

| Token | Notes |
|---|---|
| `ALVORLIG` | All-caps exclamation in researcher turn. v0.5.0 uses CAPS-normalizer pre-NER; should NOT be flagged as a name. Regression test. |

### Indirect identifiers — outside scope today

The combination of *"jobbet hos Statens vegvesen i Bergen + Stadlandet
+ Hovde + bor på Mallorca + Diakonhjemmet"* is potentially
re-identifying even after every direct identifier is removed. This is a
researcher-judgement boundary, not a model-detection boundary, and is
explicitly out of scope for v2 per the spec section 3.

---

## How to score the v0.5.0 baseline

For each token in the *MUST redact* tables: count true positives.
For each token in the *MUST keep* tables: count false positives.
Compute precision = TP / (TP + FP). The point of the v2 rewrite is to
push precision **up** without sacrificing recall (no new false
negatives in the MUST-redact set).

When v2 ships, the same fixture should be re-scored. Acceptance criteria
in the v2 spec require ≥90 % correct decisions on the ambiguous tokens
relative to v0.5.0's blanket-redaction baseline.
