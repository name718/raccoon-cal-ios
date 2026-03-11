//
//  OnboardingView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct OnboardingView: View {
    @State private var navigateToMain = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 40) {
                Spacer()
                
                // 占位内容
                VStack(spacing: 20) {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                    
                    Text("新用户引导")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("这里是新用户引导页面占位")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // 临时跳过按钮
                Button(action: {
                    navigateToMain = true
                }) {
                    Text("跳过（临时）")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            
            // 隐藏的导航链接
            NavigationLink(destination: MainTabView().navigationBarBackButtonHidden(true), isActive: $navigateToMain) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        OnboardingView()
    }
}