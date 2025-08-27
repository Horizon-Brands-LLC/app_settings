@preconcurrency import Flutter
import StoreKit
import UIKit

@MainActor
public class AppSettingsPlugin: NSObject, @preconcurrency FlutterPlugin,
    UIWindowSceneDelegate
{
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.spencerccf.app_settings/methods",
            binaryMessenger: registrar.messenger()
        )
        let instance = AppSettingsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(
        _ call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        switch call.method {
        case "openSettings":
            handleOpenSettings(call: call, result: result)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }

    /// Handle the 'openSettings' method call.
    private func handleOpenSettings(
        call: FlutterMethodCall,
        result: @escaping FlutterResult
    ) {
        let arguments = call.arguments as! [String: Any?]
        let type = arguments["type"] as! String
        let preferSystemSettings = arguments["preferSystemSettings"] as Bool?

        switch type {
        case "notification":
            if #available(iOS 16.0, *) {
                openSettings(
                    settingsUrl: UIApplication.openNotificationSettingsURLString
                )
            } else {
                openSystemSettings(
                    preferSystemSettings: preferSystemSettings ?? false
                )
            }
            result(nil)
            break
        case "subscriptions":
            if #available(iOS 15.0, *) {
                Task {
                    let windowScene =
                        UIApplication.shared.connectedScenes.first
                        as? UIWindowScene

                    if windowScene != nil {
                        await openSubscriptionSettings(windowScene!)
                    } else {
                        openSystemSettings(
                            preferSystemSettings: preferSystemSettings ?? false
                        )
                    }

                    result(nil)
                }
            } else {
                // Show the default settings as fallback.
                openSystemSettings(
                    preferSystemSettings: preferSystemSettings ?? false
                )
                result(nil)
            }
            break
        case "wifi":
            if #available(iOS 16.0, *) {
                openSystemSettings(
                    preferSystemSettings: preferSystemSettings ?? true
                )
            } else {
                openSettings(settingsUrl: "App-prefs:WIFI")
            }
            result(nil)
            break
        case "bluetooth", "location":
            openSystemSettings(
                preferSystemSettings: preferSystemSettings ?? true
            )
            break
        default:
            // Show the default settings as fallback.
            openSystemSettings(
                preferSystemSettings: preferSystemSettings ?? false
            )
            result(nil)
            break
        }
    }

    private func openSystemSettings(preferSystemSettings: Bool) {
        if preferSystemSettings {
            openSettings(settingsUrl: "App-prefs:")
        } else {
            openSettings(settingsUrl: UIApplication.openSettingsURLString)
        }
    }

    private func openSettings(settingsUrl: String) {
        guard let url = URL(string: settingsUrl) else {
            return
        }

        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }

    @available(iOS 15.0.0, *)
    private func openSubscriptionSettings(
        _ windowScene: UIWindowScene,
        preferSystemSettings: Bool
    ) async {
        do {
            try await AppStore.showManageSubscriptions(in: windowScene)
        } catch {
            // Show the default settings as fallback.
            openSystemSettings(
                preferSystemSettings: preferSystemSettings ?? false
            )
        }
    }
}
