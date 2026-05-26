# Prompt research — LLM-assisted analysis of Norwegian qualitative interviews

**Status:** Phase C1 research note (revised 2026-05-13)
**Source for:** the four baseline prompt templates that ship with ARM, plus the in-app `PromptTemplate` data model that B4 will consume.

This note captures the literature review, the LLM-specific constraints we have to design around, and the rationale for each of the four ARM templates. It is a living document — refine it as we test templates against real NAV interview material.

---

## 1. Context

ARM analyses Norwegian-language interview transcripts produced by NB-Whisper. The default analysis runtime is **local Ollama** with `qwen3:8b` (configurable). Researchers may pick one transcript (single analysis) or several (group analysis). The model output should be useful to a NAV researcher writing up interview findings — not a final report.

Three constraints that the prompts have to live with:

- **Local 7–8B-class model.** No GPT-4-class power. Smaller models hallucinate more readily, struggle with latent meaning, and lose track over long contexts. Prompts must compensate with structure and explicit verification cues.
- **Norwegian Bokmål input.** Researcher-edited transcripts. We need to instruct the model explicitly to **respond in Bokmål**, and avoid English-language analysis bleed-through (a common failure mode when the model's training data is predominantly English).
- **No upstream prompt control.** Today the prompt lives in `navt.py` upstream; ARM has zero ability to A/B-test. Phase C2 moves the prompt into ARM so researchers can pick a template per study and we can iterate quickly.

## 2. Literature findings

Four substantive findings shape every template below.

### 2.1 Structured prompting beats zero-shot, materially

Multiple 2025–2026 studies on LLM-assisted thematic analysis (e.g. Vikan et al. 2026, the arXiv paper on prompt engineering for qualitative software-engineering research, and Naeem et al. 2025) converge on the same point: a structured prompt that walks through Braun & Clarke's reflexive thematic analysis (RTA) steps internally produces materially better output than a bare "summarize the themes of this transcript" prompt. The structure does the cognitive scaffolding the model can't do for itself.

Effective prompts in the literature include all of: a role definition, the research question, methodological grounding (RTA reference), explicit step-by-step instructions, output format spec, and an embedded self-check rubric. Average prompt length in the cited papers was 1,280–1,485 tokens — long, on purpose.

### 2.2 LLMs over-summarize and miss latent meaning

The single most cited weakness: LLMs produce descriptive summaries rather than interpreted, abstracted themes. They "stay too close to surface meaning" and miss the latent register where reflexive thematic analysis lives. **Mitigation in every ARM template:** explicit instruction to surface both *semantic* (what was said) and *latent* (what it implies) meaning, with the latent reading marked as inference rather than fact (the `(tolkning)` convention).

### 2.3 Hallucinated quotes are the most dangerous failure mode

The studies repeatedly flag quote hallucination: the LLM produces something that *looks* like a verbatim quote but has changed a word, truncated mid-sentence, or merged segments. For a NAV-grade research artifact, this is the worst possible failure — the researcher could publish a misattributed quote without realising it. **Mitigation:** require *exact* verbatim quotes anchored by `[mm:ss]` or `[tt:mm:ss]` timestamps from the NB-Whisper transcript, and in the result view (Phase B5) we surface a "verify this quote" affordance that scrubs the underlying audio to that timestamp.

### 2.4 LLM-generated codes are useful but over-fragment

Naeem et al. 2025: ChatGPT produced 51 keywords vs. 24 manual, and 16 codes vs. 6 manual — more granular, but also more redundant. Reviewers preferred LLM codes 61% of the time. The implication for ARM: don't ask the model to produce *as many* themes as possible. **Cap the count** (3–6 themes per single interview, 5–8 for group), and require a "redundant?" self-check. We considered also recommending hierarchical structure (theme + subtheme) — and rejected it for the MVP: at the 7–8B tier the count cap does the same anti-fragmentation work without complicating the parser and result view. Revisit if validation suggests otherwise.

## 3. Norwegian-language considerations

Three observations relevant to running qwen3:8b / llama3.2 on Norwegian transcripts:

- **Qwen3 explicitly supports Norwegian** as part of its 119-language coverage and outperforms Llama 3 multilingually at the 7–8B tier. Norwegian is one of the 21 target languages in the cited multilingual studies. So our default model choice is reasonable; users on llama3.2 will get noticeably weaker output for the same prompt.
- **No Norwegian-specific qualitative-analysis benchmark exists.** NorBench, NLEBench+NorGLM, and NorEval evaluate Norwegian language modelling broadly, but none test for the qualitative-analysis-of-interviews use case. We will validate templates empirically against real NAV interviews (see §7).
- **Prompts should be in Norwegian.** The model produces better Norwegian output when the instruction itself is in Norwegian, even if it could parse an English instruction. All four templates are written in Bokmål. The only structured output names that remain in English are the `AnalysisResult` field names in code (`keyThemes`, `keyQuotes` etc.) — these are not user-visible and not present in the prompts.

## 4. Prompt structure used by all ARM templates

### 4.1 Relationship to the functional spec v1.0

The functional spec for the analysis function (`ARM_Analysefunksjon_Spesifikasjon_v1.docx` §6.1) defined a system prompt with `/think`, role, rules, language requirement, etc. **This system prompt is superseded by the skeleton below as of Phase C2.** Going forward:

- **System prompt** sent to Ollama is reduced to `/think` plus a one-line role anchor. It does not contain analysis instructions, output format, or self-check rubrics.
- **User prompt** carries everything else: role definition (full), research context, transcripts, analysis instructions, output format, and self-check. The user prompt is what gets versioned per template.

This split makes templates fully self-contained and avoids the role/rules duplication that v1.0 would have produced. The functional spec remains authoritative for UI behaviour, file handling, audit logging, error handling, and the streaming-and-strip-`<think>` mechanism in section 7 of the spec — none of which is affected by this change.

### 4.2 Skeleton

Every ARM template wraps its template-specific body with the same six-section skeleton, regardless of which of the four it is. This makes it easier for researchers to read each other's custom prompts and lets us reuse the same parser on the output.

```
1. Rolle
   Du er en erfaren NAV-brukerforsker som gjennomfører refleksiv
   tematisk analyse i tråd med Braun & Clarke. Svar på norsk bokmål.

2. Forskningskontekst
   <{{researchContext}} — filled in by the composer; default placeholder
    text if the researcher doesn't supply one>

3. Kildemateriale
   <transcripts, each prefixed with a header "### Intervju N — <displayName>"
    so the model can cite by header. Even a single transcript gets the
    "### Intervju 1 — ..." header for citation consistency.>

   Notat om format på kildematerialet (always present):
   - Tidsstempler [tt:mm:ss] eller [mm:ss] som første element på hver
     replikk.
   - Eventuelle SPEAKER_XX-labels kommer fra automatisk talerseparering.

4. Analyseinstrukser
   Template-specific. The four templates differ here.

5. Krav til output
   - Bokmål.
   - Eksakte sitater med tidsstempel.
   - Marker latente tolkninger eksplisitt med «(tolkning)».
   - Format: ren markdown med eksakt seksjonsoverskriftene fra punkt 4.

6. Selvkontroll — gjennomføres i thinking-fasen før output formateres
   - Står alle sitater nøyaktig slik de finnes i kildematerialet?
   - Har hvert tidsstempel et reelt forankringspunkt i transkripsjonen?
   - Er hvert hovedfunn forankret i minst ett sitat?
   - Har du blandet semantiske observasjoner med latente tolkninger?
```

The skeleton is enforced in the composer (Phase C2). Custom researcher-authored prompts are wrapped with at least sections 1, 5, and 6, even if they only author section 4. Section 6 is positioned *in the thinking-phase frame* rather than as a post-output check — Qwen3 in thinking mode processes the rubric before producing output, so this placement matches actual model behaviour.

## 5. The four baseline templates

Each template ships as a JSON file under `Resources/PromptTemplates/` (Phase C2) and as a human-readable markdown spec under `docs/prd/analysis/templates/`. The markdown is the source of truth; the JSON is generated from it.

| Template | Kind | Version | Use case | Notes |
|----------|------|---------|----------|-------|
| [single-interview-themes](templates/single-interview-themes.md) | single | v1 | Default for a single interview. Replaces today's hardcoded prompt. | Includes a `Sammendrag` prelude per spec v1.0 §4.1; maps to a new optional `summary` field on `AnalysisResult`. |
| [group-cross-cutting-patterns](templates/group-cross-cutting-patterns.md) | group | v1 | Synthesis across multiple interviews. Identifies shared themes + divergent patterns. | New. Required for B7 group analysis. Composer must guard `num_ctx` budget. |
| [pain-points-and-frustrations](templates/pain-points-and-frustrations.md) | single or group | v1 | Focused extraction of negative experiences for service-quality work. | Heavier weighting on latent emotional register. Includes one-shot example for the three-layer model. |
| [opportunity-map](templates/opportunity-map.md) | single or group | v1 | Product / service-design oriented. Extracts opportunities with preconditions and target segments. | Most prescriptive output schema. Preconditions carry a category tag (teknisk/organisatorisk/juridisk). |

The choice of four was deliberate, not arbitrary:
- One **default** to replace what we have today (so day-one upgrade users get a strictly better experience).
- One **group** template (because group analysis is a core B7 capability and needs its own prompt that explicitly handles attribution across interviews).
- Two **focused** templates (pain-points, opportunities) that map to the two most common downstream research artifacts at NAV — service-improvement papers and product-opportunity decks. These also stress-test the prompt skeleton in different directions: emotional-register weighting and structured-output weighting respectively.

### 5.1 Sammendrag handling

The functional spec v1.0 §4.1 specified a 3–5 sentence Sammendrag prelude. Of the four templates, only `single-interview-themes` carries it forward:

- **single-interview-themes**: included. Researchers want an orienting paragraph before structured findings on a single interview.
- **group-cross-cutting-patterns**: not included. The "Felles mønstre" section already serves the synthesis-overview role; a Sammendrag on top would be redundant.
- **pain-points-and-frustrations**: not included. A neutral summary before a pain-focused enumeration would either pre-bias the framing or contradict the structure.
- **opportunity-map**: not included. The template is action-oriented; a narrative prelude works against the prescriptive output schema.

The `AnalysisResult` schema gains an optional `summary: String?` field. Templates that don't produce a Sammendrag leave it nil; the result view branches on presence.

## 6. Anti-hallucination machinery (cross-template)

Three technical measures sit outside the prompt itself:

1. **Quote-verification pass.** After the LLM returns, ARM scans the result for `"`-quoted strings of ≥ 8 words and substring-checks each against the source transcript(s) — anchored by the cited timestamp. Quotes that don't match are flagged in the result view (Phase B5) with a "ikke verifisert" warning, not silently displayed. Implementation lives next to the result loader, not in the prompt.

2. **Audio-anchored verification.** Because quotes are anchored with `[mm:ss]` timestamps, the B5 "verify this quote" affordance can scrub the underlying audio to that moment. Quote authenticity is verifiable against ground truth (audio), not only against transcript text. This is the strongest available defence against hallucinated quotes that happen to substring-match an unrelated part of the transcript.

3. **Transcript hashing.** Each `AnalysisSource` carries the SHA-256 of the transcript at run time (see `Sources/Clio/Analysis/TranscriptHash.swift`). If the researcher edits a transcript later, the result view shows a stale banner — the analysis was performed against a previous version. This won't catch LLM hallucinations against the version it saw, but it does guarantee the researcher knows when a previously-validated result is no longer attached to the current text.

## 7. Validation plan

Before any template leaves "draft" status, the following must hold:

### 7.1 Material

Each template is run against **at least three real NAV interviews** from prior studies (anonymized if necessary), covering:
- At least one short interview (~10 min).
- At least one long interview (~60 min).
- For group templates: at least one set with deliberate participant diversity (so divergences are testable).

### 7.2 Rating axes

The product owner reviews the output and rates on four axes:

- **Quote verifiability.** Of the quotes produced, what fraction pass the substring-against-transcript-at-cited-timestamp check? Target: ≥ 95% verifiable. Failures are auto-flagged in the result view, not silently displayed — so the gate is "verifiable rate", not "100% verbatim". The latter is aspirational with Qwen3:8b on long transcripts and would either be quietly relaxed or block shipping.
- **Latent vs. semantic balance.** Is there at least one latent reading per theme? Target: at least 50% of themes carry a `(tolkning)` line.
- **Theme redundancy.** Are themes meaningfully distinct? Target: no two themes share > 50% of their underlying quotes.
- **Norwegian fluency.** Is the output fluent Bokmål, not Norwegian-flavoured English? Target: no English content outside proper names from source material.

A template ships at v1 when all four axes are met across all three test runs. A single axis failure on a single run is grounds to iterate, not ship.

### 7.3 Rater scope

The product owner is the primary rater. As a guardrail against single-rater drift, at least one of the three runs per template should be cross-rated by a colleague from the insight team. Where the two raters disagree, the disagreement itself is the finding to investigate — usually it reveals a prompt instruction that the model interpreted differently than the spec intended.

### 7.4 Iteration loop

Failed templates iterate via `PROMPT_ITERATION.md`. The iteration journal captures runs, observed issues, decisions, and ideas-to-try. Templates that pass are flipped from `version: 0` (draft) to `version: 1` and committed as the shipping defaults.

Iteration history per template is captured in the template's markdown file under a `## Revision log` section.

## 8. Open questions parked for now

- **Per-interview attribution in group analyses.** When 5 interviews are synthesized, should the LLM say "mentioned in interviews 2 and 4" or only aggregate? Currently the group template asks for explicit attribution. We can drop this if the output becomes noisy.
- **Direct citation of the no-anonymizer'd variant.** If the researcher has run anonymization, should analysis prefer the anonymized transcript? Default for now: use whatever the researcher selects from the picker. The composer surface in B4 will show which variant is being passed.
- **Token-budget UI in composer.** The composer in B4 should estimate token consumption before a run and warn at >85% of `num_ctx`. Especially important for group analyses. Implementation, not prompt design — flagged here so the composer team has it.

(Previously parked but now resolved: **audio-anchored timestamps in quote citations** are part of v1; see §2.3 and §6.)

## Sources

Cited in the synthesis above:
- [Large Language Models in Thematic Analysis: Prompt Engineering, Evaluation, and Guidelines for Qualitative Software Engineering Research (arXiv 2510.18456, 2025)](https://arxiv.org/abs/2510.18456)
- [Reflecting on LLM Support in Reflexive Thematic Analysis (Vikan et al., Qualitative Health Research, 2026)](https://journals.sagepub.com/doi/10.1177/10497323251365211)
- [Thematic Analysis and Artificial Intelligence: A Step-by-Step Process for Using ChatGPT in Thematic Analysis (Naeem et al., 2025)](https://journals.sagepub.com/doi/10.1177/16094069251333886)
- [Inductive thematic analysis of healthcare qualitative interviews using open-source large language models (PubMed, 2024)](https://pubmed.ncbi.nlm.nih.gov/39067136/)
- [LATA: LLM-Assisted Thematic Analysis (Wang et al., CSCW 2025)](https://www.eecis.udel.edu/~mlm/docs/2025-Wang-CSCW-LATA-Paper.pdf)
- [Qwen3 Technical Report (arXiv 2505.09388, 2025)](https://arxiv.org/abs/2505.09388)
- [NorBench — A Benchmark for Norwegian Language Models (arXiv 2305.03880)](https://arxiv.org/abs/2305.03880)
- [NorEval: Norwegian Language Understanding and Generation (ACL 2025 Findings)](https://aclanthology.org/2025.findings-acl.181.pdf)

## Revision log

- **2026-05-13:** revised to v1 baseline. Documented spec-vs-template system prompt relationship (§4.1). Un-parked timestamp anchoring (now in §2.3 and §6). Acceptance criterion reformulated from "100% verbatim" to "≥ 95% verifiable against transcript at cited timestamp" (§7.2). Hierarchical-themes recommendation dropped — count cap does the work (§2.4). Inter-rater guardrail added to validation plan (§7.3). Sammendrag handling documented per template (§5.1). Token-budget UI flagged for B4 composer (§8).
- **2026-05-11:** initial Phase C1 note.
