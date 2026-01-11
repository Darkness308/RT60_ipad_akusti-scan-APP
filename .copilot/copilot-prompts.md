# Copilot Prompts and Rules for AcoustiScan RT60 iPad App

## System Context
You are working on an iPad app for acoustic measurements, specifically RT60 reverberation time analysis. This is a professional audio engineering tool that must comply with ISO 3382-1 standards for room acoustic measurements.

## Primary Responsibilities
1. **Maintain Code Quality**: Ensure all Swift code follows best practices
2. **Fix Compilation Errors**: Automatically resolve common build issues
3. **Preserve Acoustic Accuracy**: Never compromise measurement precision
4. **Ensure iOS Compatibility**: Maintain compatibility with iPad, iOS 17+, LiDAR

## Core Prompts for Common Tasks

### Compilation Error Resolution
```prompt
When you encounter a Swift compilation error:

1. **For undefined variables**:
   - Look for similar variable names in the surrounding code
   - Check if the variable should be parsed from string data using existing parsing functions
   - Add the variable declaration before its first use
   - Example: `let t20Val = Self.parseNumber(t20raw)`

2. **For missing imports**:
   - Identify the missing framework based on the undefined type
   - Add the appropriate import statement at the top of the file
   - Common imports: Foundation, SwiftUI, AVFoundation, PDFKit, RoomPlan

3. **For force unwrapping issues**:
   - Replace force unwraps (!) with safe unwrapping patterns
   - Use guard statements or if-let bindings
   - Provide meaningful fallback values or error handling
```

### RT60 Measurement Code Rules
```prompt
When working with RT60 acoustic measurements:

1. **Always validate correlation values**:
   - Correlation must be >= 95% for ISO 3382-1 compliance
   - Flag measurements with lower correlation as questionable
   - Log correlation issues for debugging

2. **Handle missing frequency data gracefully**:
   - Check for required frequency bands (125Hz to 4kHz minimum)
   - Use interpolation for missing bands where appropriate
   - Document any data gaps in the final report

3. **Preserve measurement units and precision**:
   - Time values in seconds (T20, T30, RT60)
   - Frequency values in Hz
   - Correlation as percentage (0-100%)
   - Sound levels in dB

4. **Statistical validation**:
   - Calculate mean and standard deviation for repeated measurements
   - Flag outliers beyond 2 standard deviations
   - Provide uncertainty estimates in compliance with standards
```

### Audio Processing Guidelines
```prompt
When working with audio processing code:

1. **Audio session configuration**:
   - Use .record category with .measurement mode
   - Request microphone permissions properly
   - Handle audio interruptions gracefully
   - Validate audio input availability before starting

2. **Signal processing**:
   - Use appropriate sample rates (48kHz recommended)
   - Apply windowing functions for FFT analysis
   - Handle noise floor detection
   - Implement proper calibration procedures

3. **Real-time constraints**:
   - Minimize allocations in audio callback threads
   - Use lock-free data structures where possible
   - Profile performance for real-time processing
```

### PDF Report Generation
```prompt
When working with PDF report generation:

1. **Layout and formatting**:
   - Use consistent margins and spacing
   - Ensure content fits within page boundaries
   - Handle page breaks intelligently
   - Include proper headers and footers

2. **Data presentation**:
   - Display RT60 values with appropriate precision (0.01s)
   - Include frequency response graphs
   - Show measurement parameters and conditions
   - Add statistical analysis and uncertainty estimates

3. **Professional standards**:
   - Include ISO 3382-1 compliance statement
   - Add measurement timestamp and device info
   - Provide clear data interpretation guidance
   - Include quality indicators (correlation, etc.)
```

### Error Handling Patterns
```prompt
Always implement robust error handling:

1. **Use Result types for operations that can fail**:
   ```swift
   func processMeasurement() -> Result<RT60Data, MeasurementError> {
       // Implementation
   }
   ```

2. **Log errors with context**:
   ```swift
   logger.error("RT60 calculation failed: \(error.localizedDescription)",
                metadata: ["frequency": "\(frequency)", "correlation": "\(correlation)"])
   ```

3. **Provide user-friendly error messages**:
   - Avoid technical jargon in user-facing errors
   - Suggest specific actions to resolve issues
   - Include help documentation references
```

### SwiftUI Best Practices
```prompt
For SwiftUI code in the app:

1. **State management**:
   - Use @State for local view state
   - Use @StateObject for owned observable objects
   - Use @ObservedObject for injected dependencies
   - Minimize state updates to prevent unnecessary redraws

2. **Performance optimization**:
   - Use @ViewBuilder for complex view composition
   - Implement Equatable for custom types used in ForEach
   - Avoid heavy computations in view body
   - Cache expensive calculations with @useMemo equivalent

3. **Accessibility**:
   - Add accessibility labels for all interactive elements
   - Support VoiceOver navigation
   - Ensure sufficient color contrast
   - Provide alternative text for graphs and charts
```

### Testing Requirements
```prompt
When writing or fixing tests:

1. **Unit tests for calculations**:
   - Test RT60 calculation accuracy with known inputs
   - Verify statistical functions (mean, std dev, etc.)
   - Test edge cases (very short/long reverb times)
   - Validate frequency band processing

2. **Integration tests**:
   - Test audio session configuration
   - Verify PDF generation with sample data
   - Test RoomPlan integration flow
   - Validate data persistence and retrieval

3. **UI tests**:
   - Test measurement workflow end-to-end
   - Verify report generation and sharing
   - Test error handling in UI
   - Validate accessibility features
```

## Quick Reference Commands

### Build and Test
```bash
# Clean build
swift package clean && swift build

# Run tests with coverage
swift test --enable-code-coverage

# Lint and format
swiftlint --strict && swiftformat .
```

### Common Fix Patterns
```swift
// Safe optional unwrapping
guard let value = optionalValue else {
    logger.error("Missing required value: \(#function)")
    return .failure(.missingData)
}

// Audio session setup
do {
    try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement)
    try AVAudioSession.sharedInstance().setActive(true)
} catch {
    return .failure(.audioSessionError(error))
}

// RT60 validation
guard measurement.correlation >= 95.0 else {
    return .failure(.lowCorrelation(measurement.correlation))
}
```

## Critical Don'ts

1. **Never force unwrap in production code** - Always use safe unwrapping
2. **Don't modify acoustic calculations without validation** - RT60 precision is critical
3. **Don't ignore correlation values** - They indicate measurement quality
4. **Don't skip error handling** - Audio processing can fail in many ways
5. **Don't hardcode audio parameters** - Make them configurable for different environments

## Quality Checkpoints

Before completing any change:
1. [x] Code compiles without warnings
2. [x] All tests pass
3. [x] SwiftLint rules satisfied
4. [x] No force unwrapping in production paths
5. [x] RT60 calculations maintain accuracy
6. [x] Error handling is comprehensive
7. [x] Documentation is updated if needed

## Emergency Recovery

If you encounter persistent build issues:
1. Clean all build artifacts: `rm -rf .build && swift package clean`
2. Reset dependencies: `rm Package.resolved && swift package resolve`
3. Check for recent breaking changes in dependencies
4. Verify Xcode version compatibility
5. Review recent commits for introduced issues

## Collaboration Notes

- Always document acoustic theory behind calculations
- Include units in variable names where applicable (frequencyHz, timeSeconds)
- Reference ISO 3382-1 standard in comments where relevant
- Maintain backward compatibility for saved measurement data
- Consider professional audio engineering users in UX decisions
