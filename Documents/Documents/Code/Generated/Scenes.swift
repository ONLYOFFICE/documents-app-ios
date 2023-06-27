// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

// swiftlint:disable sorted_imports
import Foundation
import UIKit

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length implicit_return

// MARK: - Storyboard Scenes

// swiftlint:disable explicit_type_interface identifier_name line_length type_body_length type_name
internal enum StoryboardScene {
  internal enum ConnectStorage: StoryboardType {
    internal static let storyboardName = "ConnectStorage"

    internal static let ascConnectCloudViewController = SceneType<Documents.ASCConnectCloudViewController>(storyboard: Self.self, identifier: "ASCConnectCloudViewController")

    internal static let ascConnectPortalThirdPartyViewController = SceneType<Documents.ASCConnectPortalThirdPartyViewController>(storyboard: Self.self, identifier: "ASCConnectPortalThirdPartyViewController")

    internal static let ascConnectStorageNextCloudServerController = SceneType<Documents.ASCConnectStorageNextCloudServerController>(storyboard: Self.self, identifier: "ASCConnectStorageNextCloudServerController")

    internal static let ascConnectStorageOAuth2ViewController = SceneType<Documents.ASCConnectStorageOAuth2ViewController>(storyboard: Self.self, identifier: "ASCConnectStorageOAuth2ViewController")

    internal static let ascConnectStorageWebDavController = SceneType<Documents.ASCConnectStorageWebDavController>(storyboard: Self.self, identifier: "ASCConnectStorageWebDavController")
  }
  internal enum CreatePortal: StoryboardType {
    internal static let storyboardName = "CreatePortal"

    internal static let initialScene = InitialSceneType<Documents.ASCCreatePortalViewController>(storyboard: Self.self)

    internal static let createPortalStepOneController = SceneType<Documents.ASCCreatePortalViewController>(storyboard: Self.self, identifier: "createPortalStepOneController")

    internal static let createPortalStepTwoController = SceneType<Documents.ASCCreatePortalViewController>(storyboard: Self.self, identifier: "createPortalStepTwoController")
  }
  internal enum Debug: StoryboardType {
    internal static let storyboardName = "Debug"

    internal static let ascDebugConsoleViewController = SceneType<Documents.ASCDebugConsoleViewController>(storyboard: Self.self, identifier: "ASCDebugConsoleViewController")

    internal static let ascDebugNavigationController = SceneType<Documents.ASCDebugNavigationController>(storyboard: Self.self, identifier: "ASCDebugNavigationController")
  }
  internal enum Intro: StoryboardType {
    internal static let storyboardName = "Intro"

    internal static let initialScene = InitialSceneType<Documents.ASCIntroViewController>(storyboard: Self.self)

    internal static let ascIntroPageController = SceneType<Documents.ASCIntroPageController>(storyboard: Self.self, identifier: "ASCIntroPageController")

    internal static let ascIntroViewController = SceneType<Documents.ASCIntroViewController>(storyboard: Self.self, identifier: "ASCIntroViewController")
  }
  internal enum LaunchScreen: StoryboardType {
    internal static let storyboardName = "LaunchScreen"

    internal static let initialScene = InitialSceneType<UIKit.UIViewController>(storyboard: Self.self)
  }
  internal enum Login: StoryboardType {
    internal static let storyboardName = "Login"

    internal static let initialScene = InitialSceneType<Documents.ASCBaseNavigationController>(storyboard: Self.self)

    internal static let asc2FACodeViewController = SceneType<Documents.ASC2FACodeViewController>(storyboard: Self.self, identifier: "ASC2FACodeViewController")

    internal static let asc2FAStepCodePageController = SceneType<Documents.ASC2FACodeViewController>(storyboard: Self.self, identifier: "ASC2FAStepCodePageController")

    internal static let asc2FAStepInstallAppPageController = SceneType<Documents.ASC2FAPageController>(storyboard: Self.self, identifier: "ASC2FAStepInstallAppPageController")

    internal static let asc2FAStepRunAppPageController = SceneType<Documents.ASC2FAPageController>(storyboard: Self.self, identifier: "ASC2FAStepRunAppPageController")

    internal static let asc2FAStepSecretPageController = SceneType<Documents.ASC2FAPageController>(storyboard: Self.self, identifier: "ASC2FAStepSecretPageController")

    internal static let asc2FAViewController = SceneType<Documents.ASC2FAViewController>(storyboard: Self.self, identifier: "ASC2FAViewController")

    internal static let ascConnectPortalViewController = SceneType<Documents.ASCConnectPortalViewController>(storyboard: Self.self, identifier: "ASCConnectPortalViewController")

    internal static let ascCountryCodeViewController = SceneType<Documents.ASCCountryCodeViewController>(storyboard: Self.self, identifier: "ASCCountryCodeViewController")

    internal static let ascEmailSentViewController = SceneType<Documents.ASCEmailSentViewController>(storyboard: Self.self, identifier: "ASCEmailSentViewController")

    internal static let ascPasswordRecoveryViewController = SceneType<Documents.ASCPasswordRecoveryViewController>(storyboard: Self.self, identifier: "ASCPasswordRecoveryViewController")

    internal static let ascPhoneNumberViewController = SceneType<Documents.ASCPhoneNumberViewController>(storyboard: Self.self, identifier: "ASCPhoneNumberViewController")

    internal static let ascsmsCodeViewController = SceneType<Documents.ASCSMSCodeViewController>(storyboard: Self.self, identifier: "ASCSMSCodeViewController")

    internal static let ascssoSignInNavigationController = SceneType<Documents.ASCBaseNavigationController>(storyboard: Self.self, identifier: "ASCSSOSignInNavigationController")

    internal static let ascSignInViewController = SceneType<Documents.ASCSignInViewController>(storyboard: Self.self, identifier: "ASCSignInViewController")
  }
  internal enum Main: StoryboardType {
    internal static let storyboardName = "Main"

    internal static let ascCloudsEmptyViewController = SceneType<Documents.ASCCloudsEmptyViewController>(storyboard: Self.self, identifier: "ASCCloudsEmptyViewController")

    internal static let ascDocumentsNavigationController = SceneType<Documents.ASCDocumentsNavigationController>(storyboard: Self.self, identifier: "ASCDocumentsNavigationController")

    internal static let ascDocumentsViewController = SceneType<Documents.ASCDocumentsViewController>(storyboard: Self.self, identifier: "ASCDocumentsViewController")

    internal static let ascRootViewController = SceneType<Documents.ASCRootViewController>(storyboard: Self.self, identifier: "ASCRootViewController")

    internal static let ascSplashViewController = SceneType<UIKit.UIViewController>(storyboard: Self.self, identifier: "ASCSplashViewController")
  }
  internal enum Settings: StoryboardType {
    internal static let storyboardName = "Settings"

    internal static let initialScene = InitialSceneType<Documents.ASCBaseNavigationController>(storyboard: Self.self)

    internal static let ascAboutViewController = SceneType<Documents.ASCAboutViewController>(storyboard: Self.self, identifier: "ASCAboutViewController")

    internal static let ascPasscodeLockViewController = SceneType<Documents.ASCPasscodeLockViewController>(storyboard: Self.self, identifier: "ASCPasscodeLockViewController")
  }
  internal enum Sort: StoryboardType {
    internal static let storyboardName = "Sort"

    internal static let initialScene = InitialSceneType<Documents.ASCSortViewController>(storyboard: Self.self)

    internal static let ascSortViewController = SceneType<Documents.ASCSortViewController>(storyboard: Self.self, identifier: "ASCSortViewController")
  }
  internal enum Transfer: StoryboardType {
    internal static let storyboardName = "Transfer"

    internal static let initialScene = InitialSceneType<Documents.ASCTransferNavigationController>(storyboard: Self.self)

    internal static let ascTransferNavigationController = SceneType<Documents.ASCTransferNavigationController>(storyboard: Self.self, identifier: "ASCTransferNavigationController")

    internal static let ascTransferViewController = SceneType<Documents.ASCTransferViewController>(storyboard: Self.self, identifier: "ASCTransferViewController")
  }
  internal enum UserProfile: StoryboardType {
    internal static let storyboardName = "UserProfile"

    internal static let initialScene = InitialSceneType<Documents.ASCBaseNavigationController>(storyboard: Self.self)

    internal static let ascUserProfileViewController = SceneType<Documents.ASCUserProfileViewController>(storyboard: Self.self, identifier: "ASCUserProfileViewController")
  }
}
// swiftlint:enable explicit_type_interface identifier_name line_length type_body_length type_name

// MARK: - Implementation Details

internal protocol StoryboardType {
  static var storyboardName: String { get }
}

internal extension StoryboardType {
  static var storyboard: UIStoryboard {
    let name = self.storyboardName
    return UIStoryboard(name: name, bundle: BundleToken.bundle)
  }
}

internal struct SceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type
  internal let identifier: String

  internal func instantiate() -> T {
    let identifier = self.identifier
    guard let controller = storyboard.storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
      fatalError("ViewController '\(identifier)' is not of the expected class \(T.self).")
    }
    return controller
  }

  @available(iOS 13.0, tvOS 13.0, *)
  internal func instantiate(creator block: @escaping (NSCoder) -> T?) -> T {
    return storyboard.storyboard.instantiateViewController(identifier: identifier, creator: block)
  }
}

internal struct InitialSceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type

  internal func instantiate() -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController() as? T else {
      fatalError("ViewController is not of the expected class \(T.self).")
    }
    return controller
  }

  @available(iOS 13.0, tvOS 13.0, *)
  internal func instantiate(creator block: @escaping (NSCoder) -> T?) -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController(creator: block) else {
      fatalError("Storyboard \(storyboard.storyboardName) does not have an initial scene.")
    }
    return controller
  }
}

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
