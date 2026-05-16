//
//  Bundle+AppVersion.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation

extension Bundle {
    /// A human-readable version string combining CFBundleShortVersionString and CFBundleVersion.
    public var appVersionString: String {
        let shortVersion =
            infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = infoDictionary?["CFBundleVersion"] as? String

        switch (shortVersion, buildNumber) {
        case (let sv?, let bn?):
            return "\(sv) (\(bn))"
        case (let sv?, nil):
            return sv
        case (nil, let bn?):
            return bn
        default:
            return "Unknown"
        }
    }
}
