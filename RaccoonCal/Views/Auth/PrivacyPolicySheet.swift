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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("隐私政策说明")
                        .font(.headline)
                    
                    Text("当前版本仍处于开发阶段，正式的《隐私政策》和《用户协议》文本尚未接入。\n\n在正式版本上线前，这里会替换为完整的法律文本，并明确说明我们会收集哪些数据、这些数据的用途、保存期限以及你的相关权利。\n\n如果你现在继续登录，表示你已知晓当前页面仍为开发态提示。")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Spacer(minLength: 100)
                }
                .padding()
            }
            
            Button(action: {
                dismiss()
                // 延迟一下让sheet完全关闭后再导航
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigateToLogin = true
                }
            }) {
                Text("继续登录")
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
