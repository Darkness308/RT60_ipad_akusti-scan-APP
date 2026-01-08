// AcousticFramework.swift
// Consolidated 48-parameter acoustic framework
// Based on validated scientific framework for audio perception research

import Foundation

/// Comprehensive acoustic measurement framework with 48 parameters
/// Based on the validated scientific framework from audio_framework_json.json
public struct AcousticFramework {

    /// Audio parameter categories
    public enum ParameterCategory: Int, CaseIterable, Codable {
        case general = 0        // Allgemein
        case klangfarbe = 1     // Timbre/Color
        case tonalitaet = 2     // Tonality
        case geometrie = 3      // Geometry
        case raum = 4           // Room/Space
        case zeitverhalten = 5  // Temporal behavior
        case dynamik = 6        // Dynamics
        case artefakte = 7      // Artifacts
        case meta = 8           // Meta/Overall

        public var displayName: String {
            switch self {
            case .general: return "Allgemein"
            case .klangfarbe: return "Klangfarbe"
            case .tonalitaet: return "Tonalität"
            case .geometrie: return "Geometrie"
            case .raum: return "Raum"
            case .zeitverhalten: return "Zeitverhalten"
            case .dynamik: return "Dynamik"
            case .artefakte: return "Artefakte"
            case .meta: return "Meta"
            }
        }
    }

    /// Individual audio parameter
    public struct AudioParameter: Identifiable, Codable {
        public let id: Int
        public let nameId: Int
        public let name: String
        public let definition: String
        public let category: ParameterCategory
        public let scaleLabel: [String]
        public let isUnipolar: Bool
        public let isDichotom: Bool
        public let isDegreeScale: Bool

        public init(
            nameId: Int,
            name: String,
            definition: String,
            category: ParameterCategory,
            scaleLabel: [String],
            isUnipolar: Bool,
            isDichotom: Bool,
            isDegreeScale: Bool
        ) {
            self.id = nameId
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

    // MARK: - Complete 48 Parameter Set

    /// All 48 parameters from the validated acoustic framework
    public static let allParameters: [AudioParameter] = [

        // MARK: Category 0 - Allgemein (General)
        AudioParameter(
            nameId: 0, name: "Unterschied",
            definition: "Existenz eines wahrnehmbaren Unterschieds zwischen zwei Audiobeispielen.",
            category: .general, scaleLabel: ["gar keiner", "sehr großer"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        ),

        // MARK: Category 1 - Klangfarbe (Timbre)
        AudioParameter(
            nameId: 1, name: "Klangfarbe hell-dunkel",
            definition: "Klangeindruck, der durch das Verhältnis hoher zu tiefer Frequenzanteile bestimmt wird.",
            category: .klangfarbe, scaleLabel: ["dunkler", "heller"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 2, name: "Fülle/Volumen",
            definition: "Klangeindruck von Körperhaftigkeit und Gewicht des Klangs.",
            category: .klangfarbe, scaleLabel: ["weniger voll", "voller"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 3, name: "Nasalität",
            definition: "Klangcharakter, der an Sprache durch die Nase erinnert.",
            category: .klangfarbe, scaleLabel: ["weniger nasal", "nasaler"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 4, name: "Rauigkeit",
            definition: "Klangeindruck von Körnigkeit oder Granularität im Klang.",
            category: .klangfarbe, scaleLabel: ["glatter", "rauer"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 5, name: "Schärfe",
            definition: "Klangeindruck, der auf den Kraftaufwand bei der Klangerzeugung schließen lässt.",
            category: .klangfarbe, scaleLabel: ["schwächer ausgeprägt", "stärker ausgeprägt"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 6, name: "Wärme",
            definition: "Empfindung von Behaglichkeit und angenehmer Tiefe im Klang.",
            category: .klangfarbe, scaleLabel: ["kälter", "wärmer"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 7, name: "Brillanz",
            definition: "Klare, glänzende Qualität im oberen Frequenzbereich.",
            category: .klangfarbe, scaleLabel: ["matter", "brillanter"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 8, name: "Härte",
            definition: "Klangeindruck von Aggressivität oder Strenge.",
            category: .klangfarbe, scaleLabel: ["weicher", "härter"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),

        // MARK: Category 2 - Tonalität (Tonality)
        AudioParameter(
            nameId: 9, name: "Tonhöhe",
            definition: "Wahrgenommene Grundfrequenz des Klangs.",
            category: .tonalitaet, scaleLabel: ["tiefer", "höher"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 10, name: "Tonalität",
            definition: "Grad der harmonischen Struktur im Klang.",
            category: .tonalitaet, scaleLabel: ["geräuschhafter", "tonaler"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 11, name: "Reinheit",
            definition: "Klarheit der tonalen Komponenten ohne Nebengeräusche.",
            category: .tonalitaet, scaleLabel: ["unreiner", "reiner"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 12, name: "Obertongehalt",
            definition: "Reichhaltigkeit der harmonischen Obertöne.",
            category: .tonalitaet, scaleLabel: ["obertonärmer", "obertonreicher"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),

        // MARK: Category 3 - Geometrie (Geometry)
        AudioParameter(
            nameId: 13, name: "Quellenbreite",
            definition: "Wahrgenommene horizontale Ausdehnung der Schallquelle.",
            category: .geometrie, scaleLabel: ["schmaler", "breiter"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 14, name: "Quellenhöhe",
            definition: "Wahrgenommene vertikale Position der Schallquelle.",
            category: .geometrie, scaleLabel: ["tiefer", "höher"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 15, name: "Quellenentfernung",
            definition: "Wahrgenommene Distanz zur Schallquelle.",
            category: .geometrie, scaleLabel: ["näher", "weiter entfernt"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 16, name: "Lokalisationsschärfe",
            definition: "Präzision der räumlichen Ortung der Schallquelle.",
            category: .geometrie, scaleLabel: ["diffuser", "präziser"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 17, name: "Einhüllung",
            definition: "Grad der Umhüllung durch den Klang.",
            category: .geometrie, scaleLabel: ["weniger einhüllend", "stärker einhüllend"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),

        // MARK: Category 4 - Raum (Room/Space)
        AudioParameter(
            nameId: 18, name: "Raumgröße",
            definition: "Wahrgenommene Größe des akustischen Raums.",
            category: .raum, scaleLabel: ["kleiner", "größer"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 19, name: "Halligkeit",
            definition: "Stärke des wahrnehmbaren Nachhalls.",
            category: .raum, scaleLabel: ["trockener", "halliger"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 20, name: "Nachhallzeit",
            definition: "Wahrgenommene Dauer des Nachhalls (RT60).",
            category: .raum, scaleLabel: ["kürzer", "länger"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 21, name: "Klarheit",
            definition: "Unterscheidbarkeit von Direktschall und Reflexionen.",
            category: .raum, scaleLabel: ["verwaschener", "klarer"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 22, name: "Direktheit",
            definition: "Verhältnis von Direktschall zu Raumanteil.",
            category: .raum, scaleLabel: ["indirekter", "direkter"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 23, name: "Präsenz",
            definition: "Eindruck der Unmittelbarkeit und Nähe.",
            category: .raum, scaleLabel: ["weniger präsent", "präsenter"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),

        // MARK: Category 5 - Zeitverhalten (Temporal)
        AudioParameter(
            nameId: 24, name: "Einschwingzeit",
            definition: "Dauer bis zur vollen Klangentfaltung.",
            category: .zeitverhalten, scaleLabel: ["schneller", "langsamer"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 25, name: "Ausschwingzeit",
            definition: "Dauer des Abklingens nach Ende der Anregung.",
            category: .zeitverhalten, scaleLabel: ["kürzer", "länger"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 26, name: "Impulsivität",
            definition: "Schärfe und Deutlichkeit von Transienten.",
            category: .zeitverhalten, scaleLabel: ["weicher", "impulsiver"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 27, name: "Zeitliche Auflösung",
            definition: "Unterscheidbarkeit zeitlich aufeinanderfolgender Ereignisse.",
            category: .zeitverhalten, scaleLabel: ["schlechter", "besser"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 28, name: "Rhythmische Präzision",
            definition: "Exaktheit des zeitlichen Ablaufs.",
            category: .zeitverhalten, scaleLabel: ["unpräziser", "präziser"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),

        // MARK: Category 6 - Dynamik (Dynamics)
        AudioParameter(
            nameId: 29, name: "Lautheit",
            definition: "Subjektiv empfundene Lautstärke.",
            category: .dynamik, scaleLabel: ["leiser", "lauter"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 30, name: "Dynamikumfang",
            definition: "Differenz zwischen leisesten und lautesten Stellen.",
            category: .dynamik, scaleLabel: ["komprimierter", "dynamischer"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 31, name: "Kompression",
            definition: "Grad der Dynamikeinschränkung.",
            category: .dynamik, scaleLabel: ["weniger komprimiert", "stärker komprimiert"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 32, name: "Lautheitsbalance",
            definition: "Ausgewogenheit der Lautstärke verschiedener Elemente.",
            category: .dynamik, scaleLabel: ["unausgewogener", "ausgewogener"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 33, name: "Durchsetzungsfähigkeit",
            definition: "Fähigkeit, sich gegen andere Klänge durchzusetzen.",
            category: .dynamik, scaleLabel: ["zurückhaltender", "durchsetzungsfähiger"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),

        // MARK: Category 7 - Artefakte (Artifacts)
        AudioParameter(
            nameId: 34, name: "Verzerrung",
            definition: "Grad unerwünschter nichtlinearer Verzerrungen.",
            category: .artefakte, scaleLabel: ["weniger verzerrt", "stärker verzerrt"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 35, name: "Rauschen",
            definition: "Wahrnehmbarkeit von Hintergrundrauschen.",
            category: .artefakte, scaleLabel: ["weniger Rauschen", "mehr Rauschen"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 36, name: "Knacksen/Klicken",
            definition: "Auftreten von kurzen Störgeräuschen.",
            category: .artefakte, scaleLabel: ["keine", "viele"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 37, name: "Brummen",
            definition: "Wahrnehmbarkeit von tieffrequenten Störungen.",
            category: .artefakte, scaleLabel: ["kein Brummen", "starkes Brummen"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 38, name: "Aliasing",
            definition: "Hörbare Artefakte durch unzureichende Abtastrate.",
            category: .artefakte, scaleLabel: ["nicht wahrnehmbar", "stark wahrnehmbar"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 39, name: "Kompressionsartefakte",
            definition: "Hörbare Artefakte durch Audiokompression.",
            category: .artefakte, scaleLabel: ["nicht wahrnehmbar", "stark wahrnehmbar"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        ),

        // MARK: Category 8 - Meta (Overall Quality)
        AudioParameter(
            nameId: 40, name: "Gesamtqualität",
            definition: "Bewertung der allgemeinen Klangqualität.",
            category: .meta, scaleLabel: ["schlecht", "exzellent"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 41, name: "Natürlichkeit",
            definition: "Grad der Natürlichkeit des Klangs.",
            category: .meta, scaleLabel: ["künstlicher", "natürlicher"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 42, name: "Präferenz",
            definition: "Persönliche Vorliebe für den Klang.",
            category: .meta, scaleLabel: ["weniger bevorzugt", "mehr bevorzugt"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 43, name: "Annehmlichkeit",
            definition: "Grad der Annehmlichkeit beim Hören.",
            category: .meta, scaleLabel: ["unangenehmer", "angenehmer"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 44, name: "Transparenz",
            definition: "Durchhörbarkeit aller Klangelemente.",
            category: .meta, scaleLabel: ["weniger transparent", "transparenter"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 45, name: "Authentizität",
            definition: "Treue zur Originalaufnahme oder zum Live-Erlebnis.",
            category: .meta, scaleLabel: ["weniger authentisch", "authentischer"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 46, name: "Sprachverständlichkeit",
            definition: "Klarheit und Verständlichkeit von Sprache.",
            category: .meta, scaleLabel: ["schlechter verständlich", "besser verständlich"],
            isUnipolar: false, isDichotom: false, isDegreeScale: false
        ),
        AudioParameter(
            nameId: 47, name: "Ermüdung",
            definition: "Grad der Hörermüdung bei längerer Wiedergabe.",
            category: .meta, scaleLabel: ["weniger ermüdend", "stärker ermüdend"],
            isUnipolar: true, isDichotom: false, isDegreeScale: false
        )
    ]

    /// Number of parameters
    public static var parameterCount: Int {
        return allParameters.count
    }

    /// Get parameters by category
    public static func parameters(for category: ParameterCategory) -> [AudioParameter] {
        return allParameters.filter { $0.category == category }
    }

    /// Get parameter by ID
    public static func parameter(withId id: Int) -> AudioParameter? {
        return allParameters.first { $0.nameId == id }
    }

    /// Get all category names
    public static var categoryNames: [String] {
        return ParameterCategory.allCases.map { $0.displayName }
    }
}
