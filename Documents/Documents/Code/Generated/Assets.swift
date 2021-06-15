// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ColorAsset.Color", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetColorTypeAlias = ColorAsset.Color
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Colors {
    internal static let action = ColorAsset(name: "action")
    internal static let brend = ColorAsset(name: "brend")
    internal static let grayLight = ColorAsset(name: "gray-light")
    internal static let tableBackground = ColorAsset(name: "table-background")
    internal static let tableCategoryBackground = ColorAsset(name: "table-category-background")
    internal static let tableCellSelected = ColorAsset(name: "table-cell-selected")
    internal static let tableCellSeparator = ColorAsset(name: "table-cell-separator")
    internal static let textSubtitle = ColorAsset(name: "text-subtitle")
    internal static let viewBackground = ColorAsset(name: "view-background")
  }
  internal enum Images {
    internal static let _2faStepAppend = ImageAsset(name: "2fa-step-append")
    internal static let _2faStepCode = ImageAsset(name: "2fa-step-code")
    internal static let _2faStepInstall = ImageAsset(name: "2fa-step-install")
    internal static let _2faStepSecret = ImageAsset(name: "2fa-step-secret")
    internal static let barCopy = ImageAsset(name: "bar-copy")
    internal static let barDeleteAll = ImageAsset(name: "bar-delete-all")
    internal static let barDeleteLink = ImageAsset(name: "bar-delete-link")
    internal static let barDelete = ImageAsset(name: "bar-delete")
    internal static let barMove = ImageAsset(name: "bar-move")
    internal static let barRecover = ImageAsset(name: "bar-recover")
    internal static let barSelect = ImageAsset(name: "bar-select")
    internal static let navAdd = ImageAsset(name: "nav-add")
    internal static let navBack = ImageAsset(name: "nav-back")
    internal static let navMore = ImageAsset(name: "nav-more")
    internal static let navSelect = ImageAsset(name: "nav-select")
    internal static let navSort = ImageAsset(name: "nav-sort")
    internal static let categoryCommon = ImageAsset(name: "category-common")
    internal static let categoryFavorites = ImageAsset(name: "category-favorites")
    internal static let categoryIpadNew = ImageAsset(name: "category-ipad-new")
    internal static let categoryIpad = ImageAsset(name: "category-ipad")
    internal static let categoryIphoneNew = ImageAsset(name: "category-iphone-new")
    internal static let categoryIphone = ImageAsset(name: "category-iphone")
    internal static let categoryMy = ImageAsset(name: "category-my")
    internal static let categoryProjects = ImageAsset(name: "category-projects")
    internal static let categoryRecent = ImageAsset(name: "category-recent")
    internal static let categoryShare = ImageAsset(name: "category-share")
    internal static let categoryTrash = ImageAsset(name: "category-trash")
    internal static let cloudAppend = ImageAsset(name: "cloud-append")
    internal static let cloudAws = ImageAsset(name: "cloud-aws")
    internal static let cloudBox = ImageAsset(name: "cloud-box")
    internal static let cloudDocusign = ImageAsset(name: "cloud-docusign")
    internal static let cloudDropbox = ImageAsset(name: "cloud-dropbox")
    internal static let cloudGoogleDrive = ImageAsset(name: "cloud-google-drive")
    internal static let cloudIcloud = ImageAsset(name: "cloud-icloud")
    internal static let cloudNextcloud = ImageAsset(name: "cloud-nextcloud")
    internal static let cloudOnedrive = ImageAsset(name: "cloud-onedrive")
    internal static let cloudOwncloud = ImageAsset(name: "cloud-owncloud")
    internal static let cloudSharepoint = ImageAsset(name: "cloud-sharepoint")
    internal static let cloudWebdav = ImageAsset(name: "cloud-webdav")
    internal static let cloudYandexDisk = ImageAsset(name: "cloud-yandex-disk")
    internal static let createCamera = ImageAsset(name: "create-camera")
    internal static let createCloud = ImageAsset(name: "create-cloud")
    internal static let createDocument = ImageAsset(name: "create-document")
    internal static let createNewFolder = ImageAsset(name: "create-new-folder")
    internal static let createPresentation = ImageAsset(name: "create-presentation")
    internal static let createSpreadsheet = ImageAsset(name: "create-spreadsheet")
    internal static let createUploadFile = ImageAsset(name: "create-upload-file")
    internal static let createUploadImage = ImageAsset(name: "create-upload-image")
    internal static let emptyCommonError = ImageAsset(name: "empty-common-error")
    internal static let emptyConnectToCloud = ImageAsset(name: "empty-connect-to-cloud")
    internal static let emptyFolder = ImageAsset(name: "empty-folder")
    internal static let emptyNoConnection = ImageAsset(name: "empty-no-connection")
    internal static let emptySearchResult = ImageAsset(name: "empty-search-result")
    internal static let emptyTrash = ImageAsset(name: "empty-trash")
    internal static let hudCheckmark = ImageAsset(name: "hud-checkmark")
    internal static let mailNotification = ImageAsset(name: "mail-notification")
    internal static let introStepFive = ImageAsset(name: "intro-step-five")
    internal static let introStepFour = ImageAsset(name: "intro-step-four")
    internal static let introStepOne = ImageAsset(name: "intro-step-one")
    internal static let introStepThree = ImageAsset(name: "intro-step-three")
    internal static let introStepTwo = ImageAsset(name: "intro-step-two")
    internal static let listFolderBoxnet = ImageAsset(name: "list-folder-boxnet")
    internal static let listFolderDropbox = ImageAsset(name: "list-folder-dropbox")
    internal static let listFolderGoogledrive = ImageAsset(name: "list-folder-googledrive")
    internal static let listFolderNextcloud = ImageAsset(name: "list-folder-nextcloud")
    internal static let listFolderOnedrive = ImageAsset(name: "list-folder-onedrive")
    internal static let listFolderOwncloud = ImageAsset(name: "list-folder-owncloud")
    internal static let listFolderSharepoint = ImageAsset(name: "list-folder-sharepoint")
    internal static let listFolderWebdav = ImageAsset(name: "list-folder-webdav")
    internal static let listFolderYandexdisk = ImageAsset(name: "list-folder-yandexdisk")
    internal static let listFolder = ImageAsset(name: "list-folder")
    internal static let listFormatDocument = ImageAsset(name: "list-format-document")
    internal static let listFormatImage = ImageAsset(name: "list-format-image")
    internal static let listFormatPdf = ImageAsset(name: "list-format-pdf")
    internal static let listFormatPresentation = ImageAsset(name: "list-format-presentation")
    internal static let listFormatSpreadsheet = ImageAsset(name: "list-format-spreadsheet")
    internal static let listFormatUnknown = ImageAsset(name: "list-format-unknown")
    internal static let listFormatVideo = ImageAsset(name: "list-format-video")
    internal static let listMenuCopy = ImageAsset(name: "list-menu-copy")
    internal static let listMenuDownload = ImageAsset(name: "list-menu-download")
    internal static let listMenuMore = ImageAsset(name: "list-menu-more")
    internal static let listMenuMove = ImageAsset(name: "list-menu-move")
    internal static let listMenuRename = ImageAsset(name: "list-menu-rename")
    internal static let listMenuRestore = ImageAsset(name: "list-menu-restore")
    internal static let listMenuTrash = ImageAsset(name: "list-menu-trash")
    internal static let listMenuUpload = ImageAsset(name: "list-menu-upload")
    internal static let signinFacebook = ImageAsset(name: "signin-facebook")
    internal static let signinGoogle = ImageAsset(name: "signin-google")
    internal static let signinLinkedin = ImageAsset(name: "signin-linkedin")
    internal static let signinSso = ImageAsset(name: "signin-sso")
    internal static let signinTwitter = ImageAsset(name: "signin-twitter")
    internal static let categoryLogo = ImageAsset(name: "category-logo")
    internal static let logoLargeHorizontal = ImageAsset(name: "logo-large-horizontal")
    internal static let logoLarge = ImageAsset(name: "logo-large")
    internal static let avatarDefaultGroup = ImageAsset(name: "avatar-default-group")
    internal static let avatarDefault = ImageAsset(name: "avatar-default")
    internal static let passcodeLockSplash = ImageAsset(name: "passcode-lock-splash")
    internal static let shortcutCreateDoc = ImageAsset(name: "shortcut-create-doc")
    internal static let shortcutCreatePres = ImageAsset(name: "shortcut-create-pres")
    internal static let shortcutCreateSs = ImageAsset(name: "shortcut-create-ss")
    internal static let logoBoxnetLarge = ImageAsset(name: "logo-boxnet-large")
    internal static let logoDropboxLarge = ImageAsset(name: "logo-dropbox-large")
    internal static let logoGoogledriveLarge = ImageAsset(name: "logo-googledrive-large")
    internal static let logoNextcloudLarge = ImageAsset(name: "logo-nextcloud-large")
    internal static let logoOnedriveLarge = ImageAsset(name: "logo-onedrive-large")
    internal static let logoOnedriveproLarge = ImageAsset(name: "logo-onedrivepro-large")
    internal static let logoOwncloudLarge = ImageAsset(name: "logo-owncloud-large")
    internal static let logoSharepointLarge = ImageAsset(name: "logo-sharepoint-large")
    internal static let logoWebdavLarge = ImageAsset(name: "logo-webdav-large")
    internal static let logoYandexdiskLarge = ImageAsset(name: "logo-yandexdisk-large")
    internal static let logoYandexdiskRuLarge = ImageAsset(name: "logo-yandexdisk-ru-large")
    internal static let tabCloudSelected = ImageAsset(name: "tab-cloud-selected")
    internal static let tabCloud = ImageAsset(name: "tab-cloud")
    internal static let tabIpadNew = ImageAsset(name: "tab-ipad-new")
    internal static let tabIpad = ImageAsset(name: "tab-ipad")
    internal static let tabIphoneX = ImageAsset(name: "tab-iphone-x")
    internal static let tabIphone = ImageAsset(name: "tab-iphone")
    internal static let tabOnlyofficeSelected = ImageAsset(name: "tab-onlyoffice-selected")
    internal static let tabOnlyoffice = ImageAsset(name: "tab-onlyoffice")
    internal static let tabSettingsSelected = ImageAsset(name: "tab-settings-selected")
    internal static let tabSettings = ImageAsset(name: "tab-settings")
    internal static let whatsnewFutureFavourite = ImageAsset(name: "whatsnew-future-favourite")
    internal static let whatsnewFutureIcloudDrive = ImageAsset(name: "whatsnew-future-icloud-drive")
    internal static let whatsnewFutureShare = ImageAsset(name: "whatsnew-future-share")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal final class ColorAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Color = NSColor
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Color = UIColor
  #endif

  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  internal private(set) lazy var color: Color = {
    guard let color = Color(asset: self) else {
      fatalError("Unable to load color asset named \(name).")
    }
    return color
  }()

  fileprivate init(name: String) {
    self.name = name
  }
}

internal extension ColorAsset.Color {
  @available(iOS 11.0, tvOS 11.0, watchOS 4.0, macOS 10.13, *)
  convenience init?(asset: ColorAsset) {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSColor.Name(asset.name), bundle: bundle)
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
  }
}

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
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
}

internal extension ImageAsset.Image {
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
