import SwiftUI
import RealityKit
import ARKit

internal class ARCoordinator: NSObject {
    internal var arView: ARView?
    internal weak var store: SurfaceStore?

    /// Tracked planes for area estimation
    private var trackedPlanes: [UUID: ARPlaneAnchor] = [:]

    @objc internal func handleTap(_ sender: UITapGestureRecognizer) {
        guard let view = arView else { return }
        let location = sender.location(in: view)

        // Raycast to find surfaces
        guard let result = view.raycast(
            from: location,
            allowing: .estimatedPlane,
            alignment: .any
        ).first else { return }

        let position = simd_make_float3(result.worldTransform.columns.3)

        // Calculate area from the detected plane if available
        let areaEstimate = calculateAreaFromRaycast(result: result)

        // Determine surface type based on alignment
        let surfaceName = determineSurfaceName(alignment: result.targetAlignment)
        let surfaceIndex = (store?.surfaces.count ?? 0) + 1
        let name = "\(surfaceName) \(surfaceIndex)"

        // Create Surface with correct signature
        let surface = Surface(
            name: name,
            area: Double(areaEstimate)
        )
        store?.add(surface)

        // Visual feedback - add a marker sphere
        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.02))
        sphere.model?.materials = [SimpleMaterial(color: .systemBlue, isMetallic: false)]
        let anchor = AnchorEntity(world: position)
        anchor.addChild(sphere)
        arView?.scene.addAnchor(anchor)
    }

    /// Calculate estimated area from raycast result and tracked planes
    private func calculateAreaFromRaycast(result: ARRaycastResult) -> Float {
        // Try to get area from associated anchor if it's a plane
        if let planeAnchor = result.anchor as? ARPlaneAnchor {
            // ARPlaneAnchor provides extent which gives us width and height
            let extent = planeAnchor.planeExtent
            return extent.width * extent.height
        }

        // For estimated planes without anchor, use geometry if available
        if #available(iOS 16.0, *) {
            // Try to find nearby tracked plane
            let hitPosition = simd_make_float3(result.worldTransform.columns.3)
            for (_, plane) in trackedPlanes {
                let planePosition = simd_make_float3(plane.transform.columns.3)
                let distance = simd_length(hitPosition - planePosition)

                // If within 2 meters of a tracked plane, use that plane's area
                if distance < 2.0 {
                    return plane.planeExtent.width * plane.planeExtent.height
                }
            }
        }

        // Default estimation for small detected surfaces
        // Based on typical room element sizes
        return 2.0 // 2 m² as reasonable default for partial surface detection
    }

    /// Determine surface name based on plane alignment
    private func determineSurfaceName(alignment: ARRaycastResult.TargetAlignment) -> String {
        switch alignment {
        case .horizontal:
            return NSLocalizedString(LocalizationKeys.floor, comment: "Floor surface")
        case .vertical:
            return NSLocalizedString(LocalizationKeys.wall, comment: "Wall surface")
        case .any:
            return NSLocalizedString(LocalizationKeys.surface, comment: "Surface")
        @unknown default:
            return NSLocalizedString(LocalizationKeys.surface, comment: "Surface")
        }
    }

    /// Update tracked planes from AR session
    internal func updateTrackedPlane(_ anchor: ARPlaneAnchor) {
        trackedPlanes[anchor.identifier] = anchor
    }

    /// Remove tracked plane
    internal func removeTrackedPlane(_ identifier: UUID) {
        trackedPlanes.removeValue(forKey: identifier)
    }
}

struct LiDARScanView: UIViewRepresentable {
    @ObservedObject var store: SurfaceStore

    func makeCoordinator() -> ARCoordinator {
        let coordinator = ARCoordinator()
        coordinator.store = store
        return coordinator
    }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView

        // Configure AR session for LiDAR scanning
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]

        // Enable scene reconstruction if available (requires LiDAR)
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }

        // Enable frame semantics for better detection
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth) {
            config.frameSemantics.insert(.sceneDepth)
        }

        arView.session.run(config)

        // Set up session delegate for plane tracking
        arView.session.delegate = SessionDelegate(coordinator: context.coordinator)

        // Add tap gesture for surface marking
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(ARCoordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tap)

        // Accessibility configuration
        arView.isAccessibilityElement = true
        arView.accessibilityLabel = NSLocalizedString(
            "lidar_scan_view",
            comment: "LiDAR scanning view"
        )
        arView.accessibilityHint = NSLocalizedString(
            "lidar_scan_hint",
            comment: "Tap to mark surfaces"
        )
        arView.accessibilityTraits = .allowsDirectInteraction
        arView.accessibilityIdentifier = "lidarARView"

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    /// Session delegate to track plane anchors
    private class SessionDelegate: NSObject, ARSessionDelegate {
        weak var coordinator: ARCoordinator?

        init(coordinator: ARCoordinator) {
            self.coordinator = coordinator
            super.init()
        }

        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    coordinator?.updateTrackedPlane(planeAnchor)
                }
            }
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    coordinator?.updateTrackedPlane(planeAnchor)
                }
            }
        }

        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    coordinator?.removeTrackedPlane(planeAnchor.identifier)
                }
            }
        }
    }
}
