//
//  SceneKitCharacterViewController+Textures.swift
//  SkinRenderKit
//

import SceneKit

extension SceneKitCharacterViewController {

  func loadTexture() {
    guard let texturePath = skinTexturePath else { return }
    if let image = NSImage(contentsOfFile: texturePath) {
      self.skinImage = image
    } else {
      loadDefaultTextureIfNeeded()
    }
  }

  func loadCapeTexture(from path: String) {
    if let image = NSImage(contentsOfFile: path) {
      self.capeImage = image
    }
  }

  /// Load default texture only if no skin is set (does not rebuild)
  /// Used during initialization
  func loadDefaultTextureIfNeeded() {
    guard skinImage == nil else { return }
    self.skinImage = EmbeddedTextures.alexImage
  }

  /// Public method for updateNSViewController - skips if skin already loaded
  public func loadDefaultTexture() {
    // Skip if we already have a skin image or a custom path was set
    guard skinImage == nil && skinTexturePath == nil else { return }
    loadDefaultTextureIfNeeded()
    rebuildCharacter()
  }
}
