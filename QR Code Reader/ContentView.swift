//
//  ContentView.swift
//  QR Code Reader
//
//  Created by Yusuke Izawa on 2025/04/25.
//

import SwiftUI
import MessageUI

struct ScanResult: Identifiable, Hashable {
    let id = UUID()
    let code: String
    let timestamp: Date
}


struct ContentView: View {
    @State private var scannedCode: String = ""
    @State private var scannedCodes: [ScanResult] = []
    @State private var scannedSet: Set<String> = []          // 重複チェック用
    @State private var scanRect: CGRect = .zero // ← フレーム保持用
    @State private var showResetAlert = false
    
    @State private var isShowingMailView = false
    @State private var mailErrorAlert = false
    
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss" // 24時間形式
        return formatter
    }()
    
    var body: some View {
            NavigationView {
                VStack(spacing: 20) {
                    GeometryReader { geo in
                        ScannerView(
                            scannedCode: $scannedCode,
                            onScan: { code in
                                guard !scannedSet.contains(code) else { return }
                                scannedSet.insert(code)
                                let now = Date()
                                let result = ScanResult(code: code, timestamp: now)
                                scannedCodes.append(result)
                                    
                                scannedCode = code
                                QRDataManager.shared.save(code: code) // ファイル保存
                                
                                // 成功時に音と振動を鳴らす
                                playSuccessFeedback()
                            },
                            scanArea: geo.frame(in: .global) // ← グローバル座標系で取得
                        )
                        .onAppear {
                            scanRect = geo.frame(in: .global)
                        }
                    }
                    .frame(height: UIScreen.main.bounds.height * 0.45)
                    .cornerRadius(12)
                    .shadow(radius: 5)
                    .padding()

                    List(scannedCodes.reversed()) { result in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.code)
                                .font(.body)
                            Text(dateFormatter.string(from: result.timestamp))
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(4)
                    }
                    
                }
                .navigationTitle("QRコードスキャナ")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button(action: {
                                showResetAlert = true
                            }) {
                                Image(systemName: "arrow.counterclockwise")
                                    .accessibilityLabel("履歴をリセット")
                            }
                            .alert("履歴をリセットしますか？", isPresented: $showResetAlert) {
                                Button("リセット", role: .destructive) {
                                    scannedSet.removeAll()
                                    scannedCodes.removeAll()
                                }
                                Button("キャンセル", role: .cancel) {}
                            }
                        
                            Button {
                                if MFMailComposeViewController.canSendMail(),
                                    let url = QRDataManager.shared.getFileURL() {
                                        isShowingMailView = true
                                    } else {
                                        mailErrorAlert = true
                                    }
                                } label: {
                                    Image(systemName: "envelope")
                                }
                        }
                    }
                }
                .sheet(isPresented: $isShowingMailView) {
                    if let url = QRDataManager.shared.getFileURL() {
                        MailView(csvURL: url, subject: "QRコード読み取り履歴")
                    }
                }
                .alert("メール送信できません", isPresented: $mailErrorAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("このデバイスではメール送信がサポートされていないか、設定されていません。")
                }
            }
            .onAppear {
                QRDataManager.shared.initializeFile()
            }
        }
}


#Preview {
    ContentView()
}
