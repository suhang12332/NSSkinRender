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
    }
  }

  func loadCapeTexture(from path: String) {
    if let image = NSImage(contentsOfFile: path) {
      self.capeImage = image
    }
  }
}
