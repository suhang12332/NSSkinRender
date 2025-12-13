//
//  CharacterNodeBuilder+Rendering.swift
//  SkinRenderKit
//
//  Rendering configuration helpers for CharacterNodeBuilder
//

import SceneKit

extension CharacterNodeBuilder {

  // MARK: - Rendering Priorities

  func setupRenderingPriorities(_ nodes: CharacterNodes) {
    // Base layers - lowest priority
    nodes.body.renderingOrder = 100
    nodes.head.renderingOrder = 100
    nodes.rightArm.renderingOrder = 105
    nodes.leftArm.renderingOrder = 105
    nodes.rightLeg.renderingOrder = 105
    nodes.leftLeg.renderingOrder = 105

    // Outer layers - highest priority
    nodes.hat.renderingOrder = 200
    nodes.jacket.renderingOrder = 200
    nodes.rightArmSleeve.renderingOrder = 210
    nodes.leftArmSleeve.renderingOrder = 210
    nodes.rightLegSleeve.renderingOrder = 210
    nodes.leftLegSleeve.renderingOrder = 210

    // Cape - between base and outer
    nodes.capePivot?.renderingOrder = 150

    // Elytra - same priority as cape
    nodes.elytraPivot?.renderingOrder = 150
  }
}
