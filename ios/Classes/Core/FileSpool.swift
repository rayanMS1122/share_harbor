import Foundation

public struct SpoolItem: Codable {
    public let itemId: String
    public let kind: String
    public let originalName: String?
    public let internalName: String
    public let declaredMimeType: String?
    public let resolvedMimeType: String?
    public let byteLength: Int64

    public init(itemId: String, kind: String, originalName: String?, internalName: String, declaredMimeType: String?, resolvedMimeType: String?, byteLength: Int64) {
        self.itemId = itemId
        self.kind = kind
        self.originalName = originalName
        self.internalName = internalName
        self.declaredMimeType = declaredMimeType
        self.resolvedMimeType = resolvedMimeType
        self.byteLength = byteLength
    }
}

public struct SpoolDelivery: Codable {
    public let deliveryId: String
    public let receivedAtUtc: String
    public let platform: String
    public let state: String
    public let attempt: Int
    public let items: [SpoolItem]
    public let text: String?
    public let subject: String?
    public let source: String?

    public init(deliveryId: String, receivedAtUtc: String, platform: String, state: String, attempt: Int, items: [SpoolItem], text: String?, subject: String?, source: String?) {
        self.deliveryId = deliveryId
        self.receivedAtUtc = receivedAtUtc
        self.platform = platform
        self.state = state
        self.attempt = attempt
        self.items = items
        self.text = text
        self.subject = subject
        self.source = source
    }
}

public struct SpoolClaim: Codable {
    public let claimId: String
    public let deliveryId: String
    public let delivery: SpoolDelivery
    public let claimedAtUtc: String
    public let expiresAtUtc: String

    public init(claimId: String, deliveryId: String, delivery: SpoolDelivery, claimedAtUtc: String, expiresAtUtc: String) {
        self.claimId = claimId
        self.deliveryId = deliveryId
        self.delivery = delivery
        self.claimedAtUtc = claimedAtUtc
        self.expiresAtUtc = expiresAtUtc
    }
}

public class FileSpool {
    private let rootDir: URL
    private let deliveriesDir: URL
    private let lockManager: FileLockManager

    public init(containerUrl: URL) {
        self.rootDir = containerUrl.appendingPathComponent("share_harbor/v1")
        self.deliveriesDir = rootDir.appendingPathComponent("deliveries")
        let lockUrl = rootDir.appendingPathComponent("locks/spool.lock")
        self.lockManager = FileLockManager(lockFileUrl: lockUrl)

        if !FileManager.default.fileExists(atPath: deliveriesDir.path) {
            try? FileManager.default.createDirectory(at: deliveriesDir, withIntermediateDirectories: true)
        }
        performStartupCleanup()
    }

    private func isoUtcTimestamp(date: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    public func commitDelivery(items: [(SpoolItem, URL)], text: String?, subject: String?, source: String?) throws -> SpoolDelivery {
        return try lockManager.withLock {
            let deliveryId = UUID().uuidString
            let deliveryFolder = deliveriesDir.appendingPathComponent(deliveryId)
            let itemsFolder = deliveryFolder.appendingPathComponent("items")
            try FileManager.default.createDirectory(at: itemsFolder, withIntermediateDirectories: true)

            var committedItems: [SpoolItem] = []

            for (itemMeta, tempSourceUrl) in items {
                let partialUrl = itemsFolder.appendingPathComponent("\(itemMeta.itemId).partial")
                let payloadUrl = itemsFolder.appendingPathComponent("\(itemMeta.itemId).payload")

                // Copy temp source to partial
                if FileManager.default.fileExists(atPath: partialUrl.path) {
                    try FileManager.default.removeItem(at: partialUrl)
                }
                try FileManager.default.copyItem(at: tempSourceUrl, to: partialUrl)

                let fileSize = (try? FileManager.default.attributesOfItem(atPath: partialUrl.path)[.size] as? Int64) ?? itemMeta.byteLength

                // Rename partial -> payload atomically
                try FileManager.default.moveItem(at: partialUrl, to: payloadUrl)

                let updatedItem = SpoolItem(
                    itemId: itemMeta.itemId,
                    kind: itemMeta.kind,
                    originalName: itemMeta.originalName,
                    internalName: "\(itemMeta.itemId).payload",
                    declaredMimeType: itemMeta.declaredMimeType,
                    resolvedMimeType: itemMeta.resolvedMimeType,
                    byteLength: fileSize
                )
                committedItems.append(updatedItem)
            }

            let delivery = SpoolDelivery(
                deliveryId: deliveryId,
                receivedAtUtc: isoUtcTimestamp(),
                platform: "ios",
                state: "ready",
                attempt: 0,
                items: committedItems,
                text: text,
                subject: subject,
                source: source
            )

            // Atomic manifest write
            let manifestTmp = deliveryFolder.appendingPathComponent("manifest.tmp")
            let manifestJson = deliveryFolder.appendingPathComponent("manifest.json")

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(delivery)
            try data.write(to: manifestTmp, options: .atomic)

            if FileManager.default.fileExists(atPath: manifestJson.path) {
                try FileManager.default.removeItem(at: manifestJson)
            }
            try FileManager.default.moveItem(at: manifestTmp, to: manifestJson)

            // Atomic ready.marker as final commit step
            let readyMarker = deliveryFolder.appendingPathComponent("ready.marker")
            try Data().write(to: readyMarker, options: .atomic)

            return delivery
        }
    }

    public func getPendingDeliveries() -> [SpoolDelivery] {
        return (try? lockManager.withLock {
            performStartupCleanup()
            var result: [SpoolDelivery] = []

            guard let folders = try? FileManager.default.contentsOfDirectory(at: deliveriesDir, includingPropertiesForKeys: nil) else {
                return []
            }

            let decoder = JSONDecoder()

            for folder in folders {
                let readyMarker = folder.appendingPathComponent("ready.marker")
                let ackMarker = folder.appendingPathComponent("ack.marker")
                let manifestJson = folder.appendingPathComponent("manifest.json")

                if FileManager.default.fileExists(atPath: readyMarker.path) &&
                    !FileManager.default.fileExists(atPath: ackMarker.path) &&
                    FileManager.default.fileExists(atPath: manifestJson.path) {

                    let claimJson = folder.appendingPathComponent("claim.json")
                    var isClaimed = false

                    if FileManager.default.fileExists(atPath: claimJson.path) {
                        if let claimData = try? Data(contentsOf: claimJson),
                           let claimObj = try? JSONSerialization.jsonObject(with: claimData) as? [String: Any],
                           let expiresAtStr = claimObj["expiresAtUtc"] as? String {
                            let formatter = ISO8601DateFormatter()
                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                            if let expireDate = formatter.date(from: expiresAtStr), Date() < expireDate {
                                isClaimed = true
                            } else {
                                try? FileManager.default.removeItem(at: claimJson)
                            }
                        } else {
                            try? FileManager.default.removeItem(at: claimJson)
                        }
                    }

                    if !isClaimed {
                        if let manifestData = try? Data(contentsOf: manifestJson),
                           let delivery = try? decoder.decode(SpoolDelivery.self, from: manifestData) {
                            result.append(delivery)
                        }
                    }
                }
            }
            return result.sorted(by: { $0.receivedAtUtc < $1.receivedAtUtc })
        }) ?? []
    }

    public func claimDelivery(deliveryId: String, leaseDurationSeconds: Double) throws -> SpoolClaim {
        return try lockManager.withLock {
            let folder = deliveriesDir.appendingPathComponent(deliveryId)
            let readyMarker = folder.appendingPathComponent("ready.marker")
            let ackMarker = folder.appendingPathComponent("ack.marker")
            let manifestJson = folder.appendingPathComponent("manifest.json")

            guard FileManager.default.fileExists(atPath: folder.path),
                  FileManager.default.fileExists(atPath: readyMarker.path),
                  !FileManager.default.fileExists(atPath: ackMarker.path),
                  FileManager.default.fileExists(atPath: manifestJson.path),
                  let manifestData = try? Data(contentsOf: manifestJson),
                  let delivery = try? JSONDecoder().decode(SpoolDelivery.self, from: manifestData) else {
                throw NSError(domain: "ShareHarborSpool", code: 404, userInfo: [NSLocalizedDescriptionKey: "Delivery \(deliveryId) not found"])
            }

            let claimId = UUID().uuidString
            let claimedAt = Date()
            let expiresAt = claimedAt.addingTimeInterval(leaseDurationSeconds)

            let claim = SpoolClaim(
                claimId: claimId,
                deliveryId: deliveryId,
                delivery: SpoolDelivery(
                    deliveryId: delivery.deliveryId,
                    receivedAtUtc: delivery.receivedAtUtc,
                    platform: delivery.platform,
                    state: "claimed",
                    attempt: delivery.attempt,
                    items: delivery.items,
                    text: delivery.text,
                    subject: delivery.subject,
                    source: delivery.source
                ),
                claimedAtUtc: isoUtcTimestamp(date: claimedAt),
                expiresAtUtc: isoUtcTimestamp(date: expiresAt)
            )

            let claimObj: [String: Any] = [
                "claimId": claim.claimId,
                "deliveryId": claim.deliveryId,
                "claimedAtUtc": claim.claimedAtUtc,
                "expiresAtUtc": claim.expiresAtUtc
            ]

            let claimJsonFile = folder.appendingPathComponent("claim.json")
            let claimData = try JSONSerialization.data(withJSONObject: claimObj, options: .prettyPrinted)
            try claimData.write(to: claimJsonFile, options: .atomic)

            return claim
        }
    }

    public func acknowledgeClaim(claimId: String, deliveryId: String) throws {
        try lockManager.withLock {
            let folder = deliveriesDir.appendingPathComponent(deliveryId)
            if FileManager.default.fileExists(atPath: folder.path) {
                let ackMarker = folder.appendingPathComponent("ack.marker")
                try Data().write(to: ackMarker, options: .atomic) // ACK precedence
                try FileManager.default.removeItem(at: folder)
            }
        }
    }

    public func releaseClaim(claimId: String, deliveryId: String, reason: String?) throws {
        try lockManager.withLock {
            let folder = deliveriesDir.appendingPathComponent(deliveryId)
            let claimJson = folder.appendingPathComponent("claim.json")
            if FileManager.default.fileExists(atPath: claimJson.path) {
                try FileManager.default.removeItem(at: claimJson)
            }
        }
    }

    public func getPayloadUrl(deliveryId: String, itemId: String) throws -> URL {
        let payloadUrl = deliveriesDir.appendingPathComponent("\(deliveryId)/items/\(itemId).payload")
        guard FileManager.default.fileExists(atPath: payloadUrl.path) else {
            throw NSError(domain: "ShareHarborSpool", code: 404, userInfo: [NSLocalizedDescriptionKey: "Payload file not found"])
        }
        return payloadUrl
    }

    public func cleanup(maxAgeSeconds: Double) -> (Int, Int64) {
        return (try? lockManager.withLock {
            var deletedCount = 0
            var reclaimedBytes: Int64 = 0
            let cutoff = Date().addingTimeInterval(-maxAgeSeconds)

            guard let folders = try? FileManager.default.contentsOfDirectory(at: deliveriesDir, includingPropertiesForKeys: [.contentModificationDateKey]) else {
                return (0, 0)
            }

            for folder in folders {
                if let attributes = try? FileManager.default.attributesOfItem(atPath: folder.path),
                   let modDate = attributes[.modificationDate] as? Date,
                   modDate < cutoff {
                    deletedCount += 1
                    try? FileManager.default.removeItem(at: folder)
                }
            }

            return (deletedCount, reclaimedBytes)
        }) ?? (0, 0)
    }

    private func performStartupCleanup() {
        guard let folders = try? FileManager.default.contentsOfDirectory(at: deliveriesDir, includingPropertiesForKeys: nil) else {
            return
        }

        for folder in folders {
            let readyMarker = folder.appendingPathComponent("ready.marker")
            let ackMarker = folder.appendingPathComponent("ack.marker")
            if FileManager.default.fileExists(atPath: ackMarker.path) || !FileManager.default.fileExists(atPath: readyMarker.path) {
                try? FileManager.default.removeItem(at: folder)
            }
        }
    }
}
