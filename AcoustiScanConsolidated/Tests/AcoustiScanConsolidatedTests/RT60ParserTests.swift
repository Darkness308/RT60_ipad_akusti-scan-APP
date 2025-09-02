// RT60ParserTests.swift
// Comprehensive edge-case tests for RT60 log parser

import Testing
@testable import AcoustiScanConsolidated

struct RT60ParserTests {
    
    @Test("Parser handles locale and dash-dot edge cases")
    func test_locale_and_dashdot_handling() throws {
        let txt = """
        Setup:
        Device=iPadPro
        AppVersion=1.0.0
        Date=2025-07-21

        T20:
        125Hz   0,70
        250Hz   -.--
        500Hz   0.55
        1000Hz  -.-
        2000Hz  1,25

        Correltn:
        125Hz   99.0
        250Hz   97.0
        500Hz   96.0
        1000Hz  98.0
        2000Hz  95.5

        CheckSum:
        ABC123DEF456
        """
        
        let parser = RT60LogParser()
        let model = try parser.parse(text: txt, sourceFile: "edge_test.txt")
        
        // Test metadata parsing
        #expect(model.metadata["Device"] == "iPadPro")
        #expect(model.metadata["AppVersion"] == "1.0.0")
        #expect(model.metadata["Date"] == "2025-07-21")
        
        // Test frequency band parsing with different locale formats
        let band125 = model.bands.first { $0.freq_hz == 125 }
        #expect(band125 != nil)
        #expect(band125?.t20_s == 0.70, "Should parse European comma decimal: 0,70")
        #expect(band125?.valid == true)
        #expect(band125?.correlation != nil)
        
        // Test "-.--" handling (invalid measurement)
        let band250 = model.bands.first { $0.freq_hz == 250 }
        #expect(band250 != nil)
        #expect(band250?.t20_s == nil, "Should handle -.-- as nil")
        #expect(band250?.valid == false, "Should mark -.-- as invalid")
        
        // Test standard dot decimal
        let band500 = model.bands.first { $0.freq_hz == 500 }
        #expect(band500 != nil)
        #expect(band500?.t20_s == 0.55, "Should parse standard dot decimal: 0.55")
        #expect(band500?.valid == true)
        
        // Test "-.-" variant handling
        let band1000 = model.bands.first { $0.freq_hz == 1000 }
        #expect(band1000 != nil)
        #expect(band1000?.t20_s == nil, "Should handle -.- as nil")
        #expect(band1000?.valid == false, "Should mark -.- as invalid")
        
        // Test European decimal with larger value
        let band2000 = model.bands.first { $0.freq_hz == 2000 }
        #expect(band2000 != nil)
        #expect(band2000?.t20_s == 1.25, "Should parse European comma decimal: 1,25")
        #expect(band2000?.valid == true)
        
        // Test checksum
        #expect(model.checksum == "ABC123DEF456")
        #expect(model.sourceFile == "edge_test.txt")
    }
    
    @Test("Parser handles malformed input gracefully")
    func test_malformed_input_handling() throws {
        let txt = """
        Setup:
        Device=iPadPro
        CorruptedLine
        
        T20:
        125Hz   NaN
        250Hz   Inf
        500Hz   abc
        1000Hz  
        BadFreq 0.70
        
        Correltn:
        125Hz   150.0
        250Hz   -50.0
        
        CheckSum:
        """
        
        let parser = RT60LogParser()
        let model = try parser.parse(text: txt, sourceFile: "malformed.txt")
        
        // Should parse valid setup data
        #expect(model.metadata["Device"] == "iPadPro")
        
        // Should handle invalid T20 values
        let validBands = model.bands.filter { $0.valid }
        #expect(validBands.isEmpty, "No bands should be valid with malformed data")
        
        // Should clamp invalid correlation values
        let band125 = model.bands.first { $0.freq_hz == 125 }
        #expect(band125?.correlation == nil, "Correlation >100% should be rejected")
        
        let band250 = model.bands.first { $0.freq_hz == 250 }
        #expect(band250?.correlation == nil, "Negative correlation should be rejected")
    }
    
    @Test("Parser handles empty and minimal input")
    func test_empty_and_minimal_input() throws {
        // Test completely empty input
        let emptyParser = RT60LogParser()
        let emptyModel = try emptyParser.parse(text: "", sourceFile: "empty.txt")
        #expect(emptyModel.bands.isEmpty)
        #expect(emptyModel.metadata.isEmpty)
        #expect(emptyModel.checksum.isEmpty)
        
        // Test minimal valid input
        let minimalTxt = """
        T20:
        1000Hz  0.50
        """
        
        let minimalModel = try emptyParser.parse(text: minimalTxt, sourceFile: "minimal.txt")
        #expect(minimalModel.bands.count == 1)
        #expect(minimalModel.bands.first?.freq_hz == 1000)
        #expect(minimalModel.bands.first?.t20_s == 0.50)
        #expect(minimalModel.bands.first?.valid == true)
    }
    
    @Test("Parser validates RT60 value ranges")
    func test_rt60_value_range_validation() throws {
        let txt = """
        T20:
        125Hz   -1.0
        250Hz   0.05
        500Hz   15.0
        1000Hz  2.5
        """
        
        let parser = RT60LogParser()
        let model = try parser.parse(text: txt, sourceFile: "range_test.txt")
        
        // Negative RT60 should be invalid
        let band125 = model.bands.first { $0.freq_hz == 125 }
        #expect(band125?.valid == false, "Negative RT60 should be invalid")
        
        // Too short RT60 should be clamped
        let band250 = model.bands.first { $0.freq_hz == 250 }
        #expect(band250?.t20_s == 0.1, "RT60 < 0.1s should be clamped to 0.1s")
        
        // Too long RT60 should be clamped
        let band500 = model.bands.first { $0.freq_hz == 500 }
        #expect(band500?.t20_s == 10.0, "RT60 > 10s should be clamped to 10s")
        
        // Normal RT60 should be unchanged
        let band1000 = model.bands.first { $0.freq_hz == 1000 }
        #expect(band1000?.t20_s == 2.5, "Normal RT60 should be unchanged")
        #expect(band1000?.valid == true)
    }
}