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
  ///   - voxelThickness: Thickness of voxels in the direction perpendicular to the face.
  ///                    Defaults to 0.5 for head, 0.25 for body.
  ///   - baseSize: The base layer size. If provided, the size difference will be calculated
  ///               automatically. If nil, defaults to 0.5 difference (for backward compatibility).
  ///
  /// - Returns: An SCNNode containing all voxel children.
  func buildVoxelOverlay(
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    boxSize: SCNVector3,
    position: SCNVector3,
    name: String,
    voxelSize: CGFloat = 1.0,
    voxelThickness: CGFloat? = nil,
    baseSize: SCNVector3? = nil
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
      voxelSize: voxelSize,
      voxelThickness: voxelThickness,
      baseSize: baseSize
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
  ///   - voxelThickness: Thickness of voxels in the direction perpendicular to the face.
  ///   - baseSize: The base layer size. If provided, the size difference will be calculated
  ///               automatically. If nil, defaults to 0.5 difference (for backward compatibility).
  func rebuildVoxelOverlay(
    in containerNode: SCNNode,
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    boxSize: SCNVector3,
    voxelSize: CGFloat = 1.0,
    voxelThickness: CGFloat? = nil,
    baseSize: SCNVector3? = nil
  ) {
    // Clear existing voxels and clean up resources
    for child in containerNode.childNodes {
      // Clean up geometry and materials before removing
      if let geometry = child.geometry {
        for material in geometry.materials {
          material.diffuse.contents = nil
        }
        geometry.materials = []
      }
      child.removeFromParentNode()
    }

    // Repopulate with new skin data
    populateVoxelOverlay(
      in: containerNode,
      from: skinImage,
      specs: specs,
      boxSize: boxSize,
      voxelSize: voxelSize,
      voxelThickness: voxelThickness,
      baseSize: baseSize
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
    voxelSize: CGFloat,
    voxelThickness: CGFloat?,
    baseSize: SCNVector3?
  ) {
    // Half voxel size for outward offset: place voxel center so its edge touches the base layer surface
    // This ensures no gap between first and second layers
    let halfVoxelSize: CGFloat = voxelSize / 2.0
    
    // Calculate size difference between outer layer and base layer
    // If baseSize is provided, calculate actual difference; otherwise use default 0.5
    let sizeDifference: CGFloat
    if let base = baseSize {
      // For cubic shapes (head), use the difference in any dimension
      // For non-cubic shapes (body), use average difference
      let diffX = CGFloat(boxSize.x) - CGFloat(base.x)
      let diffY = CGFloat(boxSize.y) - CGFloat(base.y)
      let diffZ = CGFloat(boxSize.z) - CGFloat(base.z)
      // Use average difference, or for cubes, all dimensions should be the same
      sizeDifference = (diffX + diffY + diffZ) / 3.0
    } else {
      // Default for backward compatibility (body case)
      sizeDifference = 0.5
    }

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

          // Calculate actual size difference for this specific face
          let faceSizeDifference: CGFloat
          if let base = baseSize {
            switch faceIndex {
            case 0, 2: // front/back - use depth (z)
              faceSizeDifference = CGFloat(boxSize.z) - CGFloat(base.z)
            case 1, 3: // right/left - use width (x)
              faceSizeDifference = CGFloat(boxSize.x) - CGFloat(base.x)
            case 4, 5: // top/bottom - use height (y)
              faceSizeDifference = CGFloat(boxSize.y) - CGFloat(base.y)
            default:
              faceSizeDifference = sizeDifference
            }
          } else {
            faceSizeDifference = sizeDifference
          }
          
          // Determine voxel thickness for this face
          let thickness: CGFloat
          if let customThickness = voxelThickness {
            thickness = customThickness
          } else {
            // Default thickness based on size difference
            thickness = faceSizeDifference
          }
          
          // Half thickness for position adjustment (perpendicular to face)
          let halfThickness = thickness / 2.0
          
          voxelPosition = adjustVoxelPosition(
            voxelPosition,
            faceIndex: faceIndex,
            boxSize: boxSize,
            halfThickness: halfThickness,
            sizeDifference: faceSizeDifference
          )

          let voxelNode = createVoxelNode(
            color: color,
            position: voxelPosition,
            faceIndex: faceIndex,
            voxelSize: voxelSize,
            thickness: thickness
          )
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
  /// The voxel thickness varies based on the face direction.
  private func createVoxelNode(
    color: NSColor,
    position: SCNVector3,
    faceIndex: Int,
    voxelSize: CGFloat,
    thickness: CGFloat
  ) -> SCNNode {
    let width: CGFloat
    let height: CGFloat
    let length: CGFloat
    
    // Create voxel with reduced thickness in the direction perpendicular to the face
    switch faceIndex {
    case 0, 2: // front/back - thin in Z direction
      width = voxelSize
      height = voxelSize
      length = thickness
    case 1, 3: // right/left - thin in X direction
      width = thickness
      height = voxelSize
      length = voxelSize
    case 4, 5: // top/bottom - thin in Y direction
      width = voxelSize
      height = thickness
      length = voxelSize
    default:
      width = voxelSize
      height = voxelSize
      length = thickness
    }
    
    let voxelGeometry = SCNBox(width: width, height: height, length: length, chamferRadius: 0)
    let material = SCNMaterial()
    configureBaseMaterialProperties(material, color: color)

    voxelGeometry.materials = [material]

    let node = SCNNode(geometry: voxelGeometry)
    node.position = position
    return node
  }

  /// Adjust voxel position so it sits on the base layer surface with no gap.
  /// Calculates the offset needed to place voxel edge exactly on the first layer surface.
  /// The size difference between outer and base layers determines how much to offset.
  /// Uses halfThickness (half of voxel thickness perpendicular to face) instead of halfVoxelSize.
  private func adjustVoxelPosition(
    _ position: SCNVector3,
    faceIndex: Int,
    boxSize: SCNVector3,
    halfThickness: CGFloat,
    sizeDifference: CGFloat
  ) -> SCNVector3 {
    // Calculate size difference between second and first layer
    // Each side extends by half the size difference
    let halfSizeDifference = sizeDifference / 2.0
    
    // calculateVoxelPosition places voxel center at second layer surface
    // We want voxel edge (in the perpendicular direction) to touch first layer surface (no gap)
    // First layer surface = second layer surface - halfSizeDifference
    // Voxel center should be at: first layer surface + halfThickness
    // = (second layer surface - halfSizeDifference) + halfThickness
    // = second layer surface + (halfThickness - halfSizeDifference)
    // So offset = halfThickness - halfSizeDifference
    // For head (thickness=0.5, halfThickness=0.25, halfSizeDifference=0.125): 0.25 - 0.125 = 0.125
    // For body (thickness=0.25, halfThickness=0.125, halfSizeDifference=0.0625): 0.125 - 0.0625 = 0.0625
    
    var offset = halfThickness - halfSizeDifference
    
    // Ensure minimum offset to avoid Z-fighting
    if abs(offset) < 0.001 {
      offset = 0.01  // Small outward offset to ensure tight fit
    }
    
    switch faceIndex {
    case 0: // front (+Z) - move outward
      return SCNVector3(position.x, position.y, position.z + offset)
    case 1: // right (+X) - move outward
      return SCNVector3(position.x + offset, position.y, position.z)
    case 2: // back (-Z) - move outward
      return SCNVector3(position.x, position.y, position.z - offset)
    case 3: // left (-X) - move outward
      return SCNVector3(position.x - offset, position.y, position.z)
    case 4: // top (+Y) - move outward
      return SCNVector3(position.x, position.y + offset, position.z)
    case 5: // bottom (-Y) - move outward
      return SCNVector3(position.x, position.y - offset, position.z)
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

