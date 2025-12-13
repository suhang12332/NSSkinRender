//
//  ImageDropHandler.swift
//  SkinRenderKit
//
//  Handler for drag-and-drop image loading and validation
//

import AppKit
internal import UniformTypeIdentifiers

/// Handler for loading and validating dropped images
public enum ImageDropHandler {

  // MARK: - Validation Results

  /// Result of image validation
  public enum ValidationResult {
    case valid(NSImage)
    case invalidDimensions(width: Int, height: Int, expected: String)
    case loadFailed(String)
  }

  // MARK: - Image Loading

  /// Load an NSImage from an NSItemProvider
  /// - Parameters:
  ///   - provider: The item provider from drag operation
  ///   - completion: Callback with the loaded image or nil
  public static func loadImage(
    from provider: NSItemProvider,
    completion: @escaping (NSImage?) -> Void
  ) {
    // Try NSImage object first (for in-app drag)
    if provider.canLoadObject(ofClass: NSImage.self) {
      provider.loadObject(ofClass: NSImage.self) { object, _ in
        completion(object as? NSImage)
      }
      return
    }

    // Try file URL
    if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
      loadImageFromFileURL(provider: provider, completion: completion)
      return
    }

    // Try PNG data
    if provider.hasItemConformingToTypeIdentifier(UTType.png.identifier) {
      loadImageFromData(provider: provider, typeIdentifier: UTType.png.identifier, completion: completion)
      return
    }

    // Try JPEG data
    if provider.hasItemConformingToTypeIdentifier(UTType.jpeg.identifier) {
      loadImageFromData(provider: provider, typeIdentifier: UTType.jpeg.identifier, completion: completion)
      return
    }

    // Try generic image
    if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
      loadImageFromGeneric(provider: provider, completion: completion)
      return
    }

    completion(nil)
  }

  private static func loadImageFromFileURL(
    provider: NSItemProvider,
    completion: @escaping (NSImage?) -> Void
  ) {
    provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
      guard error == nil else {
        completion(nil)
        return
      }

      var imageURL: URL?

      if let data = item as? Data {
        imageURL = URL(dataRepresentation: data, relativeTo: nil)
      } else if let url = item as? URL {
        imageURL = url
      } else if let nsUrl = item as? NSURL {
        imageURL = nsUrl as URL
      }

      guard let url = imageURL,
            url.isFileURL,
            FileManager.default.fileExists(atPath: url.path) else {
        completion(nil)
        return
      }

      completion(NSImage(contentsOf: url))
    }
  }

  private static func loadImageFromData(
    provider: NSItemProvider,
    typeIdentifier: String,
    completion: @escaping (NSImage?) -> Void
  ) {
    provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
      guard error == nil, let data = item as? Data else {
        completion(nil)
        return
      }
      completion(NSImage(data: data))
    }
  }

  private static func loadImageFromGeneric(
    provider: NSItemProvider,
    completion: @escaping (NSImage?) -> Void
  ) {
    provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, error in
      guard error == nil else {
        completion(nil)
        return
      }

      if let data = item as? Data {
        completion(NSImage(data: data))
      } else if let image = item as? NSImage {
        completion(image)
      } else {
        completion(nil)
      }
    }
  }

  // MARK: - Validation

  /// Validate an image as a Minecraft skin
  /// - Parameter image: The image to validate
  /// - Returns: Validation result
  public static func validateSkin(_ image: NSImage) -> ValidationResult {
    guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return .loadFailed("Cannot read image data")
    }

    let w = cg.width
    let h = cg.height

    // 64x64 (or exact square multiples) or legacy 64x32 in exact 2:1 multiples
    if w == h && w % 64 == 0 {
      return .valid(image)  // e.g., 64x64, 128x128
    }
    if w % 64 == 0 && h * 2 == w {
      return .valid(image)  // e.g., 64x32, 128x64 (legacy style)
    }

    return .invalidDimensions(width: w, height: h, expected: "64x64 or 64x32")
  }

  /// Validate an image as a Minecraft cape
  /// - Parameter image: The image to validate
  /// - Returns: Validation result
  public static func validateCape(_ image: NSImage) -> ValidationResult {
    guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return .loadFailed("Cannot read image data")
    }

    let w = cg.width
    let h = cg.height

    // Standard 64x32 or any exact 2:1 multiple (e.g., 128x64, 256x128)
    if w == 2 * h && w % 64 == 0 {
      return .valid(image)
    }

    return .invalidDimensions(width: w, height: h, expected: "64x32 (2:1 ratio)")
  }
}
