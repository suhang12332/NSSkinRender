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
      loadDefaultTexture()
    }
  }

  func loadCapeTexture(from path: String) {
    if let image = NSImage(contentsOfFile: path) {
      self.capeImage = image
    }
  }

  func loadDefaultTexture() {
    if let resourceURL = Bundle.module.url(forResource: "alex", withExtension: "png"),
       let image = NSImage(contentsOf: resourceURL) {
      self.skinImage = image
    } else {
      self.skinImage = NSImage(named: "Skin")
    }
  }
}
