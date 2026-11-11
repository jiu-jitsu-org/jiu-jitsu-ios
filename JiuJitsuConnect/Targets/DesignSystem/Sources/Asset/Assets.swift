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
  public enum Bottom {
    public enum Icon {
      public static let competition = ImageAsset(name: "Bottom/Icon/competition")
      public static let home = ImageAsset(name: "Bottom/Icon/home")
      public static let my = ImageAsset(name: "Bottom/Icon/my")
      public static let setting = ImageAsset(name: "Bottom/Icon/setting")
    }
  }
  public enum Character {
    public enum Belt {
      public enum Face {
        public static let faceAngry = ImageAsset(name: "Character/Belt/Face/face-angry")
        public static let faceBored = ImageAsset(name: "Character/Belt/Face/face-bored")
        public static let faceCalm = ImageAsset(name: "Character/Belt/Face/face-calm")
        public static let faceCross = ImageAsset(name: "Character/Belt/Face/face-cross")
        public static let faceDizzy = ImageAsset(name: "Character/Belt/Face/face-dizzy")
        public static let faceFocus = ImageAsset(name: "Character/Belt/Face/face-focus")
        public static let faceGlare = ImageAsset(name: "Character/Belt/Face/face-glare")
        public static let faceHappy = ImageAsset(name: "Character/Belt/Face/face-happy")
        public static let faceHeart = ImageAsset(name: "Character/Belt/Face/face-heart")
        public static let faceMoved = ImageAsset(name: "Character/Belt/Face/face-moved")
        public static let facePain = ImageAsset(name: "Character/Belt/Face/face-pain")
        public static let facePuzzled = ImageAsset(name: "Character/Belt/Face/face-puzzled")
        public static let faceSad = ImageAsset(name: "Character/Belt/Face/face-sad")
        public static let faceScared = ImageAsset(name: "Character/Belt/Face/face-scared")
        public static let faceShock = ImageAsset(name: "Character/Belt/Face/face-shock")
        public static let faceShy = ImageAsset(name: "Character/Belt/Face/face-shy")
        public static let faceSide = ImageAsset(name: "Character/Belt/Face/face-side")
        public static let faceSleepy = ImageAsset(name: "Character/Belt/Face/face-sleepy")
        public static let faceSmug = ImageAsset(name: "Character/Belt/Face/face-smug")
        public static let faceSquint = ImageAsset(name: "Character/Belt/Face/face-squint")
        public static let faceStar = ImageAsset(name: "Character/Belt/Face/face-star")
        public static let faceSus = ImageAsset(name: "Character/Belt/Face/face-sus")
        public static let faceSweat = ImageAsset(name: "Character/Belt/Face/face-sweat")
        public static let faceTeary = ImageAsset(name: "Character/Belt/Face/face-teary")
        public static let faceWink = ImageAsset(name: "Character/Belt/Face/face-wink")
        public static let faceWorry = ImageAsset(name: "Character/Belt/Face/face-worry")
      }
      public enum Pose {
        public static let poseBow = ImageAsset(name: "Character/Belt/Pose/pose-bow")
        public static let poseDroop = ImageAsset(name: "Character/Belt/Pose/pose-droop")
        public static let poseFlinch = ImageAsset(name: "Character/Belt/Pose/pose-flinch")
        public static let poseGreet = ImageAsset(name: "Character/Belt/Pose/pose-greet")
        public static let poseHappyLean = ImageAsset(name: "Character/Belt/Pose/pose-happy-lean")
        public static let poseHello = ImageAsset(name: "Character/Belt/Pose/pose-hello")
        public static let poseLeanIn = ImageAsset(name: "Character/Belt/Pose/pose-lean-in")
        public static let poseLookBack = ImageAsset(name: "Character/Belt/Pose/pose-look-back")
        public static let poseNod = ImageAsset(name: "Character/Belt/Pose/pose-nod")
        public static let posePeek = ImageAsset(name: "Character/Belt/Pose/pose-peek")
        public static let poseProudFar = ImageAsset(name: "Character/Belt/Pose/pose-proud-far")
        public static let poseShyBack = ImageAsset(name: "Character/Belt/Pose/pose-shy-back")
        public static let poseShyLean = ImageAsset(name: "Character/Belt/Pose/pose-shy-lean")
        public static let poseShyTurn = ImageAsset(name: "Character/Belt/Pose/pose-shy-turn")
        public static let poseStandTall = ImageAsset(name: "Character/Belt/Pose/pose-stand-tall")
        public static let poseStartle = ImageAsset(name: "Character/Belt/Pose/pose-startle")
        public static let poseStiffBack = ImageAsset(name: "Character/Belt/Pose/pose-stiff-back")
        public static let poseSulk = ImageAsset(name: "Character/Belt/Pose/pose-sulk")
        public static let poseTilt = ImageAsset(name: "Character/Belt/Pose/pose-tilt")
        public static let poseWave = ImageAsset(name: "Character/Belt/Pose/pose-wave")
        public static let poseWhisper = ImageAsset(name: "Character/Belt/Pose/pose-whisper")
        public static let poseWiggleSmall = ImageAsset(name: "Character/Belt/Pose/pose-wiggle-small")
        public static let poseWiggle = ImageAsset(name: "Character/Belt/Pose/pose-wiggle")
        public static let poseWilt = ImageAsset(name: "Character/Belt/Pose/pose-wilt")
        public static let poseZigzag = ImageAsset(name: "Character/Belt/Pose/pose-zigzag")
      }
    }
  }
  public enum Common {
    public enum Icon {
      public static let arrowLeft = ImageAsset(name: "Common/Icon/arrow-left")
      public static let avatarDefault = ImageAsset(name: "Common/Icon/avatar-default")
      public static let bell = ImageAsset(name: "Common/Icon/bell")
      public static let check = ImageAsset(name: "Common/Icon/check")
      public static let chevronLeft = ImageAsset(name: "Common/Icon/chevron-left")
      public static let chevronRight = ImageAsset(name: "Common/Icon/chevron-right")
      public static let documents = ImageAsset(name: "Common/Icon/documents")
      public static let inbox = ImageAsset(name: "Common/Icon/inbox")
      public static let logOut = ImageAsset(name: "Common/Icon/log-out")
      public static let pencil = ImageAsset(name: "Common/Icon/pencil")
      public static let pin = ImageAsset(name: "Common/Icon/pin")
      public static let plus = ImageAsset(name: "Common/Icon/plus")
      public static let profile = ImageAsset(name: "Common/Icon/profile")
      public static let radioOff = ImageAsset(name: "Common/Icon/radio-off")
      public static let radioOn = ImageAsset(name: "Common/Icon/radio-on")
      public static let search = ImageAsset(name: "Common/Icon/search")
      public static let secession = ImageAsset(name: "Common/Icon/secession")
      public static let trash = ImageAsset(name: "Common/Icon/trash")
      public static let version = ImageAsset(name: "Common/Icon/version")
    }
    public enum Shaka {
      public static let burstBlack = ImageAsset(name: "Common/Shaka/burst-black")
      public static let burstBlue = ImageAsset(name: "Common/Shaka/burst-blue")
      public static let burstBrown = ImageAsset(name: "Common/Shaka/burst-brown")
      public static let burstPurple = ImageAsset(name: "Common/Shaka/burst-purple")
      public static let burstWhite = ImageAsset(name: "Common/Shaka/burst-white")
      public static let icon = ImageAsset(name: "Common/Shaka/icon")
    }
  }
  public enum Login {
    public enum Belt {
      public static let bodyBlack = ImageAsset(name: "Login/Belt/body-black")
      public static let bodyBlue = ImageAsset(name: "Login/Belt/body-blue")
      public static let bodyBrown = ImageAsset(name: "Login/Belt/body-brown")
      public static let bodyPurple = ImageAsset(name: "Login/Belt/body-purple")
      public static let bodyWhite = ImageAsset(name: "Login/Belt/body-white")
      public static let eyesBig = ImageAsset(name: "Login/Belt/eyes-big")
      public static let eyesCurious = ImageAsset(name: "Login/Belt/eyes-curious")
      public static let eyesGlare = ImageAsset(name: "Login/Belt/eyes-glare")
      public static let eyesLash = ImageAsset(name: "Login/Belt/eyes-lash")
      public static let eyesSleepy = ImageAsset(name: "Login/Belt/eyes-sleepy")
    }
    public enum Logo {
      public static let apple = ImageAsset(name: "Login/Logo/apple")
      public static let google = ImageAsset(name: "Login/Logo/google")
      public static let kakao = ImageAsset(name: "Login/Logo/kakao")
    }
    public static let pattern = ImageAsset(name: "Login/pattern")
  }
  public enum MyProfile {
    public enum Background {
      public static let styleArmLock = ImageAsset(name: "MyProfile/Background/style-arm-lock")
      public static let styleChoke = ImageAsset(name: "MyProfile/Background/style-choke")
      public static let styleEscapeDefense = ImageAsset(name: "MyProfile/Background/style-escape-defense")
      public static let styleGuardPass = ImageAsset(name: "MyProfile/Background/style-guard-pass")
      public static let styleGuardPosition = ImageAsset(name: "MyProfile/Background/style-guard-position")
      public static let styleLegLock = ImageAsset(name: "MyProfile/Background/style-leg-lock")
      public static let styleSweep = ImageAsset(name: "MyProfile/Background/style-sweep")
      public static let styleTakedown = ImageAsset(name: "MyProfile/Background/style-takedown")
      public static let styleTopPosition = ImageAsset(name: "MyProfile/Background/style-top-position")
    }
    public enum Card {
      public static let styleArmLock = ImageAsset(name: "MyProfile/Card/style-arm-lock")
      public static let styleEscapeDefense = ImageAsset(name: "MyProfile/Card/style-escape-defense")
      public static let styleGuardPosition = ImageAsset(name: "MyProfile/Card/style-guard-position")
      public static let styleTopPosition = ImageAsset(name: "MyProfile/Card/style-top-position")
    }
    public enum Icon {
      public static let badgeCheckLight = ImageAsset(name: "MyProfile/Icon/badge-check-light")
      public static let beltBlack = ImageAsset(name: "MyProfile/Icon/belt-black")
      public static let beltBlue = ImageAsset(name: "MyProfile/Icon/belt-blue")
      public static let beltBrown = ImageAsset(name: "MyProfile/Icon/belt-brown")
      public static let beltPurple = ImageAsset(name: "MyProfile/Icon/belt-purple")
      public static let beltWhite = ImageAsset(name: "MyProfile/Icon/belt-white")
      public static let camera = ImageAsset(name: "MyProfile/Icon/camera")
      public static let medalBronze = ImageAsset(name: "MyProfile/Icon/medal-bronze")
      public static let medalDefaultDisable = ImageAsset(name: "MyProfile/Icon/medal-default-disable")
      public static let medalDefault = ImageAsset(name: "MyProfile/Icon/medal-default")
      public static let medalGold = ImageAsset(name: "MyProfile/Icon/medal-gold")
      public static let medalSilver = ImageAsset(name: "MyProfile/Icon/medal-silver")
      public static let menu = ImageAsset(name: "MyProfile/Icon/menu")
      public static let styleArmLock = ImageAsset(name: "MyProfile/Icon/style-arm-lock")
      public static let styleChoke = ImageAsset(name: "MyProfile/Icon/style-choke")
      public static let styleEscapeDefense = ImageAsset(name: "MyProfile/Icon/style-escape-defense")
      public static let styleGuardPass = ImageAsset(name: "MyProfile/Icon/style-guard-pass")
      public static let styleGuardPosition = ImageAsset(name: "MyProfile/Icon/style-guard-position")
      public static let styleLegLock = ImageAsset(name: "MyProfile/Icon/style-leg-lock")
      public static let styleSweep = ImageAsset(name: "MyProfile/Icon/style-sweep")
      public static let styleTakedown = ImageAsset(name: "MyProfile/Icon/style-takedown")
      public static let styleTopPosition = ImageAsset(name: "MyProfile/Icon/style-top-position")
      public static let triangleAlert = ImageAsset(name: "MyProfile/Icon/triangle-alert")
    }
    public enum Medal {
      public static let blackBronze = ImageAsset(name: "MyProfile/Medal/black-bronze")
      public static let blackGold = ImageAsset(name: "MyProfile/Medal/black-gold")
      public static let blackParticipation = ImageAsset(name: "MyProfile/Medal/black-participation")
      public static let blackSilver = ImageAsset(name: "MyProfile/Medal/black-silver")
      public static let blueBronze = ImageAsset(name: "MyProfile/Medal/blue-bronze")
      public static let blueGold = ImageAsset(name: "MyProfile/Medal/blue-gold")
      public static let blueParticipation = ImageAsset(name: "MyProfile/Medal/blue-participation")
      public static let blueSilver = ImageAsset(name: "MyProfile/Medal/blue-silver")
      public static let brownBronze = ImageAsset(name: "MyProfile/Medal/brown-bronze")
      public static let brownGold = ImageAsset(name: "MyProfile/Medal/brown-gold")
      public static let brownParticipation = ImageAsset(name: "MyProfile/Medal/brown-participation")
      public static let brownSilver = ImageAsset(name: "MyProfile/Medal/brown-silver")
      public static let purpleBronze = ImageAsset(name: "MyProfile/Medal/purple-bronze")
      public static let purpleGold = ImageAsset(name: "MyProfile/Medal/purple-gold")
      public static let purpleParticipation = ImageAsset(name: "MyProfile/Medal/purple-participation")
      public static let purpleSilver = ImageAsset(name: "MyProfile/Medal/purple-silver")
      public static let whiteBronze = ImageAsset(name: "MyProfile/Medal/white-bronze")
      public static let whiteGold = ImageAsset(name: "MyProfile/Medal/white-gold")
      public static let whiteParticipation = ImageAsset(name: "MyProfile/Medal/white-participation")
      public static let whiteSilver = ImageAsset(name: "MyProfile/Medal/white-silver")
    }
  }
  public enum Signup {
    public enum Icon {
      public static let signupComplete = ImageAsset(name: "Signup/Icon/signup-complete")
    }
  }
  public enum Splash {
    public static let logo = ImageAsset(name: "Splash/logo")
    public static let pattern = ImageAsset(name: "Splash/pattern")
    public static let tagline = ImageAsset(name: "Splash/tagline")
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
