# Prompt iteration — working journal

**Status:** active iteration log
**Owners:** product owner + Claude
**Last updated:** 2026-05-11

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
- **Started iterating:** 2026-05-11
- **Goal of this iteration:** validate v0 against real interviews; flip to v1 when output quality is acceptable, or change the prompt if not.
- **Acceptance criteria for v1 ship** (from `PROMPT_RESEARCH.md` §7):
  - 100% quote fidelity (verbatim, not paraphrased)
  - ≥ 1 latent reading per theme
  - No redundant themes
  - Fluent Bokmål throughout

---

## Current draft

> The prompt as it would land in `PromptTemplateLibrary.swift`. Start by pasting in the current bundled body, then edit in place. Add a `## Diff from bundled v0` section below when you've changed something nontrivial.

```text
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

### Diff from bundled v0

> Note here when this draft has diverged from what `PromptTemplateLibrary.swift` ships. Use brief bullet points; don't paste full before/after blocks — the git diff is the source of truth.

- *(no diff yet — this is verbatim v0)*

---

## Run log

> One row per analysis you've actually executed in the app. Keep it terse. Use the analysisId from the result detail view's header if you need to find the on-disk manifest later (`<dataRoot>/analyses/<id>/`).

| Date | Template | Version | Model | Interview (description, not name) | Top-line observation | Quote fidelity | Acceptable? |
|------|----------|---------|-------|-----------------------------------|----------------------|----------------|-------------|
| 2026-05-11 | single-interview-themes | v0 | qwen3:8b | First test run after build (placeholder) | _fill in_ | _verbatim ✔ / paraphrased ✘_ | yes / no / partial |
|  |  |  |  |  |  |  |  |

### Quote-fidelity check protocol

For each run logged above, spot-check at least 2 quotes:

1. Pick a quote that "looks too good" — neatly framed, suspiciously articulate. Search for it verbatim in the transcript. Does it match exactly?
2. Pick a quote that includes a hesitation, repetition, or interruption. Did the LLM preserve the rough edges or smooth them out?

A single paraphrased quote means the prompt is failing its core constraint. Note it in the issues list with the exact mismatch.

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

### 2026-05-11 — baseline established

- Draft seeded from `PromptTemplateLibrary.swift` `single-interview-themes-v1` body (currently version 0).
- Acceptance criteria pulled from `PROMPT_RESEARCH.md` §7.
- No prompt changes yet — first iteration loop is observe-only.

---

## Next ideas to try

> Things you want to test but haven't yet. Pull from this list as you have time. When you do test one, move it to the run log + decisions.

- Add an explicit "if uncertain, say so" instruction in the self-check section. The literature (Vikan et al. 2026) notes that LLMs over-claim confidence; an explicit out might surface uncertainty markers naturally.
- Test with `llama3.2:latest` instead of `qwen3:8b` to see how Norwegian quality compares at the same prompt. PROMPT_RESEARCH.md predicts qwen3 wins for multilingual but worth measuring.
- Test what happens when you set `{{researchContext}}` to something *false but plausible* — does the model still reason from the data, or does it bend to the false context?
- Try removing the six-phase Braun & Clarke walkthrough in section 4 and see if output quality changes. Hypothesis: small models benefit from the scaffold; large models don't need it. Worth confirming on qwen3:8b specifically.
- Add a constraint: "every theme should be able to survive the question 'so what?'" — designed to push the model away from descriptive themes into interpretive ones.

---

## Shipping a new version

When the draft is ready to become v1 (or vN):

1. Update `PromptTemplateLibrary.swift`: copy the new prompt body into the relevant static, bump `version: 0` → `version: 1` (or next integer).
2. Update the template's markdown spec under `templates/<id>.md`: append a `## Revision log` entry summarizing what changed and why.
3. Reset this doc:
   - Move all "Decisions" entries to the spec's revision log (or summarize them there) — git history retains the detail.
   - Clear "Current draft" and "Diff from bundled v0" (re-seed from the new bundled body).
   - Clear "Run log" (keep the latest one or two as a baseline reference if useful).
   - Reset "Active focus" to whatever's next, or note that this template is now stable.
4. Re-build and re-run at least one analysis end-to-end against a fresh interview to confirm the new version works.

The first time we do this round-trip we'll probably tighten the steps. Edit this checklist as the process matures.
