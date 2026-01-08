//
//  SceneKitCharacterViewController+Convenience.swift
//  SkinRenderKit
//

import SceneKit

// MARK: - Usage Helper

extension SceneKitCharacterViewController {

  public static func presentInNewWindow(
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear
  ) {
    let characterVC = SceneKitCharacterViewController(
      playerModel: playerModel,
      rotationDuration: rotationDuration,
      backgroundColor: backgroundColor
    )
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
      styleMask: [.titled, .closable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = "SceneKit Minecraft Character - \(playerModel.displayName)"
    window.contentViewController = characterVC
    window.makeKeyAndOrderFront(nil)
  }
}

// MARK: - Convenience Initialization

extension SceneKitCharacterViewController {

  /// Primary convenience initializer - shared setup
  private convenience init(
    skinTexturePath: String? = nil,
    skinImage: NSImage? = nil,
    capeTexturePath: String? = nil,
    capeImage: NSImage? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    debugMode: Bool = false
  ) {
    self.init()
    self.skinTexturePath = skinTexturePath
    self.skinImage = skinImage
    self.capeTexturePath = capeTexturePath
    self.capeImage = capeImage
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.debugMode = debugMode

    if skinTexturePath != nil {
      loadTexture()
    }
    if let capeTexturePath = capeTexturePath {
      loadCapeTexture(from: capeTexturePath)
    }
  }

  /// Init with texture paths (cape optional)
  public convenience init(
    texturePath: String? = nil,
    capeTexturePath: String? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    debugMode: Bool = false
  ) {
    self.init(
      skinTexturePath: texturePath,
      skinImage: nil,
      capeTexturePath: capeTexturePath,
      capeImage: nil,
      playerModel: playerModel,
      rotationDuration: rotationDuration,
      backgroundColor: backgroundColor,
      debugMode: debugMode
    )
  }

  /// Init with in-memory images (cape optional)
  public convenience init(
    skinImage: NSImage,
    capeImage: NSImage? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    debugMode: Bool = false
  ) {
    self.init(
      skinTexturePath: nil,
      skinImage: skinImage,
      capeTexturePath: nil,
      capeImage: capeImage,
      playerModel: playerModel,
      rotationDuration: rotationDuration,
      backgroundColor: backgroundColor,
      debugMode: debugMode
    )
  }
}

// MARK: - Legacy Compatibility

extension SceneKitCharacterViewController {
  /// Legacy enum for backward compatibility
  public typealias LimbBottomFlipMode = TextureProcessor.FlipMode
}

#Preview {
  SceneKitCharacterViewController(rotationDuration: 12)
}
