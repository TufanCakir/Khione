//
//  ShareViewController.swift
//  KhioneShareExtension
//
//  Created by Tufan Cakir on 23.05.26.
//

import Social
import UIKit
import UniformTypeIdentifiers

@MainActor
final class ShareViewController: SLComposeServiceViewController {

    // MARK: - Constants

    private enum Constants {
        static let appGroupIdentifier = "group.khione.shared"

        static let pendingTextKey = "pendingSharedText"
        static let pendingURLKey = "pendingSharedURL"

        static let khioneShareURL = URL(string: "khione://share")!
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Khione"
        placeholder = "In Khione öffnen, um fortzufahren."
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?
            .navigationBar
            .topItem?
            .rightBarButtonItem?
            .title = "Senden"
    }

    // MARK: - SLComposeServiceViewController

    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        Task {
            let items = await loadSharedItems()

            store(items)

            await openKhione()
        }
    }

    override func configurationItems() -> [Any]! {
        []
    }
}

// MARK: - Shared Content

private extension ShareViewController {
    
    struct SharedItems {
        var text: String?
        var url: URL?
    }
    
    func loadSharedItems() async -> SharedItems {
        
        var result = SharedItems(
            text: Self.normalizedText(contentText),
            url: nil
        )
        
        guard
            let extensionItems = extensionContext?.inputItems
                as? [NSExtensionItem]
                else {
            return result
        }
        
        let providers = extensionItems.flatMap {
            $0.attachments ?? []
        }
        
        for provider in providers {
            
            // URL has priority.
            if result.url == nil,
               provider.hasItemConformingToTypeIdentifier(
                UTType.url.identifier
               ) {
                
                result.url = await loadURL(from: provider)
            }
            
            // Only load provider text if the compose field
            // doesn't already contain useful text.
            if result.text == nil,
               provider.hasItemConformingToTypeIdentifier(
                UTType.plainText.identifier
               ) {
                
                result.text = await loadText(from: provider)
            }
            
            // We already have everything Khione currently needs.
            if result.url != nil,
               result.text != nil {
                
                break
            }
        }
        
        return result
    }
    
    // MARK: URL
    
    func loadURL(
        from provider: NSItemProvider
    ) async -> URL? {
        
        // NSURL conforms to NSItemProviderReading and avoids
        // the deprecated loadItem(forTypeIdentifier:options:) API.
        
        await withCheckedContinuation { continuation in
            
            provider.loadObject(ofClass: NSURL.self) { object, error in
                
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                
                if let url = object as? URL {
                    continuation.resume(returning: url)
                    return
                }
                
                if let url = object as? NSURL {
                    continuation.resume(
                        returning: url as URL
                    )
                    return
                }
                
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: Text
    
    func loadText(
        from provider: NSItemProvider
    ) async -> String? {
        
        // NSString can be loaded directly through NSItemProvider.
        // No deprecated loadItem call is required.
        
        await withCheckedContinuation { continuation in
            
            provider.loadObject(ofClass: NSString.self) { object, error in
                
                guard error == nil else {
                    continuation.resume(returning: nil)
                    return
                }
                
                guard let string = object as? String else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(
                    returning: Self.normalizedText(string)
                )
            }
        }
    }
    
    // MARK: Helpers
    
    nonisolated static func normalizedText(_ text: String?) -> String? {
        guard let text else {
            return nil
        }
        
        let trimmed = text.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        return trimmed.isEmpty ? nil : trimmed
    }
}

// MARK: - App Group

private extension ShareViewController {

    func store(_ items: SharedItems) {

        guard
            let defaults = UserDefaults(
                suiteName: Constants.appGroupIdentifier
            )
        else {
            return
        }

        if let text = items.text {
            defaults.set(
                text,
                forKey: Constants.pendingTextKey
            )
        } else {
            defaults.removeObject(
                forKey: Constants.pendingTextKey
            )
        }

        if let url = items.url {
            defaults.set(
                url.absoluteString,
                forKey: Constants.pendingURLKey
            )
        } else {
            defaults.removeObject(
                forKey: Constants.pendingURLKey
            )
        }
    }
}

// MARK: - Open Khione

private extension ShareViewController {

    func openKhione() async {

        await withCheckedContinuation { continuation in

            extensionContext?.open(
                Constants.khioneShareURL
            ) { [weak self] _ in

                self?.extensionContext?.completeRequest(
                    returningItems: nil
                ) {_ in 
                    continuation.resume()
                }
            }
        }
    }
}
