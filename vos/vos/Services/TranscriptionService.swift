import Foundation

enum TranscriptionError: Error, LocalizedError {
  case invalidResponse
  case apiError(String)
  case networkError(Error)

  var errorDescription: String? {
    switch self {
    case .invalidResponse:
      return "Invalid API response"
    case .apiError(let message):
      return "API error: \(message)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    }
  }
}

class TranscriptionService {
  private let apiURL = "https://api.openai.com/v1/audio/transcriptions"
  private let model = "gpt-4o-transcribe"

  func transcribe(audioURL: URL, completion: @escaping (Result<String, Error>) -> Void) {
    // Get API key from settings
    guard let apiKey = SettingsManager.shared.getAPIKey() else {
      completion(
        .failure(TranscriptionError.apiError("No API key configured. Please add one in Settings.")))
      return
    }

    // Validate key format
    guard apiKey.hasPrefix("sk-") else {
      completion(
        .failure(TranscriptionError.apiError("Invalid API key format (must start with 'sk-')")))
      return
    }

    // Log for debugging (safe - only first/last chars)
    let preview = "\(apiKey.prefix(7))...\(apiKey.suffix(4))"
    print("✅ Using API key: \(preview) (length: \(apiKey.count))")

    // Create request
    guard let url = URL(string: apiURL) else {
      completion(.failure(TranscriptionError.invalidResponse))
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    print("🌐 Auth header length: \(7 + apiKey.count) (should be 171)")

    // Create multipart form data
    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue(
      "multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    do {
      request.httpBody = try createMultipartBody(
        boundary: boundary, audioURL: audioURL)
    } catch {
      completion(.failure(error))
      return
    }

    // Make request
    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        completion(.failure(TranscriptionError.networkError(error)))
        return
      }

      guard let data = data else {
        completion(.failure(TranscriptionError.invalidResponse))
        return
      }

      // Parse response
      do {
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
          if let text = json["text"] as? String {
            completion(.success(text))
          } else if let error = json["error"] as? [String: Any],
            let message = error["message"] as? String
          {
            completion(.failure(TranscriptionError.apiError(message)))
          } else {
            completion(.failure(TranscriptionError.invalidResponse))
          }
        } else {
          completion(.failure(TranscriptionError.invalidResponse))
        }
      } catch {
        completion(.failure(error))
      }
    }

    task.resume()
  }

  private func createMultipartBody(boundary: String, audioURL: URL) throws -> Data {
    var body = Data()

    // Add model parameter
    body.append(Data("--\(boundary)\r\n".utf8))
    body.append(Data("Content-Disposition: form-data; name=\"model\"\r\n\r\n".utf8))
    body.append(Data("\(model)\r\n".utf8))

    // Add file parameter
    let audioData = try Data(contentsOf: audioURL)
    body.append(Data("--\(boundary)\r\n".utf8))
    body.append(
      Data(
        "Content-Disposition: form-data; name=\"file\"; filename=\"audio.m4a\"\r\n".utf8))
    body.append(Data("Content-Type: audio/m4a\r\n\r\n".utf8))
    body.append(audioData)
    body.append(Data("\r\n".utf8))

    // Close boundary
    body.append(Data("--\(boundary)--\r\n".utf8))

    return body
  }
}
