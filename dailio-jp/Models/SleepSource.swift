import Foundation

enum SleepSource: String, Codable, CaseIterable, Sendable {
    case healthKit
    case manual
}
