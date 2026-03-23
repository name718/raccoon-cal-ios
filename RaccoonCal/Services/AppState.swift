//
//  AppState.swift
//  RaccoonCal
//
//  全局 App 状态，用于跨 Tab 导航等共享状态。
//

import SwiftUI

final class AppState: ObservableObject {
    static let shared = AppState()

    /// 当前选中的 Tab 索引（0=首页, 1=记录, 2=添加, 3=浣熊, 4=我的）
    @Published var selectedTab: Int = 0
    @Published var showAddEntryOptions: Bool = false

    private init() {}

    func presentAddEntryOptions() {
        showAddEntryOptions = true
    }
}
