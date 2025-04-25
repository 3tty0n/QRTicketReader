//
//  QRDataManager.swift
//  QR Code Reader
//
//  Created by Yusuke Izawa on 2025/04/25.
//

import Foundation

class QRDataManager {
    static let shared = QRDataManager()

    let fileName = "qr_scan_log.csv"

    private init() {}
    
    func initializeFile() {
        guard let url = getFileURL() else {
            print("❌ Failed to get file URL during initialize")
            return
        }

        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
                print("🗑️ Old CSV file removed.")
            } catch {
                print("❌ Error removing old file: \(error.localizedDescription)")
            }
        }

        // 空のファイルを作成（ヘッダー行だけ入れることも可能）
        let header = "\"Timestamp\",\"QRCode\"\n"
        do {
            try header.data(using: .utf8)?.write(to: url)
            print("🆕 New CSV file initialized.")
        } catch {
            print("❌ Error creating new file: \(error.localizedDescription)")
        }
    }

    func save(code: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "\"\(timestamp)\",\"\(code)\"\n"
        if let url = getFileURL() {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    if let handle = try? FileHandle(forWritingTo: url) {
                        handle.seekToEndOfFile()
                        if let data = line.data(using: .utf8) {
                            handle.write(data)
                            handle.closeFile()
                        }
                    }
                } else {
                    try line.data(using: .utf8)?.write(to: url)
                }
                print("✅ Saved to: \(url)")
            } catch {
                print("❌ Save error: \(error.localizedDescription)")
            }
        } else {
            print("❌ Failed to get file URL")
        }
    }

    func getFileURL() -> URL? {
        let fileManager = FileManager.default

        // iCloudのDocumentsフォルダを使う（なければローカル）
        if let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            print("Using iCloud container at: \(containerURL)")
            return containerURL.appendingPathComponent(fileName)
        }

        // ローカルのDocumentsフォルダを使う
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            print("Using local documents at: \(documentsURL)")
            return documentsURL.appendingPathComponent(fileName)
        }

        return nil
    }
}
