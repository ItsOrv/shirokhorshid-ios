/*
 * Shir o Khorshid - iOS Psiphon Fork
 * UIHostingController bridge to embed SwiftUI settings in UIKit navigation.
 */

import SwiftUI
import UIKit

@objc final class ShirSettingsHostingController: UIHostingController<ShirSettingsView> {

    @objc init() {
        let store = ShirSettingsStore()
        super.init(rootView: ShirSettingsView(store: store))
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        let store = ShirSettingsStore()
        super.init(coder: aDecoder, rootView: ShirSettingsView(store: store))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Shir o Khorshid", comment: "")
    }
}
