# Prompt iteration — working journal

**Status:** active iteration log
**Owners:** product owner + Claude
**Last updated:** 2026-05-13

This is a working document, not a spec. It's where prompts get tested, edited, and refined against real interview material before the changes are folded back into the bundled templates in `PromptTemplateLibrary.swift`.

> **Where things live:**
> - **Bundled templates** ship inline in [`PromptTemplateLibrary.swift`](../../../Sources/AudioRecordingManager/Analysis/PromptTemplateLibrary.swift). These are the read-only defaults researchers see in the composer dropdown.
> - **Template specs** at [`templates/*.md`](templates/) document each bundled template's intent, expected output, and revision history. Update these when a bundled template ships a new version.
> - **Research note** at [`PROMPT_RESEARCH.md`](PROMPT_RESEARCH.md) captures the literature foundation and the shared prompt skeleton.
> - **This document** is the *iteration scratchpad* — drafts, test runs, observations, next-to-try lists. Edit freely.

---

## How to use this doc

1. **Pick a template to focus on** (§ "Active focus" below). Iterate on one at a time.
2. **Copy the current bundled prompt** from `PromptTemplateLibrary.swift` into the "Current draft" section. This becomes your working copy.
3. **Run analyses** in the app against real interviews. Log each run in the table (template version under test, source, model, top-line observation).
4. **Note specific issues** in the issues list as you spot them. One issue per line — concrete, not abstract.
5. **Try changes** by editing "Current draft" directly. When a change works, log it under "Decisions" with the before/after.
6. **When a draft is ready to ship**: copy "Current draft" back into `PromptTemplateLibrary.swift`, bump the template's `version` field, update the template spec under `templates/`, and reset this doc's "Current draft" to the new bundled version.

The point of this doc is to keep the iteration *fast* — try things, note what happened, move on. Don't over-structure it. Don't archive old drafts in this file; git history is the archive.

---

## Active focus

> Pick one. Switching focus is fine; just update this section so the next session knows what's in flight.

- **Template being iterated:** `single-interview-themes-v1`
- **Started iterating:** 2026-05-13 (reset after v1 ship)
- **Goal of this iteration:** validate v1 against three real NAV interviews per `PROMPT_RESEARCH.md` §7. Promote to "stable" if all four rating axes pass; iterate to v2 if not.
- **Acceptance criteria for stable status** (from `PROMPT_RESEARCH.md` §7.2):
  - **Quote verifiability**: ≥ 95% of cited quotes pass substring-against-transcript-at-cited-timestamp check.
  - **Latent vs. semantic balance**: ≥ 50% of themes carry a `(tolkning)` line.
  - **Theme redundancy**: no two themes share > 50% of their underlying quotes.
  - **Norwegian fluency**: no English content outside proper names from source material.
- **Pre-validation sanity tests to run first** (see "Pre-validation tests" below): false-researchContext probe, low-content transcript probe. These run before the three-interview validation set.

---

## Current draft

> The prompt as it would land in `PromptTemplateLibrary.swift`. Start by pasting in the current bundled body, then edit in place. Add a `## Diff from bundled v1` section below when you've changed something nontrivial.

```text
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

### Diff from bundled v1

> Note here when this draft has diverged from what `PromptTemplateLibrary.swift` ships. Use brief bullet points; don't paste full before/after blocks — the git diff is the source of truth.

- *(no diff yet — this is verbatim v1)*

---

## Pre-validation tests

> Run these *before* the three-interview validation set. They probe specific failure modes that real-material validation may not surface, because real material is by construction grounded and well-formed.

### Test 1 — False-researchContext probe

**Purpose:** verify that the model is grounded in the transcript content rather than being steered by the framing in `{{researchContext}}`.

**Method:**
1. Pick one real interview transcript.
2. Run the analysis once with a truthful `researchContext`. Capture output.
3. Run the analysis again on the same transcript with a deliberately *false but plausible* `researchContext` (e.g. claim the study is about a completely different service area than what the transcript actually discusses).
4. Compare themes, quotes, and identified needs between runs.

**Acceptable behaviour:** the themes and quotes are substantively the same; the model anchors to the transcript content, not the framing. Slight shifts in emphasis (e.g. which themes are framed as primary) are acceptable.

**Failure signal:** the model invents themes that match the false context but don't appear in the transcript. If this happens, strengthen the "Basér ALL analyse utelukkende på innholdet" instruction in the prompt and add a counter-example to the analyseinstrukser section.

**Status:** *not yet run*

### Test 2 — Low-content transcript probe

**Purpose:** verify that the model under-produces rather than invents when material is thin.

**Method:**
1. Pick or construct a deliberately short transcript with only 2–3 genuinely distinct themes (5–10 minutes of material on a narrow topic).
2. Run the analysis.
3. Check whether the model produces 5–6 themes (filling the range) or 2–3 themes (matching the material).

**Acceptable behaviour:** the model produces 2–3 themes and the output is shorter than for a rich transcript. The range guidance in the prompt ("3–6, vurder å splitte hvis under 3") should bias toward fewer, more honest themes — not toward filling quota.

**Failure signal:** the model produces 5–6 themes by inventing or by splitting one real theme into artificial sub-themes. If this happens, add explicit "fewer themes is honest, padded themes is failure" guidance.

**Status:** *not yet run*

---

## Run log

> One row per analysis you've actually executed in the app. Keep it terse. Use the analysisId from the result detail view's header if you need to find the on-disk manifest later (`<dataRoot>/analyses/<id>/`).

| Date | Template | Version | Model | Interview (description, not name) | Top-line observation | Quote verifiability | Acceptable? |
|------|----------|---------|-------|-----------------------------------|----------------------|----------------------|-------------|
|  |  |  |  |  |  |  |  |

### Quote-verifiability check protocol

For each run logged above, spot-check at least 2 quotes manually in addition to the automated verification pass:

1. Pick a quote that "looks too good" — neatly framed, suspiciously articulate. Search for it verbatim in the transcript at the cited timestamp. Does it match exactly? Does the timestamp resolve to that moment in the audio if you scrub?
2. Pick a quote that includes a hesitation, repetition, or transcription marker like `(sukker)`. Did the LLM preserve the rough edges or smooth them out?

A single paraphrased quote that *passed* the automated verification pass means the substring check is too lenient — that's a finding about the verification pass, not the prompt. Note it in the issues list.

---

## Open issues

> Concrete failures observed in real runs. Format: short description, where you saw it, which template, what kind of fix you think might help.

- *(none logged yet — add as observed)*

### Issue template

```
- **<one-line title>**
  - Seen in: <run date, template version>
  - Observed: <what went wrong, with example>
  - Likely cause: <inference about which part of the prompt failed>
  - Possible fix: <change to try>
  - Status: open / testing / resolved
```

---

## Decisions

> Things you changed in the draft above and the reason. Append-only. Don't delete old decisions — supersede them with a newer entry if you reverse course.

### 2026-05-13 — v1 baseline established

- Draft re-seeded from `PromptTemplateLibrary.swift` `single-interview-themes` v1 body.
- v1 changes (vs. v0) summarized in the template's `single-interview-themes.md` revision log: timestamps replace paragraph indices; SPEAKER_XX handling added; Sammendrag prelude reintroduced; self-check folded into thinking-phase; range caps replace `Maks N`.
- Acceptance criteria reset to match `PROMPT_RESEARCH.md` §7.2 (verification-pass survival rather than 100% verbatim).
- Pre-validation tests (false-researchContext, low-content) added as a gate before the three-interview validation set.

### 2026-05-11 — v0 baseline (superseded)

- Initial draft. Iteration loop was observe-only; no prompt changes were made before v1 supersession.

---

## Next ideas to try

> Things you want to test but haven't yet. Pull from this list as you have time. When you do test one, move it to the run log + decisions.

- Test with `llama3.2:latest` instead of `qwen3:8b` to see how Norwegian quality compares at the same prompt. PROMPT_RESEARCH.md predicts qwen3 wins for multilingual but worth measuring once.
- Try removing the six-step Braun & Clarke scaffold in the thinking-phase guidance and see if output quality changes. Hypothesis: small models benefit from the scaffold; large models don't need it. Worth confirming on qwen3:8b specifically.
- Add a constraint: "every theme should be able to survive the question 'so what?'" — designed to push the model away from descriptive themes into interpretive ones.
- Probe whether the Sammendrag prelude leaks into the rest of the analysis (i.e. does the model fall into "summary tone" for themes after writing the Sammendrag?). If so, consider generating the Sammendrag as a separate Ollama call after the structured sections are produced.
- Test with a transcript where the interviewer is unusually leading (asks suggestive questions). Does the model attribute the interviewer's framings to the informant?

---

## Shipping a new version

When the draft is ready to become v2 (or vN):

1. Update `PromptTemplateLibrary.swift`: copy the new prompt body into the relevant static, bump `version: 1` → `version: 2` (or next integer).
2. Update the template's markdown spec under `templates/<id>.md`: append a `## Revision log` entry summarizing what changed and why.
3. Reset this doc:
   - Move all "Decisions" entries to the spec's revision log (or summarize them there) — git history retains the detail.
   - Clear "Current draft" and "Diff from bundled" (re-seed from the new bundled body).
   - Clear "Run log" (keep the latest one or two as a baseline reference if useful).
   - Reset "Active focus" to whatever's next, or note that this template is now stable.
4. Re-build and re-run at least one analysis end-to-end against a fresh interview to confirm the new version works.

The first time we do this round-trip we'll probably tighten the steps. Edit this checklist as the process matures.
