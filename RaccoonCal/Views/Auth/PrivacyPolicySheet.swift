//
//  PrivacyPolicySheet.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct PrivacyPolicySheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var navigateToLogin: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("隐私政策")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 30)
            
            // 隐私政策内容占位
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("隐私政策内容")
                        .font(.headline)
                    
                    Text("这里是隐私政策的详细内容占位文本。\n\n我们重视您的隐私，会妥善保管您的个人信息。\n\n使用本应用即表示您同意我们的隐私政策和用户协议。")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            
            // 同意并进入按钮
            Button(action: {
                dismiss()
                // 延迟一下让sheet完全关闭后再导航
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigateToLogin = true
                }
            }) {
                Text("同意并进入")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primary)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
    }
}

#Preview {
    PrivacyPolicySheet(navigateToLogin: .constant(false))
}