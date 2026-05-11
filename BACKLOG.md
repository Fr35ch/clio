# Product Backlog

This document tracks planned features, ongoing investigations, and future work for the Virgin Project - Audio Recording Manager.

**Last Updated:** 2026-04-14
**Project Manager:** Claude Code

## PM Guidelines

**Model Usage:**
- PM tasks (documentation, backlog updates, changelog edits): Use **Haiku model** to reduce token costs
- Technical implementation tasks: Use appropriate model based on complexity
- Complex investigations or architecture decisions: Use Sonnet/Opus as needed

---

## Current Sprint

### 🟢 ACTIVE — File Management Architecture Pivot (Phase 0)

**Epic:** File Management & Teams Sync (revised)
**Priority:** High
**Status:** Planned and scoped — ready to build
**Decision:** [ADR-1014](docs/decisions/adr/ADR-1014-file-storage-architecture-pivot.md)
**Spec:** [docs/FILE_MANAGEMENT_AND_TEAMS_SYNC.md](docs/FILE_MANAGEMENT_AND_TEAMS_SYNC.md)
**Stories:** [docs/prd/file-management-teams-sync/USER_STORIES.md](docs/prd/file-management-teams-sync/USER_STORIES.md)
**Tasks:** [docs/prd/file-management-teams-sync/PHASE_0_TASKS.md](docs/prd/file-management-teams-sync/PHASE_0_TASKS.md)

Moves storage off the Desktop and into `~/Library/Application Support/`, switches to UUID-named recording folders with sidecar metadata, relocates the audit log, and introduces the Return Machine wipe flow. Phase 1 (Graph API upload to Teams/SharePoint) follows, blocked on Azure AD app registration.

**Parallel external-dependency tracks (kicked off 2026-04-14):**
- MDM sync exclusion for `~/Library/Application Support/AudioRecordingManager/` — mac-fleet admin
- FileVault mandate confirmation on library machines — NAV IT
- Azure AD / Entra ID app registration — NAV IT (long lead time, blocks Phase 1)

**Parallel research track:**
- Researcher discovery interviews — product owner conducting. Blocks Phase 2 (project concept, destination picker UX). See interview guide prepared in the planning conversation.

---

## Planned Features

### Phase 4: Network Controls Enhancement

**Status:** Backlog

#### Features
- [ ] Upload progress tracking
- [ ] Network enable/disable automation improvements
- [ ] Better visual feedback for network operations
- [ ] Upload verification

---

### Phase 5: File Verification & Security

**Status:** Backlog

#### Features
- [ ] Audio file integrity verification
- [ ] Audit logging for file operations
- [ ] Secure file deletion options
- [ ] Backup management

---

### Phase 6: UI/UX Design Review & Redesign

**Status:** Backlog
**Priority:** Medium

#### Objective
Review and redesign all UI components to align with NAV Design System (Aksel) for improved consistency, accessibility, and user experience.

#### Features
- [ ] Audit current UI components and design patterns
- [ ] Review NAV Design System documentation at nav.aksel.no
- [ ] Identify components that can be aligned with NAV design patterns
- [ ] Create UI component inventory
- [ ] Design mockups aligned with NAV design principles
- [ ] Implement redesigned components
- [ ] Update color scheme and typography to match NAV standards
- [ ] Improve accessibility (WCAG compliance)
- [ ] Test with researchers for usability

#### Resources
- NAV Design System: https://aksel.nav.no
- Current UI: SwiftUI-based macOS application

#### Benefits
- Improved visual consistency
- Better accessibility
- Professional, polished appearance
- Alignment with Norwegian design standards
- Enhanced user experience for researchers

---

## Research Needed

### Jojo Transcribe Audio Format Support
- [ ] Test WAV file support
- [ ] Test M4A file support
- [ ] Test AIFF file support
- [ ] Test MP3 file support
- [ ] Document optimal format for transcription quality

---

## Technical Debt

None currently tracked.

---

## Ideas / Future Considerations

- Integration with other transcription services
- Cloud backup options (with network controls)
- Multi-language support
- Voice command controls
- Batch transcription queue management

---

## Notes

**File Locations:**
- Audio storage: `~/Desktop/lydfiler`
- Jojo Transcribe: `/Applications/Jojo.app`

**Security Requirements:**
- Network isolation must be maintained during normal operation
- All file operations should work offline
- Administrator privileges required for network controls
