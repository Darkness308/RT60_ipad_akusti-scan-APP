// RT60Evaluator.swift  
// RT60 evaluation engine for DIN 18041 compliance

import Foundation

/// RT60-Bewertungsengine für DIN 18041 Konformität
public class RT60Evaluator {
    
    /// Bewertet RT60-Messungen gegen DIN 18041 Sollwerte
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
            
            return RT60Deviation(
                frequency: measurement.frequency,
                measuredRT60: measurement.rt60,
                targetRT60: target.targetRT60,
                tolerance: target.tolerance
            )
        }
    }
    
    /// Erstellt eine Gesamt-Bewertung der RT60-Messungen
    public static func createOverallEvaluation(
        deviations: [RT60Deviation]
    ) -> OverallEvaluation {
        guard !deviations.isEmpty else {
            return OverallEvaluation(
                totalMeasurements: 0,
                withinTolerance: 0,
                tooHigh: 0,
                tooLow: 0,
                overallStatus: .failed,
                averageDeviation: 0.0
            )
        }
        
        let withinTolerance = deviations.filter { $0.status == .withinTolerance }.count
        let tooHigh = deviations.filter { $0.status == .tooHigh }.count
        let tooLow = deviations.filter { $0.status == .tooLow }.count
        
        let averageDeviation = deviations.reduce(0.0) { sum, deviation in
            sum + abs(deviation.relativeDeviation)
        } / Double(deviations.count)
        
        let overallStatus: OverallEvaluationStatus
        if withinTolerance == deviations.count {
            overallStatus = .excellent
        } else if Double(withinTolerance) / Double(deviations.count) >= 0.8 {
            overallStatus = .good
        } else if Double(withinTolerance) / Double(deviations.count) >= 0.6 {
            overallStatus = .acceptable
        } else {
            overallStatus = .failed
        }
        
        return OverallEvaluation(
            totalMeasurements: deviations.count,
            withinTolerance: withinTolerance,
            tooHigh: tooHigh,
            tooLow: tooLow,
            overallStatus: overallStatus,
            averageDeviation: averageDeviation
        )
    }
    
    /// Erstellt Empfehlungen basierend auf RT60-Abweichungen
    public static func generateRecommendations(
        deviations: [RT60Deviation],
        roomType: RoomType
    ) -> [AcousticRecommendation] {
        var recommendations: [AcousticRecommendation] = []
        
        let highFrequencyDeviations = deviations.filter { 
            $0.frequency >= 1000 && $0.status == .tooHigh 
        }
        let lowFrequencyDeviations = deviations.filter { 
            $0.frequency <= 500 && $0.status == .tooHigh 
        }
        
        if !highFrequencyDeviations.isEmpty {
            recommendations.append(
                AcousticRecommendation(
                    type: .absorptionIncrease,
                    priority: .high,
                    description: "Hochfrequente RT60-Werte zu hoch. Zusätzliche schallabsorbierende Materialien empfohlen.",
                    affectedFrequencies: highFrequencyDeviations.map { $0.frequency }
                )
            )
        }
        
        if !lowFrequencyDeviations.isEmpty {
            recommendations.append(
                AcousticRecommendation(
                    type: .bassTraps,
                    priority: .medium,
                    description: "Tieffrequente RT60-Werte zu hoch. Bass-Fallen oder dickere Absorber empfohlen.",
                    affectedFrequencies: lowFrequencyDeviations.map { $0.frequency }
                )
            )
        }
        
        let tooLowDeviations = deviations.filter { $0.status == .tooLow }
        if !tooLowDeviations.isEmpty {
            recommendations.append(
                AcousticRecommendation(
                    type: .absorptionReduction,
                    priority: .medium,
                    description: "RT60-Werte zu niedrig. Reduzierung der Schallabsorption oder Hinzufügung reflektierender Oberflächen.",
                    affectedFrequencies: tooLowDeviations.map { $0.frequency }
                )
            )
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

/// Gesamt-Bewertung der RT60-Messungen
public struct OverallEvaluation {
    public let totalMeasurements: Int
    public let withinTolerance: Int
    public let tooHigh: Int
    public let tooLow: Int
    public let overallStatus: OverallEvaluationStatus
    public let averageDeviation: Double
    
    /// Prozentsatz der Messungen innerhalb der Toleranz
    public var compliancePercentage: Double {
        guard totalMeasurements > 0 else { return 0.0 }
        return Double(withinTolerance) / Double(totalMeasurements) * 100.0
    }
}

/// Status der Gesamt-Bewertung
public enum OverallEvaluationStatus: String, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case acceptable = "acceptable"
    case failed = "failed"
    
    /// Deutsche Bezeichnung
    public var germanName: String {
        switch self {
        case .excellent:
            return "Ausgezeichnet"
        case .good:
            return "Gut"
        case .acceptable:
            return "Akzeptabel"
        case .failed:
            return "Ungenügend"
        }
    }
    
    /// Emoji-Symbol
    public var emoji: String {
        switch self {
        case .excellent:
            return "🟢"
        case .good:
            return "🟡"
        case .acceptable:
            return "🟠"
        case .failed:
            return "🔴"
        }
    }
}

/// Akustische Empfehlung
public struct AcousticRecommendation {
    public let type: RecommendationType
    public let priority: Priority
    public let description: String
    public let affectedFrequencies: [Int]
    
    public init(type: RecommendationType, priority: Priority, description: String, affectedFrequencies: [Int]) {
        self.type = type
        self.priority = priority
        self.description = description
        self.affectedFrequencies = affectedFrequencies
    }
}

/// Typ der akustischen Empfehlung
public enum RecommendationType: String, CaseIterable {
    case absorptionIncrease = "absorption_increase"
    case absorptionReduction = "absorption_reduction"
    case bassTraps = "bass_traps"
    case diffusion = "diffusion"
    case reflection = "reflection"
    
    public var germanName: String {
        switch self {
        case .absorptionIncrease:
            return "Absorption erhöhen"
        case .absorptionReduction:
            return "Absorption reduzieren"
        case .bassTraps:
            return "Bass-Fallen"
        case .diffusion:
            return "Schallstreuung"
        case .reflection:
            return "Schallreflexion"
        }
    }
}

/// Priorität der Empfehlung
public enum Priority: String, CaseIterable {
    case high = "high"
    case medium = "medium" 
    case low = "low"
    
    public var germanName: String {
        switch self {
        case .high:
            return "Hoch"
        case .medium:
            return "Mittel"
        case .low:
            return "Niedrig"
        }
    }
}