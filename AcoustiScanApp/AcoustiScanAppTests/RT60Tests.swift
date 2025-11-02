
import XCTest
@testable import iPadScannerApp

final class RT60Tests: XCTestCase {

    func testSabineRT60Calculation() {
        let volume = 112.5
        let absorptionArea = 38.25
        let expectedRT60 = 0.161 * volume / absorptionArea

        let result = RT60Calculation.calculateRT60(volume: volume, absorptionArea: absorptionArea)

        XCTAssertEqual(result, expectedRT60, accuracy: 0.01)
    }

    func testAbsorptionAreaSum() {
        let surfaces = [
            LabeledSurface(name: "Decke", area: 37.5, absorptionCoefficient: 0.6, color: .gray),
            LabeledSurface(name: "Boden", area: 37.5, absorptionCoefficient: 0.1, color: .gray),
            LabeledSurface(name: "Wand", area: 60.0, absorptionCoefficient: 0.2, color: .gray)
        ]
        let total = RT60Calculation.totalAbsorptionArea(
            surfaceAreas: surfaces.map { $0.area },
            absorptionCoefficients: surfaces.map { $0.absorptionCoefficient }
        )

        XCTAssertEqual(total, 22.5 + 3.75 + 12.0, accuracy: 0.01)
    }
}
