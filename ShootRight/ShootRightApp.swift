import SwiftUI

@main
struct ShootRightApp: App {
    init() {
        AppLogger.log("app launched")
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
