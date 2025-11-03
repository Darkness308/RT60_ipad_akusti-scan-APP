// AcousticMaterial.swift
// Data model for acoustic materials and their absorption properties

import Foundation

/// Acoustic material with frequency-dependent absorption coefficients
///
/// This structure represents a building material with its acoustic absorption
/// properties across different frequency bands, used for RT60 calculations
/// and acoustic modeling according to ISO 354 and DIN EN 12354.
public struct AcousticMaterial: Identifiable, Codable, Equatable {

    /// Unique identifier for the material
    public let id: UUID

    /// Material name (e.g., "Gipskarton", "Teppichboden", "Akustikplatten")
    public var name: String

    /// Absorption coefficients by frequency band (Hz -> coefficient 0.0-1.0)
    /// Typical bands: 125, 250, 500, 1000, 2000, 4000 Hz
    public var absorptionCoefficients: [Int: Double]

    /// Initialize a new acoustic material
    /// - Parameters:
    ///   - name: Material name
    ///   - absorptionCoefficients: Frequency-dependent absorption coefficients
    public init(name: String, absorptionCoefficients: [Int: Double]) {
        self.id = UUID()
        self.name = name
        self.absorptionCoefficients = absorptionCoefficients
    }
    
copilot/fix-failing-job-54309431333



main
    /// Initialize with specific ID (for testing or known materials)
    /// - Parameters:
    ///   - id: Unique identifier
    ///   - name: Material name
    ///   - absorptionCoefficients: Frequency-dependent absorption coefficients
    public init(id: UUID, name: String, absorptionCoefficients: [Int: Double]) {
        self.id = id
        self.name = name
        self.absorptionCoefficients = absorptionCoefficients
    }

    /// Get absorption coefficient for a specific frequency
    /// - Parameter frequency: Frequency in Hz
    /// - Returns: Absorption coefficient (0.0-1.0) or 0.1 if not available (backward compatibility)
    public func absorptionCoefficient(at frequency: Int) -> Double {
        return absorptionCoefficients[frequency] ?? 0.1 // Default value for backward compatibility
    }

    /// Weighted average absorption coefficient across speech frequencies (500-2000 Hz)
    public var speechAbsorption: Double {
        let speechFrequencies = [500, 1000, 2000]
        let coefficients = speechFrequencies.compactMap { absorptionCoefficients[$0] }
        guard !coefficients.isEmpty else { return 0.0 }
        return coefficients.reduce(0, +) / Double(coefficients.count)
    }

    /// Check if material has complete absorption data for standard frequencies
    public var hasCompleteData: Bool {
        let standardFrequencies = [125, 250, 500, 1000, 2000, 4000]
        return standardFrequencies.allSatisfy { absorptionCoefficients[$0] != nil }
    }
}
