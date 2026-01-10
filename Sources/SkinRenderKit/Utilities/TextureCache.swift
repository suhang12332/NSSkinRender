//
//  TextureCache.swift
//  SkinRenderKit
//
//  Cache for texture cropping operations to avoid redundant processing
//

import AppKit

/// Cache key for texture cropping operations
/// 注意：使用图像尺寸和裁剪区域作为键，而不是对象标识符
/// 这样即使同一个NSImage对象被重新加载不同内容，只要尺寸相同就能正确缓存
private struct CropCacheKey: Hashable {
  let imageSize: CGSize
  let rect: CGRect
  
  init(image: NSImage, rect: CGRect) {
    // 使用图像的尺寸作为键的一部分，而不是对象标识符
    // 这样可以避免同一NSImage对象在不同时间加载不同内容时的缓存混乱
    // 但更好的做法是在皮肤更新时清空缓存（已在updateSkinGeometry中实现）
    self.imageSize = image.size
    self.rect = rect
  }
}

/// Cache entry containing cropped image and transparency info
private struct CropCacheEntry {
  let croppedImage: NSImage
  let hasTransparency: Bool
  
  init(croppedImage: NSImage, hasTransparency: Bool) {
    self.croppedImage = croppedImage
    self.hasTransparency = hasTransparency
  }
}

/// Cache manager for texture operations
/// 纹理操作缓存管理器，用于避免重复的裁剪和透明度检测操作
public final class TextureCache {
  
  // MARK: - Cache Storage
  
  /// 裁剪结果缓存：键为 (image, rect)，值为裁剪后的图像
  private var cropCache: [CropCacheKey: CropCacheEntry] = [:]
  
  /// 最大缓存条目数（防止内存无限增长）
  private let maxCacheSize: Int
  
  // MARK: - Initialization
  
  public init(maxCacheSize: Int = 100) {
    self.maxCacheSize = maxCacheSize
  }
  
  // MARK: - Crop Cache
  
  /// 获取或执行裁剪操作（带缓存）
  /// - Parameters:
  ///   - image: 源图像
  ///   - rect: 裁剪区域
  ///   - cropFunction: 实际的裁剪函数
  /// - Returns: 裁剪结果和透明度信息
  internal func getOrCrop(
    image: NSImage,
    rect: CGRect,
    cropFunction: (NSImage, CGRect) -> Result<NSImage, TextureProcessor.Error>
  ) -> Result<(NSImage, Bool), TextureProcessor.Error> {
    let key = CropCacheKey(image: image, rect: rect)
    
    // 检查缓存
    if let cached = cropCache[key] {
      return .success((cached.croppedImage, cached.hasTransparency))
    }
    
    // 执行裁剪
    let cropResult = cropFunction(image, rect)
    
    guard case .success(let croppedImage) = cropResult else {
      return cropResult.map { ($0, false) }
    }
    
    // 检测透明度（在裁剪时一并检测，避免后续重复检测）
    let hasTransparency = TextureProcessor.hasTransparentPixels(croppedImage)
    
    // 缓存结果
    let entry = CropCacheEntry(croppedImage: croppedImage, hasTransparency: hasTransparency)
    
    // 如果缓存已满，移除最旧的条目（简单的FIFO策略）
    if cropCache.count >= maxCacheSize {
      let oldestKey = cropCache.keys.first!
      cropCache.removeValue(forKey: oldestKey)
    }
    
    cropCache[key] = entry
    
    return .success((croppedImage, hasTransparency))
  }
  
  // MARK: - Cache Management
  
  /// 清空所有缓存
  public func clear() {
    cropCache.removeAll()
  }
  
  /// 获取当前缓存大小
  public var cacheSize: Int {
    cropCache.count
  }
}
