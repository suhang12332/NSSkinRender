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
final class VoxelOuterLayerBuilder {
  
  // MARK: - Material Cache
  
  /// 材质缓存：使用颜色的RGB值作为键来复用材质
  private var materialCache: [UInt32: SCNMaterial] = [:]

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
      guard case let .success(faceImage) = TextureProcessor.crop(skinImage, rect: spec.rect),
            let cgImage = faceImage.cgImage(forProposedRect: nil, context: nil, hints: nil)
      else {
        continue
      }

      let width = Int(spec.rect.width)
      let height = Int(spec.rect.height)

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
      let data = pixelData.assumingMemoryBound(to: UInt8.self)

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

      // 批量创建体素节点
      var voxelNodes: [SCNNode] = []
      voxelNodes.reserveCapacity(width * height / 2) // 预估容量（假设一半像素不透明）

      // 遍历每个像素
      for y in 0..<height {
        for x in 0..<width {
          let pixelIndex = (y * width + x) * 4
          let alpha = data[pixelIndex + 3]

          if alpha == 0 { continue }

          // 解析像素颜色
          let r = CGFloat(data[pixelIndex]) / 255.0
          let g = CGFloat(data[pixelIndex + 1]) / 255.0
          let b = CGFloat(data[pixelIndex + 2]) / 255.0
          let a = CGFloat(alpha) / 255.0
          let color = NSColor(red: r, green: g, blue: b, alpha: a)

          // 计算体素位置（内联计算）
          var voxelPosition: SCNVector3
          switch faceIndex {
          case 0: // front (+Z)
            let px = startX + CGFloat(x) * config.voxelSize
            let py = startY - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(px, py, halfLength + offset)
            
          case 1: // right (+X)
            let pz = halfLength - offsetZ - config.voxelSize / 2.0 - CGFloat(x) * config.voxelSize
            let py = startY - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(halfWidth + offset, py, pz)
            
          case 2: // back (-Z)
            let px = halfWidth - offsetX - config.voxelSize / 2.0 - CGFloat(x) * config.voxelSize
            let py = startY - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(px, py, -halfLength - offset)
            
          case 3: // left (-X)
            let pz = startZ + CGFloat(x) * config.voxelSize
            let py = startY - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(-halfWidth - offset, py, pz)
            
          case 4: // top (+Y)
            let px = startX + CGFloat(x) * config.voxelSize
            let pz = halfLength - offsetZH - config.voxelSize / 2.0 - CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(px, halfHeight + offset, pz)
            
          case 5: // bottom (-Y)
            let px = halfWidth - offsetX - config.voxelSize / 2.0 - CGFloat(x) * config.voxelSize
            let pz = startZH + CGFloat(y) * config.voxelSize
            voxelPosition = SCNVector3(px, -halfHeight - offset, pz)
            
          default:
            continue
          }

          // 创建体素节点
          let voxelNode = createVoxelNode(
            color: color,
            position: voxelPosition,
            faceIndex: faceIndex,
            voxelSize: config.voxelSize,
            thickness: thickness
          )
          voxelNodes.append(voxelNode)
        }
      }
      
      // 批量添加节点（比逐个添加更高效）
      for node in voxelNodes {
        containerNode.addChildNode(node)
      }
    }
  }

  // MARK: - Material Cache Management
  
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
  
  private func colorToRGBKey(_ color: NSColor) -> UInt32 {
    let r = UInt32(min(255, max(0, Int(color.redComponent * 255.0))))
    let g = UInt32(min(255, max(0, Int(color.greenComponent * 255.0))))
    let b = UInt32(min(255, max(0, Int(color.blueComponent * 255.0))))
    return (r << 24) | (g << 16) | (b << 8)
  }
  
  private func clearMaterialCache() {
    for material in materialCache.values {
      material.diffuse.contents = nil
    }
    materialCache.removeAll()
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
    let (width, height, length): (CGFloat, CGFloat, CGFloat)
    
    switch faceIndex {
    case 0, 2: // front/back - Z方向薄
      (width, height, length) = (voxelSize, voxelSize, thickness)
    case 1, 3: // right/left - X方向薄
      (width, height, length) = (thickness, voxelSize, voxelSize)
    case 4, 5: // top/bottom - Y方向薄
      (width, height, length) = (voxelSize, thickness, voxelSize)
    default:
      (width, height, length) = (voxelSize, voxelSize, thickness)
    }
    
    let voxelGeometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0)
    let material = getOrCreateMaterial(for: color)
    voxelGeometry.materials = [material]

    let node = SCNNode(geometry: voxelGeometry)
    node.position = position
    return node
  }
}
