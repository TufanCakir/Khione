//
//  DocumentReview.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation
import FoundationModels

struct DocumentReviewReport: Codable, Equatable, Identifiable {
    let id: UUID
    let generatedAt: Date
    let summary: String
    let findings: [DocumentReviewFinding]

    var criticalFindingCount: Int {
        findings.count { $0.severity == .critical }
    }

    func markdown(fileName: String) -> String {
        var lines = [
            "# Khione Document Review",
            "",
            "**Document:** \(fileName)",
            "**Generated:** \(generatedAt.formatted(date: .long, time: .shortened))",
            "",
            "## Summary",
            "",
            summary,
            "",
            "## Findings",
            "",
        ]

        if findings.isEmpty {
            lines.append("No source-supported issues were found.")
        } else {
            for finding in findings {
                lines.append(
                    "### [\(finding.severity.rawValue.capitalized)] \(finding.title)"
                )
                lines.append("")
                lines.append(finding.explanation)
                lines.append("")
                if !finding.evidence.isEmpty {
                    lines.append(
                        "> \(finding.evidence.replacingOccurrences(of: "\n", with: " "))"
                    )
                    lines.append("")
                }
                lines.append("Source: \(finding.sourceLabel)")
                lines.append("")
            }
        }

        lines.append("---")
        lines.append(
            "Generated locally by Khione. Verify important decisions against the original document."
        )
        return lines.joined(separator: "\n")
    }
}

struct DocumentReviewFinding: Codable, Equatable, Identifiable {
    let id: UUID
    let severity: DocumentReviewSeverity
    let title: String
    let explanation: String
    let sourceLabel: String
    let evidence: String
}

enum DocumentReviewSeverity: String, Codable, CaseIterable, Equatable {
    case critical
    case warning
    case information

    var title: LocalizedStringResource {
        switch self {
        case .critical: "Critical"
        case .warning: "Review"
        case .information: "Information"
        }
    }

    var systemImage: String {
        switch self {
        case .critical: "exclamationmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .information: "info.circle.fill"
        }
    }
}

@Generable(
    description:
        "A concise professional review based only on the supplied document sources."
)
struct GeneratedDocumentReview {
    @Guide(description: "A neutral summary of the document and its purpose.")
    let summary: String

    @Guide(
        description:
            "Only important, source-supported findings. Return an empty list when no issues are supported."
    )
    let findings: [GeneratedDocumentFinding]
}

@Generable(description: "One source-supported document finding.")
struct GeneratedDocumentFinding {
    @Guide(description: "Exactly one of: critical, warning, information.")
    let severity: String

    @Guide(description: "A short, specific heading.")
    let title: String

    @Guide(
        description:
            "Explain why this matters without giving legal, medical, or financial advice."
    )
    let explanation: String

    @Guide(description: "The exact source identifier, such as S1 or S2.")
    let sourceID: String

    @Guide(
        description:
            "A short verbatim quote from that source. Do not paraphrase."
    )
    let evidence: String
}
