import Foundation

// MARK: - Transcript Item

struct TranscriptItem: Identifiable, Equatable, Hashable {
    let id: UUID
    /// Human-readable label shown in the UI. Comes from the recording's
    /// `displayName` in the sidecar (Phase 0+) — no longer a filesystem
    /// filename.
    let filename: String
    /// Absolute path to `transcript.txt` inside the recording's folder.
    let path: String
    let date: Date
    let size: Int64
    /// UUID of the owning recording. Used to match back to `RecordingItem`
    /// without filename-stem coupling. Optional only for the rare case of a
    /// transcript whose owning recording cannot be resolved (should never
    /// happen with `RecordingStore`-sourced data).
    let recordingId: UUID?

    /// Filename without extension. Retained for code that still wants a
    /// stem-shaped string (e.g. legacy display paths). Phase 0+ matching
    /// should use `recordingId` instead.
    var stem: String {
        URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMM, HH:mm"
        return formatter.string(from: date)
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

// MARK: - Transcript Manager
//
// As of Phase 0 (ADR-1014), transcripts live inside per-recording folders
// at `~/Library/Application Support/AudioRecordingManager/recordings/<uuid>/transcript.txt`,
// Transcripts live inside per-recording UUID folders. This class is a thin adapter that
// surfaces the store's transcripts as `[TranscriptItem]` for the UI.
//
// Folder watching has been replaced by subscription to
// `RecordingStore.didChangeNotification`.
class TranscriptManager: ObservableObject {
    static let shared = TranscriptManager()

    @Published var transcripts: [TranscriptItem] = []

    private var changeObserver: NSObjectProtocol?
    private var reloadWorkItem: DispatchWorkItem?

    private init() {
        loadTranscripts()
        subscribeToStoreChanges()
    }

    deinit {
        if let token = changeObserver {
            NotificationCenter.default.removeObserver(token)
        }
    }

    private func subscribeToStoreChanges() {
        changeObserver = NotificationCenter.default.addObserver(
            forName: RecordingStore.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.loadTranscripts()
            }
            self?.reloadWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
        }
    }

    // MARK: - Load

    func loadTranscripts() {
        let metas = RecordingStore.shared.loadAll()
        var items: [TranscriptItem] = []

        for meta in metas {
            // Only include recordings whose transcript is on disk and done.
            guard meta.transcript.status == .done else { continue }
            let url = StorageLayout.recordingFolder(id: meta.id)
                .appendingPathComponent(meta.transcript.filename)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }

            let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
            let size = (attrs?[.size] as? Int64) ?? 0
            let date = (attrs?[.modificationDate] as? Date)
                ?? meta.transcript.completedAt
                ?? meta.createdAt

            items.append(
                TranscriptItem(
                    id: meta.id,
                    filename: meta.displayName,
                    path: url.path,
                    date: date,
                    size: size,
                    recordingId: meta.id
                )
            )
        }

        transcripts = items.sorted { $0.date > $1.date }
        print("📋 Loaded \(transcripts.count) transcripts from RecordingStore")
    }

    // MARK: - Delete

    /// Removes the transcript artifacts for a recording without touching
    /// the recording itself. The audio file stays on disk, the recording
    /// metadata stays — only:
    ///
    ///   - `transcript.txt` in the recording folder
    ///   - `transcript_anonymized.txt` in the recording folder (the
    ///     de-identified variant is meaningless once the source is gone)
    ///   - the cached `TranscriptionResult` JSON under
    ///     `~/Library/.../transcripts/<uuid>.json` (preserves
    ///     diarisation labels and word timestamps; stale after delete)
    ///
    /// …are removed, and the sidecar's `transcript` + `anonymization`
    /// blocks are reset so the recording reads as "not yet transcribed".
    /// The Transcripts list reloads via `RecordingStore.didChangeNotification`.
    func deleteTranscript(_ item: TranscriptItem) {
        let id = item.recordingId ?? item.id
        let fm = FileManager.default

        // 1. transcript.txt and transcript_anonymized.txt live inside
        //    the recording's UUID folder.
        let textURL = StorageLayout.transcriptURL(id: id)
        let anonURL = StorageLayout.anonymizedTranscriptURL(id: id)
        for url in [textURL, anonURL] where fm.fileExists(atPath: url.path) {
            do {
                try fm.removeItem(at: url)
            } catch {
                print("⚠️ Could not remove \(url.lastPathComponent): \(error)")
            }
        }

        // 2. Cached TranscriptionResult JSON in Application Support.
        let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let jsonURL = support.appendingPathComponent("AudioRecordingManager/transcripts/\(id.uuidString).json")
        if fm.fileExists(atPath: jsonURL.path) {
            try? fm.removeItem(at: jsonURL)
        }

        // 3. Reset the sidecar so the recording reads as "not transcribed".
        //    Anonymisation block resets too because it referenced a now-
        //    deleted source.
        do {
            _ = try RecordingStore.shared.updateMeta(id: id) { meta in
                meta.transcript = TranscriptMeta()
                meta.anonymization = AnonymizationMeta()
            }
        } catch {
            print("⚠️ Could not reset sidecar after transcript delete: \(error)")
        }

        print("🗑️ Deleted transcript artifacts for \(item.filename)")
    }
}
