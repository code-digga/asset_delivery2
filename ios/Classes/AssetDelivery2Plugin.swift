import Flutter
import UIKit

public class AssetDelivery2Plugin: NSObject, FlutterPlugin {
  
  private var activeRequests: [String: NSBundleResourceRequest] = [:]

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "asset_delivery2", binaryMessenger: registrar.messenger())
    let instance = AssetDelivery2Plugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "initialize" {
      guard let args = call.arguments as? [String: Any],
            let odrTag = args["tag"] as? String,
            let sampleFilename = args["sampleFilename"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Both a tag and a sampleFilename must be provided.", details: nil))
        return
      }
      
      let tags = Set([odrTag])
      let request = NSBundleResourceRequest(tags: tags)
      
      self.activeRequests[odrTag] = request
      request.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent

      request.conditionallyBeginAccessingResources { (resourcesAvailable) in
        DispatchQueue.main.async {
          if resourcesAvailable {
             self.handleSuccess(request: request, sampleFilename: sampleFilename, result: result)
          } else {
             request.beginAccessingResources { (error) in
                DispatchQueue.main.async {
                  if let error = error {
                    self.activeRequests.removeValue(forKey: odrTag)
                    result(FlutterError(code: "ODR_ERROR", message: error.localizedDescription, details: nil))
                  } else {
                    self.handleSuccess(request: request, sampleFilename: sampleFilename, result: result)
                  }
                }
             }
          }
        }
      }
      
    } else if call.method == "release" {
      guard let args = call.arguments as? [String: Any],
            let odrTag = args["tag"] as? String else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "A resource tag must be provided.", details: nil))
        return
      }
      
      if let request = self.activeRequests[odrTag] {
          request.endAccessingResources()
          self.activeRequests.removeValue(forKey: odrTag)
          result(true)
      } else {
          result(FlutterError(code: "NOT_FOUND", message: "No active request found for tag: \(odrTag)", details: nil))
      }
      
    } else {
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleSuccess(request: NSBundleResourceRequest, sampleFilename: String, result: @escaping FlutterResult) {
    // 1. Clean the path (remove a leading slash if the user accidentally passed one)
    let cleanPath = sampleFilename.hasPrefix("/") ? String(sampleFilename.dropFirst()) : sampleFilename
    
    // 2. Extract the directory, filename, and extension for Apple's API
    let directory = (cleanPath as NSString).deletingLastPathComponent
    let file = (cleanPath as NSString).lastPathComponent
    let name = (file as NSString).deletingPathExtension
    let ext = (file as NSString).pathExtension
    
    let finalExt = ext.isEmpty ? nil : ext
    let finalDir = directory.isEmpty ? nil : directory
    
    // 3. Ask iOS to locate the file, explicitly providing the subdirectory
    guard let resolvedPath = request.bundle.path(forResource: name, ofType: finalExt, inDirectory: finalDir) else {
        result(FlutterError(code: "FILE_NOT_FOUND", message: "Could not find \(cleanPath) in the requested asset pack.", details: nil))
        return
    }
    
    // 4. Calculate the true root directory by backing out of the folder structure
    // If resolvedPath is ".../AssetPacks/pack1/images 3/brain_bg.png",
    // and cleanPath is "images 3/brain_bg.png" (2 components),
    // we need to delete the last component 2 times to get the root.
    var baseUrl = URL(fileURLWithPath: resolvedPath)
    let pathComponentsCount = (cleanPath as NSString).pathComponents.count
    
    for _ in 0..<pathComponentsCount {
        baseUrl = baseUrl.deletingLastPathComponent()
    }
    
    // 5. Return the root base path to Flutter
    result(baseUrl.path)
  }
}