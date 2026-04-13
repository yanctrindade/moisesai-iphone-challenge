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
            NSLocalizedString("error.badURL", comment: "")
        case .requestFailed(let statusCode):
            String(format: NSLocalizedString("error.requestFailed", comment: ""), statusCode)
        case .decodingFailed:
            NSLocalizedString("error.decodingFailed", comment: "")
        case .noConnection:
            NSLocalizedString("error.noConnection", comment: "")
        case .unknown(let error):
            error.localizedDescription
        }
    }
}
