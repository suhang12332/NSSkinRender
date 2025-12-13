//
//  CharacterNodeBuilder+Limbs.swift
//  SkinRenderKit
//
//  Arm and leg construction helpers for CharacterNodeBuilder
//

import SceneKit

extension CharacterNodeBuilder {

  // MARK: - Arm Nodes

  struct ArmNodes {
    let rightGroup: SCNNode
    let rightBase: SCNNode
    let rightOverlay: SCNNode
    let leftGroup: SCNNode
    let leftBase: SCNNode
    let leftOverlay: SCNNode
  }

  private struct SingleArmNodes {
    let group: SCNNode
    let base: SCNNode
    let overlay: SCNNode
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
  ) -> SingleArmNodes {
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

    // Arm sleeve
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
    sleeveNode.position = SCNVector3(0, -Float(sleeveDimensions.height / 2), 0)
    armGroup.addChildNode(sleeveNode)

    return SingleArmNodes(
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
    parent: SCNNode
  ) -> LegNodes {
    // Right leg group (pivot at hip)
    let rightLegGroup = SCNNode()
    rightLegGroup.name = "RightLegGroup"
    rightLegGroup.position = SCNVector3(-2, 0, 0)
    parent.addChildNode(rightLegGroup)

    // Right leg base (4x12x4)
    let rightLegGeometry = SCNBox(width: 4, height: 12, length: 4, chamferRadius: 0)
    rightLegGeometry.materials = materialFactory.createLegMaterials(
      from: skinImage, isLeft: false, isSleeve: false
    )
    let rightLegNode = SCNNode(geometry: rightLegGeometry)
    rightLegNode.name = "RightLeg"
    rightLegNode.position = SCNVector3(0, -6, 0)
    rightLegGroup.addChildNode(rightLegNode)

    // Right leg sleeve (4.5x12.5x4.5)
    let rightLegSleeveGeometry = SCNBox(width: 4.5, height: 12.5, length: 4.5, chamferRadius: 0)
    rightLegSleeveGeometry.materials = materialFactory.createLegMaterials(
      from: skinImage, isLeft: false, isSleeve: true
    )
    let rightLegSleeveNode = SCNNode(geometry: rightLegSleeveGeometry)
    rightLegSleeveNode.name = "RightLegSleeve"
    rightLegSleeveNode.position = SCNVector3(0, -6.25, 0)
    rightLegGroup.addChildNode(rightLegSleeveNode)

    // Left leg group (pivot at hip)
    let leftLegGroup = SCNNode()
    leftLegGroup.name = "LeftLegGroup"
    leftLegGroup.position = SCNVector3(2, 0, 0)
    parent.addChildNode(leftLegGroup)

    // Left leg base (4x12x4)
    let leftLegGeometry = SCNBox(width: 4, height: 12, length: 4, chamferRadius: 0)
    leftLegGeometry.materials = materialFactory.createLegMaterials(
      from: skinImage, isLeft: true, isSleeve: false
    )
    let leftLegNode = SCNNode(geometry: leftLegGeometry)
    leftLegNode.name = "LeftLeg"
    leftLegNode.position = SCNVector3(0, -6, 0)
    leftLegGroup.addChildNode(leftLegNode)

    // Left leg sleeve (4.5x12.5x4.5)
    let leftLegSleeveGeometry = SCNBox(width: 4.5, height: 12.5, length: 4.5, chamferRadius: 0)
    leftLegSleeveGeometry.materials = materialFactory.createLegMaterials(
      from: skinImage, isLeft: true, isSleeve: true
    )
    let leftLegSleeveNode = SCNNode(geometry: leftLegSleeveGeometry)
    leftLegSleeveNode.name = "LeftLegSleeve"
    leftLegSleeveNode.position = SCNVector3(0, -6.25, 0)
    leftLegGroup.addChildNode(leftLegSleeveNode)

    return LegNodes(
      rightGroup: rightLegGroup,
      rightBase: rightLegNode,
      rightOverlay: rightLegSleeveNode,
      leftGroup: leftLegGroup,
      leftBase: leftLegNode,
      leftOverlay: leftLegSleeveNode
    )
  }
}
