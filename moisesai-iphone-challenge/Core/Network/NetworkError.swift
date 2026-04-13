import Foundation

enum NetworkError: Error, LocalizedError, Sendable {
    case badURL
    case invalidResponse
    case requestFailed(statusCode: Int)
    case decodingFailed(String)
    case noConnection
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .badURL:
            NSLocalizedString("error.badURL", comment: "")
        case .invalidResponse:
            NSLocalizedString("error.invalidResponse", comment: "")
        case .requestFailed(let statusCode):
            String(format: NSLocalizedString("error.requestFailed", comment: ""), statusCode)
        case .decodingFailed:
            NSLocalizedString("error.decodingFailed", comment: "")
        case .noConnection:
            NSLocalizedString("error.noConnection", comment: "")
        case .unknown(let message):
            message
        }
    }
}
