//
//  SCNGeometry+Materials.swift
//  SkinRenderKit
//

import SceneKit

extension SCNGeometry {

  /// Clear texture references from all materials to help release image memory
  func clearMaterialContents() {
    for material in materials {
      material.diffuse.contents = nil
      material.ambient.contents = nil
      material.specular.contents = nil
      material.normal.contents = nil
      material.emission.contents = nil
    }
  }
}
