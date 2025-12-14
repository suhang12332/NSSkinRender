//
//  CharacterNodeBuilder+Head.swift
//  SkinRenderKit
//
//  Head construction helpers for CharacterNodeBuilder
//

import SceneKit

/// Container for head node hierarchy
struct HeadNodes {
  let group: SCNNode
  let base: SCNNode
  let overlay: SCNNode
}

extension CharacterNodeBuilder {

  // MARK: - Head

  func buildHead(
    skinImage: NSImage,
    parent: SCNNode
  ) -> HeadNodes {
    // Group positioned at head center for rotations/bobbing
    let headGroup = SCNNode()
    headGroup.name = "HeadGroup"
    headGroup.position = SCNVector3(0, CharacterDimensions.headY, 0)
    parent.addChildNode(headGroup)

    // Base head
    let headSize = CharacterDimensions.headSize
    let headGeometry = SCNBox(width: headSize, height: headSize, length: headSize, chamferRadius: 0)
    headGeometry.materials = materialFactory.createHeadMaterials(from: skinImage, isHat: false)
    let headNode = SCNNode(geometry: headGeometry)
    headNode.name = "Head"
    headNode.position = SCNVector3Zero
    headGroup.addChildNode(headNode)

    // Hat layer
    let hatSize = CharacterDimensions.hatSize
    let hatGeometry = SCNBox(width: hatSize, height: hatSize, length: hatSize, chamferRadius: 0)
    hatGeometry.materials = materialFactory.createHeadMaterials(from: skinImage, isHat: true)
    let hatNode = SCNNode(geometry: hatGeometry)
    hatNode.name = "Hat"
    hatNode.position = SCNVector3Zero
    headGroup.addChildNode(hatNode)

    return HeadNodes(
      group: headGroup,
      base: headNode,
      overlay: hatNode
    )
  }
}
