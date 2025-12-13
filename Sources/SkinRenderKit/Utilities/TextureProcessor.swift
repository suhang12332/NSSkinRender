//
//  TextureProcessor.swift
//  SkinRenderKit
//
//  Utility for image processing operations used in texture mapping
//

import AppKit

/// Texture processing utilities for cropping, rotating, and flipping images
public enum TextureProcessor {

  // MARK: - Error Types

  /// Errors that can occur during texture processing
  public enum Error: Swift.Error, CustomStringConvertible {
    /// Failed to convert NSImage to CGImage
    case cgImageConversionFailed
    /// The crop rectangle is outside the image bounds
    case cropRectOutOfBounds(rect: CGRect, imageBounds: CGRect)
    /// The crop rectangle does not intersect with the image
    case cropRectEmpty(rect: CGRect)
    /// CGImage cropping operation failed
    case croppingFailed(rect: CGRect)
    /// Failed to acquire graphics context for transformation
    case graphicsContextUnavailable
    /// Image has invalid or zero dimensions
    case invalidImageSize(width: CGFloat, height: CGFloat)

    public var description: String {
      switch self {
      case .cgImageConversionFailed:
        return "Failed to convert NSImage to CGImage"
      case .cropRectOutOfBounds(let rect, let imageBounds):
        return "Crop rect \(rect) is outside image bounds \(imageBounds)"
      case .cropRectEmpty(let rect):
        return "Crop rect \(rect) does not intersect with image"
      case .croppingFailed(let rect):
        return "CGImage cropping failed for rect \(rect)"
      case .graphicsContextUnavailable:
        return "Failed to acquire graphics context for image transformation"
      case .invalidImageSize(let width, let height):
        return "Invalid image size: \(width)x\(height)"
      }
    }
  }

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
  /// - Returns: Result containing cropped image or error
  public static func crop(_ image: NSImage, rect: CGRect) -> Result<NSImage, Error> {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
      return .failure(.cgImageConversionFailed)
    }

    let imageWidth = CGFloat(cgImage.width)
    let imageHeight = CGFloat(cgImage.height)
    let imageBounds = CGRect(x: 0, y: 0, width: imageWidth, height: imageHeight)

    // Validate crop rect is within image bounds
    if !imageBounds.contains(rect) {
      let intersection = rect.intersection(imageBounds)
      if intersection.isEmpty {
        return .failure(.cropRectEmpty(rect: rect))
      }
      return .failure(.cropRectOutOfBounds(rect: rect, imageBounds: imageBounds))
    }

    guard let croppedCGImage = cgImage.cropping(to: rect) else {
      return .failure(.croppingFailed(rect: rect))
    }

    return .success(NSImage(
      cgImage: croppedCGImage,
      size: NSSize(width: rect.width, height: rect.height)
    ))
  }

  // MARK: - Rotation

  /// Rotate an image by the specified degrees
  /// - Parameters:
  ///   - image: Source image to rotate
  ///   - degrees: Rotation angle in degrees
  /// - Returns: Result containing rotated image or error
  public static func rotate(_ image: NSImage, degrees: CGFloat) -> Result<NSImage, Error> {
    let radians = degrees * .pi / 180.0
    let originalSize = image.size

    guard originalSize.width > 0 && originalSize.height > 0 else {
      return .failure(.invalidImageSize(width: originalSize.width, height: originalSize.height))
    }

    let newImage = NSImage(size: originalSize)
    newImage.lockFocus()

    // Disable interpolation to preserve pixel-perfect rendering
    guard let context = NSGraphicsContext.current else {
      newImage.unlockFocus()
      return .failure(.graphicsContextUnavailable)
    }

    context.imageInterpolation = .none
    context.shouldAntialias = false
    context.cgContext.interpolationQuality = .none

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
    return .success(newImage)
  }

  // MARK: - Flipping

  /// Flip an image horizontally
  /// - Parameter image: Source image to flip
  /// - Returns: Result containing horizontally flipped image or error
  public static func flipHorizontally(_ image: NSImage) -> Result<NSImage, Error> {
    let size = image.size

    guard size.width > 0 && size.height > 0 else {
      return .failure(.invalidImageSize(width: size.width, height: size.height))
    }

    let newImage = NSImage(size: size)
    newImage.lockFocus()

    guard let context = NSGraphicsContext.current else {
      newImage.unlockFocus()
      return .failure(.graphicsContextUnavailable)
    }

    context.imageInterpolation = .none
    context.shouldAntialias = false
    context.cgContext.interpolationQuality = .none

    let transform = NSAffineTransform()
    transform.translateX(by: size.width, yBy: 0)
    transform.scaleX(by: -1, yBy: 1)
    transform.concat()

    image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    return .success(newImage)
  }

  /// Flip an image vertically
  /// - Parameter image: Source image to flip
  /// - Returns: Result containing vertically flipped image or error
  public static func flipVertically(_ image: NSImage) -> Result<NSImage, Error> {
    let size = image.size

    guard size.width > 0 && size.height > 0 else {
      return .failure(.invalidImageSize(width: size.width, height: size.height))
    }

    let newImage = NSImage(size: size)
    newImage.lockFocus()

    guard let context = NSGraphicsContext.current else {
      newImage.unlockFocus()
      return .failure(.graphicsContextUnavailable)
    }

    context.imageInterpolation = .none
    context.shouldAntialias = false
    context.cgContext.interpolationQuality = .none

    let transform = NSAffineTransform()
    transform.translateX(by: 0, yBy: size.height)
    transform.scaleX(by: 1, yBy: -1)
    transform.concat()

    image.draw(at: .zero, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
    newImage.unlockFocus()
    return .success(newImage)
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
  /// - Returns: Result containing transformed image or error
  public static func applyBottomFaceTransform(
    _ image: NSImage,
    flipMode: FlipMode,
    rotate180: Bool
  ) -> Result<NSImage, Error> {
    let flippedResult: Result<NSImage, Error> = {
      switch flipMode {
      case .none:
        return .success(image)
      case .horizontal:
        return flipHorizontally(image)
      case .vertical:
        return flipVertically(image)
      case .both:
        return flipHorizontally(image).flatMap { flipVertically($0) }
      }
    }()

    guard case .success(let flipped) = flippedResult else {
      return flippedResult
    }

    return rotate180 ? rotate(flipped, degrees: 180) : .success(flipped)
  }
}
