//
//  ScannerView.swift
//  QR Code Reader
//
//  Created by Yusuke Izawa on 2025/04/25.
//
import SwiftUI

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    var onScan: (String) -> Void
    var scanArea: CGRect // ← 追加: 表示エリアを渡す！

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        controller.scanArea = scanArea // ← エリア設定を渡す！
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, QRScannerDelegate {
        var parent: ScannerView

        init(_ parent: ScannerView) {
            self.parent = parent
        }

        func didFind(code: String) {
            parent.scannedCode = code
            parent.onScan(code)
        }
    }
}
