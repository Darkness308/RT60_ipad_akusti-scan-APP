// RT60Calculator.swift
// Consolidated RT60 calculation engine

import Foundation

/// Advanced RT60 calculation engine with DIN 18041 compliance
public class RT60Calculator {
    
    /// Calculate RT60 using Sabine formula
    public static func calculateRT60(volume: Double, absorptionArea: Double) -> Double {
        guard absorptionArea > 0 else { return 0.0 }
        let sabineConstant = 0.161 // For air at 20°C, 50% humidity
        return sabineConstant * volume / absorptionArea
    }
    
    /// Calculate total absorption area from surfaces and materials
    public static func totalAbsorptionArea(
        surfaceAreas: [Double], 
        absorptionCoefficients: [Double]
    ) -> Double {
        guard surfaceAreas.count == absorptionCoefficients.count else { return 0.0 }
        return zip(surfaceAreas, absorptionCoefficients)
            .map { $0 * $1 }
            .reduce(0, +)
    }
    
    /// Calculate RT60 for all standard frequencies
    public static func calculateFrequencySpectrum(
        volume: Double,
        surfaces: [AcousticSurface]
    ) -> [RT60Measurement] {
        let frequencies = [125, 250, 500, 1000, 2000, 4000, 8000]
        
        return frequencies.map { frequency in
            let totalAbsorption = surfaces.reduce(0.0) { total, surface in
                let coefficient = surface.material.absorptionCoefficient(at: frequency)
                return total + (surface.area * coefficient)
            }
            
            let rt60 = calculateRT60(volume: volume, absorptionArea: totalAbsorption)
            return RT60Measurement(frequency: frequency, rt60: rt60)
        }
    }
    
    /// Evaluate RT60 measurements against DIN 18041 targets
    public static func evaluateDINCompliance(
        measurements: [RT60Measurement],
        roomType: RoomType,
        volume: Double
    ) -> [RT60Deviation] {
        let targets = DIN18041Database.targets(for: roomType, volume: volume)
        
        return measurements.compactMap { measurement in
            guard let target = targets.first(where: { $0.frequency == measurement.frequency }) else {
                return nil
            }
            
            let diff = measurement.rt60 - target.targetRT60
            let status: EvaluationStatus
            
            if abs(diff) <= target.tolerance {
                status = .withinTolerance
            } else if diff > 0 {
                status = .tooHigh
            } else {
                status = .tooLow
            }
            
            return RT60Deviation(
                frequency: measurement.frequency,
                measuredRT60: measurement.rt60,
                targetRT60: target.targetRT60,
                status: status
            )
        }
    }
}

// Note: AcousticSurface and AcousticMaterial models have been moved to 
// dedicated files in the Models/ directory to avoid duplication.

/// DIN 18041 target database
public struct DIN18041Database {
    
    public struct Target {
        public let frequency: Int
        public let targetRT60: Double
        public let tolerance: Double
        
        public init(frequency: Int, targetRT60: Double, tolerance: Double) {
            self.frequency = frequency
            self.targetRT60 = targetRT60
            self.tolerance = tolerance
        }
    }
    
    /// Get DIN 18041 targets for specific room type and volume
    public static func targets(for roomType: RoomType, volume: Double) -> [Target] {
        switch roomType {
        case .classroom:
            return classroomTargets(volume: volume)
        case .officeSpace:
            return officeTargets(volume: volume)
        case .conference:
            return conferenceTargets(volume: volume)
        case .lecture:
            return lectureTargets(volume: volume)
        case .music:
            return musicTargets(volume: volume)
        case .sports:
            return sportsTargets(volume: volume)
        }
    }
    
    private static func classroomTargets(volume: Double) -> [Target] {
        // DIN 18041 targets for classrooms
        let baseRT60 = 0.6 // Base reverberation time for classrooms
        let tolerance = 0.1
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            var targetRT60 = baseRT60
            
            // Frequency-dependent adjustments
            if frequency <= 250 {
                targetRT60 *= 1.2 // Allow slightly higher RT60 at low frequencies
            } else if frequency >= 2000 {
                targetRT60 *= 0.8 // Require lower RT60 at high frequencies
            }
            
            return Target(frequency: frequency, targetRT60: targetRT60, tolerance: tolerance)
        }
    }
    
    private static func officeTargets(volume: Double) -> [Target] {
        let baseRT60 = 0.5
        let tolerance = 0.1
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
    
    private static func conferenceTargets(volume: Double) -> [Target] {
        let baseRT60 = 0.7
        let tolerance = 0.15
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
    
    private static func lectureTargets(volume: Double) -> [Target] {
        let baseRT60 = 0.8
        let tolerance = 0.15
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
    
    private static func musicTargets(volume: Double) -> [Target] {
        let baseRT60 = 1.5
        let tolerance = 0.2
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
    
    private static func sportsTargets(volume: Double) -> [Target] {
        let baseRT60 = 2.0
        let tolerance = 0.3
        
        return [125, 250, 500, 1000, 2000, 4000, 8000].map { frequency in
            Target(frequency: frequency, targetRT60: baseRT60, tolerance: tolerance)
        }
    }
}