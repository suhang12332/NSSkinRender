//
//  VoxelOuterLayerBuilder.swift
//  SkinRenderKit
//
//  Builds voxel-based overlay layers (hat, jacket, sleeves) from Minecraft skin textures.
//  Optimized version: Use configuration struct, enforce baseSize, batch processing optimization
//

import AppKit
import SceneKit

/// Voxel overlay configuration parameters
struct VoxelOverlayConfig {
  /// Outer layer size
  let boxSize: SCNVector3
  /// Base layer size (must be provided, no longer optional)
  let baseSize: SCNVector3
  /// Voxel size, default 1.0
  let voxelSize: CGFloat
  /// Voxel thickness, if nil use size difference
  let voxelThickness: CGFloat?
  
  init(
    boxSize: SCNVector3,
    baseSize: SCNVector3,
    voxelSize: CGFloat = 1.0,
    voxelThickness: CGFloat? = nil
  ) {
    self.boxSize = boxSize
    self.baseSize = baseSize
    self.voxelSize = voxelSize
    self.voxelThickness = voxelThickness
  }
}

/// Builder responsible for constructing voxelized overlay layers (hat, jacket, sleeves)
/// from a Minecraft skin texture. Each visible pixel on the specified cube faces is
/// represented as a tiny SCNBox ("voxel") to give the outer layer extra depth.
///
/// Optimized version:
/// - Use configuration struct to simplify interface
/// - Enforce baseSize, simplify logic
/// - Material cache optimization
/// - Batch processing optimization
/// - Texture crop cache
/// - CGContext reuse
/// - Phase 2 optimization: Inline voxel merging (reduce node count)
final class VoxelOuterLayerBuilder {
  
  // MARK: - Caches
  
  /// Material cache: Use color RGB values as keys to reuse materials
  private var materialCache: [UInt32: SCNMaterial] = [:]
  
  /// Texture cache: Used to cache crop results
  private let textureCache: TextureCache
  
  // Note: CGContext cannot be truly reused because its data is read-only
  // Need to create new context each time, so removed context caching
  // Performance impact is small because context creation overhead is minimal

  init(textureCache: TextureCache? = nil) {
    self.textureCache = textureCache ?? TextureCache()
  }

  /// Build a voxel-based overlay node from the given skin texture and face specs.
  ///
  /// - Parameters:
  ///   - skinImage: The full Minecraft skin texture image.
  ///   - specs: Face specifications (front/right/back/left/top/bottom) defining
  ///            the crop rectangles on the skin texture.
  ///   - config: Voxel overlay configuration parameters
  ///   - position: Position of the overlay node relative to its parent/group.
  ///   - name: Name to assign to the overlay node (for debugging).
  ///
  /// - Returns: An SCNNode containing all voxel children.
  func buildVoxelOverlay(
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    config: VoxelOverlayConfig,
    position: SCNVector3,
    name: String
  ) -> SCNNode {
    let containerNode = SCNNode()
    containerNode.name = name
    containerNode.position = position
    containerNode.renderingOrder = CharacterDimensions.RenderingOrder.outerLayers

    populateVoxelOverlay(
      in: containerNode,
      from: skinImage,
      specs: specs,
      config: config
    )

    return containerNode
  }

  /// Rebuild an existing voxel overlay node with a new skin image.
  ///
  /// - Parameters:
  ///   - containerNode: Existing overlay container node whose children will be replaced.
  ///   - skinImage: The new Minecraft skin texture image.
  ///   - specs: Face specifications defining crop rectangles.
  ///   - config: Voxel overlay configuration parameters
  func rebuildVoxelOverlay(
    in containerNode: SCNNode,
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    config: VoxelOverlayConfig
  ) {
    // Clear existing voxels and clean up resources
    for child in containerNode.childNodes {
      if let geometry = child.geometry {
        for material in geometry.materials {
          material.diffuse.contents = nil
        }
        geometry.materials = []
      }
      child.removeFromParentNode()
    }
    
    clearMaterialCache()

    populateVoxelOverlay(
      in: containerNode,
      from: skinImage,
      specs: specs,
      config: config
    )
  }

  /// Core implementation that fills a container node with voxel children
  private func populateVoxelOverlay(
    in containerNode: SCNNode,
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    config: VoxelOverlayConfig
  ) {
    // Calculate size difference (baseSize is now required, no default needed)
    let diffX = CGFloat(config.boxSize.x) - CGFloat(config.baseSize.x)
    let diffY = CGFloat(config.boxSize.y) - CGFloat(config.baseSize.y)
    let diffZ = CGFloat(config.boxSize.z) - CGFloat(config.baseSize.z)
    
    // Per-face size differences: [front, right, back, left, top, bottom]
    let faceSizeDifferences: [CGFloat] = [diffZ, diffX, diffZ, diffX, diffY, diffY]
    
    // Calculate per-face thickness
    let faceThicknesses: [CGFloat] = if let customThickness = config.voxelThickness {
      Array(repeating: customThickness, count: 6)
    } else {
      faceSizeDifferences
    }
    
    // Pre-calculate half thickness values
    let halfThicknesses = faceThicknesses.map { $0 / 2.0 }
    
    // Shared CGContext configuration
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    // Iterate over each face
    for (faceIndex, spec) in specs.enumerated() {
      // Crop directly without cache (avoid material confusion)
      // During skin rendering, each region is typically cropped only once, cache benefit is limited
      // Also NSImage instances may be reused to load different content, cache could cause incorrect results
      guard case .success(let faceImage) = TextureProcessor.crop(skinImage, rect: spec.rect),
            let cgImage = faceImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
      else {
        continue
      }

      let width = Int(spec.rect.width)
      let height = Int(spec.rect.height)

      // Optimization: Use CGImage pixel data directly (if format matches)
      // If format doesn't match, use CGContext to convert
      let data: UnsafePointer<UInt8>
      let bytesPerRow: Int

      // Use CGContext to read pixel data
      guard let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo
      ) else {
        continue
      }
      
      context.interpolationQuality = .none
      context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
      
      guard let pixelData = context.data else { continue }
      // Convert UnsafeMutablePointer to UnsafePointer (since we only read data)
      let mutablePointer = pixelData.assumingMemoryBound(to: UInt8.self)
      data = UnsafePointer(mutablePointer)
      bytesPerRow = width * 4

      // Pre-calculate parameters for this face
      let faceSizeDifference = faceSizeDifferences[faceIndex]
      let thickness = faceThicknesses[faceIndex]
      let halfThickness = halfThicknesses[faceIndex]
      
      // Pre-calculate constants needed for position calculation
      let halfWidth = CGFloat(config.boxSize.x) / 2.0
      let halfHeight = CGFloat(config.boxSize.y) / 2.0
      let halfLength = CGFloat(config.boxSize.z) / 2.0
      let totalSpanX = CGFloat(width) * config.voxelSize
      let totalSpanY = CGFloat(height) * config.voxelSize
      let offsetX = (CGFloat(config.boxSize.x) - totalSpanX) / 2.0
      let offsetY = (CGFloat(config.boxSize.y) - totalSpanY) / 2.0
      let offsetZ = (CGFloat(config.boxSize.z) - totalSpanX) / 2.0
      let offsetZH = (CGFloat(config.boxSize.z) - totalSpanY) / 2.0
      
      let startX = -halfWidth + offsetX + config.voxelSize / 2.0
      let startY = halfHeight - offsetY - config.voxelSize / 2.0
      let startZ = -halfLength + offsetZ + config.voxelSize / 2.0
      let startZH = -halfLength + offsetZH + config.voxelSize / 2.0
      
      // Position offset calculation
      let halfSizeDifference = faceSizeDifference / 2.0
      var offset = halfThickness - halfSizeDifference
      if abs(offset) < 0.001 {
        offset = 0.01
      }

      // Phase 2 optimization: Inline merging - process row by row and merge consecutive same-color pixel segments
      // Phase 4 optimization: Collect all segments, group by color, batch create nodes
      var allSegments: [(segment: VoxelSegment, position: SCNVector3, mergedWidth: CGFloat)] = []
      allSegments.reserveCapacity(height * 10)  // Pre-allocate capacity, assuming average 10 segments per row
      
      for y in 0..<height {
        // Process current row, merge consecutive same-color pixel segments
        let segments = processRowPixels(
          row: y,
          width: width,
          data: data,
          bytesPerRow: bytesPerRow
        )
        
        // Calculate position info for each segment
        for segment in segments {
          let segmentLength = segment.endX - segment.startX
          let mergedWidth = CGFloat(segmentLength) * config.voxelSize
          
          // Calculate segment center position
          let segmentStart = CGFloat(segment.startX)
          let segmentEnd = CGFloat(segment.endX)
          let centerPixelIndex = (segmentStart + segmentEnd - 1.0) / 2.0
          let centerOffset = centerPixelIndex * config.voxelSize
          
          // Calculate merged voxel position (segment geometric center)
          var voxelPosition: SCNVector3
          switch faceIndex {
          case 0: // front (+Z)
            let px = startX + centerOffset
            let py = startY - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(px, py, halfLength + offset)
            
          case 1: // right (+X) - Z坐标反向
            let pz = halfLength - offsetZ - config.voxelSize / 2.0 - centerOffset
            let py = startY - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(halfWidth + offset, py, pz)
            
          case 2: // back (-Z) - X坐标反向
            let px = halfWidth - offsetX - config.voxelSize / 2.0 - centerOffset
            let py = startY - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(px, py, -halfLength - offset)
            
          case 3: // left (-X)
            let pz = startZ + centerOffset
            let py = startY - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(-halfWidth - offset, py, pz)
            
          case 4: // top (+Y)
            let px = startX + centerOffset
            let pz = halfLength - offsetZH - config.voxelSize / 2.0 - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(px, halfHeight + offset, pz)
            
          case 5: // bottom (-Y) - X坐标反向
            let px = halfWidth - offsetX - config.voxelSize / 2.0 - centerOffset
            let pz = startZH + CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(px, -halfHeight - offset, pz)
            
          default:
            continue
          }
          
          allSegments.append((segment: segment, position: voxelPosition, mergedWidth: mergedWidth))
        }
      }
      
      // Group segments by color key (Phase 4 optimization: reduce same-material usage)
      let segmentsByColor = Dictionary(grouping: allSegments) { $0.segment.colorKey }
      
      // Batch create nodes for each color group
      for (_, colorSegments) in segmentsByColor {
        // Get material (use first segment's RGB values since same-group colors are identical)
        let firstSegment = colorSegments[0].segment
        let material = getOrCreateMaterial(
          r: firstSegment.r,
          g: firstSegment.g,
          b: firstSegment.b,
          a: firstSegment.a
        )
        
        // Create nodes for each segment (use cached material)
        for (_, position, mergedWidth) in colorSegments {
          let voxelNode = createMergedVoxelNode(
            material: material,
            position: position,
            faceIndex: faceIndex,
            voxelSize: config.voxelSize,
            mergedWidth: mergedWidth,
            thickness: thickness
          )
          containerNode.addChildNode(voxelNode)
        }
      }
    }
  }

  /// Phase 3 optimization: Get or create material directly from RGB values (avoid unnecessary NSColor object creation)
  private func getOrCreateMaterial(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> SCNMaterial {
    let rgbKey = rgbToColorKey(r: r, g: g, b: b)
    
    if let cachedMaterial = materialCache[rgbKey] {
      return cachedMaterial
    }
    
    // Only create NSColor object when creating new material
    let color = NSColor(
      red: CGFloat(r) / 255.0,
      green: CGFloat(g) / 255.0,
      blue: CGFloat(b) / 255.0,
      alpha: CGFloat(a) / 255.0
    )
    
    let material = SCNMaterial()
    configureBaseMaterialProperties(material, color: color)
    materialCache[rgbKey] = material
    
    return material
  }
  
  /// 第三阶段优化：直接从RGB值创建颜色键（避免NSColor对象创建）
  private func rgbToColorKey(r: UInt8, g: UInt8, b: UInt8) -> UInt32 {
    let r32 = UInt32(r)
    let g32 = UInt32(g)
    let b32 = UInt32(b)
    return (r32 << 24) | (g32 << 16) | (b32 << 8)
  }
  
  private func clearMaterialCache() {
    for material in materialCache.values {
      material.diffuse.contents = nil
    }
    materialCache.removeAll()
  }

  // MARK: - Voxel Merging (Stage 2 Optimization)
  
  /// 表示一个合并的体素段（同一行内连续相同颜色的像素）
  /// 第三阶段优化：存储RGB值而不是NSColor对象，延迟颜色对象创建
  private struct VoxelSegment {
    let startX: Int
    let endX: Int      // 不包含，即 [startX, endX)
    let r: UInt8       // 红色分量 (0-255)
    let g: UInt8       // 绿色分量 (0-255)
    let b: UInt8       // 蓝色分量 (0-255)
    let a: UInt8       // Alpha分量 (0-255)
    let row: Int
    let colorKey: UInt32  // 缓存的颜色键，用于快速比较
  }
  
  /// 处理一行的像素，合并连续相同颜色的像素段
  /// 第三阶段优化：直接使用RGB值比较，避免NSColor对象创建
  /// - Parameters:
  ///   - row: 行索引
  ///   - width: 图像宽度
  ///   - data: 像素数据指针
  ///   - bytesPerRow: 每行字节数
  /// - Returns: 合并后的体素段数组
  private func processRowPixels(
    row: Int,
    width: Int,
    data: UnsafePointer<UInt8>,
    bytesPerRow: Int
  ) -> [VoxelSegment] {
    var segments: [VoxelSegment] = []
    var segmentStart: Int? = nil
    var currentColorKey: UInt32? = nil
    var currentR: UInt8? = nil
    var currentG: UInt8? = nil
    var currentB: UInt8? = nil
    var currentA: UInt8? = nil
    
    let rowOffset = row * bytesPerRow
    
    for x in 0..<width {
      let pixelIndex = rowOffset + x * 4
      let alpha = data[pixelIndex + 3]
      
      // 跳过透明像素
      if alpha == 0 {
        // 如果之前有正在进行的段，结束它
        if let start = segmentStart,
           let r = currentR, let g = currentG, let b = currentB, let a = currentA,
           let key = currentColorKey {
          segments.append(VoxelSegment(
            startX: start,
            endX: x,
            r: r,
            g: g,
            b: b,
            a: a,
            row: row,
            colorKey: key
          ))
          segmentStart = nil
          currentColorKey = nil
          currentR = nil
          currentG = nil
          currentB = nil
          currentA = nil
        }
        continue
      }
      
      // 读取像素颜色（直接读取RGB值，不创建NSColor对象）
      let r = data[pixelIndex]
      let g = data[pixelIndex + 1]
      let b = data[pixelIndex + 2]
      
      // 第三阶段优化：直接使用RGB值计算颜色键，避免NSColor对象创建
      let colorKey = rgbToColorKey(r: r, g: g, b: b)
      
      // 检查颜色是否与前一个像素相同
      if let currentKey = currentColorKey, currentKey == colorKey {
        // 颜色相同，继续当前段
        continue
      } else {
        // 颜色不同或开始新段
        // 如果之前有段，先结束它
        if let start = segmentStart,
           let prevR = currentR, let prevG = currentG, let prevB = currentB, let prevA = currentA,
           let prevKey = currentColorKey {
          segments.append(VoxelSegment(
            startX: start,
            endX: x,
            r: prevR,
            g: prevG,
            b: prevB,
            a: prevA,
            row: row,
            colorKey: prevKey
          ))
        }
        // 开始新段
        segmentStart = x
        currentColorKey = colorKey
        currentR = r
        currentG = g
        currentB = b
        currentA = alpha
      }
    }
    
    // 处理行的最后一个段
    if let start = segmentStart,
       let r = currentR, let g = currentG, let b = currentB, let a = currentA,
       let key = currentColorKey {
      segments.append(VoxelSegment(
        startX: start,
        endX: width,
        r: r,
        g: g,
        b: b,
        a: a,
        row: row,
        colorKey: key
      ))
    }
    
    return segments
  }

  // MARK: - Voxel Helpers

  private func configureBaseMaterialProperties(_ material: SCNMaterial, color: NSColor) {
    material.diffuse.contents = color
    material.diffuse.magnificationFilter = .nearest
    material.diffuse.minificationFilter = .nearest
    material.isDoubleSided = true
    material.lightingModel = .lambert
  }

  /// 创建合并的体素节点（支持可变宽度，用于第二阶段优化）
  /// 第四阶段优化：接受预创建的材质，避免重复创建
  /// - Parameters:
  ///   - material: 预创建的材质
  ///   - position: 体素位置（中心点）
  ///   - faceIndex: 面索引
  ///   - voxelSize: 基础体素大小
  ///   - mergedWidth: 合并后的宽度（可以是多个像素的宽度）
  ///   - thickness: 体素厚度
  /// - Returns: 合并后的体素节点
  private func createMergedVoxelNode(
    material: SCNMaterial,
    position: SCNVector3,
    faceIndex: Int,
    voxelSize: CGFloat,
    mergedWidth: CGFloat,
    thickness: CGFloat
  ) -> SCNNode {
    let (width, height, length): (CGFloat, CGFloat, CGFloat)
    
    switch faceIndex {
    case 0, 2: // front/back - Z方向薄，宽度可变
      (width, height, length) = (mergedWidth, voxelSize, thickness)
    case 1, 3: // right/left - X方向薄，长度可变
      (width, height, length) = (thickness, voxelSize, mergedWidth)
    case 4, 5: // top/bottom - Y方向薄，宽度可变
      (width, height, length) = (mergedWidth, thickness, voxelSize)
    default:
      (width, height, length) = (mergedWidth, voxelSize, thickness)
    }
    
    let voxelGeometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0)
    // 第四阶段优化：使用预创建的材质，避免重复创建
    voxelGeometry.materials = [material]

    let node = SCNNode(geometry: voxelGeometry)
    node.position = position
    return node
  }
}
