//
//  MoneyCalculator.swift
//  PacaStop
//
//  "Ce-ți luai cu banii ăștia" (§6.5): count = floor(saved ÷ unit); show items
//  with count ≥ 1, richest first.
//

import Foundation

nonisolated struct AffordableItem: Identifiable, Equatable, Sendable {
    var item: SavingsItem
    var count: Int
    var id: SavingsItem.ID { item.id }
}

nonisolated enum MoneyCalculator {
    /// Concrete things the saved money equals, richest first, count ≥ 1 only.
    static func affordable(saved: Double) -> [AffordableItem] {
        SavingsItem.allCases
            .sorted { $0.unitPrice > $1.unitPrice }
            .compactMap { item in
                let count = Int((saved / item.unitPrice).rounded(.down))
                return count >= 1 ? AffordableItem(item: item, count: count) : nil
            }
    }
}
