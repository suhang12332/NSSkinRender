//
//  SceneKitCharacterViewController+Updates.swift
//  SkinRenderKit
//

import SceneKit

extension SceneKitCharacterViewController {

  // MARK: - Internal Update Helpers

  private func applySkinUpdate(path: String? = nil, image: NSImage? = nil) {
    if let path = path {
      // Skip if path unchanged
      guard skinTexturePath != path else { return }
      self.skinTexturePath = path
      loadTexture()
      if skinImage != nil {
        rebuildCharacter()
      }
      return
    }

    if let image = image {
      // Skip if same image instance
      guard skinImage !== image else { return }
      self.skinImage = image
      self.skinTexturePath = nil
      rebuildCharacter()
    }
  }

  private func applyCapeUpdate(path: String? = nil, image: NSImage? = nil) {
    if let path = path {
      // Skip if path unchanged
      guard capeTexturePath != path else { return }
      self.capeTexturePath = path
      loadCapeTexture(from: path)
      if capeImage != nil {
        rebuildCharacter()
      }
      return
    }

    if let image = image {
      // Skip if same image instance
      guard capeImage !== image else { return }
      self.capeImage = image
      self.capeTexturePath = nil
      rebuildCharacter()
    }
  }

  // MARK: - Public Update Methods

  public func updateTexture(path: String) {
    applySkinUpdate(path: path)
  }

  public func updateTexture(image: NSImage) {
    applySkinUpdate(image: image)
  }

  public func updateRotationDuration(_ duration: TimeInterval) {
    // Skip if duration unchanged
    guard rotationDuration != duration else { return }
    self.rotationDuration = duration
    animationController.updateRotationDuration(duration)
  }

  public func updateBackgroundColor(_ color: NSColor) {
    // Skip if color unchanged
    guard backgroundColor != color else { return }
    self.backgroundColor = color
    scnView?.backgroundColor = color
  }

  public func updateCapeTexture(path: String) {
    applyCapeUpdate(path: path)
  }

  public func updateCapeTexture(image: NSImage) {
    applyCapeUpdate(image: image)
  }

  public func removeCapeTexture() {
    // Skip if already no cape
    guard capeImage != nil || capeTexturePath != nil else { return }
    self.capeImage = nil
    self.capeTexturePath = nil
    rebuildCharacter()
  }

  public func updatePlayerModel(_ model: PlayerModel) {
    // Skip if model unchanged
    guard playerModel != model else { return }
    self.playerModel = model
    rebuildCharacter()
  }

  public func updateShowButtons(_ show: Bool) {
    guard self.debugMode != show else { return }
    self.debugMode = show

    if !show {
      allDebugButtons.forEach { $0.removeFromSuperview() }
    } else {
      setupUI()
    }
  }

  public func toggleCapeAnimation(_ enabled: Bool) {
    animationController.toggleCapeAnimation(enabled)
  }
}
