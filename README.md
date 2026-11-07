# SkinRenderKit

A Swift Package for rendering Minecraft character skins in 3D with SceneKit and SwiftUI. This package is used by [Swift Craft Launcher](https://github.com/suhang12332/Swift-Craft-Launcher).

## Features

- 3D Steve and Alex skin rendering
- Cape and elytra support with animations
- SwiftUI views and an embeddable `NSViewController`
- In-memory `NSImage` texture support
- Configurable rotation, background color, and outer layers

## Entry Points

- `SkinRenderView`: SwiftUI skin render view
- `SceneKitCharacterViewRepresentable`: SwiftUI wrapper for the SceneKit controller
- `SceneKitCharacterViewController`: AppKit character controller
- `TextureProcessor`: skin texture processing
- `PlayerModel`: Steve / Alex model definitions

## Requirements

- macOS 14+
- Swift 5.9+
