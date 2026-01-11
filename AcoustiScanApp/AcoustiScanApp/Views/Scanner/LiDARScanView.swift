import SwiftUI
import RealityKit
import ARKit

/// Mesh classification for surface categorization
enum MeshSurfaceType {
    case floor
    case ceiling
    case wall
    case unknown

    var localizedName: String {
        switch self {
        case .floor:
            return NSLocalizedString(LocalizationKeys.floor, comment: "Floor")
        case .ceiling:
            return NSLocalizedString("ceiling", comment: "Ceiling")
        case .wall:
            return NSLocalizedString(LocalizationKeys.wall, comment: "Wall")
        case .unknown:
            return NSLocalizedString(LocalizationKeys.surface, comment: "Surface")
        }
    }
}

/// Stores mesh geometry data for accurate area calculation
struct MeshGeometryData {
    let identifier: UUID
    let vertices: [SIMD3<Float>]
    let faces: [UInt32]
    let classification: ARMeshClassification?
    let transform: simd_float4x4

    /// Calculate actual surface area from mesh triangles
    var calculatedArea: Double {
        var totalArea: Double = 0.0
        let faceCount = faces.count / 3

        for faceIndex in 0..<faceCount {
            let idx0 = Int(faces[faceIndex * 3])
            let idx1 = Int(faces[faceIndex * 3 + 1])
            let idx2 = Int(faces[faceIndex * 3 + 2])

            guard idx0 < vertices.count,
                  idx1 < vertices.count,
                  idx2 < vertices.count else { continue }

            // Transform vertices to world space
            let v0 = transformPoint(vertices[idx0], by: transform)
            let v1 = transformPoint(vertices[idx1], by: transform)
            let v2 = transformPoint(vertices[idx2], by: transform)

            // Calculate triangle area using cross product
            let edge1 = v1 - v0
            let edge2 = v2 - v0
            let crossProduct = simd_cross(edge1, edge2)
            let triangleArea = Double(simd_length(crossProduct)) / 2.0

            totalArea += triangleArea
        }

        return totalArea
    }

    private func transformPoint(_ point: SIMD3<Float>, by matrix: simd_float4x4) -> SIMD3<Float> {
        let p = SIMD4<Float>(point.x, point.y, point.z, 1.0)
        let transformed = matrix * p
        return SIMD3<Float>(transformed.x, transformed.y, transformed.z)
    }

    /// Determine surface type from mesh classification
    var surfaceType: MeshSurfaceType {
        guard let classification = classification else { return .unknown }

        switch classification {
        case .floor:
            return .floor
        case .ceiling:
            return .ceiling
        case .wall:
            return .wall
        case .door, .window:
            return .wall // Treat doors/windows as wall openings
        case .seat, .table:
            return .unknown // Furniture
        default:
            return .unknown
        }
    }
}

internal class ARCoordinator: NSObject {
    internal var arView: ARView?
    internal weak var store: SurfaceStore?

    /// Tracked planes for area estimation
    private var trackedPlanes: [UUID: ARPlaneAnchor] = [:]

    /// Tracked mesh anchors for precise area calculation
    private var trackedMeshes: [UUID: MeshGeometryData] = [:]

    /// Aggregated mesh areas by surface type
    private(set) var meshAreasByType: [MeshSurfaceType: Double] = [:]

    /// Total scanned mesh area
    var totalMeshArea: Double {
        return meshAreasByType.values.reduce(0, +)
    }

    /// Update mesh anchor with geometry data
    internal func updateMeshAnchor(_ anchor: ARMeshAnchor) {
        let geometry = anchor.geometry

        // Extract vertices
        var vertices: [SIMD3<Float>] = []
        let vertexBuffer = geometry.vertices
        let vertexCount = vertexBuffer.count

        for i in 0..<vertexCount {
            let vertex = vertexBuffer[i]
            vertices.append(SIMD3<Float>(vertex.0, vertex.1, vertex.2))
        }

        // Extract face indices
        var faces: [UInt32] = []
        let faceBuffer = geometry.faces
        let faceCount = faceBuffer.count

        for i in 0..<faceCount {
            // Each face has 3 indices (triangle)
            let bytesPerIndex = faceBuffer.bytesPerIndex
            let offset = i * faceBuffer.indexCountPerPrimitive * bytesPerIndex

            for j in 0..<faceBuffer.indexCountPerPrimitive {
                let indexOffset = offset + j * bytesPerIndex
                var index: UInt32 = 0
                (faceBuffer.buffer.contents() + indexOffset)
                    .copyBytes(to: &index, count: bytesPerIndex)
                faces.append(index)
            }
        }

        // Get classification if available
        var classification: ARMeshClassification?
        if let classificationBuffer = geometry.classification {
            // Use dominant classification for the mesh
            classification = getDominantClassification(from: classificationBuffer)
        }

        let meshData = MeshGeometryData(
            identifier: anchor.identifier,
            vertices: vertices,
            faces: faces,
            classification: classification,
            transform: anchor.transform
        )

        trackedMeshes[anchor.identifier] = meshData

        // Recalculate aggregated areas
        recalculateMeshAreas()
    }

    /// Remove mesh anchor
    internal func removeMeshAnchor(_ identifier: UUID) {
        trackedMeshes.removeValue(forKey: identifier)
        recalculateMeshAreas()
    }

    /// Get dominant classification from classification buffer
    private func getDominantClassification(
        from buffer: ARGeometrySource
    ) -> ARMeshClassification {
        var classificationCounts: [ARMeshClassification: Int] = [:]

        for i in 0..<buffer.count {
            let offset = i * buffer.componentsPerVector * buffer.bytesPerComponent
            var value: UInt8 = 0
            (buffer.buffer.contents() + buffer.offset + offset)
                .copyBytes(to: &value, count: 1)

            if let classification = ARMeshClassification(rawValue: Int(value)) {
                classificationCounts[classification, default: 0] += 1
            }
        }

        return classificationCounts.max(by: { $0.value < $1.value })?.key ?? .none
    }

    /// Recalculate aggregated mesh areas by surface type
    private func recalculateMeshAreas() {
        meshAreasByType = [:]

        for (_, meshData) in trackedMeshes {
            let surfaceType = meshData.surfaceType
            let area = meshData.calculatedArea
            meshAreasByType[surfaceType, default: 0] += area
        }
    }

    /// Get precise area for a point using nearby mesh data
    internal func getPreciseMeshArea(at point: SIMD3<Float>, radius: Float = 0.5) -> Double? {
        var relevantArea: Double = 0.0
        var foundMesh = false

        for (_, meshData) in trackedMeshes {
            let totalVertices = meshData.vertices.count
            guard totalVertices > 0 else { continue }

            var nearbyVertexCount = 0

            // Count how many vertices are within the radius of the point
            for vertex in meshData.vertices {
                let worldVertex = transformVertex(vertex, by: meshData.transform)
                let distance = simd_length(worldVertex - point)

                if distance < radius {
                    nearbyVertexCount += 1
                }
            }

            if nearbyVertexCount > 0 {
                foundMesh = true
                let fraction = Double(nearbyVertexCount) / Double(totalVertices)
                relevantArea += meshData.calculatedArea * fraction
            }
        }

        return foundMesh ? relevantArea : nil
    }

    private func transformVertex(_ vertex: SIMD3<Float>, by matrix: simd_float4x4) -> SIMD3<Float> {
        let p = SIMD4<Float>(vertex.x, vertex.y, vertex.z, 1.0)
        let transformed = matrix * p
        return SIMD3<Float>(transformed.x, transformed.y, transformed.z)
    }

    /// Export all mesh surfaces to store
    internal func exportMeshSurfacesToStore() {
        guard let store = store else { return }

        // Clear existing surfaces
        store.clearAll()

        // Add surfaces by type with mesh-calculated areas
        var surfaceCountByType: [MeshSurfaceType: Int] = [:]

        for (_, meshData) in trackedMeshes {
            let surfaceType = meshData.surfaceType
            let area = meshData.calculatedArea

            // Skip very small surfaces (noise)
            guard area > 0.1 else { continue }

            let count = surfaceCountByType[surfaceType, default: 0] + 1
            surfaceCountByType[surfaceType] = count

            let name = "\(surfaceType.localizedName) \(count)"
            let surface = Surface(name: name, area: area)
            store.add(surface)
        }

        // Calculate and store room volume from mesh bounds
        calculateRoomVolumeFromMesh()
    }

    /// Calculate room volume from mesh bounding box
    private func calculateRoomVolumeFromMesh() {
        guard let store = store, !trackedMeshes.isEmpty else { return }

        var minPoint = SIMD3<Float>(Float.greatestFiniteMagnitude,
                                     Float.greatestFiniteMagnitude,
                                     Float.greatestFiniteMagnitude)
        var maxPoint = SIMD3<Float>(-Float.greatestFiniteMagnitude,
                                     -Float.greatestFiniteMagnitude,
                                     -Float.greatestFiniteMagnitude)

        for (_, meshData) in trackedMeshes {
            for vertex in meshData.vertices {
                let worldVertex = transformVertex(vertex, by: meshData.transform)
                minPoint = simd_min(minPoint, worldVertex)
                maxPoint = simd_max(maxPoint, worldVertex)
            }
        }

        let dimensions = maxPoint - minPoint
        let volume = Double(dimensions.x * dimensions.y * dimensions.z)

        store.roomVolume = volume
        store.roomDimensions = (
            width: Double(dimensions.x),
            height: Double(dimensions.y),
            depth: Double(dimensions.z)
        )
    }

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

    /// Calculate estimated area from raycast result, mesh data, or tracked planes
    /// Priority: 1. Mesh data (most accurate), 2. Plane anchor, 3. Nearby plane
    private func calculateAreaFromRaycast(result: ARRaycastResult) -> Float {
        let hitPosition = simd_make_float3(result.worldTransform.columns.3)

        // Priority 1: Try to get precise area from mesh data (most accurate)
        if !trackedMeshes.isEmpty {
            if let meshArea = getPreciseMeshArea(at: hitPosition, radius: 1.0) {
                // Mesh provides triangle-accurate surface area
                return Float(meshArea)
            }
        }

        // Priority 2: Try to get area from associated anchor if it's a plane
        if let planeAnchor = result.anchor as? ARPlaneAnchor {
            // ARPlaneAnchor provides extent which gives us width and height
            let extent = planeAnchor.planeExtent
            return extent.width * extent.height
        }

        // Priority 3: Find nearby tracked plane
        if #available(iOS 16.0, *) {
            for (_, plane) in trackedPlanes {
                let planePosition = simd_make_float3(plane.transform.columns.3)
                let distance = simd_length(hitPosition - planePosition)

                // If within 2 meters of a tracked plane, use that plane's area
                if distance < 2.0 {
                    return plane.planeExtent.width * plane.planeExtent.height
                }
            }
        }

        // Fallback: Use aggregated mesh area by surface type if available
        if !meshAreasByType.isEmpty {
            let alignment = result.targetAlignment
            switch alignment {
            case .horizontal:
                // Could be floor or ceiling
                let floorArea = meshAreasByType[.floor] ?? 0
                let ceilingArea = meshAreasByType[.ceiling] ?? 0
                if floorArea > 0 || ceilingArea > 0 {
                    return Float(max(floorArea, ceilingArea))
                }
            case .vertical:
                if let wallArea = meshAreasByType[.wall], wallArea > 0 {
                    // Return average wall area
                    let wallCount = trackedMeshes.values.filter { $0.surfaceType == .wall }.count
                    return Float(wallArea / Double(max(1, wallCount)))
                }
            default:
                break
            }
        }

        // Last resort: Default estimation for partial surface detection
        return 2.0 // 2 m^2 as reasonable default
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

    /// Session delegate to track plane and mesh anchors
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
                } else if let meshAnchor = anchor as? ARMeshAnchor {
                    // Process mesh anchor for accurate area calculation
                    coordinator?.updateMeshAnchor(meshAnchor)
                }
            }
        }

        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    coordinator?.updateTrackedPlane(planeAnchor)
                } else if let meshAnchor = anchor as? ARMeshAnchor {
                    // Update mesh anchor geometry
                    coordinator?.updateMeshAnchor(meshAnchor)
                }
            }
        }

        func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
            for anchor in anchors {
                if let planeAnchor = anchor as? ARPlaneAnchor {
                    coordinator?.removeTrackedPlane(planeAnchor.identifier)
                } else if let meshAnchor = anchor as? ARMeshAnchor {
                    coordinator?.removeMeshAnchor(meshAnchor.identifier)
                }
            }
        }
    }
}
