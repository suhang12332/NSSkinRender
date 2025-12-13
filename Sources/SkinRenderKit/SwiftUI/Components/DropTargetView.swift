//
//  DropTargetView.swift
//  SkinRenderKit
//
//  Visual component for drag-and-drop target zones
//

import SwiftUI

/// Visual component for drag-and-drop target zones
struct DropTargetView: View {
  let title: String
  let subtitle: String
  let systemImage: String
  let isActive: Bool

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: systemImage)
        .font(.system(size: 36))
        .foregroundColor(isActive ? .accentColor : .secondary)

      Text(title)
        .font(.headline)
        .foregroundColor(isActive ? .accentColor : .primary)

      Text(subtitle)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(16)
    .frame(minWidth: 180)
    .background(
      RoundedRectangle(cornerRadius: 10)
        .fill(Color(NSColor.windowBackgroundColor).opacity(isActive ? 0.95 : 0.7))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 10)
        .stroke(
          isActive ? Color.accentColor : Color.secondary.opacity(0.3),
          style: StrokeStyle(lineWidth: isActive ? 2 : 1, dash: isActive ? [] : [6])
        )
    )
    .shadow(
      color: Color.black.opacity(isActive ? 0.15 : 0.05),
      radius: isActive ? 10 : 4,
      x: 0,
      y: 2
    )
    .contentShape(RoundedRectangle(cornerRadius: 10))
  }
}

#Preview {
  HStack {
    DropTargetView(
      title: "Skin (64x64)",
      subtitle: "PNG / JPEG",
      systemImage: "person.crop.square",
      isActive: false
    )

    DropTargetView(
      title: "Cape",
      subtitle: "PNG / JPEG, 64x32",
      systemImage: "flag.fill",
      isActive: true
    )
  }
  .padding()
}
