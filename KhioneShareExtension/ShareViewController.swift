//
//  ShareViewController.swift
//  KhioneShareExtension
//
//  Created by Tufan Cakir on 23.05.26.
//

import Social
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {

    private let appGroupIdentifier = "group.khione.shared"
    private let pendingTextKey = "pendingSharedText"
    private let pendingURLKey = "pendingSharedURL"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Khione"
        placeholder = "In Khione öffnen, um fortzufahren."
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.topItem?.rightBarButtonItem?.title =
            "Senden"
    }

    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        Task {
            let sharedItems = await loadSharedItems()
            store(sharedItems)
            openKhione()
        }
    }

    override func configurationItems() -> [Any]! {
        []
    }
}

extension ShareViewController {

    fileprivate struct SharedItems {
        var text: String?
        var url: URL?
    }

    fileprivate func loadSharedItems() async -> SharedItems {
        var items = SharedItems(text: contentText, url: nil)

        guard
            let extensionItems = extensionContext?.inputItems
                as? [NSExtensionItem]
        else {
            return items
        }

        for extensionItem in extensionItems {
            for provider in extensionItem.attachments ?? [] {
                if items.url == nil,
                    provider.hasItemConformingToTypeIdentifier(
                        UTType.url.identifier
                    )
                {
                    items.url = await loadURL(from: provider)
                }

                if items.text?.trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty != false,
                    provider.hasItemConformingToTypeIdentifier(
                        UTType.plainText.identifier
                    )
                {
                    items.text = await loadText(from: provider)
                }

                if items.url == nil,
                    provider.hasItemConformingToTypeIdentifier(
                        UTType.image.identifier
                    )
                {
                    continue
                }
            }
        }

        return items
    }

    fileprivate func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(
                forTypeIdentifier: UTType.url.identifier,
                options: nil
            ) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                } else if let string = item as? String {
                    continuation.resume(returning: URL(string: string))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    fileprivate func loadText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(
                forTypeIdentifier: UTType.plainText.identifier,
                options: nil
            ) { item, _ in
                if let string = item as? String {
                    continuation.resume(returning: string)
                } else if let data = item as? Data {
                    continuation.resume(
                        returning: String(data: data, encoding: .utf8)
                    )
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    fileprivate func store(_ items: SharedItems) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }

        let text = items.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let text, !text.isEmpty {
            defaults.set(text, forKey: pendingTextKey)
        }

        if let url = items.url {
            defaults.set(url.absoluteString, forKey: pendingURLKey)
        }
    }

    fileprivate func openKhione() {
        guard let url = URL(string: "khione://share") else {
            extensionContext?.completeRequest(
                returningItems: [],
                completionHandler: nil
            )
            return
        }

        extensionContext?.open(url) { [weak self] _ in
            self?.extensionContext?.completeRequest(
                returningItems: [],
                completionHandler: nil
            )
        }
    }
}
