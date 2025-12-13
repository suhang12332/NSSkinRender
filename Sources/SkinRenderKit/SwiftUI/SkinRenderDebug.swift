//
//  SkinRenderDebug.swift
//  SkinRenderKit
//
//  Debug view with file selection functionality for testing skin rendering
//

import SwiftUI
internal import UniformTypeIdentifiers

/// Debug view with file picker functionality for choosing skin textures
/// Combines the skin render view with controls for testing
public struct SkinRenderDebug: View {

  // MARK: - State

  @State private var selectedTexturePath: String?
  @State private var selectedCapeTexturePath: String?
  @State private var rotationDuration: TimeInterval
  @State private var backgroundColor: NSColor

  // MARK: - Initialization

  public init(
    rotationDuration: TimeInterval = 15.0,
    backgroundColor: NSColor = .gray
  ) {
    self._rotationDuration = State(initialValue: rotationDuration)
    self._backgroundColor = State(initialValue: backgroundColor)
  }

  // MARK: - Body

  public var body: some View {
    VStack {
      // File selection controls
      HStack {
        Button("Select Skin Texture") {
          showFileImporter()
        }
        .padding()

        Button("Select Cape Texture") {
          showCapeFileImporter()
        }
        .padding()

        Spacer()
      }

      // Selected file names
      selectedFilesInfo

      // Rotation speed control
      rotationControl

      // Background color control
      colorControl

      // Character view
      SceneKitCharacterViewRepresentable(
        texturePath: selectedTexturePath,
        capeTexturePath: selectedCapeTexturePath,
        rotationDuration: rotationDuration,
        backgroundColor: backgroundColor,
        debugMode: true
      )
      .frame(minWidth: 400, minHeight: 300)
    }
  }

  // MARK: - Subviews

  @ViewBuilder
  private var selectedFilesInfo: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let path = selectedTexturePath {
        HStack {
          Text("Skin:")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(URL(fileURLWithPath: path).lastPathComponent)
            .font(.caption)
            .foregroundColor(.primary)
            .lineLimit(1)
            .truncationMode(.middle)
          Spacer()
        }
      }

      if let path = selectedCapeTexturePath {
        HStack {
          Text("Cape:")
            .font(.caption)
            .foregroundColor(.secondary)
          Text(URL(fileURLWithPath: path).lastPathComponent)
            .font(.caption)
            .foregroundColor(.primary)
            .lineLimit(1)
            .truncationMode(.middle)

          Button("✕") {
            selectedCapeTexturePath = nil
          }
          .font(.caption)
          .foregroundColor(.secondary)

          Spacer()
        }
      }
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  private var rotationControl: some View {
    HStack {
      Text("Rotation Speed:")
        .font(.caption)

      Slider(value: $rotationDuration, in: 0...15, step: 1) {
        Text("Rotation Duration")
      }
      .frame(width: 300)

      Text(rotationDuration == 0 ? "Static" : String(format: "%.1fs", rotationDuration))
        .font(.caption)
        .foregroundColor(.secondary)
        .frame(width: 50, alignment: .leading)
    }
    .padding(.horizontal)
  }

  @ViewBuilder
  private var colorControl: some View {
    HStack {
      Text("Background Color:")
        .font(.caption)

      ColorPicker(
        "",
        selection: Binding(
          get: { Color(backgroundColor) },
          set: { backgroundColor = NSColor($0) }
        )
      )
      .frame(width: 50)
      .labelsHidden()

      Spacer()
    }
    .padding(.horizontal)
  }

  // MARK: - File Importers

  private func showFileImporter() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg, .image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.prompt = "Select"
    panel.message = "Choose a Minecraft skin texture file"

    panel.begin { response in
      if response == .OK, let url = panel.url {
        selectedTexturePath = url.path
      }
    }
  }

  private func showCapeFileImporter() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.png, .jpeg, .image]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.canChooseFiles = true
    panel.prompt = "Select"
    panel.message = "Choose a Minecraft cape texture file (64x32 pixels)"

    panel.begin { response in
      if response == .OK, let url = panel.url {
        selectedCapeTexturePath = url.path
      }
    }
  }
}

#Preview {
  SkinRenderDebug()
}
