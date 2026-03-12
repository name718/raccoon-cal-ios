//
//  Step2BasicInfoView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct Step2BasicInfoView: View {
    @Binding var gender: String
    @Binding var height: Int
    @Binding var weight: Int
    @Binding var age: Int
    @State private var currentQuestion = 0
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 浣熊拿着尺子和秤
            Image("RaccoonMeasuring")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
            if currentQuestion == 0 {
                // 性别选择
                VStack(spacing: 20) {
                    Text("你是我的小哥哥还是小姐姐")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        genderButton(title: "小哥哥", value: "男")
                        genderButton(title: "小姐姐", value: "女")
                        genderButton(title: "保密", value: "保密")
                    }
                    .padding(.horizontal, 40)
                }
            } else if currentQuestion == 1 {
                // 身高
                VStack(spacing: 20) {
                    Text("你有多高，让我仰视一下")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("\(height) cm")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                    
                    Slider(value: Binding(
                        get: { Double(height) },
                        set: { height = Int($0) }
                    ), in: 140...220, step: 1)
                        .accentColor(AppTheme.primary)
                        .padding(.horizontal, 40)
                    
                    nextButton
                }
            } else if currentQuestion == 2 {
                // 体重
                VStack(spacing: 20) {
                    Text("现在多重，放心我嘴很严的")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("\(weight) kg")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                    
                    Slider(value: Binding(
                        get: { Double(weight) },
                        set: { weight = Int($0) }
                    ), in: 30...150, step: 1)
                        .accentColor(AppTheme.primary)
                        .padding(.horizontal, 40)
                    
                    nextButton
                }
            } else {
                // 年龄
                VStack(spacing: 20) {
                    Text("你今年几岁了（我才1岁嘿嘿）")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("\(age) 岁")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                    
                    Slider(value: Binding(
                        get: { Double(age) },
                        set: { age = Int($0) }
                    ), in: 10...100, step: 1)
                        .accentColor(AppTheme.primary)
                        .padding(.horizontal, 40)
                    
                    Button(action: onNext) {
                        Text("完成")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
            }
            
            Spacer()
        }
    }
    
    private func genderButton(title: String, value: String) -> some View {
        Button(action: {
            gender = value
            withAnimation {
                currentQuestion = 1
            }
        }) {
            Text(title)
                .font(.headline)
                .foregroundColor(gender == value ? .white : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(gender == value ? AppTheme.primary : Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    private var nextButton: some View {
        Button(action: {
            withAnimation {
                currentQuestion += 1
            }
        }) {
            Text("下一步")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primary)
                .cornerRadius(12)
        }
        .padding(.horizontal, 40)
    }
}
