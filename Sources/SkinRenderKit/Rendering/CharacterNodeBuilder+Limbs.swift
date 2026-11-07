//
//  CharacterNodeBuilder+Limbs.swift
//  SkinRenderKit
//
//  Arm and leg construction helpers for CharacterNodeBuilder
//

import SceneKit

extension CharacterNodeBuilder {

  /// Result of building a single limb (arm or leg)
  private struct SingleLimbNodes {
    let group: SCNNode
    let base: SCNNode
    let overlay: SCNNode
  }

  /// Build a single limb (arm or leg) with its voxelized outer layer
  private func buildSingleLimb(
    skinImage: NSImage,
    isLeft: Bool,
    limbName: String,
    dimensions: BoxDimensions,
    sleeveDimensions: BoxDimensions,
    position: SCNVector3,
    groupOffsetY: CGFloat,
    parent: SCNNode,
    baseMaterials: (Bool) -> [SCNMaterial],
    sleeveSpecs: () -> [CubeFace.Spec]
  ) -> SingleLimbNodes {
    let side = isLeft ? "Left" : "Right"

    // Limb group (pivot at shoulder/hip)
    let limbGroup = SCNNode()
    limbGroup.name = "\(side)\(limbName)Group"
    limbGroup.position = SCNVector3(
      CGFloat(position.x),
      CGFloat(position.y) + groupOffsetY,
      CGFloat(position.z)
    )
    parent.addChildNode(limbGroup)

    // Limb base
    let baseGeometry = SCNBox(
      width: dimensions.width,
      height: dimensions.height,
      length: dimensions.length,
      chamferRadius: 0
    )
    baseGeometry.materials = baseMaterials(isLeft)
    let baseNode = SCNNode(geometry: baseGeometry)
    baseNode.name = "\(side)\(limbName)"
    baseNode.position = SCNVector3(0, -Float(dimensions.height / 2), 0)
    limbGroup.addChildNode(baseNode)

    // Sleeve (voxelized outer layer, centered with base limb)
    let sleeveBoxSize = SCNVector3(
      sleeveDimensions.width,
      sleeveDimensions.height,
      sleeveDimensions.length
    )
    let baseSize = SCNVector3(
      dimensions.width,
      dimensions.height,
      dimensions.length
    )
    let sleevePosition = SCNVector3(0, -Float(dimensions.height / 2), 0)
    let sleeveConfig = VoxelOverlayConfig(
      boxSize: sleeveBoxSize,
      baseSize: baseSize,
      voxelThickness: 0.25
    )
    let sleeveNode = voxelBuilder.buildVoxelOverlay(
      from: skinImage,
      specs: sleeveSpecs(),
      config: sleeveConfig,
      position: sleevePosition,
      name: "\(side)\(limbName)Sleeve"
    )
    limbGroup.addChildNode(sleeveNode)

    return SingleLimbNodes(
      group: limbGroup,
      base: baseNode,
      overlay: sleeveNode
    )
  }

  private func buildSingleArm(
    skinImage: NSImage,
    isLeft: Bool,
    armDimensions: BoxDimensions,
    sleeveDimensions: BoxDimensions,
    position: SCNVector3,
    playerModel: PlayerModel,
    parent: SCNNode
  ) -> SingleLimbNodes {
    buildSingleLimb(
      skinImage: skinImage,
      isLeft: isLeft,
      limbName: "Arm",
      dimensions: armDimensions,
      sleeveDimensions: sleeveDimensions,
      position: position,
      groupOffsetY: armDimensions.height / 2,
      parent: parent,
      baseMaterials: { isLeft in
        materialFactory.createArmMaterials(
          from: skinImage,
          isLeft: isLeft,
          isSleeve: false,
          playerModel: playerModel
        )
      },
      sleeveSpecs: { CubeFace.armSleeve(isLeft: isLeft, armWidth: armDimensions.width) }
    )
  }

  struct ArmNodes {
    let rightGroup: SCNNode
    let rightBase: SCNNode
    let rightOverlay: SCNNode
    let leftGroup: SCNNode
    let leftBase: SCNNode
    let leftOverlay: SCNNode
  }

  func buildArms(
    skinImage: NSImage,
    playerModel: PlayerModel,
    parent: SCNNode
  ) -> ArmNodes {
    let armDimensions = playerModel.armDimensions
    let armSleeveDimensions = playerModel.armSleeveDimensions
    let armPositions = playerModel.armPositions

    let rightArm = buildSingleArm(
      skinImage: skinImage,
      isLeft: false,
      armDimensions: armDimensions,
      sleeveDimensions: armSleeveDimensions,
      position: armPositions.right,
      playerModel: playerModel,
      parent: parent
    )

    let leftArm = buildSingleArm(
      skinImage: skinImage,
      isLeft: true,
      armDimensions: armDimensions,
      sleeveDimensions: armSleeveDimensions,
      position: armPositions.left,
      playerModel: playerModel,
      parent: parent
    )

    return ArmNodes(
      rightGroup: rightArm.group,
      rightBase: rightArm.base,
      rightOverlay: rightArm.overlay,
      leftGroup: leftArm.group,
      leftBase: leftArm.base,
      leftOverlay: leftArm.overlay
    )
  }

  struct LegNodes {
    let rightGroup: SCNNode
    let rightBase: SCNNode
    let rightOverlay: SCNNode
    let leftGroup: SCNNode
    let leftBase: SCNNode
    let leftOverlay: SCNNode
  }

  func buildLegs(
    skinImage: NSImage,
    playerModel: PlayerModel,
    parent: SCNNode
  ) -> LegNodes {
    let legDimensions = playerModel.legDimensions
    let legSleeveDimensions = playerModel.legSleeveDimensions
    let legPositions = playerModel.legPositions

    let rightLeg = buildSingleLeg(
      skinImage: skinImage,
      isLeft: false,
      legDimensions: legDimensions,
      sleeveDimensions: legSleeveDimensions,
      position: legPositions.right,
      parent: parent
    )

    let leftLeg = buildSingleLeg(
      skinImage: skinImage,
      isLeft: true,
      legDimensions: legDimensions,
      sleeveDimensions: legSleeveDimensions,
      position: legPositions.left,
      parent: parent
    )

    return LegNodes(
      rightGroup: rightLeg.group,
      rightBase: rightLeg.base,
      rightOverlay: rightLeg.overlay,
      leftGroup: leftLeg.group,
      leftBase: leftLeg.base,
      leftOverlay: leftLeg.overlay
    )
  }

  private func buildSingleLeg(
    skinImage: NSImage,
    isLeft: Bool,
    legDimensions: BoxDimensions,
    sleeveDimensions: BoxDimensions,
    position: SCNVector3,
    parent: SCNNode
  ) -> SingleLimbNodes {
    buildSingleLimb(
      skinImage: skinImage,
      isLeft: isLeft,
      limbName: "Leg",
      dimensions: legDimensions,
      sleeveDimensions: sleeveDimensions,
      position: position,
      groupOffsetY: 0,
      parent: parent,
      baseMaterials: { isLeft in
        materialFactory.createLegMaterials(from: skinImage, isLeft: isLeft, isSleeve: false)
      },
      sleeveSpecs: { CubeFace.legSleeve(isLeft: isLeft) }
    )
  }
}
