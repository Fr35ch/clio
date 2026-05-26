# Prompt research — LLM-assisted analysis of Norwegian qualitative interviews

**Status:** Phase C1 research note (2026-05-11)
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

The single most cited weakness: LLMs produce descriptive summaries rather than interpreted, abstracted themes. They "stay too close to surface meaning" and miss the latent register where reflexive thematic analysis lives. **Mitigation in every ARM template:** explicit instruction to surface both *semantic* (what was said) and *latent* (what it implies) meaning, with the latent reading marked as inference rather than fact.

### 2.3 Hallucinated quotes are the most dangerous failure mode

The studies repeatedly flag quote hallucination: the LLM produces something that *looks* like a verbatim quote but has changed a word, truncated mid-sentence, or merged segments. For a NAV-grade research artifact, this is the worst possible failure — the researcher could publish a misattributed quote without realizing it. **Mitigation:** require *exact* verbatim quotes, demand the model include the source recording's `displayName` and a paragraph index, and in the result view (Phase B5) we surface a "verify this quote" affordance.

### 2.4 LLM-generated codes are useful but over-fragment

Naeem et al. 2025: ChatGPT produced 51 keywords vs. 24 manual, and 16 codes vs. 6 manual — more granular, but also more redundant. Reviewers preferred LLM codes 61% of the time. The implication for ARM: don't ask the model to produce *as many* themes as possible. Cap the count (4–6 themes per single interview, 5–8 for group), require a "redundant?" self-check, and prefer hierarchical structure (theme + subtheme) over flat lists.

## 3. Norwegian-language considerations

Three observations relevant to running qwen3:8b / llama3.2 on Norwegian transcripts:

- **Qwen3 explicitly supports Norwegian** as part of its 119-language coverage and outperforms Llama 3 multilingually at the 7–8B tier. Norwegian is one of the 21 target languages in the cited multilingual studies. So our default model choice is reasonable; users on llama3.2 will get noticeably weaker output for the same prompt.
- **No Norwegian-specific qualitative-analysis benchmark exists.** NorBench, NLEBench+NorGLM, and NorEval evaluate Norwegian language modelling broadly, but none test for the qualitative-analysis-of-interviews use case. We will validate templates empirically against real NAV interviews (see §5).
- **Prompts should be in Norwegian.** The model produces better Norwegian output when the instruction itself is in Norwegian, even if it could parse an English instruction. All four templates are written in Bokmål. The few English-tagged section headers in the output schema are kept English-tagged on purpose because those tags map cleanly to `AnalysisResult` fields (e.g. `key_themes`, `key_quotes`) and are not user-visible.

## 4. Prompt structure used by all ARM templates

Every ARM template follows the same skeleton, regardless of which of the four it is. This makes it easier for researchers to read each other's custom prompts and lets us reuse the same parser on the output.

```
1. Rolle
   You are a senior NAV researcher conducting reflexive thematic analysis
   in the Braun & Clarke tradition. Respond in Bokmål.

2. Forskningskontekst
   <{{researchContext}} — filled in by the composer; default placeholder text
    if the researcher doesn't supply one>

3. Kildemateriale
   <transcripts, each prefixed with a header "### Intervju N — <displayName>"
    so the model can cite by header>

4. Analyseinstrukser
   Template-specific. The four templates differ here.

5. Krav til output
   - Bokmål.
   - Eksakte sitater. Du må ikke parafrasere. Hver sitat-rad skal inneholde
     intervju-header og avsnittsindeks.
   - Markér latente tolkninger eksplisitt med «(tolkning)» foran utsagnet.
   - Maks <N> hovedfunn. Slå sammen overlappende funn.
   - Format: ren markdown med eksakt disse seksjonene: <list>.

6. Selvkontroll før du svarer
   - Står alle sitater nøyaktig slik de finnes i kildematerialet? Hvis ikke,
     fjern dem.
   - Er hvert hovedfunn forankret i minst ett sitat fra kildematerialet?
     Hvis ikke, fjern eller flytt til en lavere prioritet.
   - Har du blandet semantiske observasjoner med latente tolkninger?
     Marker latente med «(tolkning)».
```

This skeleton is enforced in code (see §6) so any custom prompt the researcher writes is wrapped with at least sections 1, 5, and 6, even if they only edit section 4.

## 5. The four baseline templates

Each template ships as a JSON file under `Resources/PromptTemplates/` (Phase C2) and as a human-readable markdown spec under `docs/prd/analysis/templates/`. The markdown is the source of truth; the JSON is generated from it.

| Template | Kind | Use case | Notes |
|----------|------|----------|-------|
| [single-interview-themes](templates/single-interview-themes.md) | single | Default for a single interview. Replaces today's hardcoded prompt. | Replaces the current `navt.py` prompt. Output maps to existing `AnalysisResult` fields. |
| [group-cross-cutting-patterns](templates/group-cross-cutting-patterns.md) | group | Synthesis across multiple interviews. Identifies shared themes + divergent patterns. | New. Required for B7 group analysis. |
| [pain-points-and-frustrations](templates/pain-points-and-frustrations.md) | single or group | Focused extraction of negative experiences for service-quality work. | Heavier weighting on latent emotional register. |
| [opportunity-map](templates/opportunity-map.md) | single or group | Product / service-design oriented. Extracts opportunities with preconditions and target segments. | Most prescriptive output schema. |

The choice of four was deliberate, not arbitrary:
- One **default** to replace what we have today (so day-one upgrade users get a strictly better experience).
- One **group** template (because group analysis is a core B7 capability and needs its own prompt that explicitly handles attribution across interviews).
- Two **focused** templates (pain-points, opportunities) that map to the two most common downstream research artifacts at NAV — service-improvement papers and product-opportunity decks. These also stress-test the prompt skeleton in different directions: emotional-register weighting and structured-output weighting respectively.

## 6. Anti-hallucination machinery (cross-template)

Two technical measures sit outside the prompt itself:

1. **Quote-verification pass.** After the LLM returns, ARM scans the result for `"`-quoted strings of ≥ 8 words and substring-checks each against the source transcript(s). Quotes that don't match are flagged in the result view (Phase B5) with a "ikke verifisert" warning, not silently displayed. Implementation lives next to the result loader, not in the prompt.

2. **Transcript hashing.** Each `AnalysisSource` carries the SHA-256 of the transcript at run time (see `Sources/Clio/Analysis/TranscriptHash.swift`). If the researcher edits a transcript later, the result view shows a stale banner — the analysis was performed against a previous version. This won't catch LLM hallucinations against the version it saw, but it does guarantee the researcher knows when a previously-validated result is no longer attached to the current text.

## 7. Validation plan

Before any template leaves "draft" status:

1. Run each template against **at least three real NAV interviews** from prior studies (anonymized if necessary), with at least one short (~10 min) and one long (~60 min) interview each.
2. The product owner reviews the output and rates:
   - **Quote fidelity** (verbatim ✔ / paraphrased ✘) — must be 100% verbatim or the prompt needs strengthening.
   - **Latent vs. semantic balance** (is there at least one latent reading per theme?).
   - **Theme redundancy** (are themes meaningfully distinct?).
   - **Norwegian fluency** (is the output fluent Bokmål, not Norwegian-flavoured English?).
3. Failed templates iterate until a clean run.
4. Templates that pass are flipped from `version: 0` (draft) to `version: 1` and committed as the shipping defaults.

Iteration history per template is captured in the template's markdown file under a `## Revision log` section.

## 8. Open questions parked for now

- **Per-interview attribution in group analyses.** When 5 interviews are synthesized, should the LLM say "mentioned in interviews 2 and 4" or only aggregate? Currently the group template asks for explicit attribution. We can drop this if the output becomes noisy.
- **Direct citation of the no-anonymizer'd variant.** If the researcher has run anonymization, should analysis prefer the anonymized transcript? Default for now: use whatever the researcher selects from the picker. The composer surface in B4 will show which variant is being passed.
- **Word-level grounding to audio.** Each NB-Whisper segment has timestamps. We could ask the LLM to also include a `[mm:ss]` after each quote so the researcher can jump straight to the audio. Out of scope for C1; revisit if researcher feedback asks for it.

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
