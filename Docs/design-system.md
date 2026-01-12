# Design System Documentation

## Overview

The AcoustiScan design system provides a comprehensive set of guidelines for creating accessible, consistent, and user-friendly interfaces. This system ensures WCAG AA compliance and follows iOS Human Interface Guidelines.

## Accessibility Standards

### WCAG AA Compliance

All interface elements must meet **WCAG 2.1 Level AA** requirements:

#### Color Contrast Requirements

**Normal Text (< 18pt or < 14pt bold)**:
- Minimum contrast ratio: **4.5:1**
- Recommended contrast ratio: **7:1** (AAA)

**Large Text (≥ 18pt or ≥ 14pt bold)**:
- Minimum contrast ratio: **3:1**
- Recommended contrast ratio: **4.5:1** (AAA)

**Graphical Objects and UI Components**:
- Minimum contrast ratio: **3:1**
- Includes buttons, form fields, focus indicators

#### Testing Tools

Use these tools to verify contrast:
- **Xcode Accessibility Inspector**: Built-in testing
- **Color Contrast Analyzer**: https://www.tpgi.com/color-contrast-checker/
- **WebAIM Contrast Checker**: https://webaim.org/resources/contrastchecker/

### Keyboard Navigation

**Required Support**:
- Tab order follows logical reading order
- All interactive elements keyboard accessible
- Focus indicators clearly visible
- Escape key dismisses modals/overlays
- Enter/Space activates buttons

**Focus States**:
```swift
.focusable()
.focusEffectDisabled(false)
.onKeyPress(.tab) { keyPress in
    // Handle tab navigation
}
```

### Touch Targets

**Minimum Sizes**:
- Primary buttons: **44x44 pt** (iOS standard)
- Secondary buttons: **44x44 pt**
- Icons/toggles: **44x44 pt**
- List items: **44 pt** height minimum

**Spacing**:
- Minimum spacing between targets: **8 pt**
- Recommended spacing: **16 pt**

### Screen Reader Support (VoiceOver)

**Implementation Requirements**:

1. **Accessibility Labels**: Every interactive element must have a clear label
```swift
Button(action: startScan) {
    Image(systemName: "camera.fill")
}
.accessibilityLabel("Start room scan")
.accessibilityHint("Begins LiDAR scanning of the room")
```

2. **Accessibility Traits**: Use appropriate traits
```swift
Text("RT60: 0.8s")
    .accessibilityAddTraits(.isStaticText)
    .accessibilityRemoveTraits(.isButton)
```

3. **Accessibility Values**: Dynamic content needs values
```swift
Slider(value: $volume, in: 0...100)
    .accessibilityLabel("Volume")
    .accessibilityValue("\(Int(volume)) percent")
```

4. **Group Related Content**:
```swift
VStack {
    Text("Room Volume")
    Text("125 m³")
}
.accessibilityElement(children: .combine)
```

### Dynamic Type Support

Support system font size preferences:
```swift
Text("Measurement Results")
    .font(.title)
    .minimumScaleFactor(0.5)
    .lineLimit(nil)
```

**Size Categories**:
- XS, S, M (default), L, XL, XXL, XXXL
- Test all interfaces at smallest and largest sizes

### Reduced Motion

Respect user's motion preferences:
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation {
    reduceMotion ? .none : .spring()
}
```

**Animation Guidelines**:
- Maximum duration: **500ms**
- Provide non-animated alternatives
- Essential animations only

## Color System

### Primary Colors

**Acoustic Blue** (Primary Brand Color):
- Light mode: `#0077CC` (RGB: 0, 119, 204)
- Dark mode: `#4DA6FF` (RGB: 77, 166, 255)
- Contrast ratio: 4.8:1 on white, 8.9:1 on black

**Success Green**:
- Light mode: `#28A745` (RGB: 40, 167, 69)
- Dark mode: `#34D058` (RGB: 52, 208, 88)
- Usage: Compliance met, successful measurements

**Warning Yellow**:
- Light mode: `#FFC107` (RGB: 255, 193, 7)
- Dark mode: `#FFD54F` (RGB: 255, 213, 79)
- Usage: Warnings, tolerance limits

**Error Red**:
- Light mode: `#DC3545` (RGB: 220, 53, 69)
- Dark mode: `#FF6B6B` (RGB: 255, 107, 107)
- Usage: Errors, compliance violations

### Neutral Colors

**Backgrounds**:
- Primary: `Color(.systemBackground)` - Adapts to light/dark mode
- Secondary: `Color(.secondarySystemBackground)`
- Tertiary: `Color(.tertiarySystemBackground)`

**Text**:
- Primary: `Color(.label)` - Contrast ratio: 7:1
- Secondary: `Color(.secondaryLabel)` - Contrast ratio: 4.5:1
- Tertiary: `Color(.tertiaryLabel)` - Contrast ratio: 3:1

**Borders**:
- Light mode: `#E0E0E0` (RGB: 224, 224, 224)
- Dark mode: `#3A3A3C` (RGB: 58, 58, 60)

### Semantic Colors

Use semantic color names instead of fixed values:
```swift
struct Colors {
    static let primary = Color("AcousticBlue")
    static let success = Color("SuccessGreen")
    static let warning = Color("WarningYellow")
    static let error = Color("ErrorRed")
}
```

### Color Usage Guidelines

**Do's**:
✅ Use color + text/icon to convey meaning  
✅ Ensure sufficient contrast for all text  
✅ Test in both light and dark modes  
✅ Use semantic color names  
✅ Support system color preferences  

**Don'ts**:
❌ Use color alone to convey information  
❌ Use text gradients on colored backgrounds  
❌ Mix warm and cool colors excessively  
❌ Use pure black (#000000) on pure white (#FFFFFF)  
❌ Override system colors unnecessarily  

## Typography

### Font Scale

Based on **SF Pro** (iOS system font):

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| Large Title | 34 pt | Regular | 41 pt | Section headers |
| Title 1 | 28 pt | Regular | 34 pt | Page titles |
| Title 2 | 22 pt | Regular | 28 pt | Card headers |
| Title 3 | 20 pt | Regular | 25 pt | Group headers |
| Headline | 17 pt | Semibold | 22 pt | Emphasized content |
| Body | 17 pt | Regular | 22 pt | Body text |
| Callout | 16 pt | Regular | 21 pt | Secondary content |
| Subheadline | 15 pt | Regular | 20 pt | Subtitles |
| Footnote | 13 pt | Regular | 18 pt | Caption text |
| Caption 1 | 12 pt | Regular | 16 pt | Small labels |
| Caption 2 | 11 pt | Regular | 13 pt | Minimum size |

### Font Weight Usage

- **Regular (400)**: Body text, descriptions
- **Medium (500)**: Subtle emphasis
- **Semibold (600)**: Headlines, labels
- **Bold (700)**: Strong emphasis, titles

### Implementation

```swift
Text("RT60 Measurement")
    .font(.title)
    .fontWeight(.semibold)
    .foregroundColor(.primary)
```

### Typography Guidelines

**Do's**:
✅ Use system fonts (SF Pro)  
✅ Support Dynamic Type  
✅ Maintain clear hierarchy  
✅ Test with large text sizes  
✅ Use appropriate line heights  

**Don'ts**:
❌ Use custom fonts without accessibility testing  
❌ Use font sizes smaller than 11 pt  
❌ Mix too many font weights  
❌ Disable Dynamic Type  
❌ Use all caps for long text  

## Spacing System

### Base Unit: 8pt Grid

All spacing follows 8pt increments:

| Token | Value | Usage |
|-------|-------|-------|
| XXS | 4 pt | Tight internal spacing |
| XS | 8 pt | Default internal spacing |
| S | 16 pt | Small gaps |
| M | 24 pt | Medium gaps |
| L | 32 pt | Large gaps |
| XL | 40 pt | Extra large gaps |
| XXL | 48 pt | Section dividers |

### Layout Spacing

**Screen Margins**:
- iPad: 20 pt (portrait), 20 pt (landscape)
- Safe area respected on all edges

**Component Spacing**:
- Between sections: 32 pt
- Between cards: 16 pt
- Between form fields: 16 pt
- Between label and value: 8 pt

**Internal Padding**:
- Buttons: 12 pt vertical, 20 pt horizontal
- Cards: 16 pt all sides
- List items: 12 pt vertical, 16 pt horizontal

### Implementation

```swift
VStack(spacing: 16) { // Use token values
    // Content
}
.padding(20) // Screen margins
```

## Components

### Buttons

#### Primary Button

For main actions (start scan, save, export):

```swift
Button("Start Measurement") {
    startMeasurement()
}
.buttonStyle(.borderedProminent)
.controlSize(.large)
.tint(.accentColor)
```

**Specifications**:
- Height: 44 pt minimum
- Corner radius: 8 pt
- Font: Body Semibold
- Min width: 88 pt

#### Secondary Button

For alternative actions (cancel, back):

```swift
Button("Cancel") {
    cancel()
}
.buttonStyle(.bordered)
.controlSize(.large)
```

#### Text Button

For tertiary actions (reset, clear):

```swift
Button("Reset") {
    reset()
}
.buttonStyle(.plain)
```

### Cards

Container for related content:

```swift
VStack(alignment: .leading, spacing: 12) {
    Text("Room Information")
        .font(.headline)
    
    // Content
}
.padding(16)
.background(Color(.secondarySystemBackground))
.cornerRadius(12)
.shadow(radius: 2)
```

**Specifications**:
- Corner radius: 12 pt
- Padding: 16 pt
- Background: Secondary system background
- Subtle shadow for depth

### Forms

Input field patterns:

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Room Name")
        .font(.subheadline)
        .foregroundColor(.secondary)
    
    TextField("Enter room name", text: $roomName)
        .textFieldStyle(.roundedBorder)
        .accessibilityLabel("Room name")
}
```

**Field Requirements**:
- Label above field
- Minimum height: 44 pt
- Clear error states
- Validation feedback

### Lists

Display collections of items:

```swift
List {
    ForEach(materials) { material in
        MaterialRow(material: material)
            .listRowBackground(Color(.secondarySystemBackground))
    }
}
.listStyle(.insetGrouped)
```

**Row Specifications**:
- Minimum height: 44 pt
- Padding: 12 pt vertical, 16 pt horizontal
- Separator: 1 pt, system gray

### Charts

Frequency response and RT60 graphs:

```swift
Chart {
    ForEach(data) { point in
        LineMark(
            x: .value("Frequency", point.frequency),
            y: .value("RT60", point.rt60)
        )
    }
}
.chartXAxis {
    AxisMarks(position: .bottom)
}
.accessibilityLabel("RT60 frequency response chart")
```

**Chart Requirements**:
- Minimum height: 200 pt
- Clear axis labels
- Grid lines for readability
- Color coding for data series
- Accessibility description

### Alerts and Dialogs

System alerts for important information:

```swift
.alert("Measurement Complete", isPresented: $showAlert) {
    Button("View Results") {
        showResults()
    }
    Button("Dismiss") {
        dismissAlert()
    }
} message: {
    Text("RT60 measurement completed successfully")
}
```

### Loading States

Progress indicators:

```swift
if isLoading {
    ProgressView("Processing scan...")
        .progressViewStyle(.circular)
        .padding()
}
```

## Interaction Patterns

### Gestures

**Supported Gestures**:
- Tap: Primary selection
- Long press: Context menu
- Swipe: Delete/archive (in lists)
- Pinch: Zoom (in 3D view)
- Pan: Navigate 3D space

**Gesture Feedback**:
- Visual: Highlight on touch
- Haptic: Light impact for confirmations
- Audio: System sounds for actions

### Animations

**Transition Durations**:
- Quick: 200ms (button highlights)
- Standard: 300ms (view transitions)
- Long: 500ms (complex animations)

**Easing Functions**:
```swift
.animation(.easeInOut(duration: 0.3), value: isExpanded)
.animation(.spring(response: 0.3, dampingFraction: 0.7), value: offset)
```

**Animation Guidelines**:
- Keep animations under 500ms
- Use spring animations for natural feel
- Respect reduced motion preference
- Provide animation skip option

### Navigation

**Tab Bar Navigation**:
- 5 main tabs: Scanner, RT60, Results, Export, Materials
- Active tab highlighted
- Tab bar always visible
- Icons + labels for clarity

**Modal Presentation**:
- Full screen for main flows
- Sheet for secondary actions
- Popover for info/help

### Feedback

**Success States**:
- Green checkmark icon
- Success message
- Haptic feedback (success)

**Error States**:
- Red error icon
- Clear error message
- Suggested action
- Haptic feedback (error)

**Loading States**:
- Activity indicator
- Progress bar (for determinate tasks)
- Descriptive text

## Icons

### System Icons (SF Symbols)

Use SF Symbols for consistency:

| Icon | Name | Usage |
|------|------|-------|
| 📷 | `camera.fill` | Start scan |
| 🎙️ | `mic.fill` | Start measurement |
| 📊 | `chart.bar.fill` | View results |
| 📄 | `doc.fill` | View report |
| ⚙️ | `gear` | Settings |
| ℹ️ | `info.circle` | Help/info |
| ✓ | `checkmark.circle.fill` | Success |
| ⚠️ | `exclamationmark.triangle.fill` | Warning |
| ✕ | `xmark.circle.fill` | Error |

**Icon Sizes**:
- Small: 16x16 pt
- Medium: 24x24 pt
- Large: 32x32 pt
- Touch target: 44x44 pt (with padding)

### Custom Icons

If custom icons needed:
- Match SF Symbols style
- Provide all sizes
- Include dark mode variants
- Ensure accessibility

## Layout Patterns

### Grid System

12-column grid for iPad:
- Column width: Flexible
- Gutter: 20 pt
- Margins: 20 pt

### Responsive Breakpoints

**Portrait**:
- Width: 768-834 pt
- 2-column layouts

**Landscape**:
- Width: 1024-1366 pt
- 3-column layouts

### Safe Areas

Always respect safe areas:
```swift
.ignoresSafeArea(.keyboard) // Only when needed
```

## Dark Mode

### Automatic Adaptation

Use semantic colors for automatic adaptation:
```swift
Color(.label) // Adapts automatically
Color(.systemBackground) // Adapts automatically
```

### Testing

Test all screens in both modes:
- Light mode
- Dark mode
- High contrast mode
- Increased contrast mode

### Guidelines

**Do's**:
✅ Use semantic system colors  
✅ Test contrast in both modes  
✅ Adjust shadows for dark mode  
✅ Maintain visual hierarchy  

**Don'ts**:
❌ Hardcode colors  
❌ Assume light mode only  
❌ Forget to test icons  
❌ Use pure black/white  

## Motion and Animation

### Principles

1. **Purposeful**: Animations should serve a purpose
2. **Quick**: Keep animations brief (< 500ms)
3. **Subtle**: Avoid distracting movements
4. **Consistent**: Use same patterns throughout

### Animation Types

**View Transitions**:
```swift
.transition(.slide)
.transition(.opacity)
.transition(.scale)
```

**Value Changes**:
```swift
withAnimation(.easeInOut(duration: 0.3)) {
    value = newValue
}
```

**Loading Animations**:
```swift
ProgressView()
    .progressViewStyle(.circular)
```

### Performance

- Use `drawingGroup()` for complex animations
- Avoid animating large images
- Limit simultaneous animations
- Profile with Instruments

## Best Practices

### Do's and Don'ts

#### Layout

**Do**:
✅ Use Auto Layout / SwiftUI layout system  
✅ Support all iPad orientations  
✅ Respect safe areas  
✅ Test on different iPad sizes  
✅ Use standard margins and spacing  

**Don't**:
❌ Hardcode positions  
❌ Assume specific screen size  
❌ Overlap safe area content  
❌ Use pixel values (use points)  
❌ Create cramped layouts  

#### Accessibility

**Do**:
✅ Test with VoiceOver  
✅ Provide text alternatives  
✅ Use sufficient contrast  
✅ Support Dynamic Type  
✅ Test with assistive technologies  

**Don't**:
❌ Use color alone to convey info  
❌ Create keyboard traps  
❌ Forget focus indicators  
❌ Use inaccessible controls  
❌ Disable accessibility features  

#### Navigation

**Do**:
✅ Maintain clear hierarchy  
✅ Provide back navigation  
✅ Use standard navigation patterns  
✅ Show current location  
✅ Keep navigation consistent  

**Don't**:
❌ Use icon-only navigation without labels  
❌ Create dead ends  
❌ Hide navigation unpredictably  
❌ Use unclear icons  
❌ Change navigation patterns  

#### Forms

**Do**:
✅ Label all fields clearly  
✅ Show validation errors  
✅ Provide helpful hints  
✅ Use appropriate keyboards  
✅ Save progress automatically  

**Don't**:
❌ Use placeholder as label  
❌ Hide validation rules  
❌ Use cryptic error messages  
❌ Require unnecessary fields  
❌ Lose user data on errors  

## Technical Resources

### Design Tools

- **SF Symbols App**: https://developer.apple.com/sf-symbols/
- **Figma**: Design mockups and prototypes
- **Xcode Preview**: Real-time UI development
- **Accessibility Inspector**: Built into Xcode

### Frameworks

- **SwiftUI**: Primary UI framework
- **Swift Charts**: Data visualization
- **RoomPlan**: 3D scanning
- **ARKit**: Augmented reality

### Documentation

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Accessibility Documentation](https://developer.apple.com/accessibility/)

## Component Library

### Reusable Components

All components should be:
- Documented
- Accessible
- Tested
- Versioned

**Example Component**:
```swift
struct MeasurementCard: View {
    let title: String
    let value: String
    let unit: String
    let status: ComplianceStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.semibold)
                
                Text(unit)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            StatusBadge(status: status)
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value) \(unit), \(status.description)")
    }
}
```

## Quality Checklist

Before shipping any UI:

- [ ] Tested in light and dark mode
- [ ] VoiceOver navigation works
- [ ] Contrast ratios meet WCAG AA
- [ ] Touch targets are 44x44 pt minimum
- [ ] Works with Dynamic Type (XS to XXXL)
- [ ] Respects reduced motion preference
- [ ] All interactions have feedback
- [ ] Error states are clear
- [ ] Loading states are shown
- [ ] Keyboard navigation works
- [ ] Tested on smallest iPad
- [ ] Tested on largest iPad
- [ ] Portrait and landscape tested
- [ ] Safe areas respected
- [ ] No hardcoded colors
- [ ] Icons have accessibility labels
- [ ] Forms have proper validation
- [ ] Animations are under 500ms

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2025-11-23 | Initial design system documentation |

---

**Document Version**: 1.0  
**Last Updated**: 2025-11-23  
**Maintainer**: Design Team  
**Review Cycle**: Quarterly

---

## Support

For questions or clarifications:
- Design Team: design@acoustiscan.app
- Accessibility: a11y@acoustiscan.app
- Documentation: docs@acoustiscan.app
