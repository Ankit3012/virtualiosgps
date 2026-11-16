# Virtual GPS — iOS starter project

A SwiftUI / MapKit app for selecting and saving a location **inside this app**.

## Important platform limitation

This app does **not** override iOS system location or change what other installed apps receive from Core Location, Find My, WhatsApp, Google Maps, etc. Ordinary third-party iOS apps cannot use a public API to inject system-wide GPS coordinates.

This starter includes:
- Interactive MapKit map
- Tap map to select a coordinate
- Search by place/address using CLGeocoder
- Manual latitude/longitude entry
- Save and reopen favourite places
- In-app simulation state

## Project files

- `VirtualGPS/VirtualGPSApp.swift`
- `VirtualGPS/ContentView.swift`
- `project.yml` — XcodeGen project definition
- `codemagic.yaml` — cloud macOS compile workflow

## How to build without owning a Mac

1. Create a GitHub repository from this project and upload these files.
2. Create a Codemagic account and connect the GitHub repository.
3. Codemagic runs Xcode on a hosted macOS machine. It first generates the Xcode project using XcodeGen and runs an unsigned compile check.
4. To install on your iPhone, configure Apple code signing in Codemagic. For TestFlight distribution, use an Apple Developer Program membership and App Store Connect signing/distribution setup.
5. Install Apple's TestFlight app on the iPhone, accept the tester invitation, and install the build.

Official references:
- Codemagic native iOS builds: https://docs.codemagic.io/yaml-quick-start/building-a-native-ios-app/
- Codemagic signed build: https://docs.codemagic.io/yaml-quick-start/first-signed-build/
- Apple TestFlight: https://testflight.apple.com/
- Apple Xcode Cloud: https://developer.apple.com/documentation/Xcode/Xcode-Cloud

## Can I install it directly from this ZIP?

No. Source code is not an installable iPhone app. iOS requires a compiled and properly signed app build. The included Codemagic workflow is an unsigned compile check; signing and distribution must be configured separately.

## Minimum target

iOS 17.0 or later. Intended for iPhone, including iPhone 13 on iOS 26.
