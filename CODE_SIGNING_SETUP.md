# Code Signing Setup Guide

This document explains how to configure code signing for the AcoustiScan iOS application.

## Overview

The Xcode project has been pre-configured for **Manual Code Signing**, which is the recommended approach for CI/CD pipelines and team development. This setup allows you to:

- Control exactly which provisioning profiles are used
- Work with multiple development teams
- Support both local development and automated builds
- Maintain consistent builds across different environments

## What's Already Configured

The following code signing settings have been configured in the project:

### 1. Project Configuration (`project.pbxproj`)

**Both Debug and Release configurations:**
- [DONE] `CODE_SIGN_STYLE = Manual` - Manual code signing for full control
- [DONE] `CODE_SIGN_ENTITLEMENTS = AcoustiScanApp/AcoustiScan.entitlements` - Points to entitlements file
- [DONE] `PRODUCT_BUNDLE_IDENTIFIER = com.acoustiscan.app` - App bundle identifier
- [WARNING]️  `DEVELOPMENT_TEAM = ""` - **Needs to be set by you** (see below)

### 2. Entitlements File (`AcoustiScanApp/AcoustiScan.entitlements`)

The entitlements file has been created and configured with:
- [DONE] Camera access (`com.apple.security.device.camera`)
- [DONE] Microphone access (`com.apple.security.device.audio-input`)

These entitlements are required for the app's LiDAR scanning and RT60 measurement features.

### 3. Info.plist (`AcoustiScanApp/Resources/Info.plist`)

All required keys are already configured:
- [DONE] Bundle identifier: `com.acoustiscan.app`
- [DONE] Privacy descriptions for camera and microphone access
- [DONE] Required device capabilities (ARKit, LiDAR)
- [DONE] App display name and version information

## What You Need to Do

### Step 1: Set Your Development Team ID

You need to add your Apple Developer Team ID to the project:

1. **Find your Team ID:**
   - Go to [developer.apple.com](https://developer.apple.com)
   - Sign in with your Apple ID
   - Navigate to "Membership" section
   - Copy your Team ID (format: ABC123XYZ4)

2. **Update the project file:**

   Open `/home/user/RT60_ipad_akusti-scan-APP/AcoustiScanApp/AcoustiScanApp.xcodeproj/project.pbxproj` and replace:

   ```
   DEVELOPMENT_TEAM = ""; /* TODO: Set your Apple Developer Team ID here (e.g., "ABC123XYZ4") */
   ```

   With your actual Team ID:

   ```
   DEVELOPMENT_TEAM = "YOUR_TEAM_ID"; /* Example: "ABC123XYZ4" */
   ```

   **Important:** You need to update this in **TWO places** (Debug and Release configurations).

   **OR** simply use Xcode:
   - Open the project in Xcode
   - Select the AcoustiScanApp target
   - Go to "Signing & Capabilities" tab
   - Select your Team from the dropdown

### Step 2: Create/Download Provisioning Profiles

With manual code signing, you need to manage provisioning profiles yourself:

1. **For Development:**
   - Go to [developer.apple.com/account](https://developer.apple.com/account)
   - Navigate to "Certificates, Identifiers & Profiles"
   - Create an App ID with identifier: `com.acoustiscan.app`
   - Enable capabilities: Camera, Microphone (should match entitlements)
   - Create a Development Provisioning Profile
   - Download and install it (double-click the .mobileprovision file)

2. **For Distribution/Production:**
   - Create a Distribution Provisioning Profile
   - Use App Store or Ad Hoc distribution type as needed
   - Download and install it

### Step 3: Configure Xcode (Alternative Method)

If you prefer using Xcode's GUI:

1. Open the project in Xcode
2. Select the **AcoustiScanApp** target
3. Go to **Signing & Capabilities** tab
4. Uncheck "Automatically manage signing" (should already be unchecked)
5. Select your **Team** from the dropdown
6. Select the appropriate **Provisioning Profile** for Debug/Release

### Step 4: Build the App

Once configured, you can build the app:

```bash
# For device
xcodebuild -project AcoustiScanApp.xcodeproj \
  -scheme AcoustiScanApp \
  -configuration Debug \
  -destination 'platform=iOS,name=Your iPad'

# For simulator (doesn't require code signing)
xcodebuild -project AcoustiScanApp.xcodeproj \
  -scheme AcoustiScanApp \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch)'
```

## CI/CD Configuration

For continuous integration and deployment:

### GitHub Actions / CI Pipeline

Set up your CI environment with the following secrets:

1. **Certificate and Profile as Base64:**
   ```bash
   base64 -i certificate.p12 > certificate.base64
   base64 -i profile.mobileprovision > profile.base64
   ```

2. **Add to CI/CD secrets:**
   - `APPLE_CERTIFICATE_BASE64` - Your development/distribution certificate
   - `APPLE_CERT_PASSWORD` - Certificate password
   - `PROVISIONING_PROFILE_BASE64` - Your provisioning profile
   - `DEVELOPMENT_TEAM` - Your Team ID

3. **Example CI workflow step:**
   ```yaml
   - name: Install certificates and profiles
     run: |
       # Import certificate
       echo "${{ secrets.APPLE_CERTIFICATE_BASE64 }}" | base64 --decode > certificate.p12
       security create-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" build.keychain
       security import certificate.p12 -k build.keychain -P "${{ secrets.APPLE_CERT_PASSWORD }}" -T /usr/bin/codesign

       # Import provisioning profile
       echo "${{ secrets.PROVISIONING_PROFILE_BASE64 }}" | base64 --decode > profile.mobileprovision
       mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
       cp profile.mobileprovision ~/Library/MobileDevice/Provisioning\ Profiles/
   ```

## Troubleshooting

### "No signing certificate found"
- Ensure you've created and installed a development certificate from Apple Developer portal
- Check that the certificate is valid and not expired
- Verify the certificate is in your Keychain Access

### "No matching provisioning profile found"
- Ensure the provisioning profile includes the Bundle ID: `com.acoustiscan.app`
- Verify the profile includes your device UDID (for development profiles)
- Check that the profile hasn't expired
- Ensure capabilities match (Camera, Microphone)

### "Team ID not found"
- Verify your Team ID is correct (format: ABC123XYZ4)
- Ensure you have an active Apple Developer Program membership
- Check that you're using the correct Team ID (not the team name)

### Building for Simulator
- Simulator builds don't require code signing
- You can test most features in the simulator, but LiDAR requires a physical device with LiDAR sensor

## Additional Resources

- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Managing Certificates and Profiles](https://developer.apple.com/account/resources/certificates/list)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)

## File Structure

```
AcoustiScanApp/
├── AcoustiScanApp.xcodeproj/
│   └── project.pbxproj              # Contains CODE_SIGN_STYLE and DEVELOPMENT_TEAM settings
├── AcoustiScanApp/
│   ├── AcoustiScan.entitlements     # App entitlements (camera, microphone)
│   └── Resources/
│       └── Info.plist                # Bundle identifier and privacy descriptions
```

## Summary

The project is now configured for manual code signing and ready for development. To get started:

1. [DONE] Set your `DEVELOPMENT_TEAM` ID in project.pbxproj (or via Xcode)
2. [DONE] Create/download provisioning profiles from Apple Developer portal
3. [DONE] Build and run the app on your device or simulator

All other code signing configuration is complete and ready to use!
