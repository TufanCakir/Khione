//
//  DocumentComparison.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import Foundation
import FoundationModels

struct DocumentComparisonReport: Codable, Equatable, Identifiable {
    let id: UUID
    let generatedAt: Date
    let documentNames: [String]
    let summary: String
    let findings: [DocumentComparisonFinding]

    func markdown(projectName: String) -> String {
        var lines = [
            "# Khione Document Comparison",
            "",
            "**Project:** \(projectName)",
            "**Documents:** \(documentNames.formatted())",
            "**Generated:** \(generatedAt.formatted(date: .long, time: .shortened))",
            "",
            "## Summary",
            "",
            summary,
            "",
            "## Comparison",
            "",
        ]

        if findings.isEmpty {
            lines.append("No source-supported differences were found.")
        } else {
            for finding in findings {
                lines.append("### \(finding.title)")
                lines.append("")
                lines.append(finding.explanation)
                lines.append("")
                for evidence in finding.evidence {
                    if !evidence.quote.isEmpty {
                        lines.append(
                            "> \(evidence.quote.replacingOccurrences(of: "\n", with: " "))"
                        )
                    }
                    lines.append("Source: \(evidence.sourceLabel)")
                    lines.append("")
                }
            }
        }

        lines.append("---")
        lines.append(
            "Generated locally by Khione. Verify important decisions against the original documents."
        )
        return lines.joined(separator: "\n")
    }
}

struct DocumentComparisonFinding: Codable, Equatable, Identifiable {
    let id: UUID
    let kind: DocumentComparisonKind
    let title: String
    let explanation: String
    let evidence: [DocumentComparisonEvidence]
}

struct DocumentComparisonEvidence: Codable, Equatable, Identifiable {
    let id: UUID
    let documentName: String
    let sourceLabel: String
    let quote: String
}

enum DocumentComparisonKind: String, Codable, Equatable {
    case difference
    case similarity
    case attention

    var title: LocalizedStringResource {
        switch self {
        case .difference: "Difference"
        case .similarity: "Match"
        case .attention: "Needs Attention"
        }
    }

    var systemImage: String {
        switch self {
        case .difference: "arrow.left.arrow.right"
        case .similarity: "equal.circle.fill"
        case .attention: "exclamationmark.triangle.fill"
        }
    }
}

@Generable(
    description:
        "A factual comparison based only on the supplied document sources."
)
struct GeneratedDocumentComparison {
    @Guide(
        description:
            "A concise neutral overview of the most important similarities and differences."
    )
    let summary: String

    @Guide(
        description:
            "Only useful comparisons supported by two different documents."
    )
    let findings: [GeneratedComparisonFinding]
}

@Generable(
    description:
        "One comparison supported by passages from two different documents."
)
struct GeneratedComparisonFinding {
    @Guide(description: "Exactly one of: difference, similarity, attention.")
    let kind: String

    @Guide(description: "A short specific heading.")
    let title: String

    @Guide(
        description:
            "Explain the practical significance without giving legal, medical, or financial advice."
    )
    let explanation: String

    @Guide(description: "An exact source identifier from the first document.")
    let firstSourceID: String

    @Guide(description: "A short verbatim quote from the first source.")
    let firstEvidence: String

    @Guide(description: "An exact source identifier from a different document.")
    let secondSourceID: String

    @Guide(description: "A short verbatim quote from the second source.")
    let secondEvidence: String
}
