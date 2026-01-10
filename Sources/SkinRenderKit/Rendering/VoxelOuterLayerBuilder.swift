//
//  VoxelOuterLayerBuilder.swift
//  SkinRenderKit
//
//  Builds voxel-based overlay layers (hat, jacket, sleeves) from Minecraft skin textures.
//  优化版本：使用配置结构体、强制baseSize、批量处理优化
//

import AppKit
import SceneKit

/// 体素覆盖层配置参数
struct VoxelOverlayConfig {
  /// 外层尺寸
  let boxSize: SCNVector3
  /// 基础层尺寸（必须提供，不再可选）
  let baseSize: SCNVector3
  /// 体素大小，默认1.0
  let voxelSize: CGFloat
  /// 体素厚度，如果为nil则使用尺寸差异
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
/// 优化版本：
/// - 使用配置结构体简化接口
/// - 强制要求baseSize，简化逻辑
/// - 材质缓存优化
/// - 批量处理优化
/// - 纹理裁剪缓存
/// - CGContext复用
/// - 第二阶段优化：行内体素合并（减少节点数量）
final class VoxelOuterLayerBuilder {
  
  // MARK: - Caches
  
  /// 材质缓存：使用颜色的RGB值作为键来复用材质
  private var materialCache: [UInt32: SCNMaterial] = [:]
  
  /// 纹理缓存：用于缓存裁剪结果
  private let textureCache: TextureCache
  
  // 注意：CGContext 不能真正复用，因为其 data 是只读的
  // 每次使用都需要创建新的 context，所以移除了 context 缓存
  // 性能影响很小，因为 context 创建开销不大

  // MARK: - Initialization
  
  init(textureCache: TextureCache? = nil) {
    self.textureCache = textureCache ?? TextureCache()
  }

  // MARK: - Public API

  /// Build a voxel-based overlay node from the given skin texture and face specs.
  ///
  /// - Parameters:
  ///   - skinImage: The full Minecraft skin texture image.
  ///   - specs: Face specifications (front/right/back/left/top/bottom) defining
  ///            the crop rectangles on the skin texture.
  ///   - config: 体素覆盖层配置参数
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
  ///   - config: 体素覆盖层配置参数
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

  // MARK: - Voxel Population Core

  /// Core implementation that fills a container node with voxel children
  private func populateVoxelOverlay(
    in containerNode: SCNNode,
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    config: VoxelOverlayConfig
  ) {
    // 计算尺寸差异（baseSize现在是必须的，不再需要默认值）
    let diffX = CGFloat(config.boxSize.x) - CGFloat(config.baseSize.x)
    let diffY = CGFloat(config.boxSize.y) - CGFloat(config.baseSize.y)
    let diffZ = CGFloat(config.boxSize.z) - CGFloat(config.baseSize.z)
    
    // 每个面的具体差异：[front, right, back, left, top, bottom]
    let faceSizeDifferences: [CGFloat] = [diffZ, diffX, diffZ, diffX, diffY, diffY]
    
    // 计算每个面的厚度
    let faceThicknesses: [CGFloat] = if let customThickness = config.voxelThickness {
      Array(repeating: customThickness, count: 6)
    } else {
      faceSizeDifferences
    }
    
    // 预先计算半厚度值
    let halfThicknesses = faceThicknesses.map { $0 / 2.0 }
    
    // 共享的CGContext配置
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    // 遍历每个面
    for (faceIndex, spec) in specs.enumerated() {
      // 直接裁剪，不使用缓存（避免材质混乱）
      // 在同一皮肤渲染过程中，每个区域通常只裁剪一次，缓存收益有限
      // 而且NSImage实例可能被复用加载不同内容，缓存可能导致错误结果
      guard case .success(let faceImage) = TextureProcessor.crop(skinImage, rect: spec.rect),
            let cgImage = faceImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
      else {
        continue
      }

      let width = Int(spec.rect.width)
      let height = Int(spec.rect.height)

      // 优化：直接使用CGImage的像素数据（如果格式匹配）
      // 如果格式不匹配，再使用CGContext转换
      let data: UnsafePointer<UInt8>
      let bytesPerRow: Int
      let shouldFreeData: Bool
      
      // 使用CGContext读取像素数据
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
      // 将 UnsafeMutablePointer 转换为 UnsafePointer（因为我们只读取数据）
      let mutablePointer = pixelData.assumingMemoryBound(to: UInt8.self)
      data = UnsafePointer(mutablePointer)
      bytesPerRow = width * 4
      shouldFreeData = false  // CGContext管理内存

      // 预先计算该面的参数
      let faceSizeDifference = faceSizeDifferences[faceIndex]
      let thickness = faceThicknesses[faceIndex]
      let halfThickness = halfThicknesses[faceIndex]
      
      // 预先计算位置计算所需的常量
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
      
      // 位置偏移计算
      let halfSizeDifference = faceSizeDifference / 2.0
      var offset = halfThickness - halfSizeDifference
      if abs(offset) < 0.001 {
        offset = 0.01
      }

      // 第二阶段优化：行内合并 - 逐行处理并合并连续相同颜色的像素段
      // 第四阶段优化：收集所有段，按颜色分组，批量创建节点
      var allSegments: [(segment: VoxelSegment, position: SCNVector3, mergedWidth: CGFloat)] = []
      allSegments.reserveCapacity(height * 10)  // 预分配容量，假设平均每行10个段
      
      for y in 0..<height {
        // 处理当前行，合并连续相同颜色的像素段
        let segments = processRowPixels(
          row: y,
          width: width,
          data: data,
          bytesPerRow: bytesPerRow
        )
        
        // 计算每个段的位置信息
        for segment in segments {
          let segmentLength = segment.endX - segment.startX
          let mergedWidth = CGFloat(segmentLength) * config.voxelSize
          
          // 计算段的中心位置
          let segmentStart = CGFloat(segment.startX)
          let segmentEnd = CGFloat(segment.endX)
          let centerPixelIndex = (segmentStart + segmentEnd - 1.0) / 2.0
          let centerOffset = centerPixelIndex * config.voxelSize
          
          // 计算合并后体素的位置（段的几何中心）
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
      
      // 按颜色键分组段（第四阶段优化：减少相同材质的使用）
      let segmentsByColor = Dictionary(grouping: allSegments) { $0.segment.colorKey }
      
      // 为每个颜色组批量创建节点
      for (colorKey, colorSegments) in segmentsByColor {
        // 获取材质（使用第一个段的RGB值，因为同组的颜色相同）
        let firstSegment = colorSegments[0].segment
        let material = getOrCreateMaterial(
          r: firstSegment.r,
          g: firstSegment.g,
          b: firstSegment.b,
          a: firstSegment.a
        )
        
        // 为每个段创建节点（使用缓存的材质）
        for (segment, position, mergedWidth) in colorSegments {
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

  // MARK: - Material Cache Management
  
  /// 获取或创建材质（从NSColor，保留用于兼容性）
  private func getOrCreateMaterial(for color: NSColor) -> SCNMaterial {
    let rgbKey = colorToRGBKey(color)
    
    if let cachedMaterial = materialCache[rgbKey] {
      return cachedMaterial
    }
    
    let material = SCNMaterial()
    configureBaseMaterialProperties(material, color: color)
    materialCache[rgbKey] = material
    
    return material
  }
  
  /// 第三阶段优化：直接从RGB值获取或创建材质（避免不必要的NSColor对象创建）
  private func getOrCreateMaterial(r: UInt8, g: UInt8, b: UInt8, a: UInt8) -> SCNMaterial {
    let rgbKey = rgbToColorKey(r: r, g: g, b: b)
    
    if let cachedMaterial = materialCache[rgbKey] {
      return cachedMaterial
    }
    
    // 只有在创建新材质时才创建NSColor对象
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
  
  /// 从NSColor创建RGB键（保留用于兼容性）
  private func colorToRGBKey(_ color: NSColor) -> UInt32 {
    let r = UInt32(min(255, max(0, Int(color.redComponent * 255.0))))
    let g = UInt32(min(255, max(0, Int(color.greenComponent * 255.0))))
    let b = UInt32(min(255, max(0, Int(color.blueComponent * 255.0))))
    return (r << 24) | (g << 16) | (b << 8)
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
    
    /// 延迟创建NSColor对象（仅在需要时创建，如创建材质时）
    var color: NSColor {
      NSColor(
        red: CGFloat(r) / 255.0,
        green: CGFloat(g) / 255.0,
        blue: CGFloat(b) / 255.0,
        alpha: CGFloat(a) / 255.0
      )
    }
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

  private func createVoxelNode(
    color: NSColor,
    position: SCNVector3,
    faceIndex: Int,
    voxelSize: CGFloat,
    thickness: CGFloat
  ) -> SCNNode {
    return createMergedVoxelNode(
      color: color,
      position: position,
      faceIndex: faceIndex,
      voxelSize: voxelSize,
      mergedWidth: voxelSize,  // 默认单个像素宽度
      thickness: thickness
    )
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
  
  /// 创建合并的体素节点（支持可变宽度，用于第二阶段优化）
  /// 第三阶段优化：直接从RGB值创建，避免NSColor对象创建
  /// - Parameters:
  ///   - r: 红色分量 (0-255)
  ///   - g: 绿色分量 (0-255)
  ///   - b: 蓝色分量 (0-255)
  ///   - a: Alpha分量 (0-255)
  ///   - position: 体素位置（中心点）
  ///   - faceIndex: 面索引
  ///   - voxelSize: 基础体素大小
  ///   - mergedWidth: 合并后的宽度（可以是多个像素的宽度）
  ///   - thickness: 体素厚度
  /// - Returns: 合并后的体素节点
  private func createMergedVoxelNode(
    r: UInt8,
    g: UInt8,
    b: UInt8,
    a: UInt8,
    position: SCNVector3,
    faceIndex: Int,
    voxelSize: CGFloat,
    mergedWidth: CGFloat,
    thickness: CGFloat
  ) -> SCNNode {
    // 第三阶段优化：直接使用RGB值创建材质，避免不必要的NSColor对象创建
    let material = getOrCreateMaterial(r: r, g: g, b: b, a: a)
    return createMergedVoxelNode(
      material: material,
      position: position,
      faceIndex: faceIndex,
      voxelSize: voxelSize,
      mergedWidth: mergedWidth,
      thickness: thickness
    )
  }
  
  /// 创建合并的体素节点（从NSColor，保留用于兼容性）
  /// - Parameters:
  ///   - color: 体素颜色
  ///   - position: 体素位置（中心点）
  ///   - faceIndex: 面索引
  ///   - voxelSize: 基础体素大小
  ///   - mergedWidth: 合并后的宽度（可以是多个像素的宽度）
  ///   - thickness: 体素厚度
  /// - Returns: 合并后的体素节点
  private func createMergedVoxelNode(
    color: NSColor,
    position: SCNVector3,
    faceIndex: Int,
    voxelSize: CGFloat,
    mergedWidth: CGFloat,
    thickness: CGFloat
  ) -> SCNNode {
    let r = UInt8(min(255, max(0, Int(color.redComponent * 255.0))))
    let g = UInt8(min(255, max(0, Int(color.greenComponent * 255.0))))
    let b = UInt8(min(255, max(0, Int(color.blueComponent * 255.0))))
    let a = UInt8(min(255, max(0, Int(color.alphaComponent * 255.0))))
    
    return createMergedVoxelNode(
      r: r,
      g: g,
      b: b,
      a: a,
      position: position,
      faceIndex: faceIndex,
      voxelSize: voxelSize,
      mergedWidth: mergedWidth,
      thickness: thickness
    )
  }
}
