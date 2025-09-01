
import Foundation

struct RT60Calculation {
    static func calculateRT60(volume: Double, absorptionArea: Double) -> Double {
        guard absorptionArea > 0 else { return 0.0 }
        let c = 0.161 // Sabine-Konstante für Luft bei 20°C, 50% rF
        return c * volume / absorptionArea
    }

    static func totalAbsorptionArea(surfaceAreas: [Double], absorptionCoefficients: [Double]) -> Double {
        guard surfaceAreas.count == absorptionCoefficients.count else { return 0.0 }
        return zip(surfaceAreas, absorptionCoefficients).map(*).reduce(0, +)
    }
}
