//
//  AppTheme.swift
//  RaccoonCal
//
//  Created by didi on 2026/3/11.
//

import SwiftUI

struct AppTheme {
    // MARK: - 主色 - 温暖的琥珀橙
    static let primary = Color(red: 255/255, green: 179/255, blue: 71/255) // #FFB347
    static let primaryLight = Color(red: 255/255, green: 212/255, blue: 163/255) // #FFD4A3
    static let primaryDark = Color(red: 230/255, green: 160/255, blue: 66/255) // #E6A042
    
    // MARK: - 辅色 - 清新草绿
    static let secondary = Color(red: 124/255, green: 179/255, blue: 66/255) // #7CB342
    static let secondaryLight = Color(red: 165/255, green: 214/255, blue: 167/255) // #A5D6A7
    static let secondaryDark = Color(red: 104/255, green: 159/255, blue: 56/255) // #689F38
    
    // MARK: - 背景色 - 奶油白
    static let backgroundPrimary = Color(red: 255/255, green: 249/255, blue: 240/255) // #FFF9F0
    static let backgroundSecondary = Color(red: 245/255, green: 245/255, blue: 240/255) // #F5F5F0
    
    // MARK: - 点缀色 - 珊瑚粉
    static let accent = Color(red: 255/255, green: 107/255, blue: 107/255) // #FF6B6B
    static let accentLight = Color(red: 255/255, green: 153/255, blue: 153/255) // #FF9999
    
    // MARK: - 功能色
    static let success = Color(red: 76/255, green: 175/255, blue: 80/255) // #4CAF50
    static let warning = Color(red: 255/255, green: 152/255, blue: 0/255) // #FF9800
    static let error = Color(red: 244/255, green: 67/255, blue: 54/255) // #F44336
    static let info = Color(red: 33/255, green: 150/255, blue: 243/255) // #2196F3
    
    // MARK: - 文字颜色
    static let textPrimary = Color(red: 46/255, green: 46/255, blue: 46/255) // #2E2E2E
    static let textSecondary = Color(red: 117/255, green: 117/255, blue: 117/255) // #757575
    static let textDisabled = Color(red: 189/255, green: 189/255, blue: 189/255) // #BDBDBD
    
    // MARK: - 渐变色
    static let gradientPrimary = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 255/255, green: 179/255, blue: 71/255),
            Color(red: 255/255, green: 138/255, blue: 101/255)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientSecondary = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 124/255, green: 179/255, blue: 66/255),
            Color(red: 139/255, green: 195/255, blue: 74/255)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let gradientBackground = LinearGradient(
        gradient: Gradient(colors: [
            Color(red: 255/255, green: 249/255, blue: 240/255),
            Color(red: 240/255, green: 248/255, blue: 232/255)
        ]),
        startPoint: .top,
        endPoint: .bottom
    )
}
