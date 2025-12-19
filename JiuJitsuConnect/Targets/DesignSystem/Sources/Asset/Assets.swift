// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif
#if canImport(SwiftUI)
  import SwiftUI
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
public typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum Assets {
  public enum Common {
    public enum Icon {
      public static let check = ImageAsset(name: "Common/Icon/check")
      public static let chevronLeft = ImageAsset(name: "Common/Icon/chevron-left")
      public static let chevronRight = ImageAsset(name: "Common/Icon/chevron-right")
      public static let documents = ImageAsset(name: "Common/Icon/documents")
      public static let logOut = ImageAsset(name: "Common/Icon/log-out")
      public static let profile = ImageAsset(name: "Common/Icon/profile")
      public static let secession = ImageAsset(name: "Common/Icon/secession")
      public static let version = ImageAsset(name: "Common/Icon/version")
    }
  }
  public enum Login {
    public enum Logo {
      public static let apple = ImageAsset(name: "Login/Logo/apple")
      public static let google = ImageAsset(name: "Login/Logo/google")
      public static let kakao = ImageAsset(name: "Login/Logo/kakao")
    }
  }
  public enum MyProfile {
    public enum Card {
      public static let styleArmLock = ImageAsset(name: "MyProfile/Card/style-arm-lock")
      public static let styleEscapeDefense = ImageAsset(name: "MyProfile/Card/style-escape-defense")
      public static let styleGuardPosition = ImageAsset(name: "MyProfile/Card/style-guard-position")
      public static let styleTopPosition = ImageAsset(name: "MyProfile/Card/style-top-position")
    }
    public enum Icon {
      public static let beltBlack = ImageAsset(name: "MyProfile/Icon/belt-black")
      public static let beltBlue = ImageAsset(name: "MyProfile/Icon/belt-blue")
      public static let beltBrown = ImageAsset(name: "MyProfile/Icon/belt-brown")
      public static let beltPurple = ImageAsset(name: "MyProfile/Icon/belt-purple")
      public static let beltWhite = ImageAsset(name: "MyProfile/Icon/belt-white")
      public static let styleArmLock = ImageAsset(name: "MyProfile/Icon/style-arm-lock")
      public static let styleChoke = ImageAsset(name: "MyProfile/Icon/style-choke")
      public static let styleEscapeDefense = ImageAsset(name: "MyProfile/Icon/style-escape-defense")
      public static let styleGuardPass = ImageAsset(name: "MyProfile/Icon/style-guard-pass")
      public static let styleGuardPosition = ImageAsset(name: "MyProfile/Icon/style-guard-position")
      public static let styleLegLock = ImageAsset(name: "MyProfile/Icon/style-leg-lock")
      public static let styleSweep = ImageAsset(name: "MyProfile/Icon/style-sweep")
      public static let styleTopPosition = ImageAsset(name: "MyProfile/Icon/style-top-position")
    }
  }
  public enum Signup {
    public enum Icon {
      public static let signupComplete = ImageAsset(name: "Signup/Icon/signup-complete")
    }
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

public struct ImageAsset {
  public fileprivate(set) var name: String

  #if os(macOS)
  public typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  public typealias Image = UIImage
  #endif

  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, macOS 10.7, *)
  public var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }

  #if os(iOS) || os(tvOS)
  @available(iOS 8.0, tvOS 9.0, *)
  public func image(compatibleWith traitCollection: UITraitCollection) -> Image {
    let bundle = BundleToken.bundle
    guard let result = Image(named: name, in: bundle, compatibleWith: traitCollection) else {
      fatalError("Unable to load image asset named \(name).")
    }
    return result
  }
  #endif

  #if canImport(SwiftUI)
  @available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
  public var swiftUIImage: SwiftUI.Image {
    SwiftUI.Image(asset: self)
  }
  #endif
}

public extension ImageAsset.Image {
  @available(iOS 8.0, tvOS 9.0, watchOS 2.0, *)
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init?(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

#if canImport(SwiftUI)
@available(iOS 13.0, tvOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension SwiftUI.Image {
  init(asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle)
  }

  init(asset: ImageAsset, label: Text) {
    let bundle = BundleToken.bundle
    self.init(asset.name, bundle: bundle, label: label)
  }

  init(decorative asset: ImageAsset) {
    let bundle = BundleToken.bundle
    self.init(decorative: asset.name, bundle: bundle)
  }
}
#endif

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
