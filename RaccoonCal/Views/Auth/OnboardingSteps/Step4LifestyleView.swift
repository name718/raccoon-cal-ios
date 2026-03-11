//
//  Step4LifestyleView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct Step4LifestyleView: View {
    @Binding var activityLevel: String
    @Binding var waterIntake: String
    @Binding var sleepTime: String
    @Binding var favoriteFood: [String]
    @State private var currentQuestion = 0
    let onNext: () -> Void
    
    let foodOptions = ["主食", "肉肉", "蔬菜", "水果", "甜点", "咖啡/茶"]
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
            
            Group {
                if currentQuestion == 0 {
                    activityQuestion
                } else if currentQuestion == 1 {
                    waterQuestion
                } else if currentQuestion == 2 {
                    sleepQuestion
                } else {
                    foodQuestion
                }
            }
            
            Spacer()
        }
    }
    
    private var activityQuestion: some View {
        VStack(spacing: 20) {
            Text("你平时爱运动吗")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                optionButton(title: "懒懒的（几乎不运动）", value: "久坐", binding: $activityLevel)
                optionButton(title: "偶尔动动（每周1-2次）", value: "轻度", binding: $activityLevel)
                optionButton(title: "经常运动（每周3-4次）", value: "中度", binding: $activityLevel)
                optionButton(title: "停不下来（每周5次+）", value: "高度", binding: $activityLevel)
            }
            .padding(.horizontal, 30)
        }
    }
    
    private var waterQuestion: some View {
        VStack(spacing: 20) {
            Text("一天喝几杯水（一杯≈250ml）")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                optionButton(title: "1-2杯", value: "1-2杯", binding: $waterIntake)
                optionButton(title: "3-4杯", value: "3-4杯", binding: $waterIntake)
                optionButton(title: "5-6杯", value: "5-6杯", binding: $waterIntake)
                optionButton(title: "7杯+", value: "7杯+", binding: $waterIntake)
            }
            .padding(.horizontal, 40)
        }
    }
    
    private var sleepQuestion: some View {
        VStack(spacing: 20) {
            Text("晚上几点睡觉（熬夜我会担心的）")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 12) {
                optionButton(title: "10点前", value: "10点前", binding: $sleepTime)
                optionButton(title: "11-12点", value: "11-12点", binding: $sleepTime)
                optionButton(title: "1点后", value: "1点后", binding: $sleepTime)
                optionButton(title: "看心情", value: "看心情", binding: $sleepTime)
            }
            .padding(.horizontal, 40)
        }
    }
    
    private var foodQuestion: some View {
        VStack(spacing: 20) {
            Text("最爱吃什么（偷偷告诉我）")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("可以多选哦")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(foodOptions, id: \.self) { food in
                    Button(action: {
                        if favoriteFood.contains(food) {
                            favoriteFood.removeAll { $0 == food }
                        } else {
                            favoriteFood.append(food)
                        }
                    }) {
                        Text(food)
                            .font(.body)
                            .foregroundColor(favoriteFood.contains(food) ? .white : AppTheme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(favoriteFood.contains(food) ? AppTheme.primary : Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 30)
            
            Button(action: onNext) {
                Text("完成")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(favoriteFood.isEmpty ? Color.gray : AppTheme.primary)
                    .cornerRadius(12)
            }
            .disabled(favoriteFood.isEmpty)
            .padding(.horizontal, 40)
        }
    }
    
    private func optionButton(title: String, value: String, binding: Binding<String>) -> some View {
        Button(action: {
            binding.wrappedValue = value
            withAnimation {
                currentQuestion += 1
            }
        }) {
            Text(title)
                .font(.body)
                .foregroundColor(binding.wrappedValue == value ? .white : AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(binding.wrappedValue == value ? AppTheme.primary : Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
}
