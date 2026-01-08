//  RoomScanView.swift
//  AcoustiScan
//
//  Created in Sprint 2 (RoomPlan & Material) on 29.08.25.
//
//  Dieses Modul integriert Apples RoomPlan‑Framework, um eine
//  LiDAR‑gestützte Raumerfassung durchzuführen.  Es stellt einen
//  Coordinator bereit, der eine `RoomCaptureSession` verwaltet und
//  Oberflächeninformationen (Flächenklassen, Positionen, Flächen) an
//  den `SurfaceStore` weiterreichen kann.  Die implementierten
//  Delegaten sind bewusst minimal gehalten – in einer echten App
//  würden hier die Objekte aus `Room` durchgegangen und zu
//  `LabeledSurface`‑Einträgen verarbeitet.  Bis RoomPlan zur
//  Verfügung steht, dient dies als struktureller Platzhalter.

import SwiftUI
import Combine
import simd

#if canImport(RoomPlan)
import RoomPlan

/// Coordinator zur Verwaltung einer RoomPlan‑Session.  Beobachtet
/// Scan‑Status und übermittelt erfasste Oberflächen an den
/// `SurfaceStore`.  Die Implementierung nutzt `RoomCaptureSession`
/// ab iOS 16.
public final class RoomScanCoordinator: NSObject, ObservableObject, RoomCaptureSessionDelegate {
    /// Flag, ob gerade ein Scan läuft. Dient der UI als Bindung.
    @Published public private(set) var isScanning: Bool = false
    /// Die Raum‑Scan‑Session.
    private let session: RoomCaptureSession
    /// Schwache Referenz auf den Surface‑Store, in den erkannte
    /// Oberflächen geschrieben werden.
    public weak var store: SurfaceStore?

    public override init() {
        self.session = RoomCaptureSession()
        super.init()
    }

    /// Startet die Erfassung mit den Standard‑Einstellungen.
    public func startScanning() {
        // Konfiguration für eine grobe Erfassung mit Coaching UI
        let config = RoomCaptureSession.Configuration()
        config.captureMode = .room
        session.delegate = self
        session.run(configuration: config)
        isScanning = true
    }

    /// Beendet die aktuelle Erfassung.  Nach dem Stop wird der
    /// Delegate `captureSession(_:didEndWith:error:)` aufgerufen.
    public func stopScanning() {
        session.stop()
        isScanning = false
    }

    // MARK: - RoomCaptureSessionDelegate

    public func captureSession(_ session: RoomCaptureSession, didUpdate room: Room) {
        // Dieses Delegate wird regelmäßig während des Scans aufgerufen.
        // Für eine Live‑Visualisierung könnten hier Zwischenergebnisse
        // verarbeitet werden.  In diesem MVP lassen wir den Körper leer.
    }

    public func captureSession(_ session: RoomCaptureSession, didEndWith room: Room, error: Error?) {
        // Verarbeite das finale Room‑Objekt.
        guard let store = store else { return }
        // Lösche alte Oberflächen.  In einer echten Implementierung
        // sollte man entscheiden, ob bestehende Labels übernommen werden.
        store.surfaces.removeAll()

        // Über die API von RoomPlan kann man Wände, Böden und
        // Decken iterieren und ihre Flächen und Klassifikationen
        // auslesen.  Da dies nur auf einem Gerät mit RoomPlan
        // möglich ist, verwenden wir hier Platzhalter.  Die
        // Verarbeitung müsste u. a. so aussehen:
        //
        // for wall in room.walls {
        //     let area = Float(wall.area)
        //     let position = SIMD3<Float>(wall.transform.columns.3.x,
        //                                  wall.transform.columns.3.y,
        //                                  wall.transform.columns.3.z)
        //     store.add(name: "Wand", position: position, area: area, absorptionCoefficient: 0.0)
        // }
        //
        // Die Absorptionskoeffizienten werden initial auf 0 gesetzt und
        // später durch Material‑Tagging ergänzt.

        // MARK: Annahme
        // Da RoomPlan im Simulator nicht verfügbar ist, fügen wir
        // beispielhaft eine Bodenfläche von 20 m² hinzu.  Dies ist
        // lediglich ein Platzhalter und muss im echten Scan ersetzt
        // werden.
        let exampleArea: Float = 20.0
        let examplePosition = SIMD3<Float>(0, 0, 0)
        store.add(name: LocalizationKeys.floor.localized(comment: "Floor surface"), position: examplePosition, area: exampleArea, absorptionCoefficient: 0.0)
    }
}

/// SwiftUI‑View zur Steuerung des Raum‑Scans.  Sie bindet an den
/// Coordinator und bietet einfache Start/Stopp‑Knöpfe.  In einer
/// vollwertigen App würde hier auch die Visualisierung des Scans
/// stattfinden.
public struct RoomScanView: View {
    @ObservedObject var coordinator: RoomScanCoordinator

    public init(coordinator: RoomScanCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        VStack(spacing: 16) {
            Text(coordinator.isScanning ? LocalizationKeys.scanning.localized(comment: "Scanning status") : LocalizationKeys.scanReady.localized(comment: "Scan ready status"))
                .font(.headline)
                .accessibilityLabel(coordinator.isScanning ? "Scanning in progress" : "Scan ready")
                .accessibilityIdentifier("scanStatusLabel")
                .accessibilityAddTraits(.isHeader)
            Button(action: {
                if coordinator.isScanning {
                    coordinator.stopScanning()
                } else {
                    coordinator.startScanning()
                }
            }) {
                Text(coordinator.isScanning ? LocalizationKeys.stopScan.localized(comment: "Stop scan button") : LocalizationKeys.startScan.localized(comment: "Start scan button"))
                    .bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .accessibilityLabel(coordinator.isScanning ? "Stop scan" : "Start scan")
            .accessibilityHint(coordinator.isScanning ? "Stops the room scanning process" : "Starts the room scanning process using LiDAR")
            .accessibilityIdentifier("scanToggleButton")
            .accessibilityAddTraits(.isButton)
        }
        .padding()
        .navigationTitle(LocalizationKeys.lidarScan.localized(comment: "LiDAR scan navigation title"))
    }
}

#endif