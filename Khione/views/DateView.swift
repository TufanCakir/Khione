//
//  DateView.swift
//  Khione
//
//  Created by Tufan Cakir on 02.01.26.
//

internal import Combine
import SwiftUI

struct DateView: View {

    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common)
        .autoconnect()

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 40) {

                VStack(spacing: 12) {
                    Text(dayString)
                        .font(.system(size: 56, weight: .bold))

                    Text(fullDateString)
                        .font(.title3)

                    Text("Week \(weekOfYear)")
                        .font(.footnote)
                }

                Clock(time: timeString)

                Spacer()
            }
            .padding(.top, 80)
        }
        .onReceive(timer) { value in
            now = value
        }
    }

    // MARK: - Formatters

    private var timeString: String {
        now.formatted(date: .omitted, time: .standard)
    }

    private var dayString: String {
        now.formatted(.dateTime.weekday(.wide))
    }

    private var fullDateString: String {
        now.formatted(.dateTime.day().month(.wide).year())
    }

    private var weekOfYear: Int {
        Calendar.current.component(.weekOfYear, from: now)
    }
}

#Preview {
    DateView()
        .environmentObject(ThemeManager())
        .preferredColorScheme(ThemeManager().colorScheme)
}
