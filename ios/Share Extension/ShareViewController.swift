import receive_sharing_intent

class ShareViewController: RSIShareViewController {
    // Redirect to the host app so the shared link can be shown as a QR code.
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
