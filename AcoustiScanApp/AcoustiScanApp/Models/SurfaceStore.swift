//
//  SurfaceStore.swift
//  AcoustiScanApp
//
//  Store for managing room surfaces and their properties
//

import Foundation
import Combine

/// Surface information from room scanning
public struct Surface: Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var area: Double  // in m^2
    public var material: AcousticMaterial?

    public init(id: UUID = UUID(), name: String, area: Double, material: AcousticMaterial? = nil) {
        self.id = id
        self.name = name
        self.area = area
        self.material = material
    }
}

/// Manager for room surfaces detected from scanning
public class SurfaceStore: ObservableObject {

    /// Published array of detected surfaces
    @Published public var surfaces: [Surface] = []

    /// Room volume in m3
    @Published public var roomVolume: Double = 0.0

    /// Room name
    @Published public var roomName: String = NSLocalizedString(
        LocalizationKeys.unnamedRoom,
        comment: "Default room name"
    )

    /// Room dimensions (optional)
    @Published public var roomDimensions: (width: Double, height: Double, depth: Double)?

    /// Initialize empty store
    public init() {
        loadSurfaces()
    }

    /// Add a new surface
    /// - Parameter surface: Surface to add
    public func add(_ surface: Surface) {
        surfaces.append(surface)
        saveSurfaces()
    }

    /// Update an existing surface
    /// - Parameters:
    ///   - id: Surface ID
    ///   - material: New material to assign
    public func updateMaterial(for id: UUID, material: AcousticMaterial) {
        if let index = surfaces.firstIndex(where: { $0.id == id }) {
            surfaces[index].material = material
            saveSurfaces()
        }
    }

    /// Remove surfaces at indices
    /// - Parameter offsets: Index set of surfaces to remove
    public func remove(at offsets: IndexSet) {
        surfaces.remove(atOffsets: offsets)
        saveSurfaces()
    }

    /// Clear all surfaces
    public func clearAll() {
        surfaces.removeAll()
        roomVolume = 0.0
        roomName = NSLocalizedString(LocalizationKeys.unnamedRoom, comment: "Default room name")
        roomDimensions = nil
        saveSurfaces()
    }

    /// Total surface area
    public var totalArea: Double {
        return surfaces.reduce(0) { $0 + $1.area }
    }

    /// Calculate total absorption for a given frequency
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Total absorption in m^2 Sabine
    /// - Note: Converts Float coefficients to Double for calculation precision
    public func totalAbsorption(at frequency: Int) -> Double {
        return surfaces.reduce(0.0) { total, surface in
            guard let material = surface.material else { return total }
            // Convert Float to Double for higher precision calculations
            let coefficient = Double(material.absorptionCoefficient(at: frequency))
            return total + (surface.area * coefficient)
        }
    }

    /// Calculate RT60 using Sabine formula for a specific frequency
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: RT60 value in seconds, or nil if volume is zero
    public func calculateRT60(at frequency: Int) -> Double? {
        guard roomVolume > 0 else { return nil }
        let absorption = totalAbsorption(at: frequency)
        guard absorption > 0 else { return nil }

        // Sabine formula: RT60 = 0.161 * V / A
        return 0.161 * roomVolume / absorption
    }

    /// Calculate RT60 for all standard frequencies
    /// - Returns: Dictionary of frequency to RT60 value
    public func calculateRT60Spectrum() -> [Int: Double] {
        var spectrum: [Int: Double] = [:]
        for frequency in AbsorptionData.standardFrequencies {
            if let rt60 = calculateRT60(at: frequency) {
                spectrum[frequency] = rt60
            }
        }
        return spectrum
    }

    /// Check if all surfaces have materials assigned
    public var allSurfacesHaveMaterials: Bool {
        return !surfaces.isEmpty && surfaces.allSatisfy { $0.material != nil }
    }

    /// Progress of material assignment (0.0 to 1.0)
    public var materialAssignmentProgress: Double {
        guard !surfaces.isEmpty else { return 0.0 }
        let assignedCount = surfaces.filter { $0.material != nil }.count
        return Double(assignedCount) / Double(surfaces.count)
    }

    // MARK: - Persistence

    private func saveSurfaces() {
        let data = SurfaceStoreData(
            surfaces: surfaces,
            roomVolume: roomVolume,
            roomName: roomName,
            roomDimensions: roomDimensions
        )

        do {
            let encoded = try JSONEncoder().encode(data)
            UserDefaults.standard.set(encoded, forKey: "surfaceStore")
        } catch {
            ErrorLogger.log(
                error,
                context: "SurfaceStore.saveSurfaces",
                level: .error
            )
        }
    }

    private func loadSurfaces() {
        guard let data = UserDefaults.standard.data(forKey: "surfaceStore") else {
            return
        }

        do {
            let decoded = try JSONDecoder().decode(SurfaceStoreData.self, from: data)
            surfaces = decoded.surfaces
            roomVolume = decoded.roomVolume
            roomName = decoded.roomName
            roomDimensions = decoded.roomDimensions
        } catch {
            ErrorLogger.log(
                error,
                context: "SurfaceStore.loadSurfaces",
                level: .error
            )
        }
    }

    /// Helper struct for encoding/decoding
    private struct SurfaceStoreData: Codable {
        let surfaces: [Surface]
        let roomVolume: Double
        let roomName: String
        let roomDimensions: (width: Double, height: Double, depth: Double)?

        enum CodingKeys: String, CodingKey {
            case surfaces, roomVolume, roomName, dimensionWidth, dimensionHeight, dimensionDepth
        }

        init(
            surfaces: [Surface],
            roomVolume: Double,
            roomName: String,
            roomDimensions: (width: Double, height: Double, depth: Double)?
        ) {
            self.surfaces = surfaces
            self.roomVolume = roomVolume
            self.roomName = roomName
            self.roomDimensions = roomDimensions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            surfaces = try container.decode([Surface].self, forKey: .surfaces)
            roomVolume = try container.decode(Double.self, forKey: .roomVolume)
            roomName = try container.decode(String.self, forKey: .roomName)

            // Decode optional room dimensions - these are optional fields
            do {
                let width = try container.decode(Double.self, forKey: .dimensionWidth)
                let height = try container.decode(Double.self, forKey: .dimensionHeight)
                let depth = try container.decode(Double.self, forKey: .dimensionDepth)
                roomDimensions = (width, height, depth)
            } catch {
                // Room dimensions are optional - log as debug info only
                ErrorLogger.log(
                    message: "Room dimensions not found in stored data (this is acceptable for older data)",
                    context: "SurfaceStoreData.decode",
                    level: .debug
                )
                roomDimensions = nil
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(surfaces, forKey: .surfaces)
            try container.encode(roomVolume, forKey: .roomVolume)
            try container.encode(roomName, forKey: .roomName)

            if let dims = roomDimensions {
                try container.encode(dims.width, forKey: .dimensionWidth)
                try container.encode(dims.height, forKey: .dimensionHeight)
                try container.encode(dims.depth, forKey: .dimensionDepth)
            }
        }
    }
}
