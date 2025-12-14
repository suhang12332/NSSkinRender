//
//  CharacterAnimationController.swift
//  SkinRenderKit
//
//  Controller for managing character animations (rotation, walking, cape sway)
//

import SceneKit

/// Controller responsible for managing all character animations
public final class CharacterAnimationController {

  // MARK: - Node References

  private weak var characterNodes: CharacterNodeBuilder.CharacterNodes?

  // MARK: - Animation Configuration

  /// Duration for one complete rotation (0 = no rotation)
  public var rotationDuration: TimeInterval = CharacterDimensions.Animation.defaultRotationDuration

  /// Whether walking animation is enabled
  public private(set) var walkingEnabled: Bool = false

  /// Whether cape sway animation is enabled
  public private(set) var capeSwayEnabled: Bool = true

  // MARK: - Cape Sway Configuration

  /// Base amplitude for cape sway animation
  public var baseCapeSwayAmplitude: Float = CharacterDimensions.Animation.capeSwayAmplitude

  /// Multiplier for cape sway when walking
  public var walkingCapeSwayMultiplier: Float = CharacterDimensions.Animation.capeSwayWalkingMultiplier

  // MARK: - Walking Animation Configuration

  /// Arm swing amplitude in radians
  private let armSwingAmplitude: CGFloat = CharacterDimensions.Animation.armSwingAmplitude

  /// Leg swing amplitude in radians
  private let legSwingAmplitude: CGFloat = CharacterDimensions.Animation.legSwingAmplitude

  /// Duration for one walking cycle
  private let walkingCycleDuration: TimeInterval = CharacterDimensions.Animation.walkingCycleDuration

  /// Head bob distance
  private let headBobDistance: CGFloat = CharacterDimensions.Animation.headBobDistance

  // MARK: - Animation Keys

  private enum AnimationKey {
    static let rotation = "rotationAnimation"
    static let capeSway = "capeSwayAnimation"
    static let walkSwing = "walkSwing"
    static let headBob = "headBob"
  }

  // MARK: - Initialization

  public init() {}

  // MARK: - Attach Nodes

  /// Attach character nodes to control
  /// - Parameter nodes: The character nodes to animate
  public func attach(to nodes: CharacterNodeBuilder.CharacterNodes) {
    self.characterNodes = nodes
  }

  // MARK: - Rotation Animation

  /// Setup or update the rotation animation
  public func setupRotationAnimation() {
    guard let root = characterNodes?.root else { return }

    // Capture current rotation angle from presentation layer (actual rendered state)
    let currentRotation = root.presentation.eulerAngles.y

    // Remove existing rotation
    root.removeAction(forKey: AnimationKey.rotation)

    // Restore the current rotation angle so animation continues from here
    root.eulerAngles.y = currentRotation

    // Only add rotation if duration is positive
    guard rotationDuration > 0 else { return }

    let rotationAction = SCNAction.rotateBy(
      x: 0,
      y: CGFloat.pi * 2,
      z: 0,
      duration: rotationDuration
    )
    let repeatAction = SCNAction.repeatForever(rotationAction)
    root.runAction(repeatAction, forKey: AnimationKey.rotation)
  }

  /// Update rotation duration and restart animation
  /// - Parameter duration: New rotation duration
  public func updateRotationDuration(_ duration: TimeInterval) {
    self.rotationDuration = duration
    setupRotationAnimation()
  }

  // MARK: - Walking Animation

  /// Start the walking animation
  public func startWalkingAnimation() {
    guard let nodes = characterNodes else { return }
    walkingEnabled = true

    // Remove existing limb actions
    stopLimbActions()

    // Create swing action generator
    func swingAction(amplitude: CGFloat) -> SCNAction {
      let forward = SCNAction.rotateTo(
        x: amplitude, y: 0, z: 0,
        duration: walkingCycleDuration / 2,
        usesShortestUnitArc: true
      )
      let backward = SCNAction.rotateTo(
        x: -amplitude, y: 0, z: 0,
        duration: walkingCycleDuration / 2,
        usesShortestUnitArc: true
      )
      forward.timingMode = .easeInEaseOut
      backward.timingMode = .easeInEaseOut
      return SCNAction.repeatForever(SCNAction.sequence([forward, backward]))
    }

    // Arms: opposite phase
    nodes.rightArmGroup.runAction(
      swingAction(amplitude: armSwingAmplitude),
      forKey: AnimationKey.walkSwing
    )

    let leftArmDelay = SCNAction.wait(duration: walkingCycleDuration / 2)
    nodes.leftArmGroup.runAction(
      SCNAction.sequence([leftArmDelay, swingAction(amplitude: armSwingAmplitude)]),
      forKey: AnimationKey.walkSwing
    )

    // Legs: opposite to corresponding arm
    let rightLegDelay = SCNAction.wait(duration: walkingCycleDuration / 2)
    nodes.rightLegGroup.runAction(
      SCNAction.sequence([rightLegDelay, swingAction(amplitude: legSwingAmplitude)]),
      forKey: AnimationKey.walkSwing
    )

    nodes.leftLegGroup.runAction(
      swingAction(amplitude: legSwingAmplitude),
      forKey: AnimationKey.walkSwing
    )

    // Head bob
    setupHeadBobAnimation()

    // Refresh cape sway with walking multiplier
    if capeSwayEnabled {
      refreshCapeSwayAnimation()
    }
  }

  /// Stop the walking animation
  public func stopWalkingAnimation() {
    guard let nodes = characterNodes else { return }
    walkingEnabled = false

    // Stop limb actions
    stopLimbActions()

    // Reset limb rotations smoothly
    let limbNodes = [
      nodes.rightArmGroup,
      nodes.leftArmGroup,
      nodes.rightLegGroup,
      nodes.leftLegGroup
    ]

    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.25
    for node in limbNodes {
      node.eulerAngles.x = 0
    }
    SCNTransaction.commit()

    // Stop and reset head bob
    nodes.headGroup.removeAction(forKey: AnimationKey.headBob)
    SCNTransaction.begin()
    SCNTransaction.animationDuration = 0.25
    nodes.headGroup.position.y = CharacterDimensions.headY
    SCNTransaction.commit()

    // Refresh cape sway without walking multiplier
    if capeSwayEnabled {
      refreshCapeSwayAnimation()
    }
  }

  /// Toggle walking animation state
  public func toggleWalkingAnimation() {
    if walkingEnabled {
      stopWalkingAnimation()
    } else {
      startWalkingAnimation()
    }
  }

  private func stopLimbActions() {
    guard let nodes = characterNodes else { return }
    nodes.rightArmGroup.removeAction(forKey: AnimationKey.walkSwing)
    nodes.leftArmGroup.removeAction(forKey: AnimationKey.walkSwing)
    nodes.rightLegGroup.removeAction(forKey: AnimationKey.walkSwing)
    nodes.leftLegGroup.removeAction(forKey: AnimationKey.walkSwing)
  }

  private func setupHeadBobAnimation() {
    guard let headGroup = characterNodes?.headGroup else { return }

    headGroup.removeAction(forKey: AnimationKey.headBob)

    let up = SCNAction.moveBy(x: 0, y: headBobDistance, z: 0, duration: walkingCycleDuration / 2)
    let down = SCNAction.moveBy(x: 0, y: -headBobDistance, z: 0, duration: walkingCycleDuration / 2)
    up.timingMode = .easeInEaseOut
    down.timingMode = .easeInEaseOut

    headGroup.runAction(
      SCNAction.repeatForever(SCNAction.sequence([up, down])),
      forKey: AnimationKey.headBob
    )
  }

  // MARK: - Cape Animation

  /// Add cape sway animation
  public func addCapeSwayAnimation() {
    guard let capePivot = characterNodes?.capePivot else { return }

    let swayAmplitude = baseCapeSwayAmplitude * (walkingEnabled ? walkingCapeSwayMultiplier : 1.0)
    let capeBaseAngle = CharacterDimensions.capeBaseAngle
    let capeSideSwayAngle = CharacterDimensions.Animation.capeSideSwayAngle

    // Animation sequence: sway left, center, right, center
    let rotateLeft = SCNAction.rotateTo(
      x: CGFloat(capeBaseAngle + swayAmplitude),
      y: 0,
      z: CGFloat(capeSideSwayAngle),
      duration: 2.0
    )

    let rotateCenter = SCNAction.rotateTo(
      x: CGFloat(capeBaseAngle),
      y: 0,
      z: 0,
      duration: 1.5
    )

    let rotateRight = SCNAction.rotateTo(
      x: CGFloat(capeBaseAngle + swayAmplitude),
      y: 0,
      z: CGFloat(-capeSideSwayAngle),
      duration: 2.0
    )

    // Smooth easing
    rotateLeft.timingMode = .easeInEaseOut
    rotateCenter.timingMode = .easeInEaseOut
    rotateRight.timingMode = .easeInEaseOut

    let swaySequence = SCNAction.sequence([
      rotateLeft, rotateCenter, rotateRight, rotateCenter
    ])

    capePivot.runAction(
      SCNAction.repeatForever(swaySequence),
      forKey: AnimationKey.capeSway
    )
  }

  /// Toggle cape sway animation
  /// - Parameter enabled: Whether to enable cape animation
  public func toggleCapeAnimation(_ enabled: Bool) {
    guard let capePivot = characterNodes?.capePivot else { return }

    capeSwayEnabled = enabled

    if enabled {
      if capePivot.action(forKey: AnimationKey.capeSway) == nil {
        addCapeSwayAnimation()
      }
    } else {
      capePivot.removeAction(forKey: AnimationKey.capeSway)
      // Reset to base rotation
      capePivot.eulerAngles = SCNVector3(CharacterDimensions.capeBaseAngle, 0, 0)
    }
  }

  /// Refresh cape sway animation (e.g., when walking state changes)
  public func refreshCapeSwayAnimation() {
    guard capeSwayEnabled else { return }
    characterNodes?.capePivot?.removeAction(forKey: AnimationKey.capeSway)
    addCapeSwayAnimation()
  }

  // MARK: - Reset All Animations

  /// Stop all animations and reset to default state
  public func resetAllAnimations() {
    guard let nodes = characterNodes else { return }

    // Stop rotation
    nodes.root.removeAction(forKey: AnimationKey.rotation)

    // Stop walking
    if walkingEnabled {
      stopWalkingAnimation()
    }

    // Stop cape
    toggleCapeAnimation(false)
  }
}
