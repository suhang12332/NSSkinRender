//
//  SceneKitCharacterViewController+Setup.swift
//  SkinRenderKit
//

import SceneKit

extension SceneKitCharacterViewController {

  func setupScene() {
    scene = SCNScene()
    scnView.scene = scene
    scnView.allowsCameraControl = true
    scnView.backgroundColor = backgroundColor
    scnView.showsStatistics = debugMode
  }

  func setupCamera() {
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.position = SCNVector3(0, 16, 36)
    cameraNode.look(at: SCNVector3(0, 6, 0))
    scene.rootNode.addChildNode(cameraNode)
  }

  func setupLighting() {
    // Ambient light
    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light?.type = .ambient
    ambientLight.light?.intensity = 300
    scene.rootNode.addChildNode(ambientLight)

    // Directional light
    let directionalLight = SCNNode()
    directionalLight.light = SCNLight()
    directionalLight.light?.type = .directional
    directionalLight.light?.intensity = 500
    directionalLight.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 4, 0)
    scene.rootNode.addChildNode(directionalLight)
  }

  func setupUI() {
    guard debugMode else { return }
    view.addSubview(toggleButton)
    view.addSubview(modelTypeButton)
    view.addSubview(capeToggleButton)
    view.addSubview(capeAnimationButton)
    view.addSubview(walkingAnimationButton)
  }

  func setupGestureRecognizers() {
    let rightClickGesture = NSClickGestureRecognizer(
      target: self,
      action: #selector(handleRightClick(_:))
    )
    rightClickGesture.buttonMask = 0x2
    scnView.addGestureRecognizer(rightClickGesture)
  }
}
