
import Foundation

struct AcousticMaterial: Identifiable, Codable {
    let id: UUID
    var name: String
    var absorptionCoefficients: [Int: Double]

    init(name: String, absorptionCoefficients: [Int: Double]) {
        self.id = UUID()
        self.name = name
        self.absorptionCoefficients = absorptionCoefficients
    }
}
