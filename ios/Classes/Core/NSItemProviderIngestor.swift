import Foundation
import MobileCoreServices

public class NSItemProviderIngestor {

    public static func ingestItems(extensionItems: [NSExtensionItem], containerUrl: URL, completion: @escaping (Result<SpoolDelivery, Error>) -> Void) {
        let spool = FileSpool(containerUrl: containerUrl)
        let group = DispatchGroup()

        var tempCopies: [(SpoolItem, URL)] = []
        var textPayload: String?
        var subjectPayload: String?
        var processError: Error?

        for item in extensionItems {
            if let subject = item.attributedTitle?.string ?? item.attributedContentText?.string {
                subjectPayload = subject
            }

            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                group.enter()

                // Check text / url representation first
                if provider.hasItemConformingToTypeIdentifier(kUTTypeURL as String) {
                    provider.loadItem(forTypeIdentifier: kUTTypeURL as String, options: nil) { (urlItem, error) in
                        defer { group.leave() }
                        if let url = urlItem as? URL {
                            if textPayload == nil {
                                textPayload = url.absoluteString
                            } else {
                                textPayload! += "\n" + url.absoluteString
                            }
                        }
                    }
                } else if provider.hasItemConformingToTypeIdentifier(kUTTypeText as String) {
                    provider.loadItem(forTypeIdentifier: kUTTypeText as String, options: nil) { (textItem, error) in
                        defer { group.leave() }
                        if let text = textItem as? String {
                            if textPayload == nil {
                                textPayload = text
                            } else {
                                textPayload! += "\n" + text
                            }
                        }
                    }
                } else {
                    // File representation with full copy inside callback
                    let typeId = provider.registeredTypeIdentifiers.first ?? (kUTTypeData as String)
                    provider.loadFileRepresentation(forTypeIdentifier: typeId) { (sourceUrl, error) in
                        defer { group.leave() }

                        if let error = error {
                            processError = error
                            return
                        }

                        guard let sourceUrl = sourceUrl else { return }

                        // Create temporary local copy inside completion handler
                        let tempCopyUrl = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                        do {
                            if FileManager.default.fileExists(atPath: tempCopyUrl.path) {
                                try FileManager.default.removeItem(at: tempCopyUrl)
                            }
                            try FileManager.default.copyItem(at: sourceUrl, to: tempCopyUrl)

                            let itemId = UUID().uuidString
                            let kind = mapTypeIdentifierToKind(typeId)
                            let spoolItem = SpoolItem(
                                itemId: itemId,
                                kind: kind,
                                originalName: sourceUrl.lastPathComponent,
                                internalName: "\(itemId).payload",
                                declaredMimeType: typeId,
                                resolvedMimeType: typeId,
                                byteLength: (try? FileManager.default.attributesOfItem(atPath: tempCopyUrl.path)[.size] as? Int64) ?? 0
                            )

                            tempCopies.append((spoolItem, tempCopyUrl))
                        } catch {
                            processError = error
                        }
                    }
                }
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) {
            if let error = processError {
                completion(.failure(error))
                return
            }

            do {
                let delivery = try spool.commitDelivery(
                    items: tempCopies,
                    text: textPayload,
                    subject: subjectPayload,
                    source: nil
                )

                // Clean up temp copy files
                for (_, tempUrl) in tempCopies {
                    try? FileManager.default.removeItem(at: tempUrl)
                }

                completion(.success(delivery))
            } catch {
                completion(.failure(error))
            }
        }
    }

    private static func mapTypeIdentifierToKind(_ typeIdentifier: String) -> String {
        if UTTypeConformsTo(typeIdentifier as CFString, kUTTypeImage) {
            return "image"
        } else if UTTypeConformsTo(typeIdentifier as CFString, kUTTypeMovie) || UTTypeConformsTo(typeIdentifier as CFString, kUTTypeVideo) {
            return "video"
        } else if UTTypeConformsTo(typeIdentifier as CFString, kUTTypeHTML) {
            return "html"
        } else if UTTypeConformsTo(typeIdentifier as CFString, kUTTypeText) {
            return "text"
        } else {
            return "file"
        }
    }
}
