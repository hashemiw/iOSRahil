import Combine
import UIKit
import Foundation

@MainActor
final class DeviceManager: ObservableObject {
    static let shared = DeviceManager()
    private init() {}

    var deviceID: UInt? {
        get { UserDefaults.standard.value(forKey: "device_id") as? UInt }
        set { UserDefaults.standard.set(newValue, forKey: "device_id") }
    }

    var uuid: String {
        UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}
