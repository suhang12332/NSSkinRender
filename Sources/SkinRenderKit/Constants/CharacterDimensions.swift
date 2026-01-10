//
//  CharacterDimensions.swift
//  SkinRenderKit
//
//  Centralized constants for Minecraft character geometry
//

import CoreGraphics
import SceneKit

/// Minecraft character geometry constants
public enum CharacterDimensions {

  // MARK: - Head

  /// Base head size (8x8x8 pixels)
  public static let headSize: CGFloat = 8

  /// Hat overlay size (8.25x8.25x8.25 pixels, thickness 0.25)
  public static let hatSize: CGFloat = 8.25

  /// Head center Y position
  public static let headY: CGFloat = 16

  // MARK: - Global Scale

  /// Global character scale factor (1.0 = original size)
  /// 调小一点让模型在画面中显得更小
  public static let globalScale: CGFloat = 0.8

  /// Global Y position offset for the character root node
  /// 上移模型位置
  public static let globalYOffset: CGFloat = 3.0

  // MARK: - Body

  /// Body width (8 pixels)
  public static let bodyWidth: CGFloat = 8

  /// Body height (12 pixels)
  public static let bodyHeight: CGFloat = 12

  /// Body depth (4 pixels)
  public static let bodyDepth: CGFloat = 4

  /// Body center Y position
  public static let bodyY: CGFloat = 6

  /// Jacket overlay width (thickness 0.125)
  public static let jacketWidth: CGFloat = 8.125

  /// Jacket overlay height (thickness 0.125)
  public static let jacketHeight: CGFloat = 12.125

  /// Jacket overlay depth (thickness 0.125)
  public static let jacketDepth: CGFloat = 4.125

  // MARK: - Legs

  /// Leg width (4 pixels)
  public static let legWidth: CGFloat = 4

  /// Leg height (12 pixels)
  public static let legHeight: CGFloat = 12

  /// Leg depth (4 pixels)
  public static let legDepth: CGFloat = 4

  /// Leg sleeve overlay width
  public static let legSleeveWidth: CGFloat = 4.5

  /// Leg sleeve overlay height
  public static let legSleeveHeight: CGFloat = 12.5

  /// Leg sleeve overlay depth
  public static let legSleeveDepth: CGFloat = 4.5

  /// Right leg X position
  public static let rightLegX: CGFloat = -2

  /// Left leg X position
  public static let leftLegX: CGFloat = 2

  /// Leg Y offset from group pivot
  public static let legYOffset: CGFloat = -6

  /// Leg sleeve Y offset from group pivot
  public static let legSleeveYOffset: CGFloat = -6.25

  // MARK: - Cape

  /// Cape width (10 pixels)
  public static let capeWidth: CGFloat = 10

  /// Cape height (16 pixels)
  public static let capeHeight: CGFloat = 16

  /// Cape depth/thickness (1 pixel)
  public static let capeDepth: CGFloat = 1.0

  /// Cape pivot Y position (shoulder line)
  public static let capePivotY: CGFloat = 11

  /// Cape pivot Z position (behind body)
  public static let capePivotZ: CGFloat = -2.5

  /// Cape Y offset from pivot
  public static let capeYOffset: CGFloat = -8

  /// Cape base backward tilt angle (~12.8°)
  public static let capeBaseAngle: Float = .pi / 14

  // MARK: - Elytra

  /// Elytra wing width (10 pixels)
  public static let elytraWingWidth: CGFloat = 10

  /// Elytra wing height (20 pixels)
  public static let elytraWingHeight: CGFloat = 20

  /// Elytra pivot Y position (shoulder line, same as cape)
  public static let elytraPivotY: CGFloat = 11

  /// Elytra pivot Z position (behind body, same as cape)
  public static let elytraPivotZ: CGFloat = -2.5

  /// Elytra wing Y offset from pivot
  public static let elytraWingYOffset: CGFloat = -10

  /// Elytra wing X offset (horizontal distance from center)
  public static let elytraWingXOffset: CGFloat = 5.5

  /// Elytra base fold angle when not flying (wings folded, ~30°)
  public static let elytraFoldAngle: Float = .pi / 6

  /// Elytra Z offset for tilted appearance (forward/backward tilt)
  public static let elytraWingZOffset: CGFloat = 0.5

  /// Elytra backward tilt angle for natural appearance
  public static let elytraTiltAngle: Float = .pi / 12  // ~15°

  // MARK: - Camera

  /// Default camera position
  public static let cameraPosition = SCNVector3(0, 6, 35)

  /// Default camera look-at target
  public static let cameraTarget = SCNVector3(0, 6, 0)

  // MARK: - Rendering Order

  /// Rendering order priorities for Z-fighting prevention
  public enum RenderingOrder {
    /// Base body parts (lowest)
    public static let baseBody: Int = 100

    /// Base limbs (slightly higher than body)
    public static let baseLimbs: Int = 105

    /// Cape (between base and outer)
    public static let cape: Int = 150

    /// Outer overlay layers
    public static let outerLayers: Int = 200

    /// Outer limb overlays (highest)
    public static let outerLimbs: Int = 210
  }

  // MARK: - Animation

  /// Animation configuration constants
  public enum Animation {
    /// Default rotation duration (seconds)
    public static let defaultRotationDuration: TimeInterval = 15.0

    /// Arm swing amplitude during walking (45°)
    public static let armSwingAmplitude: CGFloat = .pi / 4

    /// Leg swing amplitude during walking (36°)
    public static let legSwingAmplitude: CGFloat = .pi / 5

    /// Walking cycle duration (seconds)
    public static let walkingCycleDuration: TimeInterval = 0.8

    /// Head bob distance during walking
    public static let headBobDistance: CGFloat = 0.3

    /// Cape sway base amplitude (~7.5°)
    public static let capeSwayAmplitude: Float = .pi / 24

    /// Cape sway multiplier when walking
    public static let capeSwayWalkingMultiplier: Float = 1.9

    /// Cape side sway angle
    public static let capeSideSwayAngle: Float = .pi / 40
  }

  // MARK: - Lighting

  /// Lighting configuration constants
  public enum Lighting {
    /// Ambient light intensity
    public static let ambientIntensity: CGFloat = 300

    /// Directional light intensity
    public static let directionalIntensity: CGFloat = 500

    /// Directional light euler angles
    public static let directionalAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
  }
}
