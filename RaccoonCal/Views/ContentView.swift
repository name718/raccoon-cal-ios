//
//  ContentView.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // 顶部欢迎区域
                VStack(spacing: 15) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("欢迎使用浣熊卡路里")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("拍照识别食物，开始你的健康之旅")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                Spacer()
                
                // 功能按钮区域
                VStack(spacing: 20) {
                    Button(action: {
                        // TODO: 拍照功能
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("拍照识别卡路里")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // TODO: 查看宠物
                    }) {
                        HStack {
                            Image(systemName: "pawprint")
                            Text("我的浣熊宠物")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // TODO: 社交功能
                    }) {
                        HStack {
                            Image(systemName: "person.2")
                            Text("好友排行榜")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("浣熊卡路里")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

#Preview {
    ContentView()
}
