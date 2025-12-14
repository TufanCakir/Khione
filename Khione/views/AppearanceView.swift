//
//  AppearanceView.swift
//  Khione
//
//  Created by Tufan Cakir on 14.12.25.
//

import SwiftUI

struct AppearanceView: View {

    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.backgroundColor
                .ignoresSafeArea()

            List {
                Section("Theme") {
                    ForEach(themeManager.themes) { theme in
                        Button {
                            themeManager.selectTheme(theme)
                        } label: {
                            HStack {
                                Text(theme.name)
                                Spacer()
                                if theme.id == themeManager.selectedTheme.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Aussehen")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AppearanceView()
            .environmentObject(ThemeManager())
    }
}
