import UIKit
import Social
import MobileCoreServices

class ShareViewController: SLComposeServiceViewController {

    // Configure your App Group ID here
    private let appGroupId = "group.dev.shareharbor.share_harbor"

    override func isContentValid() -> Bool {
        return true
    }

    override func didSelectPost() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem],
              let groupUrl = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
            self.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        NSItemProviderIngestor.ingestItems(extensionItems: extensionItems, containerUrl: groupUrl) { [weak self] result in
            DispatchQueue.main.async {
                self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            }
        }
    }

    override func configurationItems() -> [Any]! {
        return []
    }
}
