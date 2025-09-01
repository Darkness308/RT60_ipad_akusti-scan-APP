
import Foundation
import SwiftUI

struct LabeledSurface: Identifiable, Codable {
    let id: UUID
    var name: String
    var area: Double
    var absorptionCoefficient: Double
    var color: Color

    var absorptionArea: Double {
        return area * absorptionCoefficient
    }

    enum CodingKeys: String, CodingKey {
        case id, name, area, absorptionCoefficient, colorRed, colorGreen, colorBlue, colorOpacity
    }

    init(name: String, area: Double, absorptionCoefficient: Double, color: Color = .gray) {
        self.id = UUID()
        self.name = name
        self.area = area
        self.absorptionCoefficient = absorptionCoefficient
        self.color = color
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        area = try container.decode(Double.self, forKey: .area)
        absorptionCoefficient = try container.decode(Double.self, forKey: .absorptionCoefficient)

        let red = try container.decode(Double.self, forKey: .colorRed)
        let green = try container.decode(Double.self, forKey: .colorGreen)
        let blue = try container.decode(Double.self, forKey: .colorBlue)
        let opacity = try container.decode(Double.self, forKey: .colorOpacity)
        color = Color(red: red, green: green, blue: blue).opacity(opacity)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(area, forKey: .area)
        try container.encode(absorptionCoefficient, forKey: .absorptionCoefficient)

        // Statische Farbwerte als Platzhalter
        try container.encode(0.5, forKey: .colorRed)
        try container.encode(0.5, forKey: .colorGreen)
        try container.encode(0.5, forKey: .colorBlue)
        try container.encode(1.0, forKey: .colorOpacity)
    }
}
