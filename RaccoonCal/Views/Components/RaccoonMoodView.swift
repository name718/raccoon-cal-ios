//
//  RaccoonMoodView.swift
//  RaccoonCal
//

import SwiftUI

/// 根据 PetMood 展示对应静态浣熊图片
struct RaccoonMoodView: View {
    let mood: PetMood
    var size: CGFloat = 120

    var body: some View {
        Image(mood.imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel(accessibilityDescription)
    }

    private var accessibilityDescription: String {
        switch mood {
        case .happy:     return "开心的浣熊"
        case .satisfied: return "满足的浣熊"
        case .normal:    return "正常状态的浣熊"
        case .hungry:    return "饥饿的浣熊"
        case .sad:       return "难过的浣熊"
        case .missing:   return "思念的浣熊"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ForEach(PetMood.allCases, id: \.self) { mood in
            HStack {
                RaccoonMoodView(mood: mood, size: 60)
                Text(mood.rawValue)
                    .font(.caption)
            }
        }
    }
    .padding()
}
