# GitHub Copilot Instructions for AcoustiScan RT60 iPad App

## Project Overview
This is a professional acoustic analysis iOS application for RT60 (reverberation time) measurements and room acoustics evaluation according to DIN 18041 standards. The app is designed for acoustic consultants, engineers, and architects who need to assess room acoustics professionally.

## Domain-Specific Knowledge

### Acoustic Engineering Concepts
- **RT60**: Reverberation time - the time required for sound to decay by 60 dB after the sound source has stopped
- **Sabine Formula**: `RT60 = 0.161 * V / A` where V = room volume (m³), A = total absorption area (m²)
- **DIN 18041**: German standard for acoustic quality in small to medium-sized rooms
- **Absorption Coefficients**: Material-specific values (0.0-1.0) indicating how much sound energy is absorbed
- **Frequency Analysis**: Standard octave bands: 125, 250, 500, 1000, 2000, 4000, 8000 Hz

### Room Types (DIN 18041)
- **Classroom**: Educational spaces with speech intelligibility focus
- **Office**: Work environments requiring concentration
- **Conference**: Meeting rooms optimized for speech communication
- **Lecture Hall**: Large educational spaces with public address systems
- **Music Room**: Spaces for musical performance and practice
- **Sports Hall**: Athletic facilities with specific acoustic requirements

## Code Review Guidelines

### Swift Code Quality
- **Target iOS 15.0+**, macOS 12.0+ for compatibility
- Use **Swift 5.9** features appropriately
- Follow **Apple's Swift API Design Guidelines**
- Prefer **async/await** over completion handlers for new code
- Use **@MainActor** for UI-related code when appropriate

### Architecture Patterns
- **MVVM pattern** is preferred for UI components
- **Coordinator pattern** for navigation flow management
- **Repository pattern** for data access abstraction
- **Dependency injection** through initializer parameters

### Performance Considerations
- **Audio processing** should be performed on background queues
- **RT60 calculations** are computationally intensive - use appropriate threading
- **PDF generation** should not block the main thread
- **Memory management** is critical for audio buffer handling
- **LiDAR scanning** requires careful resource management

### Testing Standards
- **Unit tests** for calculation algorithms (RT60, DIN compliance)
- **Integration tests** for workflow validation
- **Performance tests** for audio processing components
- **UI tests** for critical user journeys
- **Mock objects** for external dependencies (ARKit, RoomPlan)

### Domain-Specific Code Patterns

#### RT60 Calculations
```swift
// Prefer this pattern for frequency-specific calculations
let frequencies = [125, 250, 500, 1000, 2000, 4000, 8000]
let rt60Values = frequencies.compactMap { frequency in
    calculateRT60(for: frequency, volume: roomVolume, surfaces: surfaces)
}
```

#### Material Database Access
```swift
// Use consistent naming for acoustic materials
struct AcousticMaterial {
    let name: String
    let absorptionCoefficients: [Int: Double] // frequency -> coefficient
}
```

#### DIN 18041 Compliance
```swift
// Implement clear evaluation logic
enum DINCompliance {
    case compliant(tolerance: Double)
    case marginal(deviation: Double)
    case nonCompliant(deviation: Double)
}
```

### Error Handling Patterns
- Use **Result types** for operations that can fail
- Provide **user-friendly error messages** for acoustic measurement failures
- **Graceful degradation** when hardware features (LiDAR) are unavailable
- **Validation** for acoustic parameter inputs (positive values, realistic ranges)

### Documentation Standards
- **Document acoustic formulas** with references to standards
- **Explain calculation algorithms** with academic citations
- **Provide usage examples** for complex acoustic functions
- **Include unit specifications** (dB, Hz, m², m³, seconds)

### Security & Privacy
- **Location data** from room scanning should be handled carefully
- **Audio recordings** for analysis must follow privacy guidelines
- **PDF reports** may contain sensitive building information
- **No acoustic data** should be transmitted without explicit consent

### Build & Deployment
- **Swift Package Manager** is the preferred dependency management
- **Automated testing** should run on all pull requests
- **Build warnings** should be addressed, especially deprecation warnings
- **Code signing** requirements for iOS deployment
- **Version numbering** should follow semantic versioning

## Specific Review Focus Areas

### When Reviewing RT60 Calculation Code
- Verify **frequency range coverage** (125-8000 Hz)
- Check **unit consistency** (ensure consistent use of m², m³, seconds)
- Validate **Sabine formula implementation**
- Review **numerical precision** for small rooms or highly absorptive spaces

### When Reviewing DIN 18041 Code
- Ensure **room type classification** is accurate
- Verify **tolerance calculations** follow standard specifications
- Check **target value calculations** for different room purposes
- Validate **compliance evaluation logic**

### When Reviewing UI Code
- **Accessibility** for professional users with disabilities
- **Internationalization** for German and English markets
- **Professional appearance** suitable for consulting work
- **Data visualization** clarity for acoustic measurements

### When Reviewing PDF Export Code
- **Report completeness** for professional documentation
- **Chart quality** for acoustic data visualization
- **Corporate branding** consistency
- **File size optimization** for sharing and archiving

## Common Issues to Watch For

### Acoustic Calculation Errors
- **Division by zero** in Sabine formula when A = 0
- **Negative RT60 values** due to calculation errors
- **Unrealistic values** (RT60 > 10 seconds in normal rooms)
- **Missing frequency bands** in analysis

### iOS-Specific Issues
- **ARKit availability** checking before room scanning
- **Audio session management** during measurements
- **Background processing** limitations for calculations
- **Memory pressure** during large room analysis

### Performance Anti-Patterns
- **Synchronous audio processing** on main thread
- **Unoptimized loops** in frequency analysis
- **Excessive object allocation** during real-time analysis
- **Inefficient PDF generation** algorithms

Remember: This app serves professional acoustic consultants who depend on accurate measurements and reliable calculations for their work. Code quality and measurement accuracy are critical for user trust and professional liability.