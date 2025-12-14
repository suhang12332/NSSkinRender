//
//  CharacterNodeBuilder+Limbs.swift
//  SkinRenderKit
//
//  Arm and leg construction helpers for CharacterNodeBuilder
//

import SceneKit

extension CharacterNodeBuilder {

  // MARK: - Common Limb Structure

  /// Result of building a single limb (arm or leg)
  private struct SingleLimbNodes {
    let group: SCNNode
    let base: SCNNode
    let overlay: SCNNode
  }

  // MARK: - Arm Nodes

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

  private func buildSingleArm(
    skinImage: NSImage,
    isLeft: Bool,
    armDimensions: BoxDimensions,
    sleeveDimensions: BoxDimensions,
    position: SCNVector3,
    playerModel: PlayerModel,
    parent: SCNNode
  ) -> SingleLimbNodes {
    let side = isLeft ? "Left" : "Right"

    // Arm group (pivot at shoulder)
    let armGroup = SCNNode()
    armGroup.name = "\(side)ArmGroup"
    armGroup.position = SCNVector3(
      CGFloat(position.x),
      CGFloat(position.y) + armDimensions.height / 2,
      CGFloat(position.z)
    )
    parent.addChildNode(armGroup)

    // Arm base
    let armGeometry = SCNBox(
      width: armDimensions.width,
      height: armDimensions.height,
      length: armDimensions.length,
      chamferRadius: 0
    )
    armGeometry.materials = materialFactory.createArmMaterials(
      from: skinImage, isLeft: isLeft, isSleeve: false, playerModel: playerModel
    )
    let armNode = SCNNode(geometry: armGeometry)
    armNode.name = "\(side)Arm"
    armNode.position = SCNVector3(0, -Float(armDimensions.height / 2), 0)
    armGroup.addChildNode(armNode)

    // Arm sleeve (centered with base arm)
    let sleeveGeometry = SCNBox(
      width: sleeveDimensions.width,
      height: sleeveDimensions.height,
      length: sleeveDimensions.length,
      chamferRadius: 0
    )
    sleeveGeometry.materials = materialFactory.createArmMaterials(
      from: skinImage, isLeft: isLeft, isSleeve: true, playerModel: playerModel
    )
    let sleeveNode = SCNNode(geometry: sleeveGeometry)
    sleeveNode.name = "\(side)ArmSleeve"
    sleeveNode.position = SCNVector3(0, -Float(armDimensions.height / 2), 0)
    armGroup.addChildNode(sleeveNode)

    return SingleLimbNodes(
      group: armGroup,
      base: armNode,
      overlay: sleeveNode
    )
  }

  // MARK: - Leg Nodes

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
    let side = isLeft ? "Left" : "Right"

    // Leg group (pivot at hip)
    let legGroup = SCNNode()
    legGroup.name = "\(side)LegGroup"
    legGroup.position = position
    parent.addChildNode(legGroup)

    // Leg base
    let legGeometry = SCNBox(
      width: legDimensions.width,
      height: legDimensions.height,
      length: legDimensions.length,
      chamferRadius: 0
    )
    legGeometry.materials = materialFactory.createLegMaterials(
      from: skinImage, isLeft: isLeft, isSleeve: false
    )
    let legNode = SCNNode(geometry: legGeometry)
    legNode.name = "\(side)Leg"
    legNode.position = SCNVector3(0, -Float(legDimensions.height / 2), 0)
    legGroup.addChildNode(legNode)

    // Leg sleeve (centered with base leg)
    let sleeveGeometry = SCNBox(
      width: sleeveDimensions.width,
      height: sleeveDimensions.height,
      length: sleeveDimensions.length,
      chamferRadius: 0
    )
    sleeveGeometry.materials = materialFactory.createLegMaterials(
      from: skinImage, isLeft: isLeft, isSleeve: true
    )
    let sleeveNode = SCNNode(geometry: sleeveGeometry)
    sleeveNode.name = "\(side)LegSleeve"
    sleeveNode.position = SCNVector3(0, -Float(legDimensions.height / 2), 0)
    legGroup.addChildNode(sleeveNode)

    return SingleLimbNodes(
      group: legGroup,
      base: legNode,
      overlay: sleeveNode
    )
  }
}
