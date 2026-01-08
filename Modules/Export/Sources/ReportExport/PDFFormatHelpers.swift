import Foundation

/// Helper utilities for formatting data in PDF reports
public struct PDFFormatHelpers {

    // MARK: - Number Formatting

    /// Formats a double value with 2 decimal places, returns "-" if nil or invalid
    /// - Parameter value: Optional double value
    /// - Returns: Formatted string or "-"
    public static func formattedDecimal(_ value: Double??) -> String {
        guard let inner = value, let actual = inner else { return "-" }
        // Check for invalid values (NaN, infinity)
        guard actual.isFinite && !actual.isNaN else { return "-" }
        return String(format: "%.2f", actual)
    }

    /// Formats a double value with custom decimal places, returns "-" if nil or invalid
    /// - Parameters:
    ///   - value: Optional double value
    ///   - decimalPlaces: Number of decimal places (default: 2)
    /// - Returns: Formatted string or "-"
    public static func formattedDecimal(_ value: Double?, decimalPlaces: Int = 2) -> String {
        guard let actual = value else { return "-" }
        guard actual.isFinite && !actual.isNaN else { return "-" }
        return String(format: "%.\(decimalPlaces)f", actual)
    }

    // MARK: - String Formatting

    /// Formats a string value, returns "-" if nil or empty after trimming
    /// - Parameter value: Optional string value
    /// - Returns: Trimmed string or "-"
    public static func formattedString(_ value: String?) -> String {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return "-"
        }
        return value
    }

    // MARK: - Generic Formatting

    /// Formats any value to a string, with special handling for numeric types
    /// - Parameter value: The value to format
    /// - Returns: Formatted string representation
    public static func formattedValue(_ value: Any) -> String {
        if let doubleValue = value as? Double {
            return formattedDecimal(doubleValue)
        } else if let intValue = value as? Int {
            return String(intValue)
        } else if let stringValue = value as? String {
            return formattedString(stringValue)
        } else if let boolValue = value as? Bool {
            return boolValue ? "true" : "false"
        } else {
            return String(describing: value)
        }
    }

    // MARK: - Date Formatting

    /// Formats a date string using German locale
    /// - Parameter dateString: Date string to format
    /// - Returns: Formatted date string or original if parsing fails
    public static func formattedDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "-" }

        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .long
            displayFormatter.locale = Locale(identifier: "de_DE")
            return displayFormatter.string(from: date)
        }

        return dateString
    }

    // MARK: - Measurement Formatting

    /// Formats frequency value with Hz unit
    /// - Parameter frequency: Frequency value in Hz
    /// - Returns: Formatted string with unit
    public static func formattedFrequency(_ frequency: Int) -> String {
        "\(frequency) Hz"
    }

    /// Formats RT60 time value with seconds unit
    /// - Parameter rt60: RT60 value in seconds
    /// - Returns: Formatted string with unit
    public static func formattedRT60(_ rt60: Double?) -> String {
        guard let rt60 = rt60 else { return "- s" }
        guard rt60.isFinite && !rt60.isNaN else { return "- s" }
        return String(format: "%.2f s", rt60)
    }

    /// Formats volume with cubic meters unit
    /// - Parameter volume: Volume in m³
    /// - Returns: Formatted string with unit
    public static func formattedVolume(_ volume: Double?) -> String {
        guard let volume = volume else { return "- m³" }
        guard volume.isFinite && !volume.isNaN else { return "- m³" }
        return String(format: "%.1f m³", volume)
    }

    /// Formats area with square meters unit
    /// - Parameter area: Area in m²
    /// - Returns: Formatted string with unit
    public static func formattedArea(_ area: Double?) -> String {
        guard let area = area else { return "- m²" }
        guard area.isFinite && !area.isNaN else { return "- m²" }
        return String(format: "%.1f m²", area)
    }
}
