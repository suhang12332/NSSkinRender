//
//  SkinRenderView.swift
//  SkinRenderKit
//
//  Main SwiftUI View for rendering Minecraft character skins with drag-and-drop support
//

import SwiftUI
import AppKit
internal import UniformTypeIdentifiers

/// Main SwiftUI View for rendering Minecraft character skins
/// Provides a simple interface for displaying character models with drag-and-drop texture customization
public struct SkinRenderView: View {

  @State private var texturePath: String?
  @State private var internalSkinImage: NSImage?
  
  // External binding for skin (optional)
  private var externalSkinImageBinding: Binding<NSImage?>?
  
  // External binding for skin path (optional)
  private var externalTexturePathBinding: Binding<String?>?
  
  // External binding for cape (required, cape only supports Binding)
  private var capeImageBinding: Binding<NSImage?>?
  
  // Auxiliary state for tracking external binding changes
  @State private var externalCapeImageTracker: NSImage?
  
  // Computed property: current skin value
  private var currentSkinImage: NSImage? {
    externalSkinImageBinding?.wrappedValue ?? internalSkinImage
  }
  
  // Computed property: current texture path value
  private var currentTexturePath: String? {
    externalTexturePathBinding?.wrappedValue ?? texturePath
  }
  
  // Computed property: current cape value (Binding only)
  private var currentCapeImage: NSImage? {
    capeImageBinding?.wrappedValue
  }

  let playerModel: PlayerModel
  let rotationDuration: TimeInterval
  let backgroundColor: NSColor

  public let onSkinDropped: ((NSImage) -> Void)?
  public let onCapeDropped: ((NSImage) -> Void)?

  /// Initialize with texture path for skin (cape must use Binding)
  public init(
    texturePath: String? = nil,
    capeImage: Binding<NSImage?>? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: texturePath)
    self._internalSkinImage = State(initialValue: nil)
    self.externalSkinImageBinding = nil
    self.externalTexturePathBinding = nil
    self.capeImageBinding = capeImage
    self._externalCapeImageTracker = State(initialValue: capeImage?.wrappedValue)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }
  
  /// Initialize with texture path binding for skin (cape must use Binding)
  public init(
    texturePath: Binding<String?>,
    capeImage: Binding<NSImage?>? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: texturePath.wrappedValue)
    self._internalSkinImage = State(initialValue: nil)
    self.externalSkinImageBinding = nil
    self.externalTexturePathBinding = texturePath
    self.capeImageBinding = capeImage
    self._externalCapeImageTracker = State(initialValue: capeImage?.wrappedValue)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  /// Initialize with direct NSImage texture for skin (cape must use Binding)
  public init(
    skinImage: NSImage,
    capeImage: Binding<NSImage?>? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: nil)
    self._internalSkinImage = State(initialValue: skinImage)
    self.externalSkinImageBinding = nil
    self.externalTexturePathBinding = nil
    self.capeImageBinding = capeImage
    self._externalCapeImageTracker = State(initialValue: capeImage?.wrappedValue)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }
  
  /// Initialize with skin image binding (cape must use Binding)
  public init(
    skinImage: Binding<NSImage?>,
    capeImage: Binding<NSImage?>? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .clear,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: nil)
    self._internalSkinImage = State(initialValue: nil)
    self.externalSkinImageBinding = skinImage
    self.externalTexturePathBinding = nil
    self.capeImageBinding = capeImage
    self._externalCapeImageTracker = State(initialValue: capeImage?.wrappedValue)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  public var body: some View {
    // If using external binding, check and sync tracker
    let currentCapeImage = currentCapeImage
    let currentSkinImage = currentSkinImage
    let currentTexturePath = currentTexturePath
    
    return Group {
      if let skinImage = currentSkinImage {
        SceneKitCharacterViewRepresentable(
          skinImage: skinImage,
          capeImage: currentCapeImage,
          playerModel: playerModel,
          rotationDuration: rotationDuration,
          backgroundColor: backgroundColor,
          debugMode: false
        )
      } else {
        SceneKitCharacterViewRepresentable(
          texturePath: currentTexturePath,
          capeImage: currentCapeImage,
          playerModel: playerModel,
          rotationDuration: rotationDuration,
          backgroundColor: backgroundColor,
          debugMode: false
        )
      }
    }
    .frame(minWidth: 400, minHeight: 300)
    .contentShape(Rectangle())
    .onTapGesture {
      showFileImporter()
    }
    .onDrop(
      of: [UTType.image, UTType.fileURL, UTType.png, UTType.jpeg],
      isTargeted: nil
    ) { providers in
      handleDrop(providers: providers, target: .skin)
    }
    // No longer relying on renderKey / .id to force NSViewController rebuild;
    // let SceneKitCharacterViewRepresentable's updateNSViewController handle update logic
  }

  private enum DropTarget {
    case skin, cape
  }

  private func handleDrop(providers: [NSItemProvider], target: DropTarget) -> Bool {
    guard let provider = providers.first else {
      showDropError("No drag content detected")
      return false
    }

    ImageDropHandler.loadImage(from: provider) { image in
      DispatchQueue.main.async {
        guard let image = image else {
          showDropError("Failed to read image data")
          return
        }

        switch target {
        case .skin:
          handleSkinDrop(image)
        case .cape:
          handleCapeDrop(image)
        }
      }
    }

    return true
  }

  private func handleSkinDrop(_ image: NSImage) {
    switch ImageDropHandler.validateSkin(image) {
    case .valid(let validImage):
      // Update state on skin change, let SceneKitCharacterViewRepresentable drive partial refresh
      if let binding = externalSkinImageBinding {
        binding.wrappedValue = validImage
        // If there is a path binding, clear it
        externalTexturePathBinding?.wrappedValue = nil
      } else {
        internalSkinImage = validImage
        texturePath = nil
      }
      onSkinDropped?(validImage)
    case .invalidDimensions(let width, let height, let expected):
      showDropError("Skin size error: \(width)×\(height), need \(expected)")
    case .loadFailed(let message):
      showDropError(message)
    }
  }

  private func handleCapeDrop(_ image: NSImage) {
    switch ImageDropHandler.validateCape(image) {
    case .valid(let validImage):
      // Update binding on cape change (cape only supports Binding), let SceneKitCharacterViewRepresentable drive partial refresh
      if let binding = capeImageBinding {
        binding.wrappedValue = validImage
        onCapeDropped?(validImage)
      } else {
        showDropError("Cape requires Binding. Please use capeImage: Binding<NSImage?> parameter.")
      }
    case .invalidDimensions(let width, let height, let expected):
      showDropError("Cape size error: \(width)×\(height), need \(expected)")
    case .loadFailed(let message):
      showDropError(message)
    }
  }

  private func showDropError(_ message: String) {
    // Debug log removed; add UI presentation logic here if user-visible alerts are needed
  }

  private func showFileImporter() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg, .image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.prompt = "Select"
    panel.message = "Select a Minecraft skin texture file (64x64 or 64x32)"

    panel.begin { response in
      if response == .OK, let url = panel.url {
        loadSkinFromFile(at: url)
      }
    }
  }

  private func loadSkinFromFile(at url: URL) {
    guard let image = NSImage(contentsOf: url) else {
      showDropError("Unable to read image file")
      return
    }

    handleSkinDrop(image)
  }
}
