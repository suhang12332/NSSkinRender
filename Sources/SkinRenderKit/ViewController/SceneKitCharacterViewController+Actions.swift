//
//  SceneKitCharacterViewController+Actions.swift
//  SkinRenderKit
//

import SceneKit

extension SceneKitCharacterViewController {

  // MARK: - Action Handlers

  @objc func handleRightClick(_ gestureRecognizer: NSClickGestureRecognizer) {
    let location = gestureRecognizer.location(in: scnView)
    if isPointOverUIButton(location) { return }
    toggleWalkingAnimationAction()
  }

  @objc func toggleOuterLayers() {
    showOuterLayers.toggle()
    characterNodes?.setOuterLayersHidden(!showOuterLayers)
    toggleButton.title = showOuterLayers ? "Hide Outer Layers" : "Show Outer Layers"
  }

  @objc func toggleCape() {
    showCape.toggle()
    characterNodes?.setCapeHidden(!showCape)
    capeToggleButton.title = showCape ? "Hide Cape" : "Show Cape"
  }

  @objc func toggleCapeAnimationAction() {
    let newState = !animationController.capeSwayEnabled
    animationController.toggleCapeAnimation(newState)
    capeAnimationButton.title = newState ? "Disable Animation" : "Enable Animation"
  }

  @objc func switchModelType() {
    playerModel = (playerModel == .steve) ? .alex : .steve
    modelTypeButton.title = "Switch to \(playerModel == .steve ? "Alex" : "Steve")"
    rebuildCharacter()
  }

  @objc func toggleWalkingAnimationAction() {
    animationController.toggleWalkingAnimation()
    walkingAnimationButton.title = animationController.walkingEnabled ? "Stop Walking" : "Start Walking"
  }

  private func isPointOverUIButton(_ point: CGPoint) -> Bool {
    guard debugMode else { return false }
    return allDebugButtons.contains { $0.frame.contains(point) }
  }

  var allDebugButtons: [NSButton] {
    [toggleButton, modelTypeButton, capeToggleButton, capeAnimationButton, walkingAnimationButton]
  }
}
