//
//  OnboardingView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentStep = 0
    @State private var onboardingData = OnboardingData()
    @State private var showExitAlert = false
    @State private var navigateToMain = false
    @State private var showRegisterPrompt = false
    
    var body: some View {
        ZStack {
            if showRegisterPrompt {
                RegisterPromptView(
                    navigateToMain: $navigateToMain,
                    navigateToRegister: .constant(false)
                )
            } else {
                VStack {
                    // 顶部进度和按钮
                    HStack {
                        // 返回按钮
                        if currentStep > 0 && !showRegisterPrompt {
                            Button(action: {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(AppTheme.primary)
                                    .padding()
                            }
                        } else {
                            Spacer()
                                .frame(width: 44)
                        }
                        
                        // 进度条
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { index in
                                Capsule()
                                    .fill(index <= currentStep ? AppTheme.primary : Color.gray.opacity(0.3))
                                    .frame(height: 4)
                            }
                        }
                        
                        // 关闭按钮
                        Button(action: {
                            showExitAlert = true
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.gray)
                                .padding()
                        }
                    }
                    
                    // 当前步骤内容
                    currentStepView
                }
            }
            
            // 隐藏的导航链接
            NavigationLink(destination: MainTabView().navigationBarBackButtonHidden(true), isActive: $navigateToMain) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarHidden(true)
        .alert("确定要退出吗？", isPresented: $showExitAlert) {
            Button("继续填写", role: .cancel) { }
            Button("退出", role: .destructive) {
                navigateToMain = true
            }
        } message: {
            Text("退出后你填写的信息将不会被保存哦")
        }
    }
    
    @ViewBuilder
    private var currentStepView: some View {
        switch currentStep {
        case 0:
            Step1NicknameView(
                nickname: $onboardingData.nickname,
                onNext: nextStep
            )
            
        case 1:
            Step2BasicInfoView(
                gender: $onboardingData.gender,
                height: $onboardingData.height,
                weight: $onboardingData.weight,
                age: $onboardingData.age,
                onNext: nextStep
            )
            
        case 2:
            Step3GoalView(
                goal: $onboardingData.goal,
                goalDuration: $onboardingData.goalDuration,
                onNext: nextStep
            )
            
        case 3:
            Step4LifestyleView(
                activityLevel: $onboardingData.activityLevel,
                waterIntake: $onboardingData.waterIntake,
                sleepTime: $onboardingData.sleepTime,
                favoriteFood: $onboardingData.favoriteFood,
                onNext: nextStep
            )
            
        case 4:
            Step5CompleteView(
                nickname: onboardingData.nickname,
                onComplete: {
                    // 保存数据到本地
                    onboardingData.save()
                    // 显示注册提示
                    withAnimation {
                        showRegisterPrompt = true
                    }
                }
            )
            
        default:
            EmptyView()
        }
    }
    
    private func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }
}

#Preview {
    NavigationView {
        OnboardingView()
    }
}
