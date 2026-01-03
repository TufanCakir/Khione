//
//  FrostClock.swift.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

import SwiftUI

struct Clock: View {
    let time: String

    var body: some View {
        Text(time)
            .font(.system(size: 80, weight: .semibold, design: .rounded))
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 50))
    }
}
