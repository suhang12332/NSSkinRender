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

        configureBaseMaterialProperties(material, image: finalImage)
        configureTransparency(material, transparency: 1.0, isDoubleSided: true)
        configurePhongLighting(material, shininess: 0.1)

      case .failure:
        // Fallback material
        material.diffuse.contents = NSColor.red.withAlphaComponent(0.8)
        configureTransparency(material, transparency: 0.8, isDoubleSided: true)
        configurePhongLighting(material)
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

        configureBaseMaterialProperties(material, image: finalImage)

        // Set transparency for outer layers
        if isOuter {
          let hasTransparency = TextureProcessor.hasTransparentPixels(finalImage)
          configureTransparency(
            material,
            transparency: hasTransparency ? 1.0 : 0.9,
            isDoubleSided: hasTransparency
          )
        }

        // Use Phong lighting model for enhanced depth and material quality
        // 使用 Phong 光照模型增强质感和光影效果
        configurePhongLighting(
          material,
          shininess: 0.15,
          ambient: NSColor.white.withAlphaComponent(0.15),  // 增加 ambient 让材质更亮
          specular: NSColor.white.withAlphaComponent(0.2)
        )

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
      configureBaseMaterialProperties(material, image: croppedImage)
      configureTransparency(material, transparency: 1.0, isDoubleSided: true)
      configurePhongLighting(
        material,
        shininess: 0.2,
        specular: NSColor.white.withAlphaComponent(0.15)
      )

    case .failure:
      // Fallback material
      material.diffuse.contents = NSColor.purple.withAlphaComponent(0.8)
      configureTransparency(material, transparency: 0.8, isDoubleSided: true)
      configurePhongLighting(material)
    }

    return material
  }

  // MARK: - Material Configuration Helpers

  /// Configure base material properties for texture rendering
  /// - Parameters:
  ///   - material: The material to configure
  ///   - image: The texture image to apply
  private func configureBaseMaterialProperties(_ material: SCNMaterial, image: NSImage) {
    material.diffuse.contents = image
    material.diffuse.magnificationFilter = .nearest
    material.diffuse.minificationFilter = .nearest
    material.diffuse.wrapS = .clamp
    material.diffuse.wrapT = .clamp
  }

  /// Configure Phong lighting model with specular highlights
  /// - Parameters:
  ///   - material: The material to configure
  ///   - shininess: Material shininess (0.0-1.0)
  ///   - ambient: Ambient color intensity
  ///   - specular: Specular highlight intensity
  private func configurePhongLighting(
    _ material: SCNMaterial,
    shininess: CGFloat = 0.1,
    ambient: NSColor = NSColor.black.withAlphaComponent(0.2),
    specular: NSColor = NSColor.white.withAlphaComponent(0.1)
  ) {
    material.lightingModel = .phong
    material.shininess = shininess
    material.ambient.contents = ambient
    material.specular.contents = specular
  }

  /// Configure Lambert lighting model
  /// - Parameter material: The material to configure
  private func configureLambertLighting(_ material: SCNMaterial) {
    material.lightingModel = .lambert
  }

  /// Configure transparency and blending for materials
  /// - Parameters:
  ///   - material: The material to configure
  ///   - transparency: Transparency value (0.0-1.0, where 1.0 is fully opaque)
  ///   - isDoubleSided: Whether the material should be double-sided
  private func configureTransparency(
    _ material: SCNMaterial,
    transparency: CGFloat = 1.0,
    isDoubleSided: Bool = false
  ) {
    material.transparency = transparency
    material.blendMode = .alpha
    if isDoubleSided {
      material.isDoubleSided = true
    }
  }
}
