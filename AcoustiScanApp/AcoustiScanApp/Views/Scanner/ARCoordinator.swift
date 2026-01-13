import Foundation
import ARKit
import Combine
import SwiftUI

final class MSHARCoordinator: NSObject, ARSessionDelegate, ObservableObject {

    // MARK: - Published Properties
    @Published var currentFrame: ARFrame?
    @Published var detectedPlanes: [UUID: ARPlaneAnchor] = [:]

    // MARK: - Private
    private let session: ARSession = ARSession()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    override init() {
        super.init()
        session.delegate = self
        startSession()
    }

    // MARK: - Public Access
    func getSession() -> ARSession {
        return session
    }

    // MARK: - Session Management
    private func startSession() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func pauseSession() {
        session.pause()
    }

    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentFrame = frame
        }
    }

    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                detectedPlanes[planeAnchor.identifier] = planeAnchor
            }
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                detectedPlanes[planeAnchor.identifier] = planeAnchor
            }
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            detectedPlanes.removeValue(forKey: anchor.identifier)
        }
    }
}
