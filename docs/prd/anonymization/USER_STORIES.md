# User Stories: De-identification (avidentifisering)

**Epic:** Transcript De-identification
**Date:** 2026-04-14 (terminology + exception list, 2026-05-11)
**Status:** Draft

> **Terminology note (added 2026-05-11):** the feature was originally named "anonymisering". Under GDPR, *anonymisation* means data is irreversibly stripped of identifiers and is no longer personal data. ARM does **not** do that — the audio file is retained on disk, and the recording could in principle be re-linked to a person. What we actually do is **avidentifisering** (de-identification): we remove direct identifiers while the underlying data remains personal data. UI strings have been updated to reflect this. Swift type names (`AnonymizationService`, `AnonymizationMeta`, etc.) and the audit event `transcriptAnonymized` are kept for backwards-compatibility with already-written audit logs; only user-visible strings flip to "avidentifisering". The user stories below use "avidentifisering" throughout; older log entries and code identifiers stay as "anonymization".

---

## US-A1: De-identify a transcript automatically

**As a** researcher,
**I want to** run automatic de-identification on my transcript,
**so that** direct identifiers (names, phone numbers, SSNs) are redacted before I share or upload the text.

### Acceptance Criteria
- [x] "Avidentifiser transkripsjon" button available when a transcript exists
- [x] Runs no-anonymizer Python library via subprocess bridge
- [x] Detects and redacts: person names (NAVN), phone numbers (TELEFON), SSNs (FØDSELSNUMMER), D-numbers (D-NUMMER), email addresses (EPOST), organizations (ORG), place names (STED)
- [x] Replaces identified entities with codes (e.g., P1, P2)
- [x] Result stored atomically to `StorageLayout.anonymizedTranscriptURL(id: recordingId)`
- [x] Metadata sidecar (`meta.json`) updated with `anonymization.completedAt` and `anonymization.stats`
- [x] Original transcript is never modified (immutability guarantee)
- [x] Timeout: 180 seconds
- [x] After the BERT pass returns, redactions whose original span matches any entry in the global exception list (US-A8) are dropped before persisting — `stats` reflects the post-exception counts, not the raw model output

---

## US-A2: Understand anonymization limitations before running

**As a** researcher,
**I want to** be informed about what automatic anonymization can and cannot detect,
**so that** I understand my responsibility to manually review the result.

### Acceptance Criteria
- [x] Informed consent modal shown before anonymization runs
- [x] Lists what IS detected (names, phone numbers, SSNs, email)
- [x] Lists what IS NOT detected (indirect identifiers, nicknames, geographic proximity, incomplete info)
- [x] Warning: "Automatisk anonymisering er ikke tilstrekkelig alene"
- [x] Checkbox: "Jeg forstår at teksten må kontrolleres manuelt" (must be checked to proceed)
- [x] Single modal (`AnonymizationModal`) presented from the transcript editor's avidentifisering sheet — the legacy "recording detail" + "transcript detail" surfaces have been consolidated into one entry point

---

## US-A3: Compare original and de-identified text

**As a** researcher,
**I want to** switch between the original and de-identified versions of my transcript,
**so that** I can verify that direct identifiers were correctly removed.

### Acceptance Criteria
- [x] Tab switcher inside `AnonymizationSectionView`: "Original" vs "Avidentifisert"
- [x] Both versions accessible from the same surface (no separate sheet / external file needed)
- [x] De-identified version shows redacted text inline (replacement codes visible)
- [x] De-identification date and statistics shown (e.g., "3 navn, 1 telefonnummer fjernet")
- [x] The active tab snaps to "Avidentifisert" automatically immediately after a fresh run, so the researcher sees the output first

---

## US-A4: Re-run anonymization

**As a** researcher,
**I want to** re-run anonymization on a transcript,
**so that** I can get updated results if the anonymization model has been improved.

### Acceptance Criteria
- [ ] "Kjør på nytt" button available after initial anonymization
- [ ] Re-run overwrites previous anonymized text in metadata
- [ ] Original transcript remains untouched
- [ ] New anonymization date and stats are recorded

---

## US-A5: See anonymization status across all transcripts

**As a** researcher,
**I want to** see at a glance which transcripts have been anonymized,
**so that** I know which ones are ready to share and which still need processing.

### Acceptance Criteria
- [x] Bibliotek table shows an **AVIDENT.** status chip per row: «Avid. ✓» (success) / «Påbegynt» (warning) / «Feilet» (danger) / «Ikke avid.» (neutral)
- [x] Status derived from `meta.anonymization.status` in the canonical sidecar (`Storage/RecordingMeta.swift`)
- [x] Status updates automatically when anonymization completes — `RecordingsManager` listens to `RecordingStore.didChangeNotification` and re-derives `RecordingStatusBundle`

**Implementation note:** the original design assumed a separate "Transcripts" tab with shield-vs-doc list icons. That tab was consolidated into Bibliotek (see file-management redesign 2026-05-11); the AVIDENT. chip column carries the same information at a glance.

---

## US-A6: Audit trail for anonymization

**As a** researcher (and for compliance),
**I want** all anonymization activity to be logged,
**so that** there is a traceable record for data protection compliance.

### Acceptance Criteria
- [ ] Audit log entry on every anonymization attempt (success or failure)
- [ ] Entry includes: timestamp, recording ID, action, stats (counts only, no text), processing time, outcome
- [ ] Logged via `AuditLogger` to `~/Library/Application Support/AudioRecordingManager/audit/audit-YYYY-MM.jsonl`
- [ ] Error details included for failed attempts
- [ ] Log never contains actual transcript text (privacy)

---

## US-A7: Anonymization check before upload

**As a** researcher,
**I want to** be reminded to check anonymization before uploading files to Teams,
**so that** I don't accidentally share files containing personal data.

### Acceptance Criteria
- [ ] Anonymization reminder dialog shown before any upload flow
- [ ] Checklist: remove names, contact info, ID numbers, health information
- [ ] Instruction to use codes (P1, P2) instead of names
- [ ] Must confirm checklist before proceeding to upload
- [ ] Files marked "not anonymized" show warning icon in file selection

**Note:** The pre-upload compliance acknowledgement gate is specified in [US-FM-15](../file-management-teams-sync/USER_STORIES.md#us-fm-15-i-confirm-compliance-requirements-before-my-first-upload). US-A7 covers the per-recording de-identification reminder; US-FM-15 covers the project-level compliance checklist. Both apply.

---

## US-A8: Maintain a global exception list

**As a** researcher,
**I want to** maintain a list of words and names that the automatic de-identification must **not** remove,
**so that** organisation names like «NAV», study-specific vocabulary, or proper nouns that aren't personal data stay intact in the output.

### Acceptance Criteria
- [x] Sheet titled "Unntak fra avidentifisering" reachable from a button at the top of `AnonymizationSectionView`
- [x] Add / remove single entries — flat list of strings, no categorisation (matching is case-insensitive exact-match on the redacted span)
- [x] List is **global** across all recordings — same exceptions apply to every transcript in the app, regardless of project
- [x] List persists across launches in `AppState.avidentExceptions` (`<dataRoot>/state/app.json`)
- [x] Duplicates are deduped on add (case-insensitive)
- [x] Each entry stripped of leading/trailing whitespace before saving
- [x] Changes take effect on the next de-identification run — never retroactively modifies an existing result
- [x] Audit event `transcriptAnonymized` payload includes `exceptionCount` so it's possible to tell from the audit log whether exceptions were in effect for a given run

### Out of scope
- Per-project or per-recording exception lists (deferred — see USER_STORIES.md design discussion 2026-05-11; researcher consensus was global is enough at MVP)
- Regex / pattern matching (rejected — researchers are not expected to write regex; word-level exact match is sufficient for the realistic exception use case)
- Categorisation (NAVN / STED / ORG buckets) — the post-processor doesn't care which category the redaction came from, so adding category UI would be ceremony with no functional benefit

---

## Priority Order

| Priority | Story | Status |
|----------|-------|--------|
| 1 | US-A1 | Done |
| 2 | US-A2 | Done |
| 3 | US-A3 | Done |
| 4 | US-A7 | Blocked on Phase 1 Teams uploader (Entra ID app registration) |
| 5 | US-A5 | Done |
| 6 | US-A6 | Done |
| 7 | US-A4 | Done |
| 8 | US-A8 | Done |
