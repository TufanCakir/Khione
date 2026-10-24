//
//  ProjectsView.swift
//  Khione
//
//  Created by Tufan Cakir on 18.12.25.
//

import SwiftUI
import UniformTypeIdentifiers

struct ProjectsView: View {
    let store: DocumentProjectStore
    let access: SubscriptionLimits
    let onAskProject: (String) -> Void
    let onUpgrade: () -> Void

    @State private var isCreatingProject = false
    @State private var projectName = ""

    var body: some View {
        NavigationStack {
            Group {
                if !access.canUseProjects {
                    ProjectsLockedState(onUpgrade: onUpgrade)
                } else if store.projects.isEmpty {
                    ProjectsEmptyState(onCreate: { isCreatingProject = true })
                } else {
                    ProjectsList(
                        projects: store.projects,
                        onDelete: store.deleteProjects,
                        destination: { project in
                            ProjectDetailView(
                                projectID: project.id,
                                store: store,
                                canReviewDocuments: access.canReviewDocuments,
                                canCompareDocuments: access.canCompareDocuments,
                                onUpgrade: onUpgrade,
                                onAskProject: onAskProject
                            )
                        }
                    )
                }
            }
            .navigationTitle("Projects")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if access.canUseProjects {
                        Button("New Project", systemImage: "plus") {
                            isCreatingProject = true
                        }
                    }
                }
            }
            .alert("New Project", isPresented: $isCreatingProject) {
                TextField("Project name", text: $projectName)
                Button("Cancel", role: .cancel) { projectName = "" }
                Button("Create") {
                    store.createProject(named: projectName)
                    projectName = ""
                }
            } message: {
                Text(
                    "Group related documents and ask questions with traceable sources."
                )
            }
            .alert(
                "Import Failed",
                isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: {
                Text(store.errorMessage ?? "")
            }
        }
    }
}

private struct ProjectsLockedState: View {
    let onUpgrade: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Projects require Khione Pro", systemImage: "lock.folder")
        } description: {
            Text(
                "Create private workspaces, import documents, and ask questions with traceable sources with Khione Pro Standard or higher."
            )
        } actions: {
            Button("View Plans", action: onUpgrade)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct ProjectsEmptyState: View {
    let onCreate: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                "Your Private Workspace",
                systemImage: "folder.badge.gearshape"
            )
        } description: {
            Text(
                "Collect PDFs, images, and notes in local projects. Khione keeps every answer connected to its sources."
            )
        } actions: {
            Button("Create First Project", action: onCreate)
                .buttonStyle(.borderedProminent)
        }
    }
}

private struct ProjectsList<Destination: View>: View {
    let projects: [DocumentProject]
    let onDelete: (IndexSet) -> Void
    @ViewBuilder let destination: (DocumentProject) -> Destination

    var body: some View {
        List {
            Section {
                ForEach(projects) { project in
                    NavigationLink {
                        destination(project)
                    } label: {
                        ProjectRow(
                            name: project.name,
                            documentCount: project.documents.count,
                            updatedAt: project.updatedAt
                        )
                    }
                }
                .onDelete(perform: onDelete)
            } header: {
                Text("Document Workspaces")
            } footer: {
                Text("Files are copied into Khione's private app storage.")
            }
        }
    }
}

private struct ProjectRow: View {
    let name: String
    let documentCount: Int
    let updatedAt: Date

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "folder.fill")
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 42, height: 42)
                .background(
                    .tint.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: 12)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(
                    "\(documentCount) documents · Updated \(updatedAt, format: .relative(presentation: .named))"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ProjectDetailView: View {
    let projectID: UUID
    let store: DocumentProjectStore
    let canReviewDocuments: Bool
    let canCompareDocuments: Bool
    let onUpgrade: () -> Void
    let onAskProject: (String) -> Void

    @State private var isImporting = false
    @AppStorage("language") private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    private var project: DocumentProject? {
        store.projects.first { $0.id == projectID }
    }

    var body: some View {
        List {
            if let project {
                ProjectOverviewSection(
                    documentCount: project.documents.count,
                    sourceCount: project.documents.reduce(0) {
                        $0 + $1.sourceCount
                    },
                    isImporting: store.isImporting,
                    canAsk: store.groundedPrompt(for: projectID) != nil,
                    onImport: { isImporting = true },
                    onAsk: askProject
                )

                ProjectComparisonSection(
                    report: project.comparison,
                    projectName: project.name,
                    canCompare: project.documents.filter {
                        !$0.extractedSources.isEmpty
                    }.count >= 2,
                    hasAccess: canCompareDocuments,
                    isComparing: store.comparingProjectIDs.contains(projectID),
                    onCompare: compareDocuments,
                    onUpgrade: onUpgrade
                )

                Section("Sources") {
                    if project.documents.isEmpty {
                        Text("Import PDFs, text files, or images to begin.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(project.documents) { document in
                            NavigationLink {
                                DocumentAnalysisView(
                                    projectID: projectID,
                                    documentID: document.id,
                                    store: store,
                                    canReviewDocuments: canReviewDocuments,
                                    onUpgrade: onUpgrade
                                )
                            } label: {
                                ProjectDocumentRow(
                                    fileName: document.fileName,
                                    contentType: document.contentType,
                                    sourceCount: document.sourceCount,
                                    insightCount: document.extractedInsights
                                        .count
                                )
                            }
                            .swipeActions {
                                Button("Delete", role: .destructive) {
                                    store.removeDocument(
                                        document.id,
                                        from: projectID
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(project?.name ?? "Project")
        .navigationBarTitleDisplayMode(.large)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.pdf, .image, .plainText],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            Task { await store.importFiles(urls, into: projectID) }
        }
    }

    private func askProject() {
        guard let prompt = store.groundedPrompt(for: projectID) else { return }
        onAskProject(prompt)
    }

    private func compareDocuments() {
        Task {
            await store.compareDocuments(in: projectID, language: language)
        }
    }
}

private struct ProjectOverviewSection: View {
    let documentCount: Int
    let sourceCount: Int
    let isImporting: Bool
    let canAsk: Bool
    let onImport: () -> Void
    let onAsk: () -> Void

    var body: some View {
        Section {
            HStack {
                ProjectMetric(value: documentCount, label: "Documents")
                Divider()
                ProjectMetric(value: sourceCount, label: "Sources")
            }
            .frame(maxWidth: .infinity)

            Button(action: onImport) {
                Label("Import Documents", systemImage: "square.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isImporting)

            Button(action: onAsk) {
                Label("Ask with Sources", systemImage: "quote.bubble.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!canAsk || isImporting)
        } footer: {
            Text(
                "PDF text is separated by page so Khione can cite the exact source."
            )
        }
    }
}

private struct ProjectComparisonSection: View {
    let report: DocumentComparisonReport?
    let projectName: String
    let canCompare: Bool
    let hasAccess: Bool
    let isComparing: Bool
    let onCompare: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        Section {
            Button(action: hasAccess ? onCompare : onUpgrade) {
                HStack {
                    Label(
                        hasAccess
                            ? (report == nil
                                ? "Compare Documents" : "Compare Again")
                            : "Unlock Document Comparison",
                        systemImage: hasAccess
                            ? "rectangle.2.swap" : "lock.fill"
                    )
                    Spacer()
                    if isComparing {
                        ProgressView()
                    }
                }
            }
            .disabled((hasAccess && !canCompare) || isComparing)

            if let report {
                NavigationLink {
                    DocumentComparisonView(
                        projectName: projectName,
                        report: report
                    )
                } label: {
                    Label(
                        "View Latest Comparison",
                        systemImage: "list.bullet.clipboard"
                    )
                }
            }
        } header: {
            Text("Document Comparison")
        } footer: {
            Text(
                "Compare at least two readable documents. Every result must be supported by both sources."
            )
        }
    }
}

private struct DocumentComparisonView: View {
    let projectName: String
    let report: DocumentComparisonReport

    var body: some View {
        List {
            DocumentComparisonSummarySection(
                summary: report.summary,
                documentNames: report.documentNames,
                generatedAt: report.generatedAt
            )
            DocumentComparisonFindingsSection(findings: report.findings)
        }
        .navigationTitle("Comparison")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ShareLink(
                item: report.markdown(projectName: projectName),
                subject: Text("Khione Document Comparison"),
                preview: SharePreview(
                    projectName,
                    image: Image(systemName: "rectangle.2.swap")
                )
            ) {
                Label("Export Comparison", systemImage: "square.and.arrow.up")
            }
        }
    }
}

private struct DocumentComparisonSummarySection: View {
    let summary: String
    let documentNames: [String]
    let generatedAt: Date

    var body: some View {
        Section("Overview") {
            Text(summary)
                .textSelection(.enabled)
            LabeledContent(
                "Documents",
                value: documentNames.count,
                format: .number
            )
            ForEach(documentNames, id: \.self) { documentName in
                Label(documentName, systemImage: "doc.fill")
                    .font(.callout)
            }
            LabeledContent("Generated") {
                Text(
                    generatedAt,
                    format: .dateTime.day().month().year().hour().minute()
                )
            }
        }
    }
}

private struct DocumentComparisonFindingsSection: View {
    let findings: [DocumentComparisonFinding]

    var body: some View {
        Section {
            if findings.isEmpty {
                Label(
                    "No source-supported differences were found.",
                    systemImage: "checkmark.seal.fill"
                )
                .foregroundStyle(.green)
            } else {
                ForEach(findings) { finding in
                    DocumentComparisonFindingRow(
                        kind: finding.kind,
                        title: finding.title,
                        explanation: finding.explanation,
                        evidence: finding.evidence
                    )
                }
            }
        } header: {
            Text("Findings")
        } footer: {
            Text(
                "AI-generated comparison. Verify important decisions against the original documents."
            )
        }
    }
}

private struct DocumentComparisonFindingRow: View {
    let kind: DocumentComparisonKind
    let title: String
    let explanation: String
    let evidence: [DocumentComparisonEvidence]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(kind.title, systemImage: kind.systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(kindColor)
            Text(title)
                .font(.headline)
            Text(explanation)
                .font(.callout)

            ForEach(evidence) { item in
                VStack(alignment: .leading, spacing: 3) {
                    Label(item.documentName, systemImage: "doc.fill")
                        .font(.caption.weight(.semibold))
                    if !item.quote.isEmpty {
                        Text("“\(item.quote)”")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    Text(item.sourceLabel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    .secondary.opacity(0.08),
                    in: RoundedRectangle(cornerRadius: 10)
                )
            }
        }
        .padding(.vertical, 5)
    }

    private var kindColor: Color {
        switch kind {
        case .difference: .blue
        case .similarity: .green
        case .attention: .orange
        }
    }
}

private struct ProjectMetric: View {
    let value: Int
    let label: LocalizedStringResource

    var body: some View {
        VStack(spacing: 3) {
            Text(value, format: .number)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private struct ProjectDocumentRow: View {
    let fileName: String
    let contentType: UTType?
    let sourceCount: Int
    let insightCount: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .foregroundStyle(.tint)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(fileName)
                    .lineLimit(2)
                Text(metadataText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var iconName: String {
        if contentType?.conforms(to: .pdf) == true {
            return "doc.richtext.fill"
        }
        if contentType?.conforms(to: .image) == true { return "photo.fill" }
        return "doc.text.fill"
    }

    private var metadataText: String {
        if sourceCount == 0 { return String(localized: "Stored locally") }
        if insightCount == 0 {
            return String(localized: "\(sourceCount) cited sources")
        }
        return String(
            localized: "\(sourceCount) sources · \(insightCount) facts"
        )
    }
}

private struct DocumentAnalysisView: View {
    let projectID: UUID
    let documentID: UUID
    let store: DocumentProjectStore
    let canReviewDocuments: Bool
    let onUpgrade: () -> Void

    @AppStorage("language") private var language =
        Locale.current.language.languageCode?.identifier ?? "en"

    private var document: ProjectDocument? {
        store.projects
            .first { $0.id == projectID }?
            .documents.first { $0.id == documentID }
    }

    private var isReviewing: Bool {
        store.reviewingDocumentIDs.contains(documentID)
    }

    var body: some View {
        List {
            if let document {
                DocumentAnalysisSummary(
                    importedAt: document.importedAt,
                    sourceCount: document.extractedSources.count,
                    insightCount: document.extractedInsights.count
                )
                DocumentReviewActionSection(
                    isReviewing: isReviewing,
                    hasReview: document.review != nil,
                    canReview: !document.extractedSources.isEmpty,
                    hasAccess: canReviewDocuments,
                    onReview: reviewDocument,
                    onUpgrade: onUpgrade
                )
                if let report = document.review {
                    DocumentReviewSection(report: report)
                }
                DocumentInsightsSection(insights: document.extractedInsights)
                DocumentSourcesSection(sources: document.extractedSources)
            } else {
                ContentUnavailableView(
                    "Document Not Found",
                    systemImage: "doc.questionmark"
                )
            }
        }
        .navigationTitle(document?.fileName ?? "Document")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let document, let report = document.review {
                ShareLink(
                    item: report.markdown(fileName: document.fileName),
                    subject: Text("Khione Document Review"),
                    preview: SharePreview(
                        document.fileName,
                        image: Image(systemName: "doc.text.magnifyingglass")
                    )
                ) {
                    Label("Export Review", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private func reviewDocument() {
        Task {
            await store.reviewDocument(
                documentID,
                in: projectID,
                language: language
            )
        }
    }
}

private struct DocumentReviewActionSection: View {
    let isReviewing: Bool
    let hasReview: Bool
    let canReview: Bool
    let hasAccess: Bool
    let onReview: () -> Void
    let onUpgrade: () -> Void

    var body: some View {
        Section {
            Button(action: hasAccess ? onReview : onUpgrade) {
                HStack {
                    Label(
                        hasAccess
                            ? (hasReview ? "Review Again" : "Review Document")
                            : "Unlock Document Review",
                        systemImage: hasAccess
                            ? "doc.text.magnifyingglass"
                            : "lock.fill"
                    )
                    Spacer()
                    if isReviewing {
                        ProgressView()
                    }
                }
            }
            .disabled((hasAccess && !canReview) || isReviewing)
        } footer: {
            Text(
                "Khione reviews the recognized text locally and keeps every finding connected to its source."
            )
        }
    }
}

private struct DocumentReviewSection: View {
    let report: DocumentReviewReport

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Label("Summary", systemImage: "text.alignleft")
                    .font(.headline)
                Text(report.summary)
                    .textSelection(.enabled)
                Text(
                    report.generatedAt,
                    format: .dateTime.day().month().year().hour().minute()
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            if report.findings.isEmpty {
                Label(
                    "No source-supported issues were found.",
                    systemImage: "checkmark.seal.fill"
                )
                .foregroundStyle(.green)
            } else {
                ForEach(report.findings) { finding in
                    DocumentReviewFindingRow(
                        severity: finding.severity,
                        title: finding.title,
                        explanation: finding.explanation,
                        sourceLabel: finding.sourceLabel,
                        evidence: finding.evidence
                    )
                }
            }
        } header: {
            Text("Document Review")
        } footer: {
            Text(
                "AI-generated review. Verify important decisions against the original document."
            )
        }
    }
}

private struct DocumentReviewFindingRow: View {
    let severity: DocumentReviewSeverity
    let title: String
    let explanation: String
    let sourceLabel: String
    let evidence: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: severity.systemImage)
                .foregroundStyle(severityColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 6) {
                Text(severity.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(severityColor)
                Text(title)
                    .font(.headline)
                Text(explanation)
                    .font(.callout)
                if !evidence.isEmpty {
                    Text("“\(evidence)”")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
                Label(sourceLabel, systemImage: "quote.opening")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var severityColor: Color {
        switch severity {
        case .critical: .red
        case .warning: .orange
        case .information: .blue
        }
    }
}

private struct DocumentAnalysisSummary: View {
    let importedAt: Date
    let sourceCount: Int
    let insightCount: Int

    var body: some View {
        Section("Analysis") {
            LabeledContent("Imported") {
                Text(importedAt, format: .dateTime.day().month().year())
            }
            LabeledContent("Cited Sources", value: sourceCount, format: .number)
            LabeledContent(
                "Extracted Facts",
                value: insightCount,
                format: .number
            )
        }
    }
}

private struct DocumentInsightsSection: View {
    let insights: [DocumentInsight]

    var body: some View {
        Section("Extracted Facts") {
            if insights.isEmpty {
                ContentUnavailableView(
                    "No Structured Facts Found",
                    systemImage: "text.magnifyingglass",
                    description: Text(
                        "The document remains searchable and can still be used as a cited source."
                    )
                )
            } else {
                ForEach(insights) { insight in
                    DocumentInsightRow(
                        kind: insight.kind,
                        value: insight.value,
                        sourceLabel: insight.sourceLabel
                    )
                }
            }
        }
    }
}

private struct DocumentInsightRow: View {
    let kind: DocumentInsightKind
    let value: String
    let sourceLabel: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: kind.systemImage)
                .foregroundStyle(.tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .textSelection(.enabled)
                Text(sourceLabel)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct DocumentSourcesSection: View {
    let sources: [DocumentSource]

    var body: some View {
        Section("Recognized Sources") {
            ForEach(sources) { source in
                DisclosureGroup(source.label) {
                    Text(source.text)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(.vertical, 6)
                }
            }
        }
    }
}

#Preview {
    ProjectsView(
        store: DocumentProjectStore(),
        access: SubscriptionPlan.fallbackFree.limits,
        onAskProject: { _ in },
        onUpgrade: {}
    )
}
