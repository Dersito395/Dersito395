import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Espaço livre para o gerenciador de pacotes de conteúdo.
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SobrevivaStorage") {
      let channel = FlutterMethodChannel(name: "br.app.sobreviva/storage", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "freeBytes" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let url = URL(fileURLWithPath: NSHomeDirectory())
        if let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let capacity = values.volumeAvailableCapacityForImportantUsage {
          result(NSNumber(value: capacity))
        } else {
          result(nil)
        }
      }
    }
  }
}
