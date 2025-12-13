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

  func buildArms(
    skinImage: NSImage,
    playerModel: PlayerModel,
    parent: SCNNode
  ) -> ArmNodes {
    let armDimensions = playerModel.armDimensions
    let armSleeveDimensions = playerModel.armSleeveDimensions
    let armPositions = playerModel.armPositions

    // Right arm group (pivot at shoulder)
    let rightArmGroup = SCNNode()
    rightArmGroup.name = "RightArmGroup"
    rightArmGroup.position = SCNVector3(
      CGFloat(armPositions.right.x),
      CGFloat(armPositions.right.y) + armDimensions.height / 2,
      CGFloat(armPositions.right.z)
    )
    parent.addChildNode(rightArmGroup)

    // Right arm base
    let rightArmGeometry = SCNBox(
      width: armDimensions.width,
      height: armDimensions.height,
      length: armDimensions.length,
      chamferRadius: 0
    )
    rightArmGeometry.materials = materialFactory.createArmMaterials(
      from: skinImage, isLeft: false, isSleeve: false, playerModel: playerModel
    )
    let rightArmNode = SCNNode(geometry: rightArmGeometry)
    rightArmNode.name = "RightArm"
    rightArmNode.position = SCNVector3(0, -Float(armDimensions.height / 2), 0)
    rightArmGroup.addChildNode(rightArmNode)

    // Right arm sleeve
    let rightSleeveGeometry = SCNBox(
      width: armSleeveDimensions.width,
      height: armSleeveDimensions.height,
      length: armSleeveDimensions.length,
      chamferRadius: 0
    )
    rightSleeveGeometry.materials = materialFactory.createArmMaterials(
      from: skinImage, isLeft: false, isSleeve: true, playerModel: playerModel
    )
    let rightArmSleeveNode = SCNNode(geometry: rightSleeveGeometry)
    rightArmSleeveNode.name = "RightArmSleeve"
    rightArmSleeveNode.position = SCNVector3(0, -Float(armSleeveDimensions.height / 2), 0)
    rightArmGroup.addChildNode(rightArmSleeveNode)

    // Left arm group (pivot at shoulder)
    let leftArmGroup = SCNNode()
    leftArmGroup.name = "LeftArmGroup"
    leftArmGroup.position = SCNVector3(
      CGFloat(armPositions.left.x),
      CGFloat(armPositions.left.y) + armDimensions.height / 2,
      CGFloat(armPositions.left.z)
    )
    parent.addChildNode(leftArmGroup)

    // Left arm base
    let leftArmGeometry = SCNBox(
      width: armDimensions.width,
      height: armDimensions.height,
      length: armDimensions.length,
      chamferRadius: 0
    )
    leftArmGeometry.materials = materialFactory.createArmMaterials(
      from: skinImage, isLeft: true, isSleeve: false, playerModel: playerModel
    )
    let leftArmNode = SCNNode(geometry: leftArmGeometry)
    leftArmNode.name = "LeftArm"
    leftArmNode.position = SCNVector3(0, -Float(armDimensions.height / 2), 0)
    leftArmGroup.addChildNode(leftArmNode)

    // Left arm sleeve
    let leftSleeveGeometry = SCNBox(
      width: armSleeveDimensions.width,
      height: armSleeveDimensions.height,
      length: armSleeveDimensions.length,
      chamferRadius: 0
    )
    leftSleeveGeometry.materials = materialFactory.createArmMaterials(
      from: skinImage, isLeft: true, isSleeve: true, playerModel: playerModel
    )
    let leftArmSleeveNode = SCNNode(geometry: leftSleeveGeometry)
    leftArmSleeveNode.name = "LeftArmSleeve"
    leftArmSleeveNode.position = SCNVector3(0, -Float(armSleeveDimensions.height / 2), 0)
    leftArmGroup.addChildNode(leftArmSleeveNode)

    return ArmNodes(
      rightGroup: rightArmGroup,
      rightBase: rightArmNode,
      rightOverlay: rightArmSleeveNode,
      leftGroup: leftArmGroup,
      leftBase: leftArmNode,
      leftOverlay: leftArmSleeveNode
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
