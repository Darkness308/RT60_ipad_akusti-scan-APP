//
//  AuditTrail.swift
//  AcoustiScanApp
//
//  JSON Audit Trail for RT60 Measurements (US-7)
//

import Foundation

/// Audit trail entry for tracking measurements and changes
public struct AuditEntry: Codable, Identifiable {
    public let id: UUID
    public let timestamp: Date
    public let eventType: EventType
    public let details: [String: String]
    public let user: String?
    public let deviceInfo: DeviceInfo
    
    public enum EventType: String, Codable {
        case measurementStarted = "measurement_started"
        case measurementCompleted = "measurement_completed"
        case roomScanned = "room_scanned"
        case materialAssigned = "material_assigned"
        case surfaceAdded = "surface_added"
        case surfaceRemoved = "surface_removed"
        case reportGenerated = "report_generated"
        case dataExported = "data_exported"
        case dataImported = "data_imported"
        case settingsChanged = "settings_changed"
    }
    
    public struct DeviceInfo: Codable {
        public let model: String
        public let osVersion: String
        public let appVersion: String
        public let locale: String
        
        public init(model: String, osVersion: String, appVersion: String, locale: String) {
            self.model = model
            self.osVersion = osVersion
            self.appVersion = appVersion
            self.locale = locale
        }
        
        /// Get current device info
        public static func current(appVersion: String = "1.0.0") -> DeviceInfo {
            #if canImport(UIKit)
            import UIKit
            let model = UIDevice.current.model
            let osVersion = UIDevice.current.systemVersion
            #else
            let model = "Unknown"
            let osVersion = "Unknown"
            #endif
            
            let locale = Locale.current.identifier
            
            return DeviceInfo(
                model: model,
                osVersion: osVersion,
                appVersion: appVersion,
                locale: locale
            )
        }
    }
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        eventType: EventType,
        details: [String: String],
        user: String? = nil,
        deviceInfo: DeviceInfo
    ) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.details = details
        self.user = user
        self.deviceInfo = deviceInfo
    }
}

/// Manager for audit trail with JSON export
public class AuditTrailManager {
    
    private var entries: [AuditEntry] = []
    private let maxEntries: Int
    private let storageKey = "auditTrail"
    
    /// Initialize audit trail manager
    /// - Parameter maxEntries: Maximum number of entries to keep (default 1000)
    public init(maxEntries: Int = 1000) {
        self.maxEntries = maxEntries
        loadEntries()
    }
    
    /// Add a new audit entry
    /// - Parameters:
    ///   - eventType: Type of event
    ///   - details: Event details
    ///   - user: Optional user identifier
    public func log(
        eventType: AuditEntry.EventType,
        details: [String: String],
        user: String? = nil
    ) {
        let entry = AuditEntry(
            eventType: eventType,
            details: details,
            user: user,
            deviceInfo: AuditEntry.DeviceInfo.current()
        )
        
        entries.append(entry)
        
        // Keep only the most recent entries
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        
        saveEntries()
    }
    
    /// Get all audit entries
    public func getAllEntries() -> [AuditEntry] {
        return entries
    }
    
    /// Get entries for a specific event type
    /// - Parameter eventType: Event type to filter
    /// - Returns: Filtered entries
    public func getEntries(for eventType: AuditEntry.EventType) -> [AuditEntry] {
        return entries.filter { $0.eventType == eventType }
    }
    
    /// Get entries within a date range
    /// - Parameters:
    ///   - start: Start date
    ///   - end: End date
    /// - Returns: Filtered entries
    public func getEntries(from start: Date, to end: Date) -> [AuditEntry] {
        return entries.filter { $0.timestamp >= start && $0.timestamp <= end }
    }
    
    /// Export audit trail as JSON
    /// - Returns: JSON data
    public func exportJSON() -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        return try? encoder.encode(entries)
    }
    
    /// Export audit trail as JSON string
    /// - Returns: JSON string
    public func exportJSONString() -> String? {
        guard let data = exportJSON() else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    /// Import audit trail from JSON
    /// - Parameter jsonData: JSON data to import
    /// - Throws: Decoding error if JSON is invalid
    public func importJSON(_ jsonData: Data) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importedEntries = try decoder.decode([AuditEntry].self, from: jsonData)
        entries.append(contentsOf: importedEntries)
        
        // Keep only the most recent entries
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        
        saveEntries()
    }
    
    /// Clear all audit entries
    public func clearAll() {
        entries.removeAll()
        saveEntries()
    }
    
    /// Get audit trail statistics
    /// - Returns: Dictionary with statistics
    public func getStatistics() -> [String: Any] {
        let eventCounts = Dictionary(grouping: entries, by: { $0.eventType })
            .mapValues { $0.count }
        
        let oldestEntry = entries.first?.timestamp
        let newestEntry = entries.last?.timestamp
        
        return [
            "total_entries": entries.count,
            "event_counts": eventCounts.mapKeys { $0.rawValue },
            "oldest_entry": oldestEntry?.ISO8601Format() ?? "N/A",
            "newest_entry": newestEntry?.ISO8601Format() ?? "N/A",
            "device_models": Set(entries.map { $0.deviceInfo.model }).sorted()
        ]
    }
    
    // MARK: - Persistence
    
    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    private func loadEntries() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AuditEntry].self, from: data) {
            entries = decoded
        }
    }
}

// MARK: - Convenience Extensions

extension Dictionary {
    func mapKeys<T: Hashable>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
}

// MARK: - Integration Helpers

extension AuditTrailManager {
    
    /// Log a room scan event
    /// - Parameters:
    ///   - roomName: Name of the room
    ///   - volume: Room volume in m³
    ///   - surfaceCount: Number of surfaces detected
    public func logRoomScan(roomName: String, volume: Double, surfaceCount: Int) {
        log(
            eventType: .roomScanned,
            details: [
                "room_name": roomName,
                "volume_m3": String(format: "%.2f", volume),
                "surface_count": "\(surfaceCount)"
            ]
        )
    }
    
    /// Log an RT60 measurement
    /// - Parameters:
    ///   - roomName: Name of the room
    ///   - frequencies: Frequencies measured
    ///   - averageRT60: Average RT60 value
    public func logMeasurement(roomName: String, frequencies: [Int], averageRT60: Double) {
        log(
            eventType: .measurementCompleted,
            details: [
                "room_name": roomName,
                "frequencies": frequencies.map { "\($0)" }.joined(separator: ","),
                "average_rt60": String(format: "%.2f", averageRT60),
                "frequency_count": "\(frequencies.count)"
            ]
        )
    }
    
    /// Log material assignment
    /// - Parameters:
    ///   - surfaceName: Name of the surface
    ///   - materialName: Name of the material assigned
    public func logMaterialAssignment(surfaceName: String, materialName: String) {
        log(
            eventType: .materialAssigned,
            details: [
                "surface": surfaceName,
                "material": materialName
            ]
        )
    }
    
    /// Log PDF report generation
    /// - Parameters:
    ///   - roomName: Name of the room
    ///   - pageCount: Number of pages in report
    public func logReportGeneration(roomName: String, pageCount: Int) {
        log(
            eventType: .reportGenerated,
            details: [
                "room_name": roomName,
                "page_count": "\(pageCount)",
                "format": "PDF"
            ]
        )
    }
    
    /// Log data export
    /// - Parameters:
    ///   - format: Export format (CSV, XLSX, JSON)
    ///   - itemCount: Number of items exported
    public func logDataExport(format: String, itemCount: Int) {
        log(
            eventType: .dataExported,
            details: [
                "format": format,
                "item_count": "\(itemCount)"
            ]
        )
    }
}
