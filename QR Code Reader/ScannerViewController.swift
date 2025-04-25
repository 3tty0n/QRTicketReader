//
//  ScannerViewController.swift
//  QR Code Reader
//
//  Created by Yusuke Izawa on 2025/04/25.
//

import UIKit
import AVFoundation

protocol QRScannerDelegate: AnyObject {
    func didFind(code: String)
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: QRScannerDelegate?
    
    var scanArea: CGRect = .zero // ← SwiftUIから受け取る

    private var overlayView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        captureSession = AVCaptureSession()
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoInput) else {
            return
        }

        captureSession.addInput(videoInput)

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else { return }
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        metadataOutput.metadataObjectTypes = [.qr]

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first,
              let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue,
              let transformedObject = previewLayer.transformedMetadataObject(for: readableObject) else {
            return
        }

        // ✅ 認識したQRコードの領域を囲む
        showOverlay(for: transformedObject.bounds)

        // ✅ 一時停止 & データ通知
        captureSession.stopRunning()
        delegate?.didFind(code: stringValue)

        // ✅ 2秒後に再開 & 四角を消す
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.captureSession.startRunning()
            self.removeOverlay()
        }
    }

    private func showOverlay(for bounds: CGRect) {
        removeOverlay()

        let overlay = UIView(frame: bounds)
        overlay.layer.borderColor = UIColor.red.cgColor
        overlay.layer.borderWidth = 4
        overlay.layer.cornerRadius = 4
        overlay.backgroundColor = UIColor.clear

        view.addSubview(overlay)
        overlayView = overlay
    }

    private func removeOverlay() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}
