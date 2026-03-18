//
//  CaptchaView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/13.
//

import SwiftUI

struct CaptchaView: View {
    @StateObject private var captchaManager = CaptchaManager()
    @Binding var captchaCode: String
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onVerified: () -> Void
    
    var body: some View {
        VStack(spacing: 15) {
            // 验证码图片
            HStack {
                if captchaManager.isLoading {
                    ProgressView()
                        .frame(width: 120, height: 40)
                } else if let imageData = captchaManager.captchaImage {
                    AsyncImage(url: URL(string: imageData)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text("验证码")
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(width: 120, height: 40)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 120, height: 40)
                        .cornerRadius(8)
                        .overlay(
                            Text("点击刷新")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }
                
                // 刷新按钮
                Button(action: {
                    Task {
                        await captchaManager.generateCaptcha()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(AppTheme.primary)
                        .padding(8)
                }
                .disabled(captchaManager.isLoading)
            }
            
            // 验证码输入框
            HStack {
                TextField("请输入验证码", text: $captchaCode)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .appInputFieldStyle(isInvalid: showError)
                
                Button("验证") {
                    Task {
                        await verifyCaptcha()
                    }
                }
                .disabled(captchaCode.isEmpty)
                .appButtonStyle(kind: .primary, fullWidth: false)
            }
            
            if showError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            Task {
                await captchaManager.generateCaptcha()
            }
        }
    }
    
    @MainActor
    private func verifyCaptcha() async {
        do {
            let isValid = try await captchaManager.verifyCaptcha(code: captchaCode)
            if isValid {
                onVerified()
            } else {
                errorMessage = "验证码错误，请重新输入"
                showError = true
                captchaCode = ""
                await captchaManager.generateCaptcha()
            }
        } catch {
            errorMessage = "验证失败：\(error.localizedDescription)"
            showError = true
        }
    }
}

#Preview {
    CaptchaView(captchaCode: .constant("")) {
        print("验证码验证成功")
    }
    .padding()
}
