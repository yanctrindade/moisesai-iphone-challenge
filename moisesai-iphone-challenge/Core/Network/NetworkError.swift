import Foundation

enum NetworkError: Error, LocalizedError, Sendable {
    case badURL
    case requestFailed(statusCode: Int)
    case decodingFailed(Error)
    case noConnection
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .badURL:
            "Invalid URL"
        case .requestFailed(let statusCode):
            "Request failed with status code \(statusCode)"
        case .decodingFailed:
            "Failed to decode response"
        case .noConnection:
            "No internet connection"
        case .unknown(let error):
            error.localizedDescription
        }
    }
}
