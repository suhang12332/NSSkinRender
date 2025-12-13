//
//  SceneKitCharacterViewController+Updates.swift
//  SkinRenderKit
//

import SceneKit

extension SceneKitCharacterViewController {

  // MARK: - Public Update Methods

  public func updateTexture(path: String) {
    self.skinTexturePath = path
    loadTexture()
    if skinImage != nil {
      rebuildCharacter()
    }
  }

  public func updateTexture(image: NSImage) {
    self.skinImage = image
    self.skinTexturePath = nil
    rebuildCharacter()
  }

  public func updateRotationDuration(_ duration: TimeInterval) {
    self.rotationDuration = duration
    animationController.updateRotationDuration(duration)
  }

  public func updateBackgroundColor(_ color: NSColor) {
    self.backgroundColor = color
    scnView?.backgroundColor = color
  }

  public func updateCapeTexture(path: String) {
    self.capeTexturePath = path
    loadCapeTexture(from: path)
    rebuildCharacter()
  }

  public func updateCapeTexture(image: NSImage) {
    self.capeImage = image
    self.capeTexturePath = nil
    rebuildCharacter()
  }

  public func removeCapeTexture() {
    self.capeImage = nil
    self.capeTexturePath = nil
    rebuildCharacter()
  }

  public func updatePlayerModel(_ model: PlayerModel) {
    self.playerModel = model
    rebuildCharacter()
  }

  public func updateShowButtons(_ show: Bool) {
    guard self.debugMode != show else { return }
    self.debugMode = show

    if !show {
      toggleButton.removeFromSuperview()
      modelTypeButton.removeFromSuperview()
      capeToggleButton.removeFromSuperview()
      capeAnimationButton.removeFromSuperview()
      walkingAnimationButton.removeFromSuperview()
    } else {
      setupUI()
    }
  }

  public func toggleCapeAnimation(_ enabled: Bool) {
    animationController.toggleCapeAnimation(enabled)
  }
}
