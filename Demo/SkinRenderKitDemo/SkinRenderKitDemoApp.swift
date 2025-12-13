//
//  SkinRenderKitDemoApp.swift
//  SkinRenderKitDemo
//

import SkinRenderKit
import SwiftUI

@main
struct SkinRenderSwiftUIApp: App {
  var body: some Scene {
    WindowGroup {
      SkinRenderView(playerModel: .steve, rotationDuration: 12)
        .frame(width: 700, height: 500)
    }
  }
}

#Preview("without picker") {
  SkinRenderView(playerModel: .alex, rotationDuration: 12)
    .frame(width: 700, height: 500)
}

#Preview("with picker") {
  SkinRenderDebug(rotationDuration: 12)
    .frame(width: 700, height: 700)
}
