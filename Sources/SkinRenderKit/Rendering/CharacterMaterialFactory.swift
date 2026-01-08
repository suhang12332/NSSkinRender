//
//  CharacterMaterialFactory.swift
//  SkinRenderKit
//
//  Factory for creating SceneKit materials from Minecraft skin textures
//

import SceneKit

/// Factory responsible for creating SCNMaterial arrays for character body parts
public final class CharacterMaterialFactory {

  // MARK: - Configuration

  /// Configuration for bottom face texture transformations
  public struct BottomFaceConfig {
    public var limbFlipMode: TextureProcessor.FlipMode
    public var limbRotate180: Bool
    public var headBodyFlipMode: TextureProcessor.FlipMode
    public var headBodyRotate180: Bool

    public init(
      limbFlipMode: TextureProcessor.FlipMode = .horizontal,
      limbRotate180: Bool = true,
      headBodyFlipMode: TextureProcessor.FlipMode = .horizontal,
      headBodyRotate180: Bool = true
    ) {
      self.limbFlipMode = limbFlipMode
      self.limbRotate180 = limbRotate180
      self.headBodyFlipMode = headBodyFlipMode
      self.headBodyRotate180 = headBodyRotate180
    }
  }

  /// Configuration for bottom face transforms
  public var bottomFaceConfig: BottomFaceConfig

  // MARK: - Initialization

  public init(bottomFaceConfig: BottomFaceConfig = BottomFaceConfig()) {
    self.bottomFaceConfig = bottomFaceConfig
  }

  // MARK: - Head Materials

  /// Create materials for the head (base or hat overlay)
  /// - Parameters:
  ///   - skinImage: The skin texture image
  ///   - isHat: Whether to create hat overlay materials
  /// - Returns: Array of 6 materials for each cube face
  public func createHeadMaterials(from skinImage: NSImage, isHat: Bool) -> [SCNMaterial] {
    let specs = isHat ? CubeFace.headHat : CubeFace.headBase
    return createMaterials(
      from: skinImage,
      specs: specs,
      layerName: isHat ? "hat" : "head",
      isOuter: isHat,
      isLimb: false
    )
  }

  // MARK: - Body Materials

  /// Create materials for the body (base or jacket overlay)
  /// - Parameters:
  ///   - skinImage: The skin texture image
  ///   - isJacket: Whether to create jacket overlay materials
  /// - Returns: Array of 6 materials for each cube face
  public func createBodyMaterials(from skinImage: NSImage, isJacket: Bool) -> [SCNMaterial] {
    let specs = isJacket ? CubeFace.bodyJacket : CubeFace.bodyBase
    return createMaterials(
      from: skinImage,
      specs: specs,
      layerName: isJacket ? "jacket" : "body",
      isOuter: isJacket,
      isLimb: false
    )
  }

  // MARK: - Arm Materials

  /// Create materials for an arm (base or sleeve overlay)
  /// - Parameters:
  ///   - skinImage: The skin texture image
  ///   - isLeft: Whether this is the left arm
  ///   - isSleeve: Whether to create sleeve overlay materials
  ///   - playerModel: The player model type (affects arm width)
  /// - Returns: Array of 6 materials for each cube face
  public func createArmMaterials(
    from skinImage: NSImage,
    isLeft: Bool,
    isSleeve: Bool,
    playerModel: PlayerModel
  ) -> [SCNMaterial] {
    let armWidth = playerModel.armDimensions.width
    let specs = isSleeve
      ? CubeFace.armSleeve(isLeft: isLeft, armWidth: armWidth)
      : CubeFace.armBase(isLeft: isLeft, armWidth: armWidth)

    let layerName: String
    if isSleeve {
      layerName = isLeft ? "left_arm_sleeve" : "right_arm_sleeve"
    } else {
      layerName = isLeft ? "left_arm" : "right_arm"
    }

    return createMaterials(
      from: skinImage,
      specs: specs,
      layerName: layerName,
      isOuter: isSleeve,
      isLimb: true
    )
  }

  // MARK: - Leg Materials

  /// Create materials for a leg (base or sleeve overlay)
  /// - Parameters:
  ///   - skinImage: The skin texture image
  ///   - isLeft: Whether this is the left leg
  ///   - isSleeve: Whether to create sleeve overlay materials
  /// - Returns: Array of 6 materials for each cube face
  public func createLegMaterials(
    from skinImage: NSImage,
    isLeft: Bool,
    isSleeve: Bool
  ) -> [SCNMaterial] {
    let specs = isSleeve
      ? CubeFace.legSleeve(isLeft: isLeft)
      : CubeFace.legBase(isLeft: isLeft)

    let layerName: String
    if isSleeve {
      layerName = isLeft ? "left_leg_sleeve" : "right_leg_sleeve"
    } else {
      layerName = isLeft ? "left_leg" : "right_leg"
    }

    return createMaterials(
      from: skinImage,
      specs: specs,
      layerName: layerName,
      isOuter: isSleeve,
      isLimb: true
    )
  }

  // MARK: - Cape Materials

  /// Create materials for the cape
  /// - Parameter capeImage: The cape texture image
  /// - Returns: Array of 6 materials for each cube face
  public func createCapeMaterials(from capeImage: NSImage) -> [SCNMaterial] {
    var materials: [SCNMaterial] = []

    for spec in CubeFace.cape {
      let material = SCNMaterial()

      switch TextureProcessor.crop(capeImage, rect: spec.rect) {
      case .success(let croppedImage):
        let finalImage: NSImage
        if spec.rotate180 {
          finalImage = (try? TextureProcessor.rotate(croppedImage, degrees: 180).get()) ?? croppedImage
        } else {
          finalImage = croppedImage
        }

        material.diffuse.contents = finalImage
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.minificationFilter = .nearest
        material.diffuse.wrapS = .clamp
        material.diffuse.wrapT = .clamp

        // Cape transparency handling
        if TextureProcessor.hasTransparentPixels(croppedImage) {
          material.transparency = 1.0
          material.blendMode = .alpha
        } else {
          material.transparency = 1.0
          material.blendMode = .alpha
        }

        // Cape should be double-sided for realistic cloth appearance
        material.isDoubleSided = true

        // Phong lighting for better visual depth
        material.lightingModel = .phong
        material.shininess = 0.1

        // Subtle ambient and specular properties
        material.ambient.contents = NSColor.black.withAlphaComponent(0.2)
        material.specular.contents = NSColor.white.withAlphaComponent(0.1)

      case .failure:
        // Fallback material
        material.diffuse.contents = NSColor.red.withAlphaComponent(0.8)
        material.transparency = 0.8
        material.blendMode = .alpha
        material.isDoubleSided = true
        material.lightingModel = .phong
      }

      materials.append(material)
    }

    return materials
  }

  // MARK: - Generic Material Creation

  /// Create materials from texture specifications
  /// - Parameters:
  ///   - skinImage: The source texture image
  ///   - specs: Array of face specifications defining crop rectangles
  ///   - layerName: Name for debugging purposes
  ///   - isOuter: Whether this is an outer overlay layer
  ///   - isLimb: Whether this is a limb (affects bottom face transform)
  /// - Returns: Array of 6 materials for each cube face
  private func createMaterials(
    from skinImage: NSImage,
    specs: [CubeFace.Spec],
    layerName: String,
    isOuter: Bool,
    isLimb: Bool
  ) -> [SCNMaterial] {
    var materials: [SCNMaterial] = []

    for (index, spec) in specs.enumerated() {
      let material = SCNMaterial()

      switch TextureProcessor.crop(skinImage, rect: spec.rect) {
      case .success(let croppedImage):
        let finalImage: NSImage

        // Apply bottom face transforms
        if index == 5 {  // bottom face
          let transformResult: Result<NSImage, TextureProcessor.Error>
          if isLimb {
            transformResult = TextureProcessor.applyBottomFaceTransform(
              croppedImage,
              flipMode: bottomFaceConfig.limbFlipMode,
              rotate180: bottomFaceConfig.limbRotate180
            )
          } else {
            transformResult = TextureProcessor.applyBottomFaceTransform(
              croppedImage,
              flipMode: bottomFaceConfig.headBodyFlipMode,
              rotate180: bottomFaceConfig.headBodyRotate180
            )
          }
          finalImage = (try? transformResult.get()) ?? croppedImage
        } else {
          finalImage = croppedImage
        }

        material.diffuse.contents = finalImage
        material.diffuse.magnificationFilter = .nearest
        material.diffuse.minificationFilter = .nearest
        material.diffuse.wrapS = .clamp
        material.diffuse.wrapT = .clamp

        // Set transparency for outer layers
        if isOuter {
          if TextureProcessor.hasTransparentPixels(finalImage) {
            material.transparency = 1.0
            material.blendMode = .alpha
            material.isDoubleSided = true
          } else {
            material.transparency = 0.9
            material.blendMode = .alpha
          }
        }

        // Use lambert lighting model for proper shading response to scene lights
        material.lightingModel = .lambert

      case .failure:
        // Fallback material for failed crops
        material.diffuse.contents = isOuter
          ? NSColor.blue.withAlphaComponent(0.5)
          : NSColor.red
      }

      materials.append(material)
    }

    return materials
  }

  // MARK: - Elytra Materials

  /// Create material for elytra wing (plane-based rendering)
  /// - Parameters:
  ///   - elytraImage: The elytra texture image (64x32)
  ///   - isLeft: Whether this is the left wing
  /// - Returns: SCNMaterial for the wing plane
  public func createElytraWingMaterial(from elytraImage: NSImage, isLeft: Bool) -> SCNMaterial {
    let material = SCNMaterial()

    let spec = isLeft ? CubeFace.elytraLeftWing : CubeFace.elytraRightWing

    switch TextureProcessor.crop(elytraImage, rect: spec.rect) {
    case .success(let croppedImage):
      material.diffuse.contents = croppedImage
      material.diffuse.magnificationFilter = .nearest
      material.diffuse.minificationFilter = .nearest
      material.diffuse.wrapS = .clamp
      material.diffuse.wrapT = .clamp

      // Enable transparency for elytra
      material.transparency = 1.0
      material.blendMode = .alpha

      // Double-sided rendering for realistic wing appearance
      material.isDoubleSided = true

      // Use phong lighting for more realistic shading
      material.lightingModel = .phong
      material.shininess = 0.2

      // Add subtle ambient and specular highlights
      material.ambient.contents = NSColor.black.withAlphaComponent(0.2)
      material.specular.contents = NSColor.white.withAlphaComponent(0.15)

    case .failure:
      // Fallback material
      material.diffuse.contents = NSColor.purple.withAlphaComponent(0.8)
      material.transparency = 0.8
      material.blendMode = .alpha
      material.isDoubleSided = true
      material.lightingModel = .phong
    }

    return material
  }

  // MARK: - Material Updates

  /// Update materials on existing geometry without rebuilding nodes
  /// - Parameters:
  ///   - geometry: The geometry to update
  ///   - materials: New materials to apply
  public func updateMaterials(on geometry: SCNGeometry?, with materials: [SCNMaterial]) {
    geometry?.materials = materials
  }
}
