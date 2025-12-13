//
//  SkinRenderView.swift
//  SkinRenderKit
//
//  Main SwiftUI View for rendering Minecraft character skins with drag-and-drop support
//

import SwiftUI
internal import UniformTypeIdentifiers

/// Main SwiftUI View for rendering Minecraft character skins
/// Provides a simple interface for displaying character models with drag-and-drop texture customization
public struct SkinRenderView: View {

  // MARK: - State

  @State private var texturePath: String?
  @State private var skinImage: NSImage?
  @State private var capeTexturePath: String?
  @State private var capeImage: NSImage?

  // MARK: - Drag State

  @State private var isDragOverSkin: Bool = false
  @State private var isDragOverCape: Bool = false
  @State private var isDraggingAny: Bool = false
  @State private var dropError: String?

  // MARK: - Configuration

  let playerModel: PlayerModel
  let rotationDuration: TimeInterval
  let backgroundColor: NSColor

  // MARK: - Callbacks

  public let onSkinDropped: ((NSImage) -> Void)?
  public let onCapeDropped: ((NSImage) -> Void)?

  // MARK: - Initialization

  /// Initialize with an optional texture path
  public init(
    texturePath: String? = nil,
    capeTexturePath: String? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: texturePath)
    self._skinImage = State(initialValue: nil)
    self._capeTexturePath = State(initialValue: capeTexturePath)
    self._capeImage = State(initialValue: nil)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  /// Initialize with a direct NSImage texture
  public init(
    skinImage: NSImage,
    capeImage: NSImage? = nil,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: nil)
    self._skinImage = State(initialValue: skinImage)
    self._capeTexturePath = State(initialValue: nil)
    self._capeImage = State(initialValue: capeImage)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  /// Initialize with mixed texture inputs
  public init(
    texturePath: String? = nil,
    capeImage: NSImage,
    playerModel: PlayerModel = .steve,
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray,
    onSkinDropped: ((NSImage) -> Void)? = nil,
    onCapeDropped: ((NSImage) -> Void)? = nil
  ) {
    self._texturePath = State(initialValue: texturePath)
    self._skinImage = State(initialValue: nil)
    self._capeTexturePath = State(initialValue: nil)
    self._capeImage = State(initialValue: capeImage)
    self.playerModel = playerModel
    self.rotationDuration = rotationDuration
    self.backgroundColor = backgroundColor
    self.onSkinDropped = onSkinDropped
    self.onCapeDropped = onCapeDropped
  }

  // MARK: - Body

  public var body: some View {
    Group {
      if let skinImage = skinImage {
        SceneKitCharacterViewRepresentable(
          skinImage: skinImage,
          capeImage: capeImage,
          playerModel: playerModel,
          rotationDuration: rotationDuration,
          backgroundColor: backgroundColor,
          debugMode: false
        )
      } else {
        SceneKitCharacterViewRepresentable(
          texturePath: texturePath,
          capeTexturePath: capeTexturePath,
          playerModel: playerModel,
          rotationDuration: rotationDuration,
          backgroundColor: backgroundColor,
          debugMode: false
        )
      }
    }
    .frame(minWidth: 400, minHeight: 300)
    .overlay(dropOverlay)
    .onDrop(of: [.fileURL, .png, .jpeg, .image], isTargeted: $isDraggingAny) { providers in
      handleDrop(providers: providers, target: .skin)
    }
  }

  // MARK: - Drop Overlay

  @ViewBuilder
  private var dropOverlay: some View {
    ZStack {
      // Global outline when dragging
      if isDraggingAny || isDragOverSkin || isDragOverCape {
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.accentColor, lineWidth: 3)
          .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
      }

      // Two drop targets overlay
      if isDraggingAny || isDragOverSkin || isDragOverCape {
        HStack(spacing: 16) {
          DropTargetView(
            title: "Skin (64x64)",
            subtitle: "PNG / JPEG, 64x64",
            systemImage: "person.crop.square",
            isActive: isDragOverSkin
          )
          .onDrop(of: [.fileURL, .png, .jpeg, .image], isTargeted: $isDragOverSkin) { providers in
            handleDrop(providers: providers, target: .skin)
          }

          DropTargetView(
            title: "Cape",
            subtitle: "PNG / JPEG, 64x32",
            systemImage: "flag.fill",
            isActive: isDragOverCape
          )
          .onDrop(of: [.fileURL, .png, .jpeg, .image], isTargeted: $isDragOverCape) { providers in
            handleDrop(providers: providers, target: .cape)
          }
        }
        .padding(24)
      }

      // Error banner
      if let error = dropError {
        VStack {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundColor(.white)
            Text(error)
              .foregroundColor(.white)
              .font(.caption)
          }
          .padding(8)
          .background(Color.red.opacity(0.9), in: Capsule())
          Spacer()
        }
        .padding(.top, 12)
      }
    }
  }

  // MARK: - Drop Handling

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
      skinImage = validImage
      texturePath = nil
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
      capeImage = validImage
      capeTexturePath = nil
      onCapeDropped?(validImage)
    case .invalidDimensions(let width, let height, let expected):
      showDropError("Cape size error: \(width)×\(height), need \(expected)")
    case .loadFailed(let message):
      showDropError(message)
    }
  }

  private func showDropError(_ message: String) {
    dropError = message
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
      withAnimation { dropError = nil }
    }
  }
}
