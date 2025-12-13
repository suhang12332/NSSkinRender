//
//  EmbeddedTextures.swift
//  SkinRenderKit
//
//  Embedded default texture data (base64 encoded)

import AppKit

enum EmbeddedTextures {

  // MARK: - Base64 Encoded Data

  /// Alex skin texture (64x64 PNG, base64 encoded)
  static let alexBase64 = """
  iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAMAAACdt4HsAAAAUVBMVEX///+qlUB/T0CtrbXW1ta7\
  u7suN/K5mSLGjjfPlmXS1d3UnILZ2ePar6Xa3uPiyMvjoADj4ufkpAzm6O7osjPt7vDv7/L4+Pr5\
  68z9+Ov///+0XURvAAAABnRSTlMADBAfH/Cc0qXAAAAEUUlEQVRYw+1X7ZbrJgykH7dgTOpLKbA3\
  7/+gnRlB4iR2bndPf1a7JzYWGoSExrJzQ0pOkFxaq5DW3ItQz+tv7lBKKbXipw05mAG9O5fCZVst\
  rcIF/LzOqIewN8mFrpd8ugXTvwHIjEDOjfsorx5M/RsPIJgjeyCc6c9jwDRkTLtKDnzNZr66+WPy\
  yz2NMabyBoB6XBY3f27py8m2Jw9soIcw0JrZ8j88cHMfA7Da0knnSBeMkBI+5R0NbeY4SMmeOkc9\
  AcaiKfwJCWm4U+UC7pzpMTN4HwwHj+SQkCoRIIvtfeE97Csu0Oc89fd0mt6ZngBIHFy+Xr3+sXQZ\
  Z4pL1akfYVue9a5xVGqZALjlg8YZtJ/6CfCsd60Z4HWILYljb8u0qQ8GEJ71jhWEvxbMPoyhDDnR\
  uWa1JYRwG+oAlNsxBQ/AegZqljTDVxTycZQUq/u83TnPZa9ofYP0lhTxewZYKi8Avyo1a98r+sbR\
  1hOe9zWnHUA79CBl/whw4ejSc/K9+3sFIoGvACkxo/7ae9F+ufd+gQvbpTdFWMKDlbGDJr7Ku7Im\
  ADwAADdclPpGF2jPjNX6MY4N+AAIlXVSdgA66wBoCjlmMc3r9boy08T8+OvvanzEImV2WSk7ANaK\
  eZB0uIBUURlLFTtlAvwoqgdpq9H3jutYVvKAi6SqE0QAHaQK++9AqNmYrikIe8qTfQz0AJ7UVOUT\
  t5BlUA2AfjMQcqDt6Zn2KwEaiAMAjZ6zuJdcLIQE+Khmnywxu8PluH4MywAoTCrsUBlB4Sz1hwGQ\
  5GKKlpi4T2NceW4BkNKGP8YRMeiKQTYE2FcRUIx6/VXjOJNtsTrs/QKkZcFCcCL0ayAxEoEAfCXQ\
  Pm4E2IwNTSYPdAivyCVWQ0wCXzLi6QL7HE3qupa13gG+3QFw/njFgas6md6gdL7xb7PW9XLZLus6\
  6+HbH+5/+W8EofZ28zVzloO/3X7afvCB3bv8eScGHwwAl74AID4YlfkVAOMD3cefAqR20MCKDwZA\
  Se+aMPKBWs4nPgjD3q1pSe88JR8YwI4P/HLvuMLiz50ffCAO2fPBq/x++DQucQlxMQ+WEbTPCFos\
  H/xsM3z4SWpFILeIk48P38rnETcGugEggv8agP0CeoIHgPYZAPUH/tHl9uTR+/2XrqYC1Dq+H9gT\
  5JRHg3Bs5WfHwFkE4FQDqEUNhb4V8O49qVbPDlx//G6jB2obsixLs85Ajek5gHiBAPJgjAXAlmB0\
  B+xMjwHY7/OViwZaHoxxzXF8zBVrTMrJd1vQFwP4jB04PJhjAtAFdd1y4BRg1TeHABoBbEwAdgTW\
  t9MnAbSXmkWZcE282w1gN9ayUd8eZATF4HkshIA185JWNCFdnS7HaBj0SRxpkfKeD/bjCeJBDmG9\
  2Gv+GhZ0C5sAWP+02PPBfvx4jEefMAXtgPqB2R9MPgA9xMkPjwCjT5iCdkD9wOwPJh+QHkgL/wAy\
  E5BEy5xLAgAAAABJRU5ErkJggg==
  """

  /// Default cape texture (64x32 PNG, base64 encoded)
  static let capeBase64 = """
  iVBORw0KGgoAAAANSUhEUgAAAEAAAAAgCAMAAACVQ462AAAABGdBTUEAALGPC/xhBQAAAB5QTFRFAAAA\
  +tmf+sBP+qor1YgZsGwCkloVakAVMyEREwAAHAdBvAAAAAF0Uk5TAEDm2GYAAAD9SURBVHja7c9BbgIx\
  EERRp/pXd+f+Fw4ZC4IGGyFWWfAP8FQ1BllHyfet8VdcAnvsKkRmgqi+dQ+M51Wir0siF8Ak5ogd4KrK\
  zCpvAWYbgPwV7NwBI5CwM3eAM4FkAvUAQByCdwDp58AhRMQGiG7THVvAU5BiCVhdUK0rUA9AHELAGkDu\
  tjiAWgGKAIyWQJq+FPYekMJGOyC6agJ1BXwWbAm8BIgKVTCBWgG427bXQIgQd0A9AHKXu4sV4JBC0gHM\
  ujXuQ4LuspaAJhDPAPsAWAFcAW5A9emsPS94vNoZoNvgtwEUgDNfBhhLwS8DOi+SIoC3gYH12/j06Z/2\
  A2f3DGXX7SvhAAAAAElFTkSuQmCC
  """

  // MARK: - Image Accessors

  /// Returns the default Alex skin as NSImage
  static var alexImage: NSImage? {
    guard let data = Data(base64Encoded: alexBase64, options: .ignoreUnknownCharacters) else {
      return nil
    }
    return NSImage(data: data)
  }

  /// Returns the default cape as NSImage
  static var capeImage: NSImage? {
    guard let data = Data(base64Encoded: capeBase64, options: .ignoreUnknownCharacters) else {
      return nil
    }
    return NSImage(data: data)
  }
}
