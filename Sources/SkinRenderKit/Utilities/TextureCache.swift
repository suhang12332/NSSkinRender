//
//  TextureCache.swift
//  SkinRenderKit
//
//  Cache for texture cropping operations to avoid redundant processing
//

import AppKit

/// Cache key for texture cropping operations
/// Note: Uses image size and crop region as key, not object identifier
/// This way even if the same NSImage object is reloaded with different content, caching works correctly as long as the size is the same
private struct CropCacheKey: Hashable {
  let imageSize: CGSize
  let rect: CGRect
  
  init(image: NSImage, rect: CGRect) {
    // Use the image size as part of the key, not the object identifier
    // This avoids cache confusion when the same NSImage object loads different content at different times
    // But a better approach is to clear the cache when the skin updates (already implemented in updateSkinGeometry)
    self.imageSize = image.size
    self.rect = rect
  }
}

/// Cache entry containing cropped image and transparency info
private struct CropCacheEntry {
  let croppedImage: NSImage
  let hasTransparency: Bool
}

/// Cache manager for texture operations
/// Texture operation cache manager, used to avoid redundant cropping and transparency detection operations
public final class TextureCache {
  
  /// Crop result cache: key is (image, rect), value is cropped image
  private var cropCache: [CropCacheKey: CropCacheEntry] = [:]
  
  /// Maximum cache entries (prevents unbounded memory growth)
  private let maxCacheSize: Int
  
  public init(maxCacheSize: Int = 100) {
    self.maxCacheSize = maxCacheSize
  }
  
  /// Get or perform crop operation (with caching)
  /// - Parameters:
  ///   - image: Source image
  ///   - rect: Crop region
  ///   - cropFunction: Actual crop function
  /// - Returns: Crop result and transparency info
  internal func getOrCrop(
    image: NSImage,
    rect: CGRect,
    cropFunction: (NSImage, CGRect) -> Result<NSImage, TextureProcessor.Error>
  ) -> Result<(NSImage, Bool), TextureProcessor.Error> {
    let key = CropCacheKey(image: image, rect: rect)
    
    // Check cache
    if let cached = cropCache[key] {
      return .success((cached.croppedImage, cached.hasTransparency))
    }
    
    // Perform crop
    let cropResult = cropFunction(image, rect)
    
    guard case .success(let croppedImage) = cropResult else {
      return cropResult.map { ($0, false) }
    }
    
    // Detect transparency (detect during cropping to avoid redundant detection later)
    let hasTransparency = TextureProcessor.hasTransparentPixels(croppedImage)
    
    // Cache result
    let entry = CropCacheEntry(croppedImage: croppedImage, hasTransparency: hasTransparency)
    
    // If cache is full, remove the oldest entry (simple FIFO strategy)
    if cropCache.count >= maxCacheSize {
      let oldestKey = cropCache.keys.first!
      cropCache.removeValue(forKey: oldestKey)
    }
    
    cropCache[key] = entry
    
    return .success((croppedImage, hasTransparency))
  }
  
  /// Clear all caches
  public func clear() {
    cropCache.removeAll()
  }
  
}
