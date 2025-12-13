//
//  CubeFace.swift
//  SkinRenderKit
//

import Foundation
import CoreGraphics

public enum CubeFace: String, CaseIterable {
  case front, right, back, left, top, bottom

  /// Named specification for a single face texture.
  public struct Spec {
    public let face: CubeFace
    public let rect: CGRect
    public let rotate180: Bool

    public init(_ face: CubeFace, rect: CGRect, rotate180: Bool = false) {
      self.face = face
      self.rect = rect
      self.rotate180 = rotate180
    }
  }

  /// Cape face specifications in rendering order.
  public static let cape: [Spec] = [
    Spec(.front,  rect: CGRect(x: 12, y: 1, width: 10, height: 16)),
    Spec(.right,  rect: CGRect(x:  0, y: 1, width:  1, height: 16)),
    Spec(.back,   rect: CGRect(x:  1, y: 1, width: 10, height: 16)),
    Spec(.left,   rect: CGRect(x: 11, y: 1, width:  1, height: 16)),
    Spec(.top,    rect: CGRect(x:  1, y: 0, width: 10, height:  1)),
    Spec(.bottom, rect: CGRect(x: 11, y: 0, width: 10, height:  1), rotate180: true)
  ]

  // MARK: - Head
  public static let headBase: [Spec] = [
    Spec(.front,  rect: CGRect(x:  8, y: 8, width: 8, height: 8)),
    Spec(.right,  rect: CGRect(x: 16, y: 8, width: 8, height: 8)),
    Spec(.back,   rect: CGRect(x: 24, y: 8, width: 8, height: 8)),
    Spec(.left,   rect: CGRect(x:  0, y: 8, width: 8, height: 8)),
    Spec(.top,    rect: CGRect(x:  8, y: 0, width: 8, height: 8)),
    Spec(.bottom, rect: CGRect(x: 16, y: 0, width: 8, height: 8))
  ]

  public static let headHat: [Spec] = [
    Spec(.front,  rect: CGRect(x: 40, y: 8, width: 8, height: 8)),
    Spec(.right,  rect: CGRect(x: 48, y: 8, width: 8, height: 8)),
    Spec(.back,   rect: CGRect(x: 56, y: 8, width: 8, height: 8)),
    Spec(.left,   rect: CGRect(x: 32, y: 8, width: 8, height: 8)),
    Spec(.top,    rect: CGRect(x: 40, y: 0, width: 8, height: 8)),
    Spec(.bottom, rect: CGRect(x: 48, y: 0, width: 8, height: 8))
  ]

  // MARK: - Body
  public static let bodyBase: [Spec] = [
    Spec(.front,  rect: CGRect(x: 20, y: 20, width: 8, height: 12)),
    Spec(.right,  rect: CGRect(x: 28, y: 20, width: 4, height: 12)),
    Spec(.back,   rect: CGRect(x: 32, y: 20, width: 8, height: 12)),
    Spec(.left,   rect: CGRect(x: 16, y: 20, width: 4, height: 12)),
    Spec(.top,    rect: CGRect(x: 20, y: 16, width: 8, height:  4)),
    Spec(.bottom, rect: CGRect(x: 28, y: 16, width: 8, height:  4))
  ]

  public static let bodyJacket: [Spec] = [
    Spec(.front,  rect: CGRect(x: 20, y: 36, width: 8, height: 12)),
    Spec(.right,  rect: CGRect(x: 28, y: 36, width: 4, height: 12)),
    Spec(.back,   rect: CGRect(x: 32, y: 36, width: 8, height: 12)),
    Spec(.left,   rect: CGRect(x: 16, y: 36, width: 4, height: 12)),
    Spec(.top,    rect: CGRect(x: 20, y: 32, width: 8, height:  4)),
    Spec(.bottom, rect: CGRect(x: 28, y: 32, width: 8, height:  4))
  ]

  // MARK: - Arms
  public static func armBase(isLeft: Bool, armWidth: CGFloat) -> [Spec] {
    if isLeft {
      return [
        Spec(.front,  rect: CGRect(x: 36, y: 52, width: armWidth, height: 12)),
        Spec(.right,  rect: CGRect(x: 36 + armWidth, y: 52, width: 4, height: 12)),
        Spec(.back,   rect: CGRect(x: 36 + armWidth + 4, y: 52, width: armWidth, height: 12)),
        Spec(.left,   rect: CGRect(x: 32, y: 52, width: 4, height: 12)),
        Spec(.top,    rect: CGRect(x: 36, y: 48, width: armWidth, height: 4)),
        Spec(.bottom, rect: CGRect(x: 36 + armWidth, y: 48, width: armWidth, height: 4))
      ]
    } else {
      return [
        Spec(.front,  rect: CGRect(x: 44, y: 20, width: armWidth, height: 12)),
        Spec(.right,  rect: CGRect(x: 44 + armWidth, y: 20, width: 4, height: 12)),
        Spec(.back,   rect: CGRect(x: 44 + armWidth + 4, y: 20, width: armWidth, height: 12)),
        Spec(.left,   rect: CGRect(x: 40, y: 20, width: 4, height: 12)),
        Spec(.top,    rect: CGRect(x: 44, y: 16, width: armWidth, height: 4)),
        Spec(.bottom, rect: CGRect(x: 44 + armWidth, y: 16, width: armWidth, height: 4))
      ]
    }
  }

  public static func armSleeve(isLeft: Bool, armWidth: CGFloat) -> [Spec] {
    if isLeft {
      return [
        Spec(.front,  rect: CGRect(x: 52, y: 52, width: armWidth, height: 12)),
        Spec(.right,  rect: CGRect(x: 52 + armWidth, y: 52, width: 4, height: 12)),
        Spec(.back,   rect: CGRect(x: 52 + armWidth + 4, y: 52, width: armWidth, height: 12)),
        Spec(.left,   rect: CGRect(x: 48, y: 52, width: 4, height: 12)),
        Spec(.top,    rect: CGRect(x: 52, y: 48, width: armWidth, height: 4)),
        Spec(.bottom, rect: CGRect(x: 52 + armWidth, y: 48, width: armWidth, height: 4))
      ]
    } else {
      return [
        Spec(.front,  rect: CGRect(x: 44, y: 36, width: armWidth, height: 12)),
        Spec(.right,  rect: CGRect(x: 44 + armWidth, y: 36, width: 4, height: 12)),
        Spec(.back,   rect: CGRect(x: 44 + armWidth + 4, y: 36, width: armWidth, height: 12)),
        Spec(.left,   rect: CGRect(x: 40, y: 36, width: 4, height: 12)),
        Spec(.top,    rect: CGRect(x: 44, y: 32, width: armWidth, height: 4)),
        Spec(.bottom, rect: CGRect(x: 44 + armWidth, y: 32, width: armWidth, height: 4))
      ]
    }
  }

  // MARK: - Elytra (Wings)
  /// Left wing texture specification for plane rendering
  /// The left wing uses the main wing texture from the elytra texture (64x32)
  public static let elytraLeftWing: Spec = Spec(.front, rect: CGRect(x: 12, y: 0, width: 10, height: 20))

  /// Right wing texture specification for plane rendering
  /// The right wing mirrors the left wing texture
  public static let elytraRightWing: Spec = Spec(.front, rect: CGRect(x: 22, y: 0, width: 10, height: 20))

  // MARK: - Legs
  public static func legBase(isLeft: Bool) -> [Spec] {
    if isLeft {
      return [
        Spec(.front,  rect: CGRect(x: 20, y: 52, width: 4, height: 12)),
        Spec(.right,  rect: CGRect(x: 24, y: 52, width: 4, height: 12)),
        Spec(.back,   rect: CGRect(x: 28, y: 52, width: 4, height: 12)),
        Spec(.left,   rect: CGRect(x: 16, y: 52, width: 4, height: 12)),
        Spec(.top,    rect: CGRect(x: 20, y: 48, width: 4, height:  4)),
        Spec(.bottom, rect: CGRect(x: 24, y: 48, width: 4, height:  4))
      ]
    } else {
      return [
        Spec(.front,  rect: CGRect(x:  4, y: 20, width: 4, height: 12)),
        Spec(.right,  rect: CGRect(x:  8, y: 20, width: 4, height: 12)),
        Spec(.back,   rect: CGRect(x: 12, y: 20, width: 4, height: 12)),
        Spec(.left,   rect: CGRect(x:  0, y: 20, width: 4, height: 12)),
        Spec(.top,    rect: CGRect(x:  4, y: 16, width: 4, height:  4)),
        Spec(.bottom, rect: CGRect(x:  8, y: 16, width: 4, height:  4))
      ]
    }
  }

  public static func legSleeve(isLeft: Bool) -> [Spec] {
    if isLeft {
      return [
        Spec(.front,  rect: CGRect(x:  4, y: 52, width: 4, height: 12)),
        Spec(.right,  rect: CGRect(x:  8, y: 52, width: 4, height: 12)),
        Spec(.back,   rect: CGRect(x: 12, y: 52, width: 4, height: 12)),
        Spec(.left,   rect: CGRect(x:  0, y: 52, width: 4, height: 12)),
        Spec(.top,    rect: CGRect(x:  4, y: 48, width: 4, height:  4)),
        Spec(.bottom, rect: CGRect(x:  8, y: 48, width: 4, height:  4))
      ]
    } else {
      return [
        Spec(.front,  rect: CGRect(x:  4, y: 36, width: 4, height: 12)),
        Spec(.right,  rect: CGRect(x:  8, y: 36, width: 4, height: 12)),
        Spec(.back,   rect: CGRect(x: 12, y: 36, width: 4, height: 12)),
        Spec(.left,   rect: CGRect(x:  0, y: 36, width: 4, height: 12)),
        Spec(.top,    rect: CGRect(x:  4, y: 32, width: 4, height:  4)),
        Spec(.bottom, rect: CGRect(x:  8, y: 32, width: 4, height:  4))
      ]
    }
  }
}
