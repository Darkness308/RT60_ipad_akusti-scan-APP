
import XCTest
@testable import AcousticEngine

final class RT60Tests: XCTestCase {

    func testSabineRT60Calculation() {
        let volume = 112.5
        let absorptionArea = 38.25
        let expectedRT60 = 0.161 * volume / absorptionArea

        let result = RT60Calculation.calculateRT60(volume: volume, absorptionArea: absorptionArea)

        XCTAssertEqual(result, expectedRT60, accuracy: 0.01)
    }

    func testAbsorptionAreaCalculation() {
        let surfaceAreas = [37.5, 37.5, 60.0]
        let coefficients = [0.6, 0.1, 0.2]
        
        let total = RT60Calculation.totalAbsorptionArea(
            surfaceAreas: surfaceAreas,
            absorptionCoefficients: coefficients
        )

        XCTAssertEqual(total, 22.5 + 3.75 + 12.0, accuracy: 0.01)
    }
    
    func testEnergyDecayCurve() {
        let impulseResponse: [Float] = [1.0, 0.8, 0.6, 0.4, 0.2, 0.0]
        let energyCurve = ImpulseResponseAnalyzer.energyDecayCurve(ir: impulseResponse)
        
        XCTAssertFalse(energyCurve.isEmpty)
        XCTAssertEqual(energyCurve.count, impulseResponse.count)
    }
}
