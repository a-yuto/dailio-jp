import Foundation

/// StoreKit 2 のプロダクト識別子。App Store Connect / Configuration.storekit と一致させる。
enum ProductIDs {
    static let monthly = "niki.kibun-log.pro.monthly"
    static let yearly = "niki.kibun-log.pro.yearly"
    static let lifetime = "niki.kibun-log.pro.lifetime"

    static let all: [String] = [monthly, yearly, lifetime]

    /// 表示順（月額 → 年額 → Lifetime）
    static let displayOrder: [String] = [monthly, yearly, lifetime]
}
