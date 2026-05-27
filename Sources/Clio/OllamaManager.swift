import Foundation

// MARK: - OllamaManager

/// Manages the lifecycle of a local Ollama server process.
/// Used by TranscriptionService to auto-start Ollama before analysis.
final class OllamaManager {
    static let shared = OllamaManager()
    private init() {}

    private var ollamaProcess: Process?

    /// Returns true if Ollama responds at localhost:11434.
    func isRunning() -> Bool {
        let url = URL(string: "http://localhost:11434")!
        var request = URLRequest(url: url, timeoutInterval: 2)
        request.httpMethod = "GET"
        var isUp = false
        let sem = DispatchSemaphore(value: 0)
        URLSession.shared.dataTask(with: request) { _, response, _ in
            isUp = (response as? HTTPURLResponse)?.statusCode == 200
            sem.signal()
        }.resume()
        sem.wait()
        return isUp
    }

    /// Path to the ollama binary, or nil if not installed.
    var ollamaBinaryPath: String? {
        let candidates = [
            "/opt/homebrew/bin/ollama",
            "/usr/local/bin/ollama",
            "/usr/bin/ollama",
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0) }
    }

    /// True if the ollama binary exists on disk.
    var isInstalled: Bool { ollamaBinaryPath != nil }

    /// Start ollama serve in background. Returns immediately; Ollama takes ~2s to be ready.
    func startServer() {
        guard let binary = ollamaBinaryPath else { return }
        guard !isRunning() else { return }
        let process = Process()
        process.launchPath = binary
        process.arguments = ["serve"]
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        try? process.run()
        ollamaProcess = process
    }

    /// Wait up to `timeout` seconds for Ollama to become available.
    /// Returns true if it came up within the deadline.
    func waitUntilReady(timeout: TimeInterval = 15) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if isRunning() { return true }
            Thread.sleep(forTimeInterval: 0.5)
        }
        return false
    }

    // MARK: - Model pull

    enum PullError: LocalizedError {
        case notInstalled
        case pullFailed(String)

        var errorDescription: String? {
            switch self {
            case .notInstalled:
                return "Ollama er ikke installert."
            case .pullFailed(let msg):
                return "Kunne ikke laste ned modellen: \(msg)"
            }
        }
    }

    /// Check whether a model is already available locally.
    /// Calls `ollama list` and scans output for the model ID.
    func isModelAvailable(_ modelId: String) -> Bool {
        guard let binary = ollamaBinaryPath else { return false }
        let process = Process()
        process.launchPath = binary
        process.arguments = ["list"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        try? process.run()
        process.waitUntilExit()
        let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        // Model names in `ollama list` output are colon-separated; do a simple substring check.
        return output.localizedCaseInsensitiveContains(modelId)
    }

    /// Pull a model from Ollama Hub (or HuggingFace via `hf.co/` prefix).
    /// Streams stderr lines to `onProgress`. Throws `PullError` on failure.
    /// Must be called off the main thread (uses synchronous Process).
    func pull(modelId: String, onProgress: @escaping (String) -> Void) throws {
        guard let binary = ollamaBinaryPath else {
            throw PullError.notInstalled
        }
        let process = Process()
        process.launchPath = binary
        process.arguments = ["pull", modelId]
        process.standardOutput = FileHandle.nullDevice

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty,
                  let line = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !line.isEmpty
            else { return }
            onProgress(line)
        }

        try process.run()
        process.waitUntilExit()
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        if process.terminationStatus != 0 {
            throw PullError.pullFailed("Prosessen avsluttet med kode \(process.terminationStatus)")
        }
    }
}
