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

    internal static let ascConnectCloudViewController = SceneType<Documents_withouteditors.ASCConnectCloudViewController>(storyboard: ConnectStorage.self, identifier: "ASCConnectCloudViewController")

    internal static let ascConnectPortalThirdPartyViewController = SceneType<Documents_withouteditors.ASCConnectPortalThirdPartyViewController>(storyboard: ConnectStorage.self, identifier: "ASCConnectPortalThirdPartyViewController")

    internal static let ascConnectStorageNextCloudServerController = SceneType<Documents_withouteditors.ASCConnectStorageNextCloudServerController>(storyboard: ConnectStorage.self, identifier: "ASCConnectStorageNextCloudServerController")

    internal static let ascConnectStorageOAuth2ViewController = SceneType<Documents_withouteditors.ASCConnectStorageOAuth2ViewController>(storyboard: ConnectStorage.self, identifier: "ASCConnectStorageOAuth2ViewController")

    internal static let ascConnectStorageWebDavController = SceneType<Documents_withouteditors.ASCConnectStorageWebDavController>(storyboard: ConnectStorage.self, identifier: "ASCConnectStorageWebDavController")
  }
  internal enum CreatePortal: StoryboardType {
    internal static let storyboardName = "CreatePortal"

    internal static let initialScene = InitialSceneType<Documents_withouteditors.ASCCreatePortalViewController>(storyboard: CreatePortal.self)

    internal static let createPortalStepOneController = SceneType<Documents_withouteditors.ASCCreatePortalViewController>(storyboard: CreatePortal.self, identifier: "createPortalStepOneController")

    internal static let createPortalStepTwoController = SceneType<Documents_withouteditors.ASCCreatePortalViewController>(storyboard: CreatePortal.self, identifier: "createPortalStepTwoController")
  }
  internal enum Debug: StoryboardType {
    internal static let storyboardName = "Debug"

    internal static let ascDebugConsoleViewController = SceneType<Documents_withouteditors.ASCDebugConsoleViewController>(storyboard: Debug.self, identifier: "ASCDebugConsoleViewController")

    internal static let ascDebugNavigationController = SceneType<Documents_withouteditors.ASCDebugNavigationController>(storyboard: Debug.self, identifier: "ASCDebugNavigationController")
  }
  internal enum Intro: StoryboardType {
    internal static let storyboardName = "Intro"

    internal static let initialScene = InitialSceneType<Documents_withouteditors.ASCIntroViewController>(storyboard: Intro.self)

    internal static let ascIntroPageController = SceneType<Documents_withouteditors.ASCIntroPageController>(storyboard: Intro.self, identifier: "ASCIntroPageController")

    internal static let ascIntroViewController = SceneType<Documents_withouteditors.ASCIntroViewController>(storyboard: Intro.self, identifier: "ASCIntroViewController")
  }
  internal enum LaunchScreen: StoryboardType {
    internal static let storyboardName = "LaunchScreen"

    internal static let initialScene = InitialSceneType<UIKit.UIViewController>(storyboard: LaunchScreen.self)
  }
  internal enum Login: StoryboardType {
    internal static let storyboardName = "Login"

    internal static let initialScene = InitialSceneType<Documents_withouteditors.ASCBaseNavigationController>(storyboard: Login.self)

    internal static let asc2FACodeViewController = SceneType<Documents_withouteditors.ASC2FACodeViewController>(storyboard: Login.self, identifier: "ASC2FACodeViewController")

    internal static let asc2FAStepCodePageController = SceneType<Documents_withouteditors.ASC2FACodeViewController>(storyboard: Login.self, identifier: "ASC2FAStepCodePageController")

    internal static let asc2FAStepInstallAppPageController = SceneType<Documents_withouteditors.ASC2FAPageController>(storyboard: Login.self, identifier: "ASC2FAStepInstallAppPageController")

    internal static let asc2FAStepRunAppPageController = SceneType<Documents_withouteditors.ASC2FAPageController>(storyboard: Login.self, identifier: "ASC2FAStepRunAppPageController")

    internal static let asc2FAStepSecretPageController = SceneType<Documents_withouteditors.ASC2FAPageController>(storyboard: Login.self, identifier: "ASC2FAStepSecretPageController")

    internal static let asc2FAViewController = SceneType<Documents_withouteditors.ASC2FAViewController>(storyboard: Login.self, identifier: "ASC2FAViewController")

    internal static let ascAccountsViewController = SceneType<Documents_withouteditors.ASCAccountsViewController>(storyboard: Login.self, identifier: "ASCAccountsViewController")

    internal static let ascConnectPortalViewController = SceneType<Documents_withouteditors.ASCConnectPortalViewController>(storyboard: Login.self, identifier: "ASCConnectPortalViewController")

    internal static let ascCountryCodeViewController = SceneType<Documents_withouteditors.ASCCountryCodeViewController>(storyboard: Login.self, identifier: "ASCCountryCodeViewController")

    internal static let ascEmailSentViewController = SceneType<Documents_withouteditors.ASCEmailSentViewController>(storyboard: Login.self, identifier: "ASCEmailSentViewController")

    internal static let ascPasswordRecoveryViewController = SceneType<Documents_withouteditors.ASCPasswordRecoveryViewController>(storyboard: Login.self, identifier: "ASCPasswordRecoveryViewController")

    internal static let ascPhoneNumberViewController = SceneType<Documents_withouteditors.ASCPhoneNumberViewController>(storyboard: Login.self, identifier: "ASCPhoneNumberViewController")

    internal static let ascsmsCodeViewController = SceneType<Documents_withouteditors.ASCSMSCodeViewController>(storyboard: Login.self, identifier: "ASCSMSCodeViewController")

    internal static let ascssoSignInNavigationController = SceneType<Documents_withouteditors.ASCBaseNavigationController>(storyboard: Login.self, identifier: "ASCSSOSignInNavigationController")

    internal static let ascSignInViewController = SceneType<Documents_withouteditors.ASCSignInViewController>(storyboard: Login.self, identifier: "ASCSignInViewController")
  }
  internal enum Main: StoryboardType {
    internal static let storyboardName = "Main"

    internal static let ascCloudsEmptyViewController = SceneType<Documents_withouteditors.ASCCloudsEmptyViewController>(storyboard: Main.self, identifier: "ASCCloudsEmptyViewController")

    internal static let ascDocumentsNavigationController = SceneType<Documents_withouteditors.ASCDocumentsNavigationController>(storyboard: Main.self, identifier: "ASCDocumentsNavigationController")

    internal static let ascDocumentsViewController = SceneType<Documents_withouteditors.ASCDocumentsViewController>(storyboard: Main.self, identifier: "ASCDocumentsViewController")

    internal static let ascRootViewController = SceneType<Documents_withouteditors.ASCRootViewController>(storyboard: Main.self, identifier: "ASCRootViewController")

    internal static let ascSplashViewController = SceneType<UIKit.UIViewController>(storyboard: Main.self, identifier: "ASCSplashViewController")
  }
  internal enum Settings: StoryboardType {
    internal static let storyboardName = "Settings"

    internal static let initialScene = InitialSceneType<Documents_withouteditors.ASCBaseNavigationController>(storyboard: Settings.self)

    internal static let ascAboutViewController = SceneType<Documents_withouteditors.ASCAboutViewController>(storyboard: Settings.self, identifier: "ASCAboutViewController")

    internal static let ascPasscodeLockViewController = SceneType<Documents_withouteditors.ASCPasscodeLockViewController>(storyboard: Settings.self, identifier: "ASCPasscodeLockViewController")
  }
  internal enum Sort: StoryboardType {
    internal static let storyboardName = "Sort"

    internal static let initialScene = InitialSceneType<Documents_withouteditors.ASCSortViewController>(storyboard: Sort.self)

    internal static let ascSortViewController = SceneType<Documents_withouteditors.ASCSortViewController>(storyboard: Sort.self, identifier: "ASCSortViewController")
  }
  internal enum Transfer: StoryboardType {
    internal static let storyboardName = "Transfer"

    internal static let initialScene = InitialSceneType<Documents_withouteditors.ASCTransferNavigationController>(storyboard: Transfer.self)

    internal static let ascTransferNavigationController = SceneType<Documents_withouteditors.ASCTransferNavigationController>(storyboard: Transfer.self, identifier: "ASCTransferNavigationController")

    internal static let ascTransferViewController = SceneType<Documents_withouteditors.ASCTransferViewController>(storyboard: Transfer.self, identifier: "ASCTransferViewController")
  }
  internal enum UserProfile: StoryboardType {
    internal static let storyboardName = "UserProfile"

    internal static let initialScene = InitialSceneType<Documents_withouteditors.ASCBaseNavigationController>(storyboard: UserProfile.self)

    internal static let ascUserProfileViewController = SceneType<Documents_withouteditors.ASCUserProfileViewController>(storyboard: UserProfile.self, identifier: "ASCUserProfileViewController")
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
