@preconcurrency import AVFoundation
import SwiftUI
import UIKit

struct CodeScanner: UIViewControllerRepresentable {
    let scanned: (String) -> Void
    let failed: (String) -> Void
    func makeUIViewController(context: Context) -> ScannerController {
        ScannerController(scanned: scanned, failed: failed)
    }
    func updateUIViewController(_ controller: ScannerController, context: Context) {}
}

@MainActor final class ScannerController: UIViewController, @preconcurrency AVCaptureMetadataOutputObjectsDelegate {
    private let capture = AVCaptureSession()
    private let queue = DispatchQueue(label: "com.marcellovictorino.infinitary.camera")
    private var preview: AVCaptureVideoPreviewLayer?
    private var delivered = false
    private var visible = false
    private let scanned: (String) -> Void
    private let failed: (String) -> Void

    init(scanned: @escaping (String) -> Void, failed: @escaping (String) -> Void) {
        self.scanned = scanned; self.failed = failed
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Not used") }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated); visible = true
        Task {
            let allowed = await AVCaptureDevice.requestAccess(for: .video)
            guard visible else { return }
            guard allowed else {
                failed("Allow Camera for Infinitary in Settings, or paste the link instead."); return
            }
            configure()
        }
    }

    private func configure() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera), capture.canAddInput(input)
        else { failed("This device has no camera available. Paste your computer’s link instead."); return }
        capture.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard capture.canAddOutput(output) else { failed("Could not open the camera. Paste the link instead."); return }
        capture.addOutput(output); output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: capture)
        preview.videoGravity = .resizeAspectFill; self.preview = preview
        view.layer.addSublayer(preview); preview.frame = view.bounds
        let capture = capture
        queue.async { capture.startRunning() }
    }

    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); preview?.frame = view.bounds }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated); visible = false
        let capture = capture
        queue.async { capture.stopRunning() }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !delivered, visible, let value = metadataObjects.compactMap({ ($0 as? AVMetadataMachineReadableCodeObject)?.stringValue }).first else { return }
        delivered = true; scanned(value)
    }
}
