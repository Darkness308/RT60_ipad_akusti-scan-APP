//  RoomScanView.swift
//  AcoustiScan
//
//  RoomPlan integration for LiDAR-based room capture.
//  Provides automatic surface detection and area calculation.

import SwiftUI
import Combine
import simd

#if canImport(RoomPlan)
import RoomPlan

/// Coordinator for managing a RoomPlan capture session.
/// Observes scan status and transfers captured surfaces to SurfaceStore.
public final class RoomScanCoordinator: NSObject, ObservableObject, RoomCaptureSessionDelegate {

    /// Flag indicating if scan is in progress
    @Published public private(set) var isScanning: Bool = false

    /// Number of surfaces detected during current scan
    @Published public private(set) var detectedSurfaceCount: Int = 0

    /// The room capture session
    private let session: RoomCaptureSession

    /// Weak reference to surface store
    public weak var store: SurfaceStore?

    public override init() {
        self.session = RoomCaptureSession()
        super.init()
    }

    /// Start scanning with default configuration
    public func startScanning() {
        let config = RoomCaptureSession.Configuration()
        session.delegate = self
        session.run(configuration: config)
        isScanning = true
        detectedSurfaceCount = 0
    }

    /// Stop the current scan
    public func stopScanning() {
        session.stop()
        isScanning = false
    }

    // MARK: - RoomCaptureSessionDelegate

    public func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        // Update surface count during live scan
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let wallCount = room.walls.count
            let floorCount = room.floors.count
            let ceilingCount = room.doors.count // Using doors as proxy for openings
            self.detectedSurfaceCount = wallCount + floorCount + ceilingCount
        }
    }

    public func captureSession(
        _ session: RoomCaptureSession,
        didEndWith data: CapturedRoomData,
        error: Error?
    ) {
        guard let store = store else { return }

        // Handle any errors
        if let error = error {
            ErrorLogger.log(error, context: "RoomScanCoordinator.didEndWith", level: .error)
            return
        }

        // Process the final room data
        DispatchQueue.main.async { [weak self] in
            self?.processRoomData(data, store: store)
        }
    }

    /// Process captured room data and add surfaces to store
    private func processRoomData(_ data: CapturedRoomData, store: SurfaceStore) {
        // Clear existing surfaces for fresh scan
        store.clearAll()

        // Process walls
        for (index, wall) in data.walls.enumerated() {
            let dimensions = wall.dimensions
            let area = Double(dimensions.x * dimensions.y) // width * height
            let surface = Surface(
                name: "\(NSLocalizedString(LocalizationKeys.wall, comment: "Wall")) \(index + 1)",
                area: area
            )
            store.add(surface)
        }

        // Process floors
        for (index, floor) in data.floors.enumerated() {
            let dimensions = floor.dimensions
            let area = Double(dimensions.x * dimensions.z) // width * depth
            let surface = Surface(
                name: "\(NSLocalizedString(LocalizationKeys.floor, comment: "Floor")) \(index + 1)",
                area: area
            )
            store.add(surface)
        }

        // Process ceilings (if available in API)
        // Note: RoomPlan may not expose ceilings directly in all versions
        // We estimate ceiling area from floor area
        let totalFloorArea = data.floors.reduce(0.0) { total, floor in
            total + Double(floor.dimensions.x * floor.dimensions.z)
        }
        if totalFloorArea > 0 {
            let ceilingSurface = Surface(
                name: NSLocalizedString("ceiling", comment: "Ceiling"),
                area: totalFloorArea
            )
            store.add(ceilingSurface)
        }

        // Calculate room volume from bounding box or dimensions
        calculateRoomVolume(from: data, store: store)
    }

    /// Calculate room volume from captured data
    private func calculateRoomVolume(from data: CapturedRoomData, store: SurfaceStore) {
        // Estimate volume from floor area and wall heights
        var maxWallHeight: Float = 2.5 // Default ceiling height

        for wall in data.walls {
            let height = wall.dimensions.y
            if height > maxWallHeight {
                maxWallHeight = height
            }
        }

        let totalFloorArea = data.floors.reduce(0.0) { total, floor in
            total + Double(floor.dimensions.x * floor.dimensions.z)
        }

        store.roomVolume = totalFloorArea * Double(maxWallHeight)

        // Set room dimensions if we can estimate them
        if let firstFloor = data.floors.first {
            store.roomDimensions = (
                width: Double(firstFloor.dimensions.x),
                height: Double(maxWallHeight),
                depth: Double(firstFloor.dimensions.z)
            )
        }
    }
}

/// SwiftUI view for room scanning control
public struct RoomScanView: View {
    @ObservedObject var coordinator: RoomScanCoordinator

    public init(coordinator: RoomScanCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        VStack(spacing: 20) {
            // Status display
            VStack(spacing: 8) {
                Text(coordinator.isScanning
                     ? NSLocalizedString(LocalizationKeys.scanning, comment: "Scanning")
                     : NSLocalizedString(LocalizationKeys.scanReady, comment: "Ready"))
                    .font(.headline)
                    .accessibilityLabel(coordinator.isScanning ? "Scanning in progress" : "Scan ready")
                    .accessibilityIdentifier("scanStatusLabel")
                    .accessibilityAddTraits(.isHeader)

                if coordinator.isScanning {
                    Text("\(coordinator.detectedSurfaceCount) surfaces detected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("\(coordinator.detectedSurfaceCount) surfaces detected")
                }
            }

            // Scan button
            Button(action: {
                if coordinator.isScanning {
                    coordinator.stopScanning()
                } else {
                    coordinator.startScanning()
                }
            }) {
                HStack {
                    Image(systemName: coordinator.isScanning ? "stop.fill" : "camera.fill")
                    Text(coordinator.isScanning
                         ? NSLocalizedString(LocalizationKeys.stopScan, comment: "Stop")
                         : NSLocalizedString(LocalizationKeys.startScan, comment: "Start"))
                        .bold()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(coordinator.isScanning ? Color.red : Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .accessibilityLabel(coordinator.isScanning ? "Stop scan" : "Start scan")
            .accessibilityHint(coordinator.isScanning
                              ? "Stops the room scanning process"
                              : "Starts the room scanning process using LiDAR")
            .accessibilityIdentifier("scanToggleButton")
            .accessibilityAddTraits(.isButton)

            // Instructions
            if !coordinator.isScanning {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Instructions:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text("1. Point your iPad at the room")
                    Text("2. Slowly scan all walls, floor, and ceiling")
                    Text("3. Keep the device steady for best results")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .navigationTitle(NSLocalizedString(LocalizationKeys.lidarScan, comment: "LiDAR Scan"))
    }
}

#else

// Fallback for platforms without RoomPlan (pre-iOS 16 or Simulator)
public struct RoomScanView: View {
    @ObservedObject var store: SurfaceStore

    public init(store: SurfaceStore) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lidar.not.available")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("RoomPlan Not Available")
                .font(.headline)

            Text("RoomPlan requires iOS 16+ and a device with LiDAR sensor.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Use manual room dimension entry or LiDAR scan instead.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Room Scan")
    }
}

#endif
