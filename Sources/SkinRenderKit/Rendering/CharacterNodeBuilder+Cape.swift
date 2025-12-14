//
//  CharacterNodeBuilder+Cape.swift
//  SkinRenderKit
//
//  Cape construction helpers for CharacterNodeBuilder
//

import SceneKit

extension CharacterNodeBuilder {

  // MARK: - Cape

  func buildCape(
    capeImage: NSImage,
    parent: SCNNode
  ) -> (pivot: SCNNode, cape: SCNNode) {
    // Pivot node at upper back (shoulder line)
    let capePivotNode = SCNNode()
    capePivotNode.name = "CapePivot"
    capePivotNode.position = SCNVector3(0, CharacterDimensions.capePivotY, CharacterDimensions.capePivotZ)

    // Cape geometry
    let capeGeometry = SCNBox(
      width: CharacterDimensions.capeWidth,
      height: CharacterDimensions.capeHeight,
      length: CharacterDimensions.capeDepth,
      chamferRadius: 0
    )
    capeGeometry.materials = materialFactory.createCapeMaterials(from: capeImage)

    let capeNode = SCNNode(geometry: capeGeometry)
    capeNode.name = "Cape"
    capeNode.position = SCNVector3(0, CharacterDimensions.capeYOffset, 0)

    // Apply slight backward tilt
    capePivotNode.eulerAngles = SCNVector3(CharacterDimensions.capeBaseAngle, 0, 0)

    capePivotNode.addChildNode(capeNode)
    parent.addChildNode(capePivotNode)

    return (capePivotNode, capeNode)
  }

  // MARK: - Default Cape

  func loadDefaultCapeTexture() -> NSImage? {
    EmbeddedTextures.capeImage
  }
}
