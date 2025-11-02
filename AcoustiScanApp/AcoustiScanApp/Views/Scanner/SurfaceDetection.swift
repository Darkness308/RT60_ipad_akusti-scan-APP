import Foundation
import SwiftUI
import ARKit
import Combine

/// Eine einfache SwiftUI-View zur Darstellung erkannter Flächen in ARKit.
struct SurfaceDetectionView: View {
    @StateObject private var coordinator = MSHARCoordinator()
    
    var body: some View {
        ZStack {
            ARViewContainer(coordinator: coordinator)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Erkannte Ebenen: \(coordinator.detectedPlanes.count)")
                    .padding()
                    .background(Color.black.opacity(0.6))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Spacer()
            }
            .padding()
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    var coordinator: MSHARCoordinator

    func makeUIView(context: Context) -> ARSCNView {
        let view = ARSCNView(frame: .zero)
        view.session = coordinator.getSession()
        view.delegate = context.coordinator
        view.autoenablesDefaultLighting = true
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // ggf. updaten, falls State sich ändert
    }

    func makeCoordinator() -> SceneDelegate {
        return SceneDelegate(coordinator: coordinator)
    }

    class SceneDelegate: NSObject, ARSCNViewDelegate {
        var coordinator: MSHARCoordinator

        init(coordinator: MSHARCoordinator) {
            self.coordinator = coordinator
        }

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                DispatchQueue.main.async {
                    self.coordinator.detectedPlanes[planeAnchor.identifier] = planeAnchor
                }
            }
        }

        func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                DispatchQueue.main.async {
                    self.coordinator.detectedPlanes.removeValue(forKey: planeAnchor.identifier)
                }
            }
        }
    }
}
