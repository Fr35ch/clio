// OllamaAnalysisService.swift
// AudioRecordingManager
//
// Direct HTTP analysis path: takes a fully-rendered prompt + model, calls
// Ollama at `localhost:11434/api/generate`, and parses the response into
// an `AnalysisResult`. Bypasses `navt.py` for analysis — the prompt now
// lives in ARM (see `PromptTemplateLibrary`).
//
// The diarization + transcription pipeline continues to use `navt.py`;
// only the analyze step has been brought in-process. This means upstream
// Python changes are no longer required to iterate on analysis prompts.

import Foundation

// MARK: - Errors

enum OllamaAnalysisError: LocalizedError {
    case notInstalled
    case failedToStart
    case httpFailure(status: Int, body: String)
    case decodeFailure(String)
    case timeout
    case cancelled

    var errorDescription: String? {
        switch self {
        case .notInstalled:
            return "Ollama er ikke installert. Last ned fra ollama.com og prøv igjen."
        case .failedToStart:
            return "Ollama startet ikke innen tidsfristen. Start Ollama manuelt og prøv igjen."
        case .httpFailure(let status, let body):
            return "Ollama svarte HTTP \(status): \(body.prefix(300))"
        case .decodeFailure(let msg):
            return "Kunne ikke tolke svaret fra Ollama: \(msg)"
        case .timeout:
            return "Analysen tok lengre enn 10 minutter og ble avbrutt."
        case .cancelled:
            return "Analysen ble avbrutt."
        }
    }
}

// MARK: - HTTP wire types

/// Ollama `/api/generate` request payload. Only the fields we set.
private struct GenerateRequest: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
}

/// Ollama `/api/generate` non-streaming response. We ignore the timing
/// fields for now — could be surfaced as analysis runtime in the result
/// header in a future iteration.
private struct GenerateResponse: Decodable {
    let response: String
}

// MARK: - Service

final class OllamaAnalysisService {

    static let shared = OllamaAnalysisService()
    private init() {}

    /// Run an analysis end-to-end: ensure Ollama is up, POST the prompt,
    /// parse the markdown response into `AnalysisResult`. Throws on any
    /// failure with a Norwegian-localized `errorDescription`.
    func analyse(prompt: String, model: String) async throws -> AnalysisResult {
        guard OllamaManager.shared.isInstalled else {
            throw OllamaAnalysisError.notInstalled
        }
        if !OllamaManager.shared.isRunning() {
            OllamaManager.shared.startServer()
            if !OllamaManager.shared.waitUntilReady(timeout: 20) {
                throw OllamaAnalysisError.failedToStart
            }
        }

        let url = URL(string: "http://localhost:11434/api/generate")!
        var request = URLRequest(url: url, timeoutInterval: 600)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = GenerateRequest(model: model, prompt: prompt, stream: false)
        request.httpBody = try JSONEncoder().encode(body)

        let session = URLSession.shared
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            if Task.isCancelled { throw OllamaAnalysisError.cancelled }
            if (error as NSError).code == NSURLErrorTimedOut {
                throw OllamaAnalysisError.timeout
            }
            throw OllamaAnalysisError.decodeFailure(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw OllamaAnalysisError.decodeFailure("Manglet HTTP-respons")
        }
        guard http.statusCode == 200 else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "(uleselig)"
            throw OllamaAnalysisError.httpFailure(status: http.statusCode, body: bodyStr)
        }

        let decoded: GenerateResponse
        do {
            decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        } catch {
            throw OllamaAnalysisError.decodeFailure(error.localizedDescription)
        }

        return AnalysisResultParser.parse(markdown: decoded.response, model: model)
    }
}
