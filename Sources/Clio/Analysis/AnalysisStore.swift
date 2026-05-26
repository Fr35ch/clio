// AnalysisStore.swift
// Clio
//
// CRUD over the per-analysis folder layout under `<dataRoot>/analyses/`.
// Mirrors the shape of `RecordingStore` but operates on `Analysis` manifests.
//
// Each analysis owns a folder containing manifest.json, optionally result.json
// (only after a successful run), and prompt.txt (the literal LLM input).

import Foundation

/// Errors thrown by `AnalysisStore`. Surfaced to the UI so the researcher
/// sees a real cause rather than a silent failure.
enum AnalysisStoreError: LocalizedError {
    case notFound(UUID)
    case write(underlying: Error)
    case decode(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .notFound(let id):
            return "Fant ikke analyse med id \(id.uuidString)"
        case .write(let err):
            return "Kunne ikke skrive analyse: \(err.localizedDescription)"
        case .decode(let err):
            return "Kunne ikke lese analyse: \(err.localizedDescription)"
        }
    }
}

/// Singleton CRUD facade for analyses on disk. Reads are O(N) over the
/// analyses directory; that's fine at expected scale (researchers run on
/// the order of tens of analyses, not thousands).
///
/// Conforms to `ObservableObject` so SwiftUI views can react to changes
/// without polling — every successful write bumps `changeToken`, and
/// observing views reload via `.onChange(of:)`.
final class AnalysisStore: ObservableObject {

    static let shared = AnalysisStore()

    private init() {}

    /// Monotonically increasing token bumped after any successful
    /// `save`, `create`, `delete`, or `saveResult`. Views observing the
    /// store can attach `.onChange(of: store.changeToken) { ... }` to
    /// trigger a reload.
    @Published private(set) var changeToken: Int = 0

    @MainActor
    private func bumpToken() {
        changeToken &+= 1
    }

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let resultEncoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        e.dateEncodingStrategy = .secondsSince1970
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()

    private let resultDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .secondsSince1970
        return d
    }()

    // MARK: - Manifest CRUD

    /// Writes a fresh manifest for the given analysis to disk. Creates the
    /// analysis folder if needed.
    @discardableResult
    func create(_ analysis: Analysis) throws -> Analysis {
        try ensureFolder(id: analysis.id)
        try save(analysis)
        return analysis
    }

    /// Saves an existing analysis (atomic write). Caller is responsible for
    /// having mutated it via `update` or holding a fresh in-memory copy.
    func save(_ analysis: Analysis) throws {
        try ensureFolder(id: analysis.id)
        let data: Data
        do {
            data = try encoder.encode(analysis)
        } catch {
            throw AnalysisStoreError.write(underlying: error)
        }
        do {
            try data.write(to: StorageLayout.analysisManifestURL(id: analysis.id), options: .atomic)
        } catch {
            throw AnalysisStoreError.write(underlying: error)
        }
        Task { @MainActor in bumpToken() }
    }

    /// Read-modify-write helper. Loads the current manifest, hands it to the
    /// transform closure (which may mutate freely), then writes it back.
    @discardableResult
    func update(id: UUID, _ transform: (inout Analysis) -> Void) throws -> Analysis {
        var current = try load(id: id)
        transform(&current)
        try save(current)
        return current
    }

    /// Loads a single manifest by id. Throws `.notFound` if the folder or
    /// manifest is missing.
    func load(id: UUID) throws -> Analysis {
        let url = StorageLayout.analysisManifestURL(id: id)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AnalysisStoreError.notFound(id)
        }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(Analysis.self, from: data)
        } catch {
            throw AnalysisStoreError.decode(underlying: error)
        }
    }

    /// Loads every analysis from disk, newest first by `createdAt`. Returns
    /// an empty array if the analyses root does not yet exist. Decode errors
    /// on individual manifests are skipped (logged) so one corrupt folder
    /// does not block the rest of the list.
    func loadAll() -> [Analysis] {
        let fm = FileManager.default
        let root = StorageLayout.analysesRoot
        guard fm.fileExists(atPath: root.path) else { return [] }
        guard let entries = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) else {
            return []
        }
        var results: [Analysis] = []
        for url in entries {
            guard
                let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory,
                isDir == true,
                let id = UUID(uuidString: url.lastPathComponent)
            else { continue }
            do {
                results.append(try load(id: id))
            } catch {
                print("⚠️ AnalysisStore: skipping unreadable analysis \(id.uuidString): \(error)")
            }
        }
        return results.sorted { $0.createdAt > $1.createdAt }
    }

    /// Removes the analysis folder and all its contents (manifest, result,
    /// prompt). Throws if the underlying delete fails for any reason other
    /// than "not found".
    func delete(id: UUID) throws {
        let folder = StorageLayout.analysisFolder(id: id)
        let fm = FileManager.default
        guard fm.fileExists(atPath: folder.path) else { return }
        do {
            try fm.removeItem(at: folder)
        } catch {
            throw AnalysisStoreError.write(underlying: error)
        }
        Task { @MainActor in bumpToken() }
    }

    // MARK: - Result / prompt sidecars

    /// Persists the LLM output for the given analysis. Uses snake_case +
    /// epoch-seconds Date encoding to match the wire format produced by
    /// `navt.py`, so a result written here is byte-compatible with one
    /// streamed from the subprocess.
    func saveResult(_ result: AnalysisResult, id: UUID) throws {
        try ensureFolder(id: id)
        let data: Data
        do {
            data = try resultEncoder.encode(result)
        } catch {
            throw AnalysisStoreError.write(underlying: error)
        }
        do {
            try data.write(to: StorageLayout.analysisResultURL(id: id), options: .atomic)
        } catch {
            throw AnalysisStoreError.write(underlying: error)
        }
        Task { @MainActor in bumpToken() }
    }

    /// Loads the LLM output for an analysis, or `nil` if the result has not
    /// been written yet (the analysis is still pending or failed before
    /// returning any output).
    func loadResult(id: UUID) -> AnalysisResult? {
        let url = StorageLayout.analysisResultURL(id: id)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? resultDecoder.decode(AnalysisResult.self, from: data)
    }

    /// Persists the literal prompt text that was sent to the LLM, so a
    /// researcher can later open `prompt.txt` to inspect or copy the input.
    /// Atomic write — partial files are not visible to readers.
    func savePrompt(_ prompt: String, id: UUID) throws {
        try ensureFolder(id: id)
        do {
            try prompt.write(to: StorageLayout.analysisPromptURL(id: id), atomically: true, encoding: .utf8)
        } catch {
            throw AnalysisStoreError.write(underlying: error)
        }
    }

    /// Loads the saved prompt text, or `nil` if it was never written.
    func loadPrompt(id: UUID) -> String? {
        try? String(contentsOf: StorageLayout.analysisPromptURL(id: id), encoding: .utf8)
    }

    // MARK: - Folder management

    private func ensureFolder(id: UUID) throws {
        let folder = StorageLayout.analysisFolder(id: id)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        } catch {
            throw AnalysisStoreError.write(underlying: error)
        }
    }
}
