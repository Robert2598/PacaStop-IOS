//
//  MoneyFormatter.swift
//  PacaStop
//
//  Romanian number formatting: "." thousands, "," decimals → "1.131,42 lei" (§6.1).
//

import Foundation

nonisolated enum MoneyFormatter {
    /// Shared formatter configured for the Romanian convention, independent of device locale.
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = "."
        f.decimalSeparator = ","
        f.usesGroupingSeparator = true
        f.minimumIntegerDigits = 1
        return f
    }()

    /// Formats the number with the given decimals, e.g. `1131.42 → "1.131,42"`.
    /// Not thread-isolated but `NumberFormatter` isn't Sendable; all call sites are on the main actor.
    static func number(_ amount: Double, decimals: Int = 2) -> String {
        formatter.minimumFractionDigits = decimals
        formatter.maximumFractionDigits = decimals
        return formatter.string(from: NSNumber(value: amount)) ?? String(format: "%.\(decimals)f", amount)
    }

    /// Formats with the "lei" suffix, e.g. `"1.131,42 lei"`.
    static func lei(_ amount: Double, decimals: Int = 2) -> String {
        "\(number(amount, decimals: decimals)) lei"
    }

    /// Whole-lei string (no decimals), for big gut-punch numbers.
    static func leiWhole(_ amount: Double) -> String {
        lei(amount, decimals: 0)
    }
}
