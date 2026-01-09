//
//  VoxelOuterLayerBuilder.swift
//  SkinRenderKit
//
//  Builds voxel-based overlay layers (hat, jacket, sleeves) from Minecraft skin textures.
//

import AppKit
import SceneKit

/// Builder responsible for constructing voxelized overlay layers (hat, jacket, sleeves)
/// from a Minecraft skin texture. Each visible pixel on the specified cube faces is
/// represented as a tiny SCNBox ("voxel") to give the outer layer extra depth.
final class VoxelOuterLayerBuilder {

  // MARK: - Public API

  /// Build a voxel-based overlay node from the given skin texture and face specs.
  ///
  /// - Parameters:
  ///   - skinImage: The full Minecraft skin texture image.
  ///   - specs: Face specifications (front/right/back/left/top/bottom) defining
  ///            the crop rectangles on the skin texture. The expected order of
  ///            the array is: front, right, back, left, top, bottom.
  ///   - boxSize: The approximate outer box size that the voxels should occupy.
  ///   - position: Position of the overlay node relative to its parent/group.
  ///   - name: Name to assign to the overlay node (for debugging).
  ///   - voxelSize: Logical size of each voxel. Defaults to 1.0 which matches the
  ///                pixel-to-world mapping used by CharacterDimensions.
  ///
  /// - Returns: An SCNNode containing all voxel children.
  func buildVoxelOverlay(
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    boxSize: SCNVector3,
    position: SCNVector3,
    name: String,
    voxelSize: CGFloat = 1.0
  ) -> SCNNode {
    let containerNode = SCNNode()
    containerNode.name = name
    containerNode.position = position

    // Slightly higher rendering order to ensure overlays render on top of base layers.
    containerNode.renderingOrder = CharacterDimensions.RenderingOrder.outerLayers

    populateVoxelOverlay(
      in: containerNode,
      from: skinImage,
      specs: specs,
      boxSize: boxSize,
      voxelSize: voxelSize
    )

    return containerNode
  }

  /// Rebuild an existing voxel overlay node with a new skin image.
  ///
  /// - Parameters:
  ///   - containerNode: Existing overlay container node whose children will be replaced.
  ///   - skinImage: The new Minecraft skin texture image.
  ///   - specs: Face specifications defining crop rectangles (same semantics as buildVoxelOverlay).
  ///   - boxSize: The approximate outer box size that the voxels should occupy.
  ///   - voxelSize: Logical size of each voxel.
  func rebuildVoxelOverlay(
    in containerNode: SCNNode,
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    boxSize: SCNVector3,
    voxelSize: CGFloat = 1.0
  ) {
    // Clear existing voxels
    containerNode.childNodes.forEach { $0.removeFromParentNode() }

    // Repopulate with new skin data
    populateVoxelOverlay(
      in: containerNode,
      from: skinImage,
      specs: specs,
      boxSize: boxSize,
      voxelSize: voxelSize
    )
  }

  // MARK: - Voxel Population Core

  /// Core implementation that fills a container node with voxel children
  /// based on a skin image and face specifications.
  private func populateVoxelOverlay(
    in containerNode: SCNNode,
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    boxSize: SCNVector3,
    voxelSize: CGFloat
  ) {
    // Small inward offset so voxels sit just above the base geometry without Z-fighting.
    let halfThickness: CGFloat = 0.5

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

    for (faceIndex, spec) in specs.enumerated() {
      // Crop the specific face region from the skin image.
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

      for y in 0..<height {
        for x in 0..<width {
          let pixelIndex = (y * width + x) * 4
          let alpha = data[pixelIndex + 3]

          // Skip fully transparent pixels.
          if alpha == 0 { continue }

          let color = NSColor(
            red: CGFloat(data[pixelIndex]) / 255.0,
            green: CGFloat(data[pixelIndex + 1]) / 255.0,
            blue: CGFloat(data[pixelIndex + 2]) / 255.0,
            alpha: CGFloat(alpha) / 255.0
          )

          var voxelPosition = calculateVoxelPosition(
            faceIndex: faceIndex,
            x: x,
            y: y,
            width: width,
            height: height,
            boxSize: boxSize,
            voxelSize: voxelSize
          )

          voxelPosition = adjustVoxelPosition(
            voxelPosition,
            faceIndex: faceIndex,
            halfThickness: halfThickness
          )

          let voxelNode = createVoxelNode(color: color, position: voxelPosition, size: voxelSize)
          containerNode.addChildNode(voxelNode)
        }
      }
    }
  }

  // MARK: - Voxel Helpers

  /// Configure base material properties for color-based rendering
  /// - Parameters:
  ///   - material: The material to configure
  ///   - color: The color to apply
  private func configureBaseMaterialProperties(_ material: SCNMaterial, color: NSColor) {
    material.diffuse.contents = color
    material.diffuse.magnificationFilter = .nearest
    material.diffuse.minificationFilter = .nearest
    material.isDoubleSided = true
    material.lightingModel = .lambert
  }

  /// Create a single voxel node with the given color and position.
  private func createVoxelNode(
    color: NSColor,
    position: SCNVector3,
    size: CGFloat
  ) -> SCNNode {
    let voxelGeometry = SCNBox(width: size, height: size, length: size, chamferRadius: 0)
    let material = SCNMaterial()
    configureBaseMaterialProperties(material, color: color)

    voxelGeometry.materials = [material]

    let node = SCNNode(geometry: voxelGeometry)
    node.position = position
    return node
  }

  /// Adjust voxel position so it sits slightly "inside" the overlay thickness
  /// to avoid Z-fighting with the base geometry.
  private func adjustVoxelPosition(
    _ position: SCNVector3,
    faceIndex: Int,
    halfThickness: CGFloat
  ) -> SCNVector3 {
    switch faceIndex {
    case 0: // front
      return SCNVector3(position.x, position.y, position.z - halfThickness)
    case 1: // right
      return SCNVector3(position.x - halfThickness, position.y, position.z)
    case 2: // back
      return SCNVector3(position.x, position.y, position.z + halfThickness)
    case 3: // left
      return SCNVector3(position.x + halfThickness, position.y, position.z)
    case 4: // top
      return SCNVector3(position.x, position.y - halfThickness, position.z)
    case 5: // bottom
      return SCNVector3(position.x, position.y + halfThickness, position.z)
    default:
      return position
    }
  }

  /// Map a pixel (x, y) on a given cube face to a 3D position around an
  /// approximate box of the given size.
  ///
  /// The face index is assumed to follow the order:
  ///   0: front, 1: right, 2: back, 3: left, 4: top, 5: bottom
  private func calculateVoxelPosition(
    faceIndex: Int,
    x: Int,
    y: Int,
    width: Int,
    height: Int,
    boxSize: SCNVector3,
    voxelSize: CGFloat
  ) -> SCNVector3 {
    let halfWidth = CGFloat(boxSize.x) / 2.0
    let halfHeight = CGFloat(boxSize.y) / 2.0
    let halfLength = CGFloat(boxSize.z) / 2.0

    // Span of the voxel grid in each dimension.
    let totalSpanX = CGFloat(width) * voxelSize
    let totalSpanY = CGFloat(height) * voxelSize

    // Offsets to center the voxel grid on each face.
    let offsetX = (CGFloat(boxSize.x) - totalSpanX) / 2.0
    let offsetY = (CGFloat(boxSize.y) - totalSpanY) / 2.0
    let offsetZ = (CGFloat(boxSize.z) - totalSpanX) / 2.0
    let offsetZH = (CGFloat(boxSize.z) - totalSpanY) / 2.0

    let startX = -halfWidth + offsetX + voxelSize / 2.0
    let startY = halfHeight - offsetY - voxelSize / 2.0
    let startZ = -halfLength + offsetZ + voxelSize / 2.0
    let startZH = -halfLength + offsetZH + voxelSize / 2.0

    switch faceIndex {
    case 0: // front (+Z)
      let px = startX + CGFloat(x) * voxelSize
      let py = startY - CGFloat(y) * voxelSize
      return SCNVector3(px, py, halfLength)

    case 1: // right (+X)
      let pz = halfLength - offsetZ - voxelSize / 2.0 - CGFloat(x) * voxelSize
      let py = startY - CGFloat(y) * voxelSize
      return SCNVector3(halfWidth, py, pz)

    case 2: // back (-Z)
      let px = halfWidth - offsetX - voxelSize / 2.0 - CGFloat(x) * voxelSize
      let py = startY - CGFloat(y) * voxelSize
      return SCNVector3(px, py, -halfLength)

    case 3: // left (-X)
      let pz = startZ + CGFloat(x) * voxelSize
      let py = startY - CGFloat(y) * voxelSize
      return SCNVector3(-halfWidth, py, pz)

    case 4: // top (+Y)
      let px = startX + CGFloat(x) * voxelSize
      let pz = halfLength - offsetZH - voxelSize / 2.0 - CGFloat(y) * voxelSize
      return SCNVector3(px, halfHeight, pz)

    case 5: // bottom (-Y)
      let px = halfWidth - offsetX - voxelSize / 2.0 - CGFloat(x) * voxelSize
      let pz = startZH + CGFloat(y) * voxelSize
      return SCNVector3(px, -halfHeight, pz)

    default:
      return SCNVector3Zero
    }
  }
}

