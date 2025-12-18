//
//  KhioneInfoView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI

struct KhioneInfoView: View {

    @AppStorage("khione_language")
    private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    private var content: KhioneInfoContent {
        Bundle.main.loadKhioneInfo(language: language)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                header

                ForEach(content.sections) { section in
                    infoBlock(
                        title: section.title,
                        text: section.text
                    )
                }
            }
            .padding()
        }
        .navigationTitle(content.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "snowflake")
                .font(.system(size: 44))

            Text(content.title)
                .font(.largeTitle.bold())

            Text(content.subtitle)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }

    private func infoBlock(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            Text(text)
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
