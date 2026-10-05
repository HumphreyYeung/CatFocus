//
//  ContentView.swift
//  CatFocus
//
//  Created by Humphrey Yeung on 6/14/26.
//

import SwiftUI

struct ContentView: View {
    @AppStorage(CFLocalization.languagePreferenceKey) private var appLanguage = "system"

    var body: some View {
        AppFlowView()
            .environment(\.locale, CFLocalization.locale(for: appLanguage))
    }
}

#Preview {
    ContentView()
}
