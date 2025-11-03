import SwiftUI
import RealityKit
import ARKit

class ARCoordinator: NSObject {
    var arView: ARView?
    var store: SurfaceStore?

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        guard let view = arView else { return }
        let location = sender.location(in: view)
        guard let result = view.raycast(from: location, allowing: .estimatedPlane, alignment: .any).first else { return }

        let position = simd_make_float3(result.worldTransform.columns.3)
        let areaEstimate: Float = 1.0 // placeholder
        let name = "Fläche \(store?.surfaces.count ?? 0 + 1)"

        store?.add(name: name, position: position, area: areaEstimate)

        let sphere = ModelEntity(mesh: .generateSphere(radius: 0.01))
        sphere.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
        let anchor = AnchorEntity(world: position)
        anchor.addChild(sphere)
        arView?.scene.addAnchor(anchor)
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

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.sceneReconstruction = .mesh
        arView.session.run(config)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(ARCoordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}