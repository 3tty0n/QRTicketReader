//
//  QRDataManager.swift
//  QR Code Reader
//
//  Created by Yusuke Izawa on 2025/04/25.
//

import Foundation

class QRDataManager {
    static let shared = QRDataManager()

    private var fileName: String = ""

    private init() {}

    func initializeFile() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")

        let timestamp = formatter.string(from: Date())
        fileName = "qr_scan_log_\(timestamp).csv"

        guard let url = getFileURL() else {
            print("❌ Failed to get file URL during initialize")
            return
        }

        // 作成：ヘッダー行だけ
        let header = "\"Timestamp\",\"QRCode\",\"ID\",\"Name\"\n"

        do {
            try header.data(using: .utf8)?.write(to: url)
            print("🆕 New CSV file created: \(fileName)")
        } catch {
            print("❌ Error creating new file: \(error.localizedDescription)")
        }
    }

    func save(code: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let timestamp = formatter.string(from: Date())

        // --- QRコードの中身を解析 ---
        var id = ""
        var name = ""

        // 正規表現：先頭に8桁の数字、その後ろに名前（全角 or 半角スペース区切り）を想定
        let pattern = #"^(\d{8})[　]+(.+)$"#
        if let match = code.range(of: pattern, options: .regularExpression) {
            let matchedString = String(code[match])
            let components = matchedString.components(separatedBy: CharacterSet(charactersIn: " 　")).filter { !$0.isEmpty }
            if components.count >= 2 {
                id = components[0]
                name = components.dropFirst().joined(separator: " ")
            }
        }

        // --- CSV行を作成 ---
        let line = "\"\(timestamp)\",\"\(code)\",\"\(id)\",\"\(name)\"\n"

        guard let url = getFileURL() else {
            print("❌ Failed to get file URL")
            return
        }

        do {
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                if let data = line.data(using: .utf8) {
                    handle.write(data)
                    handle.closeFile()
                }
            }
        } catch {
            print("❌ Save error: \(error.localizedDescription)")
        }
    }

    func getFileURL() -> URL? {
        let fileManager = FileManager.default

        if fileName.isEmpty {
            return nil
        }

        // iCloud優先
        if let containerURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("Documents") {
            return containerURL.appendingPathComponent(fileName)
        }

        // ローカル fallback
        if let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            return documentsURL.appendingPathComponent(fileName)
        }

        return nil
    }
}
