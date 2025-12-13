//
//  TextureProcessor.swift
//  SkinRenderKit
//
//  Utility for image processing operations used in texture mapping
//

import AppKit

/// Texture processing utilities for cropping, rotating, and flipping images
public enum TextureProcessor {

  /// Bottom face flip mode options
  public enum FlipMode {
    case none
    case horizontal
    case vertical
    case both
  }

  // MARK: - Cropping

  /// Crop an image to the specified rectangle
  /// - Parameters:
  ///   - image: Source image to crop
  ///   - rect: Rectangle defining the crop area in pixel coordinates
  /// - Returns: Cropped image, or nil if cropping fails
  public static func crop(_ image: NSImage, rect: CGRect) -> NSImage? {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return nil
    }

    let imageWidth = CGFloat(cgImage.width)
    let imageHeight = CGFloat(cgImage.height)
    let imageBounds = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)

    // Validate crop rect is within image bounds
    if !imageBounds.contains(rect) {
      let intersection = rect.intersection(imageBounds)
      if intersection.isEmpty {
        return nil
      }
    }

    guard let croppedCGImage = cgImage.cropping(to: rect) else {
      return nil
    }

    return NSImage(
      cgImage: croppedCGImage,
      size: NSSize(width: rect.width, height: rect.height)
    )
  }

  // MARK: - Rotation

  /// Rotate an image by the specified degrees
  /// - Parameters:
  ///   - image: Source image to rotate
  ///   - degrees: Rotation angle in degrees
  /// - Returns: Rotated image, or nil if rotation fails
  public static func rotate(_ image: NSImage, degrees: CGFloat) -> NSImage? {
    let radians = degrees * .pi / 180.0
    let originalSize = image.size

    let newImage = NSImage(size: originalSize)
    newImage.lockFocus()

    // Disable interpolation to preserve pixel-perfect rendering
    if let context = NSGraphicsContext.current {
      context.imageInterpolation = .none
      context.shouldAntialias = false
      context.cgContext.interpolationQuality = .none
    }

    let transform = NSAffineTransform()
    transform.translateX(by: originalSize.width / 2, yBy: originalSize.height / 2)
    transform.rotate(byRadians: radians)
    transform.translateX(by: -originalSize.width / 2, yBy: -originalSize.height / 2)
    transform.concat()

    image.draw(
      at: NSPoint.zero,
      from: NSRect.zero,
      operation: .copy,
      fraction: 1.0
    )

    newImage.unlockFocus()
    return newImage
  }

  // MARK: - Flipping

  /// Flip an image horizontally
  /// - Parameter image: Source image to flip
  /// - Returns: Horizontally flipped image, or nil if operation fails
  public static func flipHorizontally(_ image: NSImage) -> NSImage? {
    let size = image.size
    let newImage = NSImage(size: size)
    newImage.lockFocus()

    if let context = NSGraphicsContext.current {
      context.imageInterpolation = .none
      context.shouldAntialias = false
      context.cgContext.interpolationQuality = .none
    }

    let transform = NSAffineTransform()
    transform.translateX(by: size.width, yBy: 0)
    transform.scaleX(by: -1, yBy: 1)
    transform.concat()

    image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    return newImage
  }

  /// Flip an image vertically
  /// - Parameter image: Source image to flip
  /// - Returns: Vertically flipped image, or nil if operation fails
  public static func flipVertically(_ image: NSImage) -> NSImage? {
    let size = image.size
    let newImage = NSImage(size: size)
    newImage.lockFocus()

    if let context = NSGraphicsContext.current {
      context.imageInterpolation = .none
      context.shouldAntialias = false
      context.cgContext.interpolationQuality = .none
    }

    let transform = NSAffineTransform()
    transform.translateX(by: 0, yBy: size.height)
    transform.scaleX(by: 1, yBy: -1)
    transform.concat()

    image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    return newImage
  }

  // MARK: - Transparency Detection

  /// Check if an image contains transparent pixels
  /// - Parameter image: Image to check
  /// - Returns: True if the image has an alpha channel with transparency
  public static func hasTransparentPixels(_ image: NSImage) -> Bool {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return false
    }

    let alphaInfo = cgImage.alphaInfo
    return alphaInfo != .none
      && alphaInfo != .noneSkipFirst
      && alphaInfo != .noneSkipLast
  }

  // MARK: - Combined Transforms

  /// Apply flip and rotation transforms for bottom face processing
  /// - Parameters:
  ///   - image: Source image
  ///   - flipMode: Flip mode to apply
  ///   - rotate180: Whether to rotate 180 degrees after flipping
  /// - Returns: Transformed image
  public static func applyBottomFaceTransform(
    _ image: NSImage,
    flipMode: FlipMode,
    rotate180: Bool
  ) -> NSImage {
    let flipped: NSImage = {
      switch flipMode {
      case .none:
        return image
      case .horizontal:
        return flipHorizontally(image) ?? image
      case .vertical:
        return flipVertically(image) ?? image
      case .both:
        let h = flipHorizontally(image) ?? image
        return flipVertically(h) ?? h
      }
    }()

    return rotate180 ? (rotate(flipped, degrees: 180) ?? flipped) : flipped
  }
}
