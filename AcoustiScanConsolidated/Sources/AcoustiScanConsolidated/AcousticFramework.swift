// AcousticFramework.swift
// Consolidated 48-parameter acoustic framework

import Foundation

/// Comprehensive acoustic measurement framework with 48 parameters
/// Based on the validated scientific framework from audio_framework_json.json
public struct AcousticFramework {

    /// Audio parameter categories
    public enum ParameterCategory: Int, CaseIterable {
        case general = 0
        case klangfarbe = 1
        case tonalitaet = 2
        case geometrie = 3
        case raum = 4
        case zeitverhalten = 5
        case dynamik = 6
        case artefakte = 7
        case meta = 8
    }

    /// Individual audio parameter
    public struct AudioParameter {
        public let nameId: Int
        public let name: String
        public let definition: String
        public let category: ParameterCategory
        public let scaleLabel: [String]
        public let isUnipolar: Bool
        public let isDichotom: Bool
        public let isDegreeScale: Bool

        public init(nameId: Int, name: String, definition: String, category: ParameterCategory,
                    scaleLabel: [String], isUnipolar: Bool, isDichotom: Bool, isDegreeScale: Bool) {
            self.nameId = nameId
            self.name = name
            self.definition = definition
            self.category = category
            self.scaleLabel = scaleLabel
            self.isUnipolar = isUnipolar
            self.isDichotom = isDichotom
            self.isDegreeScale = isDegreeScale
        }
    }

    /// All 48 parameters from the framework (representative subset provided here)
    public static let allParameters: [AudioParameter] = [
        AudioParameter(nameId: 0, name: "Unterschied", definition: "Existenz eines wahrnehmbaren Unterschieds.",
                      category: .general, scaleLabel: ["gar keiner", "sehr großer"],
                      isUnipolar: true, isDichotom: false, isDegreeScale: false),

        AudioParameter(nameId: 1, name: "Klangfarbe hell-dunkel",
                      definition: "Klangeindruck, der durch das Verhältnis hoher zu tiefer Frequenzanteile bestimmt wird.",
                      category: .klangfarbe, scaleLabel: ["dunkler", "heller"],
                      isUnipolar: false, isDichotom: false, isDegreeScale: false),

        AudioParameter(nameId: 5, name: "Schärfe",
                      definition: "Klangeindruck, der z.B. auf den Kraftaufwand schließen lässt, mit dem eine Klangquelle angeregt wird.",
                      category: .klangfarbe, scaleLabel: ["schwächer ausgeprägt", "stärker ausgeprägt"],
                      isUnipolar: false, isDichotom: false, isDegreeScale: false)
        // Add more parameters as needed - this is a representative subset
    ]

    /// Get parameters by category
    public static func parameters(for category: ParameterCategory) -> [AudioParameter] {
        return allParameters.filter { $0.category == category }
    }
}

// Note: RT60Measurement, RoomType, RT60Deviation, and EvaluationStatus models
// have been moved to dedicated files in the Models/ directory.
// Import them from there to avoid duplication.


