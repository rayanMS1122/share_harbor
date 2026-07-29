import Flutter
import UIKit

public class ShareHarborPlugin: NSObject, FlutterPlugin, ShareHarborHostApi {

    private var storageCore: NativeStorageCore?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = ShareHarborPlugin()
        instance.storageCore = NativeStorageCore()
        ShareHarborHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
    }

    public func getPendingDeliveries(completion: @escaping (Result<[NativeDelivery], Error>) -> Void) {
        guard let storageCore = storageCore else {
            completion(.failure(NSError(domain: "ShareHarbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage core uninitialized"])))
            return
        }
        completion(.success(storageCore.getPendingDeliveries()))
    }

    public func claimDelivery(deliveryId: String, leaseDurationSeconds: Int64, completion: @escaping (Result<NativeClaim, Error>) -> Void) {
        guard let storageCore = storageCore else {
            completion(.failure(NSError(domain: "ShareHarbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage core uninitialized"])))
            return
        }
        do {
            let claim = try storageCore.claimDelivery(deliveryId: deliveryId, leaseDurationSeconds: leaseDurationSeconds)
            completion(.success(claim))
        } catch {
            completion(.failure(error))
        }
    }

    public func claimNextDelivery(leaseDurationSeconds: Int64, completion: @escaping (Result<NativeClaim?, Error>) -> Void) {
        guard let storageCore = storageCore else {
            completion(.failure(NSError(domain: "ShareHarbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage core uninitialized"])))
            return
        }
        do {
            let claim = try storageCore.claimNextDelivery(leaseDurationSeconds: leaseDurationSeconds)
            completion(.success(claim))
        } catch {
            completion(.failure(error))
        }
    }

    public func acknowledgeClaim(claimId: String, deliveryId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let storageCore = storageCore else {
            completion(.failure(NSError(domain: "ShareHarbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage core uninitialized"])))
            return
        }
        do {
            try storageCore.acknowledgeClaim(claimId: claimId, deliveryId: deliveryId)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    public func releaseClaim(claimId: String, deliveryId: String, reason: String?, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let storageCore = storageCore else {
            completion(.failure(NSError(domain: "ShareHarbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage core uninitialized"])))
            return
        }
        do {
            try storageCore.releaseClaim(claimId: claimId, deliveryId: deliveryId, reason: reason)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    public func retryDelivery(deliveryId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        storageCore?.retryDelivery(deliveryId: deliveryId)
        completion(.success(()))
    }

    public func inspectInbox(completion: @escaping (Result<NativeHealth, Error>) -> Void) {
        guard let storageCore = storageCore else {
            completion(.failure(NSError(domain: "ShareHarbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage core uninitialized"])))
            return
        }
        completion(.success(storageCore.inspectInbox()))
    }

    public func cleanupInbox(maxAgeSeconds: Int64, completion: @escaping (Result<NativeCleanupResult, Error>) -> Void) {
        guard let storageCore = storageCore else {
            completion(.failure(NSError(domain: "ShareHarbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage core uninitialized"])))
            return
        }
        completion(.success(storageCore.cleanupInbox(maxAgeSeconds: maxAgeSeconds)))
    }

    public func getPayloadPath(deliveryId: String, itemId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let storageCore = storageCore else {
            completion(.failure(NSError(domain: "ShareHarbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Storage core uninitialized"])))
            return
        }
        do {
            let path = try storageCore.getPayloadPath(deliveryId: deliveryId, itemId: itemId)
            completion(.success(path))
        } catch {
            completion(.failure(error))
        }
    }
}
